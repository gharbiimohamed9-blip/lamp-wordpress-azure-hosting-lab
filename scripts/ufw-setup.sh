#!/bin/bash
# Pare-feu de la VM. SSH d'abord, sinon tu te bloques toi-même.
set -euo pipefail
sudo ufw allow OpenSSH
sudo ufw allow 'Apache Full'      # 80 + 443
sudo ufw allow 21/tcp             # FTP
sudo ufw allow 40000:40100/tcp    # FTP passif
sudo ufw allow 53                 # DNS (TCP + UDP)
sudo ufw --force enable
sudo ufw status verbose
