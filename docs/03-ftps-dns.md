# 03 — FTPS (vsftpd) et DNS (BIND9) — étapes 7 et 8

## A. FTPS avec vsftpd
Le FTP classique envoie les mots de passe en clair : on active **FTPS** (FTP + TLS).

### Compte client isolé
```bash
sudo apt install vsftpd -y
sudo adduser --home /var/www/monsite --no-create-home --shell /usr/sbin/nologin --gecos "" ftpwp
echo /usr/sbin/nologin | sudo tee -a /etc/shells
sudo usermod -aG www-data ftpwp
sudo chmod -R g+w /var/www/monsite/wp-content
sudo find /var/www/monsite/wp-content -type d -exec chmod g+s {} \;
echo ftpwp | sudo tee /etc/vsftpd.userlist
```
- Pas de shell (`nologin`) : le compte ne sert qu'au transfert.
- `chroot_local_user=YES` : le client reste dans `/var/www/monsite`.
- Écriture limitée à `wp-content` (thèmes, plugins, médias).
- Liste blanche via `userlist_deny=NO`.

### TLS
Réutilisation du certificat Let's Encrypt (aucun avertissement dans FileZilla). Un hook de renouvellement redémarre vsftpd :
```bash
printf '#!/bin/bash\nsystemctl restart vsftpd\n' | sudo tee /etc/letsencrypt/renewal-hooks/deploy/restart-vsftpd.sh
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/restart-vsftpd.sh
```

### Configuration
Voir `config/vsftpd.conf` : TLS 1.2 minimum, TLS obligatoire pour login et données, anonyme désactivé.

### Le piège du mode passif sur Azure
La VM ne connaît que son IP privée `10.x`. Sans `pasv_address=IP_PUBLIQUE`, le serveur annonce cette IP inaccessible : connexion de contrôle OK, **liste des fichiers bloquée**. Il faut aussi ouvrir la plage `40000-40100` dans le NSG **et** UFW.

### Tests
- FileZilla : FTP explicite sur TLS (« TLS actif » dans le journal), envoi d'un fichier dans `wp-content/uploads`.
- Connexion `anonymous` et `azureuser` refusées (attendu).
- CLI : `curl -v --ssl-reqd --user ftpwp ftp://<FQDN>/wp-content/`

| Ordre de diagnostic si la liste se bloque |
|---|
| 1. `pasv_address` correcte  2. plage passive ouverte NSG + UFW  3. IP perso dans la règle NSG  4. `/var/log/vsftpd.log` |

## B. DNS avec BIND9
Création de la zone `monsite.test` (suffixe `.test`, non routable) pour démontrer la gestion DNS d'un hébergeur. Le site, lui, utilise le nom DNS Azure.

### Sécurité : serveur autoritaire uniquement
`recursion no; allow-recursion { none; }; allow-transfer { none; };` (voir `config/named.conf.options`) pour ne pas devenir un résolveur ouvert (attaques par amplification). Conséquence : ne pas l'utiliser comme DNS du poste, on l'interroge avec `dig @IP_PUBLIQUE`.

### Zone
`config/named.conf.local` déclare la zone, `config/db.monsite.test` contient les enregistrements :

| Type | Nom | Valeur | Rôle |
|---|---|---|---|
| SOA | `@` | `ns1.monsite.test.` | Autorité, numéro de série |
| NS | `@` | `ns1.monsite.test.` | Serveur de noms |
| A | `@`, `ns1`, `mail` | IP publique | Nom vers IPv4 |
| CNAME | `www`, `ftp` | `monsite.test.` | Alias |
| MX | `@` | `10 mail.monsite.test.` | Messagerie (priorité 10) |
| TXT | `@` | `v=spf1 mx -all` | SPF |

### Validation
```bash
sudo named-checkconf
sudo named-checkzone monsite.test /etc/bind/db.monsite.test   # OK
sudo systemctl restart bind9
dig @IP_PUBLIQUE monsite.test A +short
dig @IP_PUBLIQUE www.monsite.test +short
dig @IP_PUBLIQUE monsite.test MX +short
dig @IP_PUBLIQUE monsite.test TXT +short
dig @IP_PUBLIQUE google.com +short        # vide : pas de récursion (attendu)
```
Erreur classique : oublier le point final d'un nom complet. Le serial doit être incrémenté à chaque modification.

### Amélioration possible
Avec un vrai domaine : mêmes enregistrements chez un registrar, ou délégation vers BIND (deux serveurs de noms + glue records).
