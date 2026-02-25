#!/bin/bash

# --- WARNA TERMINAL ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- KONFIGURASI REPO ---
REPO_URL="https://raw.githubusercontent.com/Mhmdaji21/Mikbot/main"
DIR="$HOME/mikrobot"

# --- FUNGSI HEADER ---
draw_line() { echo -e "${CYAN}=============================================${NC}"; }

# --- MENU UTAMA ---
show_menu() {
    clear
    draw_line
    echo -e "${GREEN}      MIKROBOT MANAGER BY MHMAJI21       ${NC}"
    draw_line
    echo -e "1) 🚀 Install Bot Baru"
    echo -e "2) 🔄 Upgrade Script (Simpan Config)"
    echo -e "3) 🛠️  Perbaikan (Reinstall Library)"
    echo -e "4) 🗑️  Hapus / Uninstall Bot"
    echo -e "5) ❌ Keluar"
    draw_line
    echo -n "Pilih menu [1-5]: "
}

# --- FUNGSI INSTALASI ---
install_bot() {
    echo -e "\n${YELLOW}📦 [1/4] Menginstall Dependency System...${NC}"
    sudo apt update && sudo apt install -y python3-pip python3-venv git curl

    echo -e "${YELLOW}📁 [2/4] Menyiapkan Folder & Download Source...${NC}"
    mkdir -p $DIR
    cd $DIR
    curl -sLO $REPO_URL/mikro_bot.py
    curl -sLO $REPO_URL/requirements.txt

    echo -e "${YELLOW}🐍 [3/4] Setup Virtual Environment...${NC}"
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt

    echo -e "\n${CYAN}📝 [4/4] INPUT KONFIGURASI (JANGAN DIKOSONGKAN):${NC}"
    # Gunakan </dev/tty agar input tidak skip saat pakai curl | bash
    read -p "🔹 Token Bot       : " TOKEN < /dev/tty
    read -p "🔹 Chat ID         : " CHAT_ID < /dev/tty
    read -p "🔹 Thread Utama ID : " T_UTAMA < /dev/tty
    read -p "🔹 Thread Modem ID : " T_MODEM < /dev/tty
    echo "---------------------------------------------"
    read -p "🔸 IP MikroTik     : " MT_IP < /dev/tty
    read -p "🔸 Port API (8854) : " MT_PORT < /dev/tty
    MT_PORT=${MT_PORT:-8854}
    read -p "🔸 User MikroTik   : " MT_USER < /dev/tty
    read -p "🔸 Pass MikroTik   : " MT_PASS < /dev/tty
    echo "---------------------------------------------"
    read -p "📟 IP Modem        : " MD_IP < /dev/tty
    read -p "📟 User Telnet     : " MD_USER < /dev/tty
    MD_USER=${MD_USER:-root}
    read -p "📟 Pass Telnet     : " MD_PASS < /dev/tty
    MD_PASS=${MD_PASS:-adminhw}

    # Membuat config.py
    cat > config.py <<EOF
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

    setup_service
    echo -e "\n${GREEN}✅ INSTALASI BERHASIL!${NC}"
    echo -e "Cek Status: ${YELLOW}sudo systemctl status mikrobot.service${NC}"
    read -p "Tekan Enter untuk kembali ke menu..." < /dev/tty
}

# --- FUNGSI UPGRADE ---
upgrade_bot() {
    if [ ! -d "$DIR" ]; then
        echo -e "${RED}❌ Folder tidak ditemukan. Install dulu!${NC}"
        sleep 2
        return
    fi
    echo -e "\n${YELLOW}🔄 Sedang mengupdate script...${NC}"
    sudo systemctl stop mikrobot.service
    cd $DIR
    curl -sLO $REPO_URL/mikro_bot.py
    curl -sLO $REPO_URL/requirements.txt
    $DIR/venv/bin/pip install -r requirements.txt
    sudo systemctl start mikrobot.service
    echo -e "${GREEN}✅ Update Berhasil! Config aman.${NC}"
    sleep 2
}

# --- FUNGSI PERBAIKAN ---
repair_bot() {
    if [ ! -d "$DIR" ]; then
        echo -e "${RED}❌ Folder tidak ditemukan.${NC}"
        sleep 2
        return
    fi
    echo -e "\n${YELLOW}🛠️  Membangun ulang Virtual Environment...${NC}"
    cd $DIR
    sudo systemctl stop mikrobot.service
    rm -rf venv
    python3 -m venv venv
    $DIR/venv/bin/pip install --upgrade pip
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
