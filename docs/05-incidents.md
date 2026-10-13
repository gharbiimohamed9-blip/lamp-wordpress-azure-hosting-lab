# 05 — Simulation et résolution d'incidents — étape 11

Chaque incident a été provoqué volontairement, diagnostiqué à partir des logs et corrigé.

| # | Incident provoqué | Symptôme client | Diagnostic | Solution |
|---|---|---|---|---|
| 1 | `systemctl stop mysql` | « Error establishing a database connection » | `systemctl status mysql` | `sudo systemctl start mysql` |
| 2 | Mauvais mot de passe dans `wp-config.php` | Même erreur de connexion à la base | `mysql -u wp_user -p` vs `wp-config.php` | Corriger le mot de passe |
| 3 | `.htaccess` invalide | Erreur 500 | `tail /var/log/apache2/monsite_error.log` | Corriger / renommer `.htaccess`, régénérer les permaliens |
| 4 | `chmod 000 wp-content` | Images et thèmes cassés, 403 | Logs Apache, `ls -ld` | `chown www-data` + `chmod 755/644` |
| 5 | Port passif fermé dans UFW | FTP : connexion OK, liste bloquée | `sudo ufw status`, log vsftpd | Rouvrir `40000:40100/tcp` |
| 6 | Point final retiré dans la zone DNS | Le domaine ne résout pas / mauvais nom | `named-checkzone`, `dig` | Corriger, incrémenter le serial, redémarrer bind9 |
| 7 | Disque rempli (`fallocate -l 5G /tmp/gros`) | Site lent, erreurs d'écriture, upload impossible | `df -h`, `du -sh /var/* \| sort -h` | `rm /tmp/gros`, rotation des logs et sauvegardes |
| 8 | **Azure** : règle NSG Allow-Web supprimée | Site injoignable (timeout) alors que `curl localhost` fonctionne | Test local OK / externe KO, Network Watcher (vérification des flux IP) | Recréer la règle NSG |
| 9 | **Azure** : `pasv_address` retiré de vsftpd | FTP : liste bloquée (IP privée annoncée) | Journal FileZilla (IP `10.x` dans la réponse PASV), `ip a` | Remettre `pasv_address=IP_PUBLIQUE`, redémarrer vsftpd |
| 10 | **Azure** : port 80 fermé puis `certbot renew --dry-run` | Renouvellement en échec, risque de certificat expiré | Sortie certbot « Timeout during connect », `/var/log/letsencrypt/letsencrypt.log` | Rouvrir le port 80, relancer le dry-run |

## Méthode de diagnostic réseau en deux temps
1. **Le service fonctionne-t-il dans la VM ?** `curl -I http://localhost`, `ss -tulpn`, `systemctl status`. Sinon : problème de service.
2. **Est-il joignable de l'extérieur ?** Sinon : NSG puis UFW. Azure Network Watcher (Vérification des flux IP, Règles de sécurité en vigueur) indique la règle bloquante.

## Commandes de diagnostic de référence
```bash
systemctl status apache2 mysql vsftpd bind9
sudo journalctl -u apache2 -n 50 --no-pager
sudo tail -f /var/log/apache2/monsite_error.log
sudo ss -tulpn
sudo ufw status verbose
df -h && free -h && uptime
dig @IP_PUBLIQUE monsite.test +short
```

## Difficultés réelles rencontrées
> À compléter avec TES problèmes réels (3 à 5), au format : **Symptôme → Cause → Correctif**.
> Exemple : *Liste FTP bloquée → IP privée annoncée en mode passif → `pasv_address` + ouverture de la plage 40000-40100 dans NSG et UFW.*
