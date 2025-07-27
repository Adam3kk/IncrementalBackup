#!/bin/bash

CONFIG_FILE="${1:-config.sh}"
source "${CONFIG_FILE}"

DIRS=("${SOURCE_DIRS[@]}")

exec >> "$LOG_FILE" 2>&1
echo "========== START BACKUP: $(date) =========="

#Functio helps user to check free spaces before make backup
check_free_space(){
	AVAILABLE_SPACE=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
	AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE / 1024 / 1024))
	FREE_SPACE=2

	if [ "$AVAILABLE_SPACE_GB" -lt "$FREE_SPACE" ]; then
		echo "[ERROR] Not enough disk space for backup. Minimum required: $FREE_SPACE GB"
        	echo "========== BACKUP COMPLETED: $(date) =========="
		exit 1
	fi
	echo "[INFO] Free space available: $AVAILABLE_SPACE_GB GB"
}


# Function to delete local backup files older than 5 days
check_old_local_backups() {
    	echo "[INFO] Checking for old backups in: $BACKUP_DIR"

	# Condition to find old backup files
	AGE_CONDITION="-mtime +5"

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
		echo "[INFO] LOG_FILE path is not included."
		exit 1
	fi
}


check_dirs(){
	for dir in ${DIRS[@]}; do
		if [ ! -d "$dir" ]; then
			echo "[INFO] One or more source directories are missing. Stopping backup"
			exit 1
		fi
	done
}

check_backup_dir(){
	if [ ! -d "$BACKUP_DIR" ]; then
		mkdir -p "$BACKUP_DIR"
	fi
}

check_snapshot_file(){
	if [ ! -f "$SNAPSHOT_FILE" ]; then
		touch "$SNAPSHOT_FILE"
		echo "[INFO] Created snaphshot file snapshot.file"
	else
		echo "[INFO] File snapshot.file already exists"
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
	else
		echo "[ERROR] Problem sending data. Error code: $?."
	fi

}

#Execute all functions
check_free_space
check_old_local_backups
check_dirs
check_backup_dir
check_snapshot_file
create_backup
send_to_server

echo "========== BACKUP COMPLETED: $(date) =========="

