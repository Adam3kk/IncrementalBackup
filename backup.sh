#!/bin/bash

DIRS=("/home/adam/files" "/test/files") #sciezki do okreslonych folderow
BACKUP_DIR="/tmp/backup"
TIMESTAMP=$(date +%Y_%m_%d_%H:%M:%S) #aktualna data



#funkcja do tworzenia kopii przyrostowej
create_backup(){
	local backup_name="backup_$TIMESTAMP"
	local temp_backup="$BACKUP_DIR/$backup_name"
	mkdir -p $temp_backup 
	


}














#wyswietlanie wszystkich folderow
for dir in ${DIRS[@]}; do
	echo $dir
done

echo $BACKUP_DIR
echo $TIMESTAMP
echo $NEW_BACKUP_DIR
create_backup
