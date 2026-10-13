#!/bin/bash
# Création de l'infrastructure Azure (Cloud Shell ou az en local)
# Remplacer MON_IP par ton IP publique personnelle (curl -4 ifconfig.me)
set -euo pipefail

RG=rg-monsite
LOC=francecentral
VM=vm-monsite
DNS_LABEL=monsite-gharbi        # doit être unique dans la région
MON_IP=203.0.113.10

# 1. Groupe de ressources + VM Ubuntu 24.04
az group create --name $RG --location $LOC
az vm create \
  --resource-group $RG --name $VM \
  --image Canonical:ubuntu-24_04-lts:server:latest \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --public-ip-address-dns-name $DNS_LABEL \
  --os-disk-delete-option Delete

# 2. Règles du NSG (vérifier le nom : az network nsg list -g $RG -o table)
NSG=vm-monsiteNSG
az network nsg rule update -g $RG --nsg-name $NSG -n default-allow-ssh \
  --source-address-prefixes $MON_IP
az network nsg rule create -g $RG --nsg-name $NSG -n Allow-Web --priority 1010 \
  --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 80 443
az network nsg rule create -g $RG --nsg-name $NSG -n Allow-FTP --priority 1020 \
  --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes $MON_IP --destination-port-ranges 21 40000-40100
az network nsg rule create -g $RG --nsg-name $NSG -n Allow-DNS-TCP --priority 1030 \
  --direction Inbound --access Allow --protocol Tcp \
  --source-address-prefixes $MON_IP --destination-port-ranges 53
az network nsg rule create -g $RG --nsg-name $NSG -n Allow-DNS-UDP --priority 1040 \
  --direction Inbound --access Allow --protocol Udp \
  --source-address-prefixes $MON_IP --destination-port-ranges 53

# 3. Nettoyage en fin de projet (supprime TOUT, arrête la facturation)
# az group delete --name $RG --yes --no-wait
