#!/bin/bash
# Test de restauration : sudo ./restore_test.sh <db_xxx.sql.gz> <files_xxx.tar.gz>
set -euo pipefail
DB_FILE="${1:?fichier .sql.gz requis}"
FILES_ARCHIVE="${2:?archive .tar.gz requise}"

echo "[1/2] Restauration de la base wp_monsite..."
gunzip < "$DB_FILE" | mysql wp_monsite

echo "[2/2] Extraction des fichiers dans /tmp/restore_test (test non destructif)..."
rm -rf /tmp/restore_test && mkdir /tmp/restore_test
tar -xzf "$FILES_ARCHIVE" -C /tmp/restore_test
ls /tmp/restore_test
echo "Restauration de test terminée."
