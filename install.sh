#!/bin/bash

# Warna untuk tampilan terminal
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}=============================================${NC}"
echo -e "${GREEN}🚀 MIKROBOT STB INSTALLER - AUTO DOWNLOAD${NC}"
echo -e "${CYAN}=============================================${NC}"

# 1. Update dan Install Dependency System
echo -e "\n${YELLOW}📦 [1/5] Menginstall dependency system...${NC}"
sudo apt update
sudo apt install -y python3-pip python3-venv git curl

# 2. Persiapkan Folder
echo -e "\n${YELLOW}📁 [2/5] Menyiapkan direktori kerja...${NC}"
mkdir -p ~/mikrobot
cd ~/mikrobot

# 3. Download Source Code langsung dari GitHub kamu
echo -e "\n${YELLOW}📥 [3/5] Mendownload file source dari GitHub...${NC}"
curl -sLO https://raw.githubusercontent.com/Mhmdaji21/Mikbot/main/mikro_bot.py
curl -sLO https://raw.githubusercontent.com/Mhmdaji21/Mikbot/main/requirements.txt

# 4. Setup Virtual Environment & Install Library
echo -e "\n${YELLOW}🐍 [4/5] Membuat Virtual Environment & Install Library...${NC}"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 5. Konfigurasi Interaktif
echo -e "\n${CYAN}📝 [5/5] SILAKAN ISI KONFIGURASI BOT ANDA:${NC}"
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
