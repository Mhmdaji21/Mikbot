#!/bin/bash

# --- KONFIGURASI WARNA ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' 

# --- KONFIGURASI REPO ---
REPO_URL="https://raw.githubusercontent.com/Mhmdaji21/Mikbot/main"
DIR="$HOME/mikrobot"

# --- FUNGSI HEADER ---
header_logo() {
    clear
    echo -e "${CYAN}"
    echo -e "  __  __ _ _   _           _     ____       _   "
    echo -e " |  \/  (_) | | |         | |   |  _ \     | |  "
    echo -e " | \  / |_| |_| |__   ___ | |_  | |_) | ___| |_ "
    echo -e " | |\/| | | __| '_ \ / _ \| __| |  _ < / _ \ __|"
    echo -e " | |  | | | |_| |_) | (_) | |_  | |_) | (_) | |_ "
    echo -e " |_|  |_|_|\__|_.__/ \___/ \__| |____/ \___/ \__|"
    echo -e "       ${BOLD}PREMIUM STB MANAGER BY MHMAJI21${NC}"
    echo -e "${CYAN}=================================================${NC}"
}

# --- MENU UTAMA ---
show_menu() {
    header_logo
    echo -e "${BOLD}MAIN MENU:${NC}"
    echo -e "  ${BLUE}[1]${NC} 🚀 ${BOLD}Install Bot Baru${NC}"
    echo -e "  ${BLUE}[2]${NC} 🔄 ${BOLD}Upgrade Script${NC} ${YELLOW}(Simpan Config)${NC}"
    echo -e "  ${BLUE}[3]${NC} 🛠️  ${BOLD}Perbaikan${NC} ${YELLOW}(Re-install Library)${NC}"
    echo -e "  ${BLUE}[4]${NC} 🗑️  ${BOLD}Hapus Bot${NC} ${RED}(Uninstall Total)${NC}"
    echo -e "  ${BLUE}[5]${NC} ❌ ${BOLD}Keluar${NC}"
    echo -e "${CYAN}-------------------------------------------------${NC}"
    echo -n -e "${BOLD}Pilih nomor [1-5]: ${NC}"
}

# --- FUNGSI INSTALASI (DENGAN OPSI CANCEL) ---
install_bot() {
    header_logo
    echo -e "${YELLOW}${BOLD}⚠️ KONFIRMASI INSTALASI${NC}"
    echo -e "Proses ini akan mengunduh komponen dan library baru."
    read -p "Apakah Anda ingin melanjutkan? (y/n): " CONFIRM_INS < /dev/tty
    
    if [[ $CONFIRM_INS != "y" ]]; then
        echo -e "${RED}❌ Instalasi dibatalkan. Kembali ke menu...${NC}"
        sleep 2
        return
    fi

    echo -e "\n${MAGENTA}📦 STEP 1: Mengunduh Komponen...${NC}"
    sudo apt update -y && sudo apt install -y python3-pip python3-venv git curl
    mkdir -p $DIR
    cd $DIR
    
    echo -e "  ${CYAN}•${NC} Mengambil script utama..."
    curl -sLO $REPO_URL/mikro_bot.py
    echo -e "  ${CYAN}•${NC} Mengambil daftar library..."
    curl -sLO $REPO_URL/requirements.txt

    echo -e "\n${MAGENTA}🐍 STEP 2: Menyiapkan Virtual Environment...${NC}"
    python3 -m venv venv
    source venv/bin/activate
    echo -e "  ${CYAN}•${NC} Menginstall library (mohon tunggu)..."
    pip install --upgrade pip -q
    pip install -r requirements.txt -q

    header_logo
    echo -e "${YELLOW}${BOLD}📝 STEP 3: KONFIGURASI BOT${NC}"
    echo -e "${CYAN}Lengkapi data di bawah atau tekan Ctrl+C untuk paksa batal.${NC}"
    echo -e "${CYAN}-------------------------------------------------${NC}"
    
    echo -e "${BOLD}[ A. TELEGRAM SETTINGS ]${NC}"
    read -p "   Enter Token Bot    : " TOKEN < /dev/tty
    read -p "   Enter Chat ID      : " CHAT_ID < /dev/tty
    read -p "   Enter Thread Utama : " T_UTAMA < /dev/tty
    read -p "   Enter Thread Modem : " T_MODEM < /dev/tty
    
    echo -e "\n${BOLD}[ B. MIKROTIK SETTINGS ]${NC}"
    read -p "   Enter IP MikroTik  : " MT_IP < /dev/tty
    read -p "   Enter Port API     : " MT_PORT < /dev/tty
    MT_PORT=${MT_PORT:-8854}
    read -p "   Enter Username     : " MT_USER < /dev/tty
    read -p "   Enter Password     : " MT_PASS < /dev/tty
    
    echo -e "\n${BOLD}[ C. MODEM SETTINGS ]${NC}"
    read -p "   Enter IP Modem     : " MD_IP < /dev/tty
    read -p "   Enter User Telnet  : " MD_USER < /dev/tty
    MD_USER=${MD_USER:-root}
    read -p "   Enter Pass Telnet  : " MD_PASS < /dev/tty
    MD_PASS=${MD_PASS:-adminhw}
    
    # Konfirmasi Akhir sebelum Save
    echo -e "${CYAN}-------------------------------------------------${NC}"
    read -p "Simpan konfigurasi dan jalankan bot? (y/n): " FINAL_CONF < /dev/tty
    if [[ $FINAL_CONF != "y" ]]; then
        echo -e "${RED}❌ Konfigurasi tidak disimpan. Instalasi dibatalkan.${NC}"
        sleep 2
        return
    fi

    # Membuat file config.py
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
    echo -e "\n${GREEN}${BOLD}🚀 INSTALASI BERHASIL!${NC}"
    echo -e "${GREEN}Bot sedang berjalan di background.${NC}"
    read -p "Tekan Enter untuk kembali ke menu..." < /dev/tty
}

