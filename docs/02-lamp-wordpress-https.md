# 02 — PHP, MySQL, WordPress et HTTPS — étapes 4 à 6

## PHP 8.3
```bash
sudo apt install php libapache2-mod-php php-mysql php-curl php-gd php-mbstring \
  php-xml php-zip php-intl php-imagick -y
```
Réglages WordPress dans `/etc/php/8.3/apache2/php.ini` (voir `config/php-wordpress.ini.txt`) : uploads 64 Mo, mémoire 256 Mo, `expose_php = Off`.
Test avec `phpinfo()` puis **suppression immédiate** du fichier (il révèle de nombreuses informations).

## MySQL 8
```bash
sudo apt install mysql-server -y
sudo mysql_secure_installation
```
Création de la base et d'un utilisateur dédié aux droits limités :
```sql
CREATE DATABASE wp_monsite CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY '<mot_de_passe_fort>';
GRANT ALL PRIVILEGES ON wp_monsite.* TO 'wp_user'@'localhost';
FLUSH PRIVILEGES;
```
Vérification : `sudo ss -tlnp | grep 3306` doit afficher `127.0.0.1:3306` (MySQL non exposé).
Bonnes pratiques : un utilisateur par site, jamais `root` pour WordPress.

## WordPress
```bash
cd /tmp && wget https://wordpress.org/latest.tar.gz && tar -xzf latest.tar.gz
sudo mkdir -p /var/www/monsite && sudo rsync -a wordpress/ /var/www/monsite/
sudo cp /var/www/monsite/wp-config-sample.php /var/www/monsite/wp-config.php
```
`wp-config.php` : identifiants de base + salts générés via l'API officielle (exemple : `config/wp-config.EXAMPLE.php`).

Permissions :
```bash
sudo chown -R www-data:www-data /var/www/monsite
sudo find /var/www/monsite -type d -exec chmod 755 {} \;
sudo find /var/www/monsite -type f -exec chmod 644 {} \;
sudo chmod 640 /var/www/monsite/wp-config.php
```

## Virtual host Apache
Fichier `config/monsite.conf` (`AllowOverride All` pour les permaliens).
```bash
sudo a2dissite 000-default.conf && sudo a2ensite monsite.conf
sudo apache2ctl configtest && sudo systemctl reload apache2
```

## HTTPS avec Let's Encrypt
Le HTTPS est activé **avant** de terminer l'installation WordPress : le mot de passe admin ne circule jamais en clair.
```bash
sudo apt install certbot python3-certbot-apache -y
sudo certbot --apache -d monsite-gharbi.francecentral.cloudapp.azure.com \
  -m <email> --agree-tos --no-eff-email --redirect
sudo certbot renew --dry-run
systemctl list-timers | grep certbot
```
Vérifications :
```bash
curl -I http://<FQDN>     # 301 vers https
curl -I https://<FQDN>    # 200 / 302
openssl s_client -connect <FQDN>:443 -servername <FQDN> </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```
Un certificat auto-signé a été généré à titre de comparaison (émetteur = sujet) puis supprimé : le navigateur l'avertit car aucune autorité reconnue ne l'a signé.

## Finalisation WordPress
Installation dans le navigateur, création d'une page et d'un article de test, permaliens « Nom de l'article » (valide `mod_rewrite` + `AllowOverride`), adresses WordPress en `https://`.

## Durcissement Apache
`ServerTokens Prod` et `ServerSignature Off` dans `security.conf`. HSTS optionnel avec `max-age=300` pour commencer.

## Dépannage rapide
| Symptôme | Piste |
|---|---|
| Page blanche / 500 | `tail /var/log/apache2/monsite_error.log` |
| « Error establishing a database connection » | identifiants `wp-config.php`, `systemctl status mysql` |
| Certbot « Timeout during connect » | port 80 fermé (NSG ou UFW) |
| Certbot « DNS problem » | `nslookup <FQDN>` |
