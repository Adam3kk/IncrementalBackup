# Incremental Backup Script with Encryption and Remote Upload

## This script provides automated, encrypted **incremental backups** for specified directories. It is designed to be simple, secure, and efficient, and supports remote backup. 

##  Requirement

### Check the installed version of tar
```
tar --version
```
### Check the installed version of openssl
```
openssl version
```
### Install rsync
```
apt update
apt install rsync
```
### Copy your local public SSH key to the remote server
#### This step allows the script to connect via SSH without prompting for a password. It is important for automated backups:
```
ssh-copy-id -i ~/.ssh/id_rsa.pub username@remote_server_ipv4_address
```
### Add the backup script to crontab
```
sudo crontab -e
```
### Schedule the script to run daily at 6 PM
```
0 18 * * * /path/to/backup.sh
```
### How It Works

#### First Run (Full backup)
- The script creates a **full archive** of all files and folders defined by the user in a configuration file,

#### Subsequent Runs (Incremental Backup)
- Only files that have changed since the last backup are archived,
- File changes are tracked using a **snapshot file** (`SNAPSHOT_FILE`), which stores metadata about file states over time,

#### Archiving & Encryption
- The script uses the `tar` utility to create backup archives,
- Each archive is **encrypted using OpenSSL** with the `AES-256-CBC` algorithm,
- The encryption password is defined within the script,

#### Remote Backup Support

##### Backups can be securely transferred to a remote server using `rsync`.

`rsync` is provided with:
- the path to the local archive file,
- remote server login credentials (username and IPv4 address),
- the destination path on the remote server.

#### Information about functions

##### `check_dirs()`
- Verifies that all source directories (to be backed up) exist.
- If any are missing, the script exits immediately to avoid inconsistent backups.

##### `check_backup_dir()`
- Ensures that the local destination directory for backups exists.
- Automatically creates the directory if it's missing.

##### `check_snapshot_file()`
- Checks if the snapshot file exists.
- If not, it creates one. This file is essential for detecting incremental changes.

##### `create_backup()`
- Creates an incremental archive using `tar` and a snapshot file,
- The archive includes only files changed since the last backup,
- The archive is encrypted using AES-256-CBC via `openssl`,
- The resulting `.tar.enc` file is saved to the `BACKUP_DIR`,

##### `send_to_server()`
- Transfers all files from `BACKUP_DIR` to the remote server using `rsync` over SSH,
- Uses the SSH private key specified by `SSH_KEY`,
- All output is logged to the file defined in `LOG_FILE`,

##### `check_old_local_backups()`
- Searches the local backup directory (BACKUP_DIR) for .tar.enc files older than 5 days,
- If old backup files are found, their paths are printed to the log and then deleted using find, 
- Otherwise if no old files are found, an informational message is logged instead,
