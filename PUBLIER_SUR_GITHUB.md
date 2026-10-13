# Publier le projet sur GitHub (à faire, puis supprimer ce fichier)

## 0. Avant de pousser : vérifications
- [ ] Remplacer `<TON NOM>`, `<ton-user>`, `<ton-profil>` dans README.md et LICENSE
- [ ] Ajouter tes 12 captures dans `screenshots/` (IDs d'abonnement et e-mails floutés)
- [ ] Compléter les « Difficultés rencontrées » avec tes vrais problèmes
- [ ] `grep -rniE "password|passwd|BEGIN (RSA|OPENSSH)" .` ne doit rien révéler de réel
- [ ] Aucun `.pem`, `.key`, `wp-config.php` réel dans le dossier

## 1. Créer le dépôt sur github.com
Nom : `lamp-wordpress-azure-hosting-lab` — Public — sans README (il existe déjà).
Description : *Laboratoire d'hébergement web : LAMP + WordPress sur Azure, FTPS, DNS BIND9, HTTPS, sauvegardes, 10 incidents résolus.*
Topics : `azure` `ubuntu` `apache` `php` `mysql` `wordpress` `vsftpd` `bind9` `letsencrypt` `linux` `sysadmin` `hosting` `devops`

## 2. Pousser le code
```bash
cd lamp-wordpress-azure-hosting-lab
git init -b main
git add .
git status                       # relis la liste : aucun secret
git commit -m "Projet LAMP + WordPress sur Azure : docs, configs, scripts"
git remote add origin https://github.com/<ton-user>/lamp-wordpress-azure-hosting-lab.git
git push -u origin main
```
Si le push est refusé, utilise un Personal Access Token (Settings > Developer settings) ou GitHub CLI : `gh auth login`.

## 3. Finitions
- Épingler le dépôt sur ton profil (Customize your pins)
- Créer une release `v1.0` (facultatif)
- Copier le lien du dépôt dans le CV

## 4. Quand tout est poussé
Supprimer l'environnement Azure pour arrêter la facturation :
```bash
az group delete --name rg-monsite --yes --no-wait
```
