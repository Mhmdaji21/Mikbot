import telebot
from telebot import types
from routeros_api import RouterOsApiPool
import threading
import time
import requests
import telnetlib
import re
import config  # Mengambil data dari config.py

# Inisialisasi Bot
bot = telebot.TeleBot(config.TOKEN)
last_arp_list = []
vendor_cache = {}

# --- FUNGSI KONEKSI MIKROTIK ---
def get_api():
    return RouterOsApiPool(
        config.MT_HOST, 
        username=config.MT_USER, 
        password=config.MT_PASS, 
        port=config.MT_PORT, 
        plaintext_login=True
    )

# --- FUNGSI VENDOR LOOKUP ---
def get_vendor(mac):
    if mac in vendor_cache: return vendor_cache[mac]
    try:
        # Menggunakan API eksternal untuk cek merk perangkat
        response = requests.get(f"https://api.macvendors.com/{mac}", timeout=2)
        if response.status_code == 200:
            vendor = response.text
            vendor_cache[mac] = vendor
            return vendor
    except: pass
    return "Unknown Device"

# --- FUNGSI TELNET MODEM HUAWEI ---
def get_redaman():
    try:
        tn = telnetlib.Telnet(config.MODEM_HOST, timeout=5)
        
        # Handler Login
        tn.expect([b"Login:", b"username:", b"Name:", b"User:"], timeout=3)
        tn.write(config.MODEM_USER.encode('ascii') + b"\n")
        tn.read_until(b"Password:", timeout=2)
        tn.write(config.MODEM_PASS.encode('ascii') + b"\n")
        
        time.sleep(0.5)
        tn.write(b"wap\n") # Masuk ke mode WAP
        time.sleep(0.5)
        tn.write(b"display optic\n") 
        time.sleep(1.5)
        
        output = tn.read_very_eager().decode('ascii', errors='ignore')
        tn.write(b"quit\n")
        
        # Mencari angka Rx dan Tx dengan Regex
        rx_match = re.search(r"(?:Rx|receive).*?([-+]?\d+\.\d+)", output, re.IGNORECASE)
        tx_match = re.search(r"(?:Tx|transmit).*?([-+]?\d+\.\d+)", output, re.IGNORECASE)
        
        if rx_match:
            rx = rx_match.group(1)
            tx = tx_match.group(1) if tx_match else "N/A"
            val_rx = float(rx)
            # Logika indikator warna
            status = "✅ BAGUS" if val_rx > -25 else "🟡 CUKUP" if val_rx > -27 else "🚨 BURUK"
            return f"📥 <b>Rx Power:</b> <code>{rx} dBm</code>\n📤 <b>Tx Power:</b> <code>{tx} dBm</code>\n📊 <b>Status  :</b> {status}"
        return "❌ Gagal parsing data. Pastikan perintah 'display optic' benar."
    except Exception as e:
        return f"❌ Telnet Error: {e}"

# --- MENU UI ---
def menu_mikrotik():
    markup = types.InlineKeyboardMarkup()
    markup.row(types.InlineKeyboardButton("🖥️ RESOURCE", callback_data="cek_status"),
               types.InlineKeyboardButton("📋 CEK ARP", callback_data="cek_arp"))
    return markup

def menu_modem():
    markup = types.InlineKeyboardMarkup()
    markup.row(types.InlineKeyboardButton("📡 CEK REDAMAN", callback_data="cek_opm"))
    return markup

# --- HANDLER COMMAND ---
@bot.message_handler(commands=['start', 'menu'])
def send_welcome(message):
    bot.send_message(config.CHAT_ID, "🖥️ <b>MikroTik Monitor</b>", parse_mode='HTML', 
                     reply_markup=menu_mikrotik(), message_thread_id=config.THREAD_UTAMA)
    bot.send_message(config.CHAT_ID, "📡 <b>Modem Control</b>", parse_mode='HTML', 
                     reply_markup=menu_modem(), message_thread_id=config.THREAD_MODEM)

