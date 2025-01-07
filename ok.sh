#!/bin/bash

# Skrip ini digunakan untuk memeriksa apakah sistem rentan terhadap beberapa kerentanan utama dari tahun 2021 hingga 2024
# Termasuk CVE-2021-4034, CVE-2022-0847 (Dirty Pipe), CVE-2023-3215, dan CVE-2024-0013
# Dan menambahkan pemeriksaan layanan seperti MYSQL, PERL, PYTHON, WGET, CURL, GCC, dan PKEXEC
# kalau eror gunakan perintah ini sed -i 's/\r//' d.sh

echo "===== Scanner Kerentanan dan Status Layanan ====="

# Pemeriksaan layanan
echo "Memeriksa status layanan..."

check_status() {
    local service=$1
    if command -v $service > /dev/null 2>&1; then
        echo "$service: ON"
    else
        echo "$service: OFF"
    fi
}

# Periksa status layanan
check_status "mysql"
check_status "perl"
check_status "python"
check_status "wget"
check_status "curl"
check_status "gcc"
check_status "pkexec"

echo "Memeriksa fungsi yang dinonaktifkan..."

# Pemeriksaan fungsi yang dinonaktifkan
disabled_functions=$(php -r "echo ini_get('disable_functions');")
if [[ -z "$disabled_functions" ]]; then
    echo "[INFO] Tidak ada fungsi yang dinonaktifkan di PHP."
else
    echo "Fungsi yang dinonaktifkan: $disabled_functions"
fi

# Langkah 1: Periksa apakah pkexec terpasang
echo "Memeriksa apakah 'pkexec' tersedia di sistem..."
if ! command -v pkexec > /dev/null 2>&1; then
    echo "[INFO] pkexec tidak ditemukan di sistem ini."
else
    echo "[INFO] pkexec ditemukan."
    
    # Langkah 2: Periksa versi Polkit yang terpasang
    echo "Memeriksa versi Polkit..."
    polkit_version=$(pkexec --version 2>&1 | grep "pkexec" | awk '{print $3}')

    if [[ -z "$polkit_version" ]]; then
        echo "[ERROR] Gagal mendapatkan versi Polkit."
    else
        echo "[INFO] Versi Polkit yang terpasang: $polkit_version"

        # Langkah 3: Periksa kerentanan Polkit (CVE-2021-4034 dan lainnya)
        vulnerable_versions=("0.105" "0.106" "0.107" "0.108" "0.109")
        is_vulnerable=false
        for v in "${vulnerable_versions[@]}"; do
            if [[ "$polkit_version" == "$v" ]]; then
                is_vulnerable=true
                break
            fi
        done

        # Laporan kerentanan Polkit
        if [[ "$is_vulnerable" == true ]]; then
            echo "[ALERT] Sistem ini kemungkinan rentan terhadap CVE-2021-4034 (Polkit pkexec)."
        else
            echo "[INFO] Sistem ini TIDAK rentan terhadap CVE-2021-4034 berdasarkan versi Polkit saat ini."
        fi
    fi
fi

# Langkah 4: Periksa kerentanan Dirty Pipe (CVE-2022-0847)
echo "Memeriksa kerentanan Dirty Pipe (CVE-2022-0847)..."
kernel_version=$(uname -r)

# Kernel rentan jika versinya antara 5.8 hingga 5.16.11
if [[ "$kernel_version" > "5.8" && "$kernel_version" < "5.16.11" ]]; then
    echo "[ALERT] Kernel versi $kernel_version kemungkinan rentan terhadap CVE-2022-0847 (Dirty Pipe)."
else
    echo "[INFO] Kernel tidak rentan terhadap Dirty Pipe (CVE-2022-0847)."
fi

# Langkah 5: Periksa kerentanan Systemd Privilege Escalation (CVE-2023-3215)
echo "Memeriksa kerentanan Systemd Privilege Escalation (CVE-2023-3215)..."
if systemctl --version > /dev/null 2>&1; then
    systemd_version=$(systemctl --version | head -n 1 | awk '{print $2}')
    if [[ "$systemd_version" < "250" ]]; then
        echo "[ALERT] Sistem ini rentan terhadap CVE-2023-3215 (Systemd Privilege Escalation)."
    else
        echo "[INFO] Sistem ini TIDAK rentan terhadap CVE-2023-3215."
    fi
else
    echo "[INFO] Systemd tidak ditemukan di sistem ini."
fi

# Langkah 6: Periksa kerentanan terbaru di kernel (CVE-2024-0013)
echo "Memeriksa kerentanan kernel (CVE-2024-0013)..."
if [[ "$kernel_version" > "6.0" && "$kernel_version" < "6.2" ]]; then
    echo "[ALERT] Kernel versi $kernel_version mungkin rentan terhadap CVE-2024-0013."
else
    echo "[INFO] Kernel versi $kernel_version tidak rentan terhadap CVE-2024-0013."
fi

# Langkah 7: Memeriksa kerentanan GNU Screen (CVE-2019-18420) - Local Privilege Escalation
echo "Memeriksa kerentanan GNU Screen (CVE-2019-18420) - Local Privilege Escalation..."

# Periksa apakah GNU Screen terpasang
if command -v screen > /dev/null 2>&1; then
    echo "[INFO] GNU Screen terpasang di sistem ini."

    # Memeriksa versi GNU Screen
    screen_version=$(screen --version | head -n 1 | awk '{print $3}')
    echo "[INFO] Versi GNU Screen yang terpasang: $screen_version"

    # Daftar versi GNU Screen yang rentan
    vulnerable_versions=("4.5.0" "4.5.1" "4.6.0" "4.6.1" "4.6.2" "4.7.0")
    is_vulnerable=false
    for v in "${vulnerable_versions[@]}"; do
        if [[ "$screen_version" == "$v" ]]; then
            is_vulnerable=true
            break
        fi
    done

    # Laporan kerentanan
    if [[ "$is_vulnerable" == true ]]; then
        echo "[ALERT] Sistem ini rentan terhadap CVE-2019-18420 (Local Privilege Escalation) pada versi GNU Screen $screen_version."
    else
        echo "[INFO] Sistem ini TIDAK rentan terhadap CVE-2019-18420 berdasarkan versi GNU Screen."
    fi

    # Cek apakah setuid pada executable screen ada
    screen_binary=$(which screen)
    if [[ -f "$screen_binary" && -x "$screen_binary" && $(stat -c "%a" "$screen_binary") == "4755" ]]; then
        echo "[ALERT] Binary GNU Screen memiliki hak akses setuid (4755), yang memungkinkan eskalasi hak istimewa."
    else
        echo "[INFO] Binary GNU Screen tidak memiliki hak akses setuid."
    fi
else
    echo "[INFO] GNU Screen tidak ditemukan di sistem ini."
fi

echo "===== Pengecekan selesai ====="
