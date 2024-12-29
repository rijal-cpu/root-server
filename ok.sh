#!/bin/bash

# Skrip ini digunakan untuk memeriksa apakah sistem rentan terhadap beberapa kerentanan utama dari tahun 2021 hingga 2024
# Termasuk CVE-2021-4034, CVE-2022-0847 (Dirty Pipe), CVE-2023-3215, dan CVE-2024-0013

echo "===== Scanner Kerentanan Polkit dan Kernel Vulnerabilities ====="
echo "Memeriksa apakah 'pkexec' tersedia di sistem..."

# Langkah 1: Periksa apakah pkexec terpasang
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

echo "===== Pengecekan selesai ====="
