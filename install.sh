#!/bin/bash

echo "🚀 Memulai Instalasi Mikrobot STB..."

# 1. Update dan Install Dependency
sudo apt update && sudo apt install -y python3-pip python3-venv git

# 2. Persiapkan Folder
mkdir -p ~/mikrobot
cd ~/mikrobot

# 3. Setup Virtual Environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. Input Konfigurasi dari User
echo "📝 Masukkan Konfigurasi Anda:"
read -p "Token Bot Telegram: " TOKEN
read -p "Chat ID: " CHAT_ID
read -p "Thread Utama ID: " T_UTAMA
read -p "Thread Modem ID: " T_MODEM
read -p "IP Mikrotik: " MT_IP
read -p "User Mikrotik: " MT_USER
read -p "Pass Mikrotik: " MT_PASS
read -p "IP Modem Huawei: " MD_IP

# 5. Buat file config.py
cat > config.py <<EOF
TOKEN = '$TOKEN'
CHAT_ID = $CHAT_ID
THREAD_UTAMA = $T_UTAMA
THREAD_MODEM = $T_MODEM
MT_HOST = '$MT_IP'
MT_USER = '$MT_USER'
MT_PASS = '$MT_PASS'
MT_PORT = 8854
MODEM_HOST = '$MD_IP'
MODEM_USER = 'root'
MODEM_PASS = 'adminhw'
EOF

# 6. Buat Systemd Service
sudo cat > /etc/systemd/system/mikrobot.service <<EOF
[Unit]
Description=Mikrotik Telegram Bot
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/mikrobot
ExecStart=$HOME/mikrobot/venv/bin/python $HOME/mikrobot/mikro_bot.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 7. Aktifkan Service
sudo systemctl daemon-reload
sudo systemctl enable mikrobot.service
sudo systemctl restart mikrobot.service

echo "✅ Instalasi Selesai! Bot sekarang berjalan di background."
