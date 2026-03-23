#!/bin/bash

# ==========================================
# MIKBOT STB MANAGER - INSTALLER SCRIPT
# Project Owner : Mhmdaji21
# ==========================================

# --- ANSI Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Variabel Global ---
APP_DIR="$HOME/mikrobot"
VENV_DIR="$APP_DIR/venv"

# --- ASCII Art Header ---
clear
echo -e "${CYAN}"
cat << "EOF"
  __  __ _ _    _           _   
 |  \/  (_) |  | |         | |  
 | \  / |_| | _| |__   ___ | |_ 
 | |\/| | | |/ / '_ \ / _ \| __|
 | |  | | |   <| |_) | (_) | |_ 
 |_|  |_|_|_|\_\_.__/ \___/ \__|
   STB Manager & Web Dashboard  
EOF
echo -e "${NC}"
echo -e "System Installer & Maintenance Tool\n"

# --- Helper: Konfirmasi y/n via /dev/tty ---
confirm_action() {
    local prompt="$1"
    local response
    while true; do
        # Menggunakan /dev/tty untuk mencegah input skipping via curl | bash
        read -p "$(echo -e ${YELLOW}"$prompt (y/n): "${NC})" response < /dev/tty
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo -e "${RED}Tolong jawab y atau n.${NC}";;
        esac
    done
}

# --- MENU 1: INSTALL ---
install_mikbot() {
    echo -e "${CYAN}[*] Memulai Instalasi Mikbot...${NC}"
    
    # 1. Update & Install System Dependencies
    echo -e "${GREEN}[+] Menginstal dependensi sistem (Python3, venv, pip)...${NC}"
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip python3-venv curl wget git
    
    # 2. Persiapan Direktori
    if [ ! -d "$APP_DIR" ]; then
        echo -e "${GREEN}[+] Membuat direktori $APP_DIR...${NC}"
        mkdir -p "$APP_DIR"
    fi
    cd "$APP_DIR" || exit
    
    # 3. Setup Virtual Environment
    echo -e "${GREEN}[+] Membangun Python Virtual Environment...${NC}"
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    
    # 4. Install Library Requirements
    if [ -f "requirements.txt" ]; then
        echo -e "${GREEN}[+] Menginstal library Python dari requirements.txt...${NC}"
        pip install --upgrade pip
        pip install -r requirements.txt
    else
        echo -e "${RED}[!] File requirements.txt tidak ditemukan! Menginstal library standar...${NC}"
        pip install pyTelegramBotAPI routeros-api speedtest-cli flask pysnmp pexpect
    fi
    
    # 5. Setup config.py (Interactive)
    if [ ! -f "config.py" ]; then
        echo -e "\n${CYAN}--- Setup Konfigurasi Awal ---${NC}"
        read -p "Masukkan Bot TOKEN Telegram: " bot_token < /dev/tty
        read -p "Masukkan CHAT_ID Admin: " chat_id < /dev/tty
        read -p "Masukkan IP Mikrotik: " mt_ip < /dev/tty
        read -p "Masukkan User Mikrotik: " mt_user < /dev/tty
        read -p "Masukkan Pass Mikrotik: " mt_pass < /dev/tty
        
        cat <<EOF > config.py
TOKEN = "$bot_token"
CHAT_ID = "$chat_id"
THREAD_ID = "" # Isi manual jika pakai mode Forum

MT_IP = "$mt_ip"
MT_USER = "$mt_user"
MT_PASS = "$mt_pass"

MD_IP = "192.168.100.1"
MD_USER = "telecomadmin"
MD_PASS = "admintelecom"
SNMP_COMMUNITY = "public"
EOF
        echo -e "${GREEN}[+] File config.py berhasil dibuat!${NC}"
    fi
    
    # 6. Setup Systemd Service (Telegram Bot)
    echo -e "${GREEN}[+] Mengonfigurasi systemd untuk Telegram Bot...${NC}"
    cat <<EOF | sudo tee /etc/systemd/system/mikbot.service > /dev/null
[Unit]
Description=Mikbot Telegram Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=$VENV_DIR/bin/python3 $APP_DIR/mikro_bot.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    # 7. Setup Systemd Service (Web Dashboard)
    echo -e "${GREEN}[+] Mengonfigurasi systemd untuk Web Dashboard...${NC}"
    cat <<EOF | sudo tee /etc/systemd/system/mikbot-web.service > /dev/null
[Unit]
Description=Mikbot Web Dashboard (Flask)
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=$VENV_DIR/bin/python3 $APP_DIR/web_app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    # 8. Start Services
    echo -e "${GREEN}[+] Mengaktifkan dan menjalankan layanan...${NC}"
    sudo systemctl daemon-reload
    sudo systemctl enable mikbot.service mikbot-web.service
    sudo systemctl start mikbot.service mikbot-web.service
    
    echo -e "\n${CYAN}==========================================${NC}"
    echo -e "${GREEN}✅ INSTALASI SELESAI!${NC}"
    echo -e "Bot Telegram sudah berjalan di background."
    echo -e "Web Dashboard bisa diakses di: ${YELLOW}http://<IP_STB>:5000${NC}"
    echo -e "${CYAN}==========================================${NC}\n"
}

