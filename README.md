# 🤖 MikroBot Manager (STB Version)
> **Solusi All-in-One Monitoring MikroTik & Modem Huawei langsung dari Telegram.**

![Python](https://img.shields.io/badge/Python-3.9+-blue?style=for-the-badge&logo=python&logoColor=white)
![MikroTik](https://img.shields.io/badge/MikroTik-RouterOS-orange?style=for-the-badge&logo=micro-star-international&logoColor=white)
![Telegram](https://img.shields.io/badge/Telegram-Bot_API-blue?style=for-the-badge&logo=telegram&logoColor=white)

`MikroBot` adalah asisten pintar berbasis Python yang dirancang untuk berjalan di **Armbian/STB**. Bot ini membantu pengelola jaringan (RT/RW Net) memantau resource router dan kondisi kabel optik modem tanpa perlu membuka Winbox atau Web GUI modem.

---

## ✨ Fitur Utama
* **📂 Multi-Function Menu:** Installer pintar dengan opsi *Install*, *Upgrade*, *Repair*, dan *Uninstall*.
* **🖥️ Resource Monitoring:** Cek CPU Load, Free RAM, Uptime, dan Versi OS secara real-time.
* **📡 Huawei OPM Info:** Cek redaman (Rx/Tx Power) modem Huawei EG/HG series via Telnet.
* **🚨 Auto ARP Alert:** Notifikasi otomatis jika ada perangkat baru yang terhubung ke jaringan.
* **💬 Thread/Topic Support:** Mendukung pengiriman pesan ke topik tertentu dalam grup Telegram.

---

## 🚀 Instalasi Cepat (One-Liner)

Cukup salin dan tempel perintah di bawah ini ke terminal STB Anda:

```bash
curl -sSL [https://raw.githubusercontent.com/Mhmdaji21/Mikbot/main/install.sh](https://raw.githubusercontent.com/Mhmdaji21/Mikbot/main/install.sh) | bash
Cek Status: sudo systemctl status mikrobot.service
Restart Bot: sudo systemctl restart mikrobot.service
Stop Bot: sudo systemctl stop mikrobot.service
🤝 Kontribusi
Punya ide fitur baru? Silakan lakukan Fork repository ini dan kirimkan Pull Request. Segala bentuk kontribusi sangat dihargai!
Dibuat dengan ❤️ untuk komunitas RT/RW Net Indonesia.
