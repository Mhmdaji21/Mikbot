from flask import Flask, render_template, jsonify
from pysnmp.hlapi import *
import pexpect
import re

app = Flask(__name__)

# --- KONFIGURASI MIKBOT ---
# Silakan sesuaikan dengan IP & Kredensial asli Anda nanti
MT_IP = "192.168.88.1"
SNMP_COMMUNITY = "public" 

MD_IP = "192.168.100.1"
MD_USER = "telecomadmin"
MD_PASS = "admintelecom"

def format_bytes(size):
    try:
        size = float(size)
    except (ValueError, TypeError):
        return "0 B"
        
    power = 1024
    n = 0
    power_labels = {0: 'B', 1: 'KB', 2: 'MB', 3: 'GB', 4: 'TB'}
    while size >= power and n < 4:
        size /= power
        n += 1
    return f"{size:.2f} {power_labels[n]}"

def snmp_walk(host, community, oid):
    results = {}
    for (errorIndication, errorStatus, errorIndex, varBinds) in nextCmd(
        SnmpEngine(),
        CommunityData(community),
        UdpTransportTarget((host, 161), timeout=2.0, retries=1),
        ContextData(),
        ObjectType(ObjectIdentity(oid)),
        lexicographicMode=False
    ):
        if errorIndication or errorStatus:
            break
        for varBind in varBinds:
            index = str(varBind[0]).split('.')[-1]
            val = str(varBind[1])
            results[index] = val
    return results

@app.route('/')
def dashboard():
    return render_template('index.html')

@app.route('/api/redaman')
def get_redaman():
    try:
        child = pexpect.spawn(f"telnet {MD_IP}", timeout=5, encoding='utf-8')
        child.expect(['[Ll]ogin:', '[Uu]sername:'])
        child.sendline(MD_USER)
        child.expect('[Pp]assword:')
        child.sendline(MD_PASS)
        child.expect([r'>', r'#'])
        
        child.sendline('display ont info 0/0/1 1') 
        child.expect([r'>', r'#'])
        output = child.before
        child.sendline('quit')
        child.close()

        match = re.search(r"Rx\s+optical\s+power\s*[:=]\s*([-+]?\d+\.\d+)", output)
        if match:
            return jsonify({"success": True, "output": f"🔌 Koneksi Modem Huawei Sukses!\nRx Optical Power: {match.group(1)} dBm"})
        return jsonify({"success": True, "output": f"Output mentah:\n{output[-500:]}"})
    except Exception as e:
        return jsonify({"success": False, "error": f"Gagal Telnet Modem: {str(e)}"})

@app.route('/api/arp')
def get_arp():
    # Placeholder untuk fungsi ARP via routeros_api (sama seperti sebelumnya)
    return jsonify({"success": True, "output": "Fitur ARP siap disambungkan ke routeros_api"})

@app.route('/api/speedtest')
def get_speedtest():
    try:
        child = pexpect.spawn("speedtest-cli --simple", timeout=60, encoding='utf-8')
        child.expect(pexpect.EOF)
        output = child.before.strip()
        return jsonify({"success": True, "output": f"🚀 Hasil Speedtest STB:\n{output}"})
    except Exception as e:
        return jsonify({"success": False, "error": f"Speedtest gagal: {str(e)}"})

@app.route('/api/interfaces')
def get_interfaces():
    try:
        OID_NAME = '1.3.6.1.2.1.31.1.1.1.1'
        OID_STATUS = '1.3.6.1.2.1.2.2.1.8'
        OID_RX_HC = '1.3.6.1.2.1.31.1.1.1.6'
        OID_TX_HC = '1.3.6.1.2.1.31.1.1.1.10'

        names = snmp_walk(MT_IP, SNMP_COMMUNITY, OID_NAME)
        statuses = snmp_walk(MT_IP, SNMP_COMMUNITY, OID_STATUS)
        rx_bytes = snmp_walk(MT_IP, SNMP_COMMUNITY, OID_RX_HC)
        tx_bytes = snmp_walk(MT_IP, SNMP_COMMUNITY, OID_TX_HC)

        if not names:
            return jsonify({"success": False, "error": "Tidak ada respon SNMP dari Mikrotik."})

        parsed_data = []
        for index, name in names.items():
            if name.startswith('<') or name == 'lo':
                continue
            status_val = statuses.get(index, '2')
            rx_val = rx_bytes.get(index, '0')
            tx_val = tx_bytes.get(index, '0')

            parsed_data.append({
                "name": name,
                "type": "SNMP-Interface",
                "running": 'true' if status_val == '1' else 'false',
                "rx_formatted": format_bytes(rx_val),
                "tx_formatted": format_bytes(tx_val)
            })

        return jsonify({"success": True, "data": parsed_data})
    except Exception as e:
        return jsonify({"success": False, "error": f"SNMP Fault: {str(e)}"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
  
