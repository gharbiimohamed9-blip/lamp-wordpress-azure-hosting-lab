# 01 — VM Azure, réseau (NSG + UFW) — étapes 1 à 3

## Objectif
Déployer une VM Ubuntu Server 24.04 LTS sur Azure, la joindre en SSH et la protéger à **deux niveaux** : NSG (pare-feu réseau Azure) et UFW (pare-feu de la VM).

## Paramètres retenus
| Élément | Valeur |
|---|---|
| Groupe de ressources | `rg-monsite` |
| VM | `vm-monsite` (Standard_B2s, 2 vCPU / 4 Go) |
| Région | `francecentral` |
| Image | Ubuntu Server 24.04 LTS x64 Gen2 |
| Authentification | Clé SSH (utilisateur `azureuser`) |
| IP publique | Statique (SKU Standard) + étiquette DNS Azure |
| Disque | SSD standard 30 Go, supprimé avec la VM |

## 1. Création de la VM
Via le portail ou via `scripts/azure-cli-commands.sh` (`az vm create`). La clé privée `.pem` n'est téléchargeable qu'une seule fois : elle est stockée hors du dépôt.

## 2. Contrôle des coûts (fait dès le départ)
- Budget de 10 € avec alertes à 80 % et 100 %.
- Arrêt automatique de la VM à 23:00.
- Arrêt toujours depuis le portail (état « Arrêtée (libérée) ») : un `shutdown` interne ne libère pas le calcul facturé.

## 3. Connexion SSH et préparation
```bash
ssh -i ~/.ssh/vm-monsite_key.pem azureuser@IP_PUBLIQUE
sudo apt update && sudo apt upgrade -y
sudo timedatectl set-timezone Africa/Tunis
ip a; curl -4 ifconfig.me; lsb_release -a
```
**Constat important :** l'IP privée (`10.x.x.x`) diffère de l'IP publique, car Azure fait du NAT. La VM ne connaît pas son IP publique, ce qui impacte le FTP passif (voir doc 03). Pas de netplan statique ni de changement de hostname (cloud-init le réinitialise).

## 4. Filtrage à deux niveaux
### NSG (Azure, avant la VM)
| Priorité | Nom | Port | Proto | Source |
|---|---|---|---|---|
| 1000 | SSH | 22 | TCP | Mon IP |
| 1010 | Allow-Web | 80, 443 | TCP | Internet |
| 1020 | Allow-FTP | 21, 40000-40100 | TCP | Mon IP |
| 1030 | Allow-DNS-TCP | 53 | TCP | Mon IP |
| 1040 | Allow-DNS-UDP | 53 | UDP | Mon IP |

### UFW (dans la VM)
```bash
sudo ufw allow OpenSSH          # AVANT d'activer UFW
sudo ufw allow 'Apache Full'
sudo ufw allow 21/tcp
sudo ufw allow 40000:40100/tcp
sudo ufw allow 53
sudo ufw enable
```
> Un port doit être ouvert **dans les deux** pare-feu. Source d'incident classique (voir doc 05, incident 8).

## 5. Apache
```bash
sudo apt install apache2 -y
sudo systemctl enable --now apache2
curl -I http://localhost                 # 200 OK
sudo a2enmod rewrite ssl headers && sudo systemctl restart apache2
```
Test externe : la page « Apache2 Ubuntu Default Page » s'affiche via le FQDN Azure. Si `localhost` répond mais pas l'extérieur, le NSG est en cause.

## Points d'attention
- IP personnelle dynamique : mettre à jour la règle SSH du NSG sinon perte d'accès.
- Captures associées : 1, 2, 3.
