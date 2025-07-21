#!/bin/bash

CONFIG_FILE="${1:-config.sh}"
source "${CONFIG_FILE}"

DIRS=("${SOURCE_DIRS[@]}")

exec >> "$LOG_FILE" 2>&1
echo "========== START BACKUP: $(date) =========="

check_dirs(){
	for dir in ${DIRS[@]}; do
		if [ ! -d "$dir" ]; then
			echo "Podany foldery nie istnieja.. Przerywam wykonywanie kopii"
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
		echo "Utworzono plik snapshot.file"
	else
		echo "Plik snapshot.file juz istnieje"
	fi
}

#funkcja do tworzenia kopii przyrostowej
create_backup(){
	
	TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        local archive_name="backup_${TIMESTAMP}.tar"
        local encrypted_name="${BACKUP_DIR}/${archive_name}.enc"

        tar --listed-incremental="$SNAPSHOT_FILE" -czf - "${DIRS[@]}" \
  | openssl enc -aes-256-cbc -pbkdf2 -pass pass:"$ENCRYPTION_PASSWORD" -out "$encrypted_name"

}

#funkcja umozliwiajaca przesylanie kopii
send_to_server(){

        rsync -avz -e "ssh -i ${SSH_KEY}" --progress "${BACKUP_DIR}/" "${DEST_USER}@${DEST_HOST}:${DEST_PATH}/"
	
	if [[ $? -eq 0 ]]; then
		echo "Przesylanie zakonczylo sie sukcesem"
	else	
		echo "Blad podczas przesylania kopii zapasowej, kod bledu $?."
	fi



}

#Wywolanie poszczegolnych funkcji

check_dirs
check_backup_dir
check_snapshot_file
create_backup
send_to_server
