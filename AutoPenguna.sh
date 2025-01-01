#!/bin/bash

# Fungsi untuk menambahkan user root baru
add_root_user() {
    echo -n "Masukkan nama pengguna baru: "
    read -r username

    echo -n "Masukkan password untuk pengguna baru: "
    read -s password
    echo

    echo -n "Masukkan direktori untuk pengguna baru: "
    read -r home_directory

    # Menambahkan pengguna baru secara manual ke /etc/passwd
    echo "Menambahkan pengguna baru ke /etc/passwd..."
    echo "$username:x:0:0:$username:$home_directory:/bin/bash" >> /etc/passwd
    echo
    # Mengenkripsi password menggunakan perintah passwd
    echo "Mengenkripsi password..."
    echo "$username:$password" | chpasswd
    echo
    # Membuat direktori home untuk user baru jika tidak ada
    if [ ! -d "$home_directory" ]; then
        echo "Membuat direktori home untuk pengguna baru..."
        mkdir -p "$home_directory"
        chown $username:$username "$home_directory"
    fi

    echo "Pengguna dengan nama '$username' password '$password' berhasil dengan direktori '$home_directory'"
    echo
}

# Pastikan script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
    echo "Harap jalankan script ini sebagai root."
    exit 1
fi

# Memanggil fungsi untuk menambahkan pengguna root
add_root_user
