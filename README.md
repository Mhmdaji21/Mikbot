🤖 MikroBot STB Manager
Asisten Pintar Monitoring MikroTik & Modem Huawei dalam Satu Genggaman Telegram.
MikroBot STB Manager adalah bot Telegram berbasis Python yang dirancang khusus untuk berjalan di Armbian (STB). Bot ini memungkinkan Anda memantau kesehatan router MikroTik dan mengecek redaman (optical power) pada modem Huawei EG8145V5 langsung dari topik (thread) yang berbeda di grup Telegram.
✨ Fitur Unggulan
Dual-Topic Mode: Notifikasi MikroTik dan Modem dipisahkan ke dalam topik (thread) yang berbeda agar grup tetap rapi.
Real-time Monitoring: Alert otomatis jika ada perangkat baru yang terhubung ke jaringan (Auto ARP Alert).
MikroTik Insight: Cek Resource (CPU, RAM, Uptime) dan daftar ARP lengkap dengan info Vendor & DHCP Server.
Modem OPM Check: Mengambil data Rx/Tx optical power dari modem Huawei via Telnet dengan perintah display optic.
Installer Interaktif: Instalasi super mudah dengan script yang akan menanyakan konfigurasi Anda secara otomatis.
🛠️ Prasyarat
Sebelum menginstal, pastikan Anda memiliki:
STB dengan Armbian (atau distro Linux lainnya).
MikroTik dengan API yang sudah aktif (IP > Services > API).
Modem Huawei EG8145V5 dengan akses Telnet aktif.
Bot Token dari @BotFather.
🚀 Instalasi Cepat (One-Liner)
Jalankan perintah sakti ini di terminal Armbian Anda untuk memulai proses instalasi otomatis:



📋 Konfigurasi yang Dibutuhkan
Saat instalasi, script akan meminta data berikut:
Telegram: Token Bot, Chat ID Grup, ID Thread Utama, dan ID Thread Modem.
MikroTik: IP Router, Port API (default: 8854/8728), Username, dan Password.
Modem: IP Modem, Username Telnet (root), dan Password Telnet.
🖥️ Preview Tampilan
MikroTik Monitoring
📊 SYSTEM RESOURCE
👤 Identity : MikroTik-Utama
🕒 Uptime : 1d 05:20:10
⚙️ CPU Load : 2%
📟 Free RAM : 192.5 MB
Modem Huawei OPM
🔌 OPTIK INFO
📥 Rx Power: -19.45 dBm
📤 Tx Power: 2.10 dBm
📊 Status : ✅ BAGUS
🔧 Maintenance
Untuk mengecek apakah bot berjalan dengan normal, gunakan perintah berikut:
Cek Status: sudo systemctl status mikrobot.service
Restart Bot: sudo systemctl restart mikrobot.service
Stop Bot: sudo systemctl stop mikrobot.service
🤝 Kontribusi
Punya ide fitur baru? Silakan lakukan Fork repository ini dan kirimkan Pull Request. Segala bentuk kontribusi sangat dihargai!
Dibuat dengan ❤️ untuk komunitas RT/RW Net Indonesia.