# --- MENU 2: UPGRADE ---
upgrade_mikbot() {
    if confirm_action "Apakah Anda ingin memperbarui Mikbot dari GitHub?"; then
        echo -e "${CYAN}[*] Memulai Upgrade...${NC}"
        cd "$APP_DIR" || exit
        git pull origin main
        
        echo -e "${GREEN}[+] Memperbarui library Python...${NC}"
        source "$VENV_DIR/bin/activate"
        pip install -r requirements.txt
        
        echo -e "${GREEN}[+] Me-restart layanan...${NC}"
        sudo systemctl restart mikbot.service mikbot-web.service
        echo -e "${GREEN}✅ Upgrade selesai!${NC}"
    else
        echo -e "${YELLOW}[-] Upgrade dibatalkan.${NC}"
    fi
}

# --- MENU 3: REPAIR ---
repair_mikbot() {
    if confirm_action "Perbaikan akan menghapus venv lama dan menginstalnya kembali. Lanjutkan?"; then
        echo -e "${CYAN}[*] Memulai Repair venv...${NC}"
        cd "$APP_DIR" || exit
        
        sudo systemctl stop mikbot.service mikbot-web.service
        rm -rf "$VENV_DIR"
        
        python3 -m venv "$VENV_DIR"
        source "$VENV_DIR/bin/activate"
        pip install --upgrade pip
        pip install -r requirements.txt
        
        sudo systemctl start mikbot.service mikbot-web.service
        echo -e "${GREEN}✅ Repair selesai! Services telah dihidupkan ulang.${NC}"
    else
        echo -e "${YELLOW}[-] Repair dibatalkan.${NC}"
    fi
}

# --- MENU 4: UNINSTALL ---
uninstall_mikbot() {
    if confirm_action "⚠️ PERINGATAN! Ini akan menghapus semua service systemd Mikbot. Lanjutkan?"; then
        echo -e "${CYAN}[*] Menghentikan dan menghapus services...${NC}"
        sudo systemctl stop mikbot.service mikbot-web.service
        sudo systemctl disable mikbot.service mikbot-web.service
        sudo rm /etc/systemd/system/mikbot.service
        sudo rm /etc/systemd/system/mikbot-web.service
        sudo systemctl daemon-reload
        
        if confirm_action "Apakah Anda juga ingin MENGHAPUS folder $APP_DIR beserta isinya (termasuk config.py)?"; then
            rm -rf "$APP_DIR"
            echo -e "${GREEN}[+] Direktori $APP_DIR dihapus.${NC}"
        fi
        
        echo -e "${GREEN}✅ Uninstall selesai! Mikbot telah dicabut dari sistem.${NC}"
    else
        echo -e "${YELLOW}[-] Uninstall dibatalkan.${NC}"
    fi
}

# --- MAIN MENU LOGIC ---
show_menu() {
    echo -e "Pilih opsi di bawah ini:"
    echo -e "${GREEN}1.${NC} Install Baru"
    echo -e "${GREEN}2.${NC} Upgrade (Pull Update & Restart)"
    echo -e "${GREEN}3.${NC} Repair (Re-build venv)"
    echo -e "${GREEN}4.${NC} Uninstall"
    echo -e "${GREEN}5.${NC} Keluar"
    echo -ne "Masukkan pilihan [1-5]: "
    read -r choice < /dev/tty
    
    case $choice in
        1) install_mikbot ;;
        2) upgrade_mikbot ;;
        3) repair_mikbot ;;
        4) uninstall_mikbot ;;
        5) echo -e "${CYAN}Keluar dari installer. Sampai jumpa!${NC}"; exit 0 ;;
        *) echo -e "${RED}Pilihan tidak valid!${NC}"; show_menu ;;
    esac
}