# --- FUNGSI UPGRADE ---
upgrade_bot() {
    header_logo
    echo -e "${YELLOW}🔄 Anda akan memperbarui script ke versi terbaru.${NC}"
    read -p "Lanjutkan? (y/n): " CONFIRM_UP < /dev/tty
    if [[ $CONFIRM_UP != "y" ]]; then return; fi

    if [ -d "$DIR" ]; then
        sudo systemctl stop mikrobot.service
        cd $DIR
        curl -sLO $REPO_URL/mikro_bot.py
        curl -sLO $REPO_URL/requirements.txt
        $DIR/venv/bin/pip install -r requirements.txt -q
        sudo systemctl start mikrobot.service
        echo -e "${GREEN}✅ Update Selesai!${NC}"
    else
        echo -e "${RED}❌ Error: Folder bot tidak ditemukan!${NC}"
    fi
    sleep 2
}

# --- FUNGSI PERBAIKAN ---
repair_bot() {
    header_logo
    echo -e "${YELLOW}🛠️  Anda akan memperbaiki library (Re-install).${NC}"
    read -p "Lanjutkan? (y/n): " CONFIRM_REP < /dev/tty
    if [[ $CONFIRM_REP != "y" ]]; then return; fi

    if [ -d "$DIR" ]; then
        cd $DIR
        sudo systemctl stop mikrobot.service
        rm -rf venv
        python3 -m venv venv
        $DIR/venv/bin/pip install --upgrade pip -q
        $DIR/venv/bin/pip install -r requirements.txt -q
        setup_service
        echo -e "${GREEN}✅ Perbaikan Selesai!${NC}"
    else
        echo -e "${RED}❌ Error: Folder tidak ditemukan.${NC}"
    fi
    sleep 2
}

# --- FUNGSI UNINSTALL ---
uninstall_bot() {
    header_logo
    echo -e "${RED}${BOLD}⚠️ PERINGATAN HAPUS TOTAL!${NC}"
    echo -e "Semua data bot dan konfigurasi akan dihapus."
    read -p "Apakah Anda benar-benar yakin? (y/n): " KONFIRM < /dev/tty
    if [[ $KONFIRM == "y" ]]; then
        sudo systemctl stop mikrobot.service
        sudo systemctl disable mikrobot.service
        sudo rm /etc/systemd/system/mikrobot.service
        sudo systemctl daemon-reload
        rm -rf $DIR
        echo -e "${GREEN}✅ Bot telah dihapus sepenuhnya.${NC}"
    else
        echo -e "${CYAN}Dibatalkan.${NC}"
    fi
    sleep 2
}

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

# --- JALANKAN PROGRAM ---
while true; do
    show_menu
    read -r PILIH < /dev/tty
    case $PILIH in
        1) install_bot ;;
        2) upgrade_bot ;;
        3) repair_bot ;;
        4) uninstall_bot ;;
        5) clear; echo "Sampai jumpa!"; exit 0 ;;
        *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
    esac
done
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