# --- HANDLER CALLBACK (TOMBOL) ---
@bot.callback_query_handler(func=lambda call: True)
def callback_query(call):
    if call.data == "cek_opm":
        bot.answer_callback_query(call.id, "Checking OPM...")
        bot.send_message(config.CHAT_ID, f"<b>🔌 OPTIK INFO</b>\n{get_redaman()}", 
                         parse_mode='HTML', message_thread_id=config.THREAD_MODEM, reply_markup=menu_modem())
    
    elif call.data == "cek_status":
        try:
            conn = get_api(); api = conn.get_api()
            res = api.get_resource('/system/resource').get()[0]
            ident = api.get_resource('/system/identity').get()[0]['name']
            conn.disconnect()
            
            teks =  "<b>📊 SYSTEM RESOURCE</b>\n"
            teks += f"<code>{'─'*22}</code>\n"
            teks += f"👤 <b>Identity :</b> <code>{ident}</code>\n"
            teks += f"🕒 <b>Uptime   :</b> <code>{res['uptime']}</code>\n"
            teks += f"⚙️ <b>CPU Load :</b> <code>{res['cpu-load']}%</code>\n"
            teks += f"📟 <b>Free RAM :</b> <code>{int(res['free-memory'])/1048576:.1f} MB</code>\n"
            teks += f"📦 <b>Version  :</b> <code>{res['version']}</code>\n"
            teks += f"<code>{'─'*22}</code>\n"
            teks += f"🕒 <i>Update: {time.strftime('%H:%M:%S')}</i>"
            
            bot.send_message(config.CHAT_ID, teks, parse_mode='HTML', 
                             message_thread_id=config.THREAD_UTAMA, reply_markup=menu_mikrotik())
        except Exception as e:
            bot.send_message(config.CHAT_ID, f"❌ Error: {e}", message_thread_id=config.THREAD_UTAMA)

    elif call.data == "cek_arp":
        bot.answer_callback_query(call.id, "Loading ARP...")
        try:
            conn = get_api(); api = conn.get_api()
            arp_data = api.get_resource('/ip/arp').get()
            leases = api.get_resource('/ip/dhcp-server/lease').get()
            conn.disconnect()
            
            l_map = {l['address']: l.get('server', 'Static') for l in leases if 'address' in l}
            teks = "<b>📋 DAFTAR ARP LENGKAP</b>\n"
            teks += f"<code>{'─'*25}</code>\n"
            
            for item in arp_data:
                ip, mac, iface = item.get('address'), item.get('mac-address'), item.get('interface')
                vendor = get_vendor(mac)
                srv = l_map.get(ip, "Static")
                teks += f"🌐 <b>{ip}</b>\n└ 🏢 <i>{vendor}</i>\n└ 📡 <code>{iface}</code> | 🔌 <code>{srv}</code>\n└ 🔑 <code>{mac}</code>\n\n"
            
            bot.send_message(config.CHAT_ID, teks, parse_mode='HTML', 
                             message_thread_id=config.THREAD_UTAMA, reply_markup=menu_mikrotik())
        except: pass

# --- BACKGROUND WORKER (MONITORING PERANGKAT BARU) ---
def auto_alert_worker():
    global last_arp_list
    while True:
        try:
            conn = get_api(); api = conn.get_api()
            current_arp = api.get_resource('/ip/arp').get()
            conn.disconnect()
            curr = {i['address']: i['mac-address'] for i in current_arp}
            
            if last_arp_list:
                for ip, mac in curr.items():
                    if ip not in last_arp_list:
                        v = get_vendor(mac)
                        msg = f"⚠️ <b>PERANGKAT BARU!</b>\nIP: <code>{ip}</code>\nMerk: <i>{v}</i>\n🔑 <code>{mac}</code>"
                        bot.send_message(config.CHAT_ID, msg, parse_mode='HTML', message_thread_id=config.THREAD_UTAMA)
            
            last_arp_list = list(curr.keys())
        except: pass
        time.sleep(60) # Cek setiap 60 detik

# Menjalankan Worker di Background Thread
t = threading.Thread(target=auto_alert_worker)
t.daemon = True
t.start()

# Menjalankan Bot Polling
print("🚀 Bot sedang berjalan...")
bot.polling(none_stop=True)
  
