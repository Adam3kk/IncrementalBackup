#!/bin/bash

#Konfiguracja
DIRS=("/home/adam/files" "/test/files") #sciezki do okreslonych folderow
BACKUP_DIR="/tmp/backup" #sciezka do zapisywania kopii
TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S) #aktualna data
SNAPSHOT_FILE="$BACKUP_DIR/snapshot.file" #plik pamietajacy ostatnie zmiany w kopiach
ENCRYPTION_PASSWORD="qwerty123" #Haslo do szyfrowania

check_snapshot_file(){
	if [ ! -f "$SNAPSHOT_FILE" ]; then
		touch $SNAPSHOT_FILE
		echo "Utworzono plik snapshot.file"
	else
		echo "Plik snapshot.file juz istnieje"
	fi
}

#funkcja do tworzenia kopii przyrostowej
create_backup(){
	local backup_name="backup_$TIMESTAMP"
	local temp_backup="$BACKUP_DIR/$backup_name.tar.enc"
	
	tar --listed-incremental=$SNAPSHOT_FILE -cz ${DIRS[@]} | openssl enc -aes-256-cbc -pbkdf2 -pass pass:$ENCRYPTION_PASSWORD -out $temp_backup 
}


#wyswietlanie wszystkich folderow
for dir in ${DIRS[@]}; do
	echo $dir
done

check_snapshot_file

create_backup
