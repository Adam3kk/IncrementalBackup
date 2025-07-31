#!/bin/bash

# Load configuration file
CONFIG_FILE="${1:-config.sh}"
source "$CONFIG_FILE"

# Check location on decrypt.sh for decrypt.log
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Location for decrypt.log 
DECRYPT_LOG_FILE="${SCRIPT_DIR}/decrypt.log"

exec >> "$DECRYPT_LOG_FILE" 2>&1

echo "========== START DECRYPT: $(date) =========="

ENCRYPTED_FILE="$2"
DECRYPTED_DIR="$3"

# Function to check if correct number of arguments is provided
check_arguments() {
    if [ "$#" -ne 3 ]; then
        echo "Usage: $0 config.sh /path/to/backup_file.tar.enc /destination/dir"
        exit 1
    fi
}

# Function to check if encrypted file and destination directory exist
check_files() {
    if [ ! -f "$ENCRYPTED_FILE" ]; then
        echo "[ERROR] Encrypted file '$ENCRYPTED_FILE' does not exist or is not accessible."
        exit 1
    fi

    if [ ! -d "$DECRYPTED_DIR" ]; then
        echo "[ERROR] Destination directory '$DECRYPTED_DIR' does not exist."
        exit 1
    fi
}

# Function to decrypt and extract the backup file
decrypt_file() {
    echo "[INFO] Starting decryption of $ENCRYPTED_FILE ..."
    openssl enc -d -aes-256-cbc -pbkdf2 \
        -in "$ENCRYPTED_FILE" \
        -pass pass:"$ENCRYPTION_PASSWORD" \
    | tar -xzvf - -C "$DECRYPTED_DIR"

    if [ $? -eq 0 ]; then
        echo "[INFO] Decryption and extraction completed successfully."
    else
        echo "[ERROR] Decryption or extraction failed."
        exit 1
    fi
}

# Run all functions
check_arguments "$@"
check_files
decrypt_file

echo "========== DECRYPT COMPLETED: Sun Jul 27 17:19:02 UTC 2025 =========="
