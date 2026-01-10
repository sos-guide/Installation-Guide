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
- ✅ **42 services d'urgence pré-enregistrés** - SAMU, Pompiers, Police, Services sociaux
- ✅ **Guides de survie complets** - Équipements, protocoles, premiers secours
- ✅ **FAQ santé mentale** - Support psychologique en situation de crise
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
- SOS Médecins (3624), Centre Anti-Poison, Urgences Gaz/Électricité
- SAMU Social (115), Enfance en Danger (119), Violences Femmes (3919)
- Suicide Écoute (3114), Handicap Écoute (0 800 360 360)

### 🤝 Associations & Solidarité
- Restos du Cœur, Croix-Rouge, Secours Catholique, Emmaüs
- Médecins du Monde, Banque Alimentaire, Secours Populaire
- SPA, Petits Frères des Pauvres, SOS Amitié

### 🌍 Organisations Internationales
- UNICEF, Médecins Sans Frontières, CARE France
- Action contre la Faim, WWF, Amnesty International
- Handicap International, Croix-Rouge Internationale

### 📚 Guides Pratiques Complets
- **Équipements de survie** - Liste complète des 12 catégories essentielles
- **Protocole d'urgence** - Les 5 étapes à suivre en situation critique
- **Alerte & communication** - Systèmes d'alerte officiels (FR-Alert, SAIP)
- **Santé & premiers secours** - Trousse médicale et gestes qui sauvent
- **FAQ santé mentale** - 8 questions-réponses sur le bien-être en crise

## 🛠️ Installation sur Raspberry Pi 4

### 🟠 **PRÉ-REQUIS OBLIGATOIRES**
- **Raspberry Pi 4** (2GB, 4GB ou 8GB) - **MODÈLE PLUS RÉCENT RECOMMANDÉ**
- **Carte microSD** 16GB+ (classe 10 recommandée)
- **Alimentation officielle 5V/3A** (ESSENTIEL pour stabilité)
- **Optionnel** : Boîtier, dissipateur thermique, batterie externe

---

### Méthode 1 : Script d'installation (Recommandé)
```bash
# Télécharger le script
wget https://raw.githubusercontent.com/sos-guide/Installation-Guide/main/install.sh

# Rendre exécutable
chmod +x install.sh

# Exécuter en root
sudo ./install.sh