# Jalankan menu utama
show_menu
ade pip
    $DIR/venv/bin/pip install -r requirements.txt
    setup_service
    echo -e "${GREEN}✅ Perbaikan Selesai!${NC}"
    sleep 2
}

# --- FUNGSI UNINSTALL ---
uninstall_bot() {
    echo -e "\n${RED}🗑️  Menghapus Bot sepenuhnya...${NC}"
    sudo systemctl stop mikrobot.service
    sudo systemctl disable mikrobot.service
    sudo rm /etc/systemd/system/mikrobot.service
    sudo systemctl daemon-reload
    rm -rf $DIR
    echo -e "${GREEN}✅ Bot berhasil dihapus dari STB.${NC}"
    sleep 2
}

# --- FUNGSI SERVICE ---
setup_service() {
    sudo cat > /etc/systemd/system/mikrobot.service <<EOF
[Unit]
Description=MikroTik Telegram Bot
After=network.target

[Service]
User=$USER
WorkingDirectory=$DIR
ExecStart=$DIR/venv/bin/python $DIR/mikro_bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable mikrobot.service
    sudo systemctl restart mikrobot.service
}

# --- JALANKAN MENU ---
while true; do
    show_menu
    read -p "" PILIH < /dev/tty
    case $PILIH in
        1) install_bot ;;
        2) upgrade_bot ;;
        3) repair_bot ;;
        4) uninstall_bot ;;
        5) echo "Sampai jumpa!"; exit 0 ;;
        *) echo -e "${RED}Pilihan salah!${NC}"; sleep 1 ;;
    esac
done
echo -e "---------------------------------------------"
read -p "🔹 Masukkan Token Bot Telegram: " TOKEN
read -p "🔹 Masukkan Chat ID: " CHAT_ID
read -p "🔹 Masukkan ID Thread Utama: " T_UTAMA
read -p "🔹 Masukkan ID Thread Modem: " T_MODEM
echo -e "---------------------------------------------"
read -p "🔸 Masukkan IP MikroTik: " MT_IP
read -p "🔸 Masukkan Port API MikroTik (Default 8854): " MT_PORT
MT_PORT=${MT_PORT:-8854}
read -p "🔸 Masukkan Username MikroTik: " MT_USER
read -p "🔸 Masukkan Password MikroTik: " MT_PASS
echo -e "---------------------------------------------"
read -p "📟 Masukkan IP Modem Huawei: " MD_IP
read -p "📟 Username Telnet Modem (Default root): " MD_USER
MD_USER=${MD_USER:-root}
read -p "📟 Password Telnet Modem (Default adminhw): " MD_PASS
MD_PASS=${MD_PASS:-adminhw}

# Buat file config.py
cat > config.py <<EOF
# --- GENERATED CONFIGURATION ---
TOKEN = '$TOKEN'
CHAT_ID = $CHAT_ID
THREAD_UTAMA = $T_UTAMA
THREAD_MODEM = $T_MODEM

MT_HOST = '$MT_IP'
MT_PORT = $MT_PORT
MT_USER = '$MT_USER'
MT_PASS = '$MT_PASS'

MODEM_HOST = '$MD_IP'
MODEM_USER = '$MD_USER'
MODEM_PASS = '$MD_PASS'
EOF

# Buat Systemd Service
sudo cat > /etc/systemd/system/mikrobot.service <<EOF
[Unit]
Description=MikroTik Telegram Bot Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/mikrobot
ExecStart=$HOME/mikrobot/venv/bin/python $HOME/mikrobot/mikro_bot.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Aktifkan Service
sudo systemctl daemon-reload
sudo systemctl enable mikrobot.service
sudo systemctl restart mikrobot.service

echo -e "\n${GREEN}=============================================${NC}"
echo -e "${GREEN}✅  INSTALASI SELESAI!${NC}"
echo -e "Bot berjalan otomatis sebagai service."
echo -e "Cek status: ${CYAN}sudo systemctl status mikrobot.service${NC}"
echo -e "Log bot   : ${CYAN}journalctl -u mikrobot.service -f${NC}"
echo -e "${GREEN}=============================================${NC}"
