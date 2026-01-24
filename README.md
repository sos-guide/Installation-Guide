# ⛑️ SOS GUIDE - Système d'Information Citoyen Résilient

**Solution open-source basée sur Raspberry Pi 4 pour situations d'urgence et zones sans connexion internet**

## 🎯 Présentation

**SOS GUIDE** est une solution innovante **exclusivement conçue pour Raspberry Pi 4** permettant de diffuser des informations essentielles aux citoyens en situation de crise, coupure réseau, ou dans des zones sans accès internet. Le système fonctionne sur un **Raspberry Pi 4** qui crée son propre réseau Wi-Fi local diffusant une page web contenant tous les services d'urgence et informations vitales.

### 🟠 **SPÉCIFICITÉ RASPBERRY PI 4**
> **⚠️ IMPORTANT : Ce projet nécessite impérativement un Raspberry Pi 4 (ou supérieur). Il ne fonctionnera pas correctement sur les modèles antérieurs (Pi 3, Pi 2, Pi Zero) en raison des exigences matérielles.**

### ✨ Fonctionnalités principales

- ✅ **Fonctionne 100% hors-ligne** - Aucune connexion internet nécessaire
- ✅ **Raspberry Pi 4 exclusif** - Optimisé pour la puissance et la connectivité du Pi 4
- ✅ **Réseau Wi-Fi local ouvert** - SSID: `⛑️ SOS Guide` (pas de mot de passe)
- ✅ **Interface web moderne et responsive** - Compatible mobile/tablete/ordinateur
- ✅ **Multi-utilisateurs** - Jusqu'à 50 connexions simultanées (Pi 4 uniquement)
- ✅ **Faible consommation** - 3-5 watts (fonctionne sur batterie externe)
- ✅ **Installation rapide** - Moins de 10 minutes
- ✅ **Open Source** - Licence MIT, communauté contributive

## 🖥️ Démonstration en ligne

- **Page de présentation** : [sos-guide.fr](https://sos-guide.fr)
- **Démo interactive** : [sos-guide.fr/demo.html](https://sos-guide.fr/demo.html)

*Note : La démo nécessite une connexion internet. Le système réel fonctionne sans internet sur Raspberry Pi 4.*

## 📋 Contenu inclus

### 🚨 Services d'Urgence (42 numéros)
- SAMU (15), Police (17), Pompiers (18), Numéro unique UE (112)

## 🛠️ Installation sur Raspberry Pi 4

### 🟠 **PRÉ-REQUIS OBLIGATOIRES**
- **Raspberry Pi 4** (2GB, 4GB ou 8GB) - **MODÈLE PLUS RÉCENT RECOMMANDÉ**
- **Carte microSD** 16GB+ (classe 10 recommandée)
- **Alimentation officielle 5V/3A** (ESSENTIEL pour stabilité)
- **Optionnel** : Boîtier, dissipateur thermique, batterie externe

---

### Méthode 1 : Script d'installation (Recommandé)

# Télécharger le script
git clone https://github.com/sos-guide/Installation-Guide.git

# Entrer dans le dossier
cd Installation-Guide

# Rendre exécutable
chmod +x install.sh

# Exécuter en root
sudo ./install.sh


### Méthode 2 : Image système complète
*Disponible prochainement - Image pré-configurée pour flashage direct*
   
Se connecter au réseau
   - Chercher le Wi-Fi `⛑️ SOS Guide` (émis par votre Pi 4)
   - Se connecter (pas de mot de passe)
   - Ouvrir un navigateur à l'adresse `http://10.0.0.1`
