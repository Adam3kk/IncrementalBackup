#!/bin/bash
# Directories to back up (space-separated)
SOURCE_DIRS=("/home/ubuntu/")

# Local backup directory
BACKUP_DIR="/home/ubuntu/local_backup"

# Snapshot file path
SNAPSHOT_FILE="${BACKUP_DIR}/snapshot.snar"

# Remote server details
DEST_USER="ubuntu"
DEST_HOST=127.0.0.1
# DESTINATION PATH with all data that was backed up
DEST_PATH="/home/ubuntu/remote_backup"

# Encryption passphrase (recommended to use an environment variable)
ENCRYPTION_PASS="qwerty123"

# Optional path to a private key. In my case, it is needed to access an AWS VM.
SSH_KEY="/home/ubuntu/backup.pem"

#Path to log file
LOG_FILE="/home/ubuntu/Backup/backup.log"
