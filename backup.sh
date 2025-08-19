#!/bin/bash

CONFIG_FILE="${1:-config.sh}"
source "${CONFIG_FILE}"

DIRS=("${SOURCE_DIRS[@]}")

exec >> "$LOG_FILE" 2>&1

#Function helps user to check free spaces before make backup
check_free_space(){
	#
	AVAILABLE_SPACE=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
	# Convert available space from KB to GB
	AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE / 1024 / 1024))

	# Check if the available space is less than the required free space
	if [ "$AVAILABLE_SPACE_GB" -lt "$MIN_FREE_SPACE_GB" ]; then
		echo "[ERROR] Not enough disk space for backup. Minimum required: $MIN_FREE_SPACE_GB GB"
        	echo "========== BACKUP COMPLETED: $(date) =========="
		send_notification_to_discord error
		exit 1
	fi
	echo "[INFO] Free space available: $AVAILABLE_SPACE_GB GB"
}

# Function to delete local backup files older than 5 days
check_old_local_backups() {
    	echo "[INFO] Checking for old backups in: $BACKUP_DIR"

	# Condition to find old backup files
	AGE_CONDITION="-mtime +${RETENTION_DAYS}"

	# Check old backups
	OLD_FILES=$(find "$BACKUP_DIR" -name "*.tar.enc" -type f $AGE_CONDITION)

	# If OLD_FILES is empty, print info. Otherwise, list and delete old backups.
   	if [[ -z "$OLD_FILES" ]]; then
        	echo "[INFO] No old backups found to delete."
    	else
       		echo "[INFO] The following backup files will be deleted:"
		echo "$OLD_FILES"
        	echo "[INFO] Deleting files..."

        	find "$BACKUP_DIR" -name "*.tar.enc" -type f $AGE_CONDITION -print -delete

        	echo "[INFO] Old backups deleted successfully."
	fi
}

check_log_file(){
	if [ -z "$LOG_FILE" ]; then
		echo "[ERROR] LOG_FILE path is not included."
		exit 1
	fi
}

# Function to check the size of backup.log. If it is greater than 10 MB, create a new log file and rename the old one with the current date plus .old
check_size_file_log() {
    if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE")" -gt 10000000 ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        ROTATED_FILE="${LOG_FILE}_${TIMESTAMP}.old"

        mv "$LOG_FILE" "$ROTATED_FILE"
        touch "$LOG_FILE"

        echo "[INFO] Log file rotated: $ROTATED_FILE"
    fi
}

check_dirs(){
	for dir in "${DIRS[@]}"; do
		if [ ! -d "$dir" ]; then
			echo "[ERROR] One or more source directories are missing. Stopping backup"
			send_notification_to_discord error
			exit 1
		fi
	done
}

check_backup_dir(){
	if [ ! -d "$BACKUP_DIR" ]; then
		mkdir -p "$BACKUP_DIR"
		echo "[INFO] Backup directory not found. Created: $BACKUP_DIR"
	fi
}

check_snapshot_file(){
	if [ ! -f "$SNAPSHOT_FILE" ]; then
		touch "$SNAPSHOT_FILE"
		echo "[INFO] Created snaphshot file snapshot.file"
	else
		echo "[INFO] File $SNAPSHOT_FILE already exists"
	fi
}

#Function to create an incremental backup
create_backup(){

	TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        local archive_name="backup_${TIMESTAMP}.tar"
        local encrypted_name="${BACKUP_DIR}/${archive_name}.enc"

	tar --listed-incremental="$SNAPSHOT_FILE" --warning=none -czf - "${DIRS[@]}" 2>/dev/null \
  | openssl enc -aes-256-cbc -pbkdf2 -pass pass:"$ENCRYPTION_PASSWORD" -out "$encrypted_name"

	echo "[INFO] Backup archive created and encrypted."
}

#Function to send backup files to a remote server
send_to_server(){

        rsync -avz -e "ssh -i ${SSH_KEY}" --progress "${BACKUP_DIR}/" "${DEST_USER}@${DEST_HOST}:${DEST_PATH}/" --quiet

	if [[ $? -eq 0 ]]; then
		echo "[INFO] Successfully sent all data to the remote server."
		send_notification_to_discord success
	else
		echo "[ERROR] Problem sending data. Error code: $?."
		send_notification_to_discord error
	fi

}
# Function to send a notification to the user about the backup status
send_notification_to_discord(){

	STATUS="$1"
	# Define the Discord webhook URL for the target channel
	WEBHOOK_URL=""
	if [ "$STATUS" == "success" ]; then
		# JSON payload to send to Discord
        	BODY='{"username": "BackupBot", "content": "[INFO] Your backup was successfully sent to the remote server without any problems. "}'
	else
		# JSON payload to send to Discord
                BODY='{"username": "BackupBot", "content": "[ERROR] Backup failed! Please check the logs. "}'

	fi
	# Send notification
	curl -H "Content-Type: application/json" -d "$BODY" $WEBHOOK_URL
	echo "[INFO] Backup status notification sent to the user."
}

# Function to prevent running multiple instances of the backup script
lock_backup(){
	LOCKFILE="/tmp/backup.lock"

	if [ -e "$LOCKFILE" ]; then
		echo "[INFO] Another backup is already running. Exiting"
		exit 0

	fi

	touch "$LOCKFILE"
	trap 'rm -f "$LOCKFILE"' EXIT
}

#Execute all functions
lock_backup
echo "========== START BACKUP: $(date) =========="
check_free_space
check_old_local_backups
check_log_file
check_size_file_log
check_dirs
check_backup_dir
check_snapshot_file
create_backup
send_to_server

echo "========== BACKUP COMPLETED: $(date) =========="

