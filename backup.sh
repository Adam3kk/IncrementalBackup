#!/bin/bash

#Konfiguracja
DIRS=("/home/adam/files" "/test/files" "/testowyfolder/pliki") #sciezki do okreslonych folderow
BACKUP_DIR="/tmp/backup/files" #sciezka do zapisywania kopii
TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S) #aktualna data
SNAPSHOT_FILE="/tmp/backup/snapshot.file" #plik pamietajacy ostatnie zmiany w kopiach
ENCRYPTION_PASSWORD="qwerty123" #Haslo do szyfrowania



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
	local backup_name="backup_$TIMESTAMP"
	local temp_backup="$BACKUP_DIR/$backup_name.tar.enc"
	
	tar --listed-incremental="$SNAPSHOT_FILE" -cz ${DIRS[@]} | openssl enc -aes-256-cbc -pbkdf2 -pass pass:$ENCRYPTION_PASSWORD -out $temp_backup 
}

#funkcja umozliwiajaca przesylanie kopii
send_to_server(){
	local local_dir="/tmp/backup/files" #lokalizacja pliku z kopia
	local remote_user="adam" #nazwa uzytkownika na zdalnym serwerze
	local remote_ip="172.22.233.105" #adres ip zdalnego serwera
	local remote_dir="/home/adam/backup" #sciezka w ktorej pojawi sie nowy plik

	rsync -avz --progress "$local_dir" "$remote_user"@"$remote_ip":"$remote_dir"
	
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
