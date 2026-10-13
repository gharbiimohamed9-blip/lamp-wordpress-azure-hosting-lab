#!/bin/bash
# Sauvegarde quotidienne : base MySQL + fichiers du site, rotation 7 jours
set -euo pipefail
umask 077   # lisible uniquement par root (wp-config contient un mot de passe)

DATE=$(date +%F_%H%M)
BACKUP_DIR=/var/backups/monsite
SITE_DIR=/var/www/monsite
DB_NAME=wp_monsite
RETENTION_DAYS=7
LOG=/var/log/monsite_backup.log

mkdir -p "$BACKUP_DIR"

# 1. Base de données
mysqldump --single-transaction "$DB_NAME" | gzip > "$BACKUP_DIR/db_${DB_NAME}_${DATE}.sql.gz"

# 2. Fichiers du site
tar -czf "$BACKUP_DIR/files_${DATE}.tar.gz" -C "$SITE_DIR" .

# 3. Rotation
find "$BACKUP_DIR" -type f -mtime +"$RETENTION_DAYS" -delete

echo "$(date '+%F %T') sauvegarde OK ($DATE)" >> "$LOG"
