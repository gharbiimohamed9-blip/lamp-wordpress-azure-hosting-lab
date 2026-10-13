# 04 — Sauvegardes automatiques — étape 9

> Une sauvegarde jamais restaurée n'est pas une sauvegarde.

## Script
`scripts/backup_monsite.sh` :
1. `mysqldump --single-transaction` de `wp_monsite`, compressé en `.sql.gz`
2. archive `tar.gz` du dossier `/var/www/monsite`
3. rotation : suppression des fichiers de plus de 7 jours
4. journal dans `/var/log/monsite_backup.log`

`umask 077` : les archives (qui contiennent `wp-config.php`) ne sont lisibles que par root. `set -euo pipefail` : le script s'arrête à la première erreur.

## Planification
```bash
sudo cp scripts/backup_monsite.sh /usr/local/bin/ && sudo chmod 750 /usr/local/bin/backup_monsite.sh
sudo crontab -e
0 2 * * * /usr/local/bin/backup_monsite.sh
```
Test préalable avec `* * * * *` pendant 2 minutes. Attention : la VM doit être allumée à 02h00 (conflit possible avec l'arrêt automatique Azure).

## Test de restauration (scénario de démo)
1. Publier un article dans WordPress
2. Lancer la sauvegarde
3. Supprimer l'article
4. Restaurer la base : `gunzip < db_wp_monsite_XXXX.sql.gz | sudo mysql wp_monsite`
5. Vérifier que l'article est revenu
6. Vérifier les fichiers : extraction de l'archive dans `/tmp/restore_test` (`scripts/restore_test.sh`)

## Règle 3-2-1
Une sauvegarde sur le même disque ne protège pas de la perte de la VM. Mesures appliquées / possibles :
- copie hors serveur depuis le poste :
  `ssh -i <clé> azureuser@IP "sudo tar -C /var/backups -cz monsite" > monsite_backups.tar.gz`
- instantané du disque OS dans Azure
- évolution : Azure Backup ou Blob Storage
