#!/bin/bash

# Fungsi untuk membersihkan file log
clean_log() {
    echo "Membersihkan file log..."
    chown -R root:root /var/log/
    find /var/log/ -type f -exec truncate -s 0 {} \;
    chmod -R 000 /var/log/
    rm -rf /tmp/*
    find / -type f -name '.bash_history' -exec rm -f {} \;
    find / -type f -iname "*_docs" -exec rm -f {} \;
    find / -type f \( -iname '*.history' -o -iname '*_history' \) -exec rm -f {} \;
    find / -type f -iname "*.log" -exec rm -f {} \;
    find / -type f -iname "*.logs" -exec rm -f {} \;
    find / -type f -iname "*_log" -exec rm -f {} \;
    find / -type d -iname "logs" -exec rm -rf {} +
    find / -type f \( -iname '*.zip' -o -iname '*.tar.gz' -o -iname '*.tar.bz2' -o -iname '*.tar.xz' -o -iname '*.tar' -o -iname '*.bak' \) -exec rm -f {} \;
    find / -type f \( -iname '*_backup' -o -iname '*.old' -o -iname '*.swp' -o -iname '*.backup' \) -exec rm -f {} \;
}

# Fungsi untuk membersihkan file yang diproses
clean_processed() {
    echo "Membersihkan file yang diproses..."
    find / -type f -iname "*.processed" -exec rm -f {} \;
}

# Fungsi untuk membersihkan file statistik web
clean_webstat() {
    echo "Membersihkan file statistik web..."
    find / -type f -iname "*.webstat" -exec rm -f {} \;
}

# Pembersihan sistem
clean_system() {
    echo "Melakukan pembersihan sistem..."
    dpkg --list | grep '^rc' | awk '{print $2}' | xargs dpkg --purge
    yum autoremove -y
    yum clean all
    yum makecache
    apt-get autoremove -y
    apt-get clean
}

# Pembersihan Docker (jika terinstal)
clean_docker() {
    if command -v docker &> /dev/null; then
        echo "Membersihkan Docker..."
        docker system prune -af
    fi
}

# Pembersihan Snap (jika terinstal)
clean_snap() {
    if command -v snap &> /dev/null; then
        echo "Membersihkan Snap..."
        snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
            snap remove "$snapname" --revision="$revision"
        done
    fi
}

# Optimasi Filesystem
optimize_filesystem() {
    echo "Mengoptimasi filesystem..."
    sync && sysctl -w vm.drop_caches=3
}

# Menjalankan semua fungsi
clean_log
clean_processed
clean_webstat
clean_system
clean_docker
clean_snap
optimize_filesystem

# Membersihkan cache di paling bawah
clean_cache() {
    echo "Membersihkan cache..."
    find / -type f -iname "*cache*" -exec rm -f {} \;
    find / -type d -iname "*cache*" -exec rm -rf {} \;
}

clean_cache

# Menampilkan pesan selesai
echo "Pembersihan selesai! VPS Anda sekarang lebih bersih dan lebih optimal."
