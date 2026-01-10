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
bash
# Télécharger le script
wget https://raw.githubusercontent.com/sos-guide/Installation-Guide/main/install.sh

# Rendre exécutable
chmod +x install.sh

# Exécuter en root
sudo ./install.sh


### Méthode 2 : Image système complète
*Disponible prochainement - Image pré-configurée pour flashage direct*

## 🖥️ Configuration Technique du Raspberry Pi 4

### 🟠 **SPECIFICATIONS MATÉRIELLES REQUISES**

Raspberry Pi 4 Modèle B (2019 ou plus récent)
└── Processeur : Broadcom BCM2711, quad-core Cortex-A72 (ARM v8) 64-bit @ 1.5GHz
└── Mémoire RAM : 2GB minimum (4GB recommandé pour 30+ utilisateurs)
└── Connectivité : 
    • Wi-Fi 802.11ac dual-band (2.4GHz et 5GHz)
    • Bluetooth 5.0
    • Port Gigabit Ethernet (désactivé dans notre configuration)
    • 2 × ports USB 3.0, 2 × ports USB 2.0
└── Vidéo : 2 × micro-HDMI ports (jusqu'à 4Kp60)
└── Stockage : Carte microSD (boot)
└── Alimentation : USB-C 5V/3A (IMPORTANT : utiliser l'alimentation officielle)


### 🔧 Configuration réseau optimisée pour Pi 4
yaml
SSID: "⛑️ SOS Guide"
IP du serveur: 10.0.0.1
Plage DHCP: 10.0.0.2 à 10.0.0.49
Port: HTTP 80
Bande Wi-Fi: 2.4GHz (meilleure portée pour les bâtiments)
Canal: 7 (moins de interférences)
Mode sécurité: Ouvert (facilite l'accès en urgence)
Utilisateurs max: 50 simultanés (capacité réelle du Pi 4)


### ⚙️ Logiciels optimisés pour Raspberry Pi 4
bash
Système: Raspberry Pi OS Lite (32-bit) Bullseye
Serveur web: Lighttpd (léger et rapide)
Point d'accès: Hostapd (optimisé pour le chipset Wi-Fi Pi 4)
DHCP: Dnsmasq (configuration minimale)
Interface: HTML5, CSS3, JavaScript vanilla (pas de frameworks lourds)


## 🚀 Démarrage rapide Raspberry Pi 4

1. **Préparer le Raspberry Pi 4**
   bash
   # Utiliser Raspberry Pi Imager pour flasher Raspberry Pi OS Lite
   # Activer SSH dans les préférences
   # Configurer le Wi-Fi si nécessaire pour les mises à jour initiales
   

2. **Connecter et mettre à jour**
   bash
   ssh pi@votre-raspberry
   sudo apt update && sudo apt full-upgrade -y
   sudo raspi-config
   # → Network Options → Hostname → "sos-guide"
   # → Performance Options → Overclock → Medium (optionnel)
   

3. **Exécuter l'installation**
   bash
   sudo ./install.sh
   

4. **Se connecter au réseau**
   - Chercher le Wi-Fi `⛑️ SOS Guide` (émis par votre Pi 4)
   - Se connecter (pas de mot de passe)
   - Ouvrir un navigateur à l'adresse `http://10.0.0.1`

## 🎨 Personnalisation

### Ajouter des services
Modifier le fichier `demo.html` dans la section `SERVICES` :
javascript
{
    id: 43,
    cat: 'NouvelleCatégorie',
    name: 'Nouveau Service',
    num: '01 23 45 67 89',
    col: '#CouleurHexa',
    icon: ICONS.nom_icone,
    desc: 'Description courte',
    detail: 'Description détaillée pour le modal'
}


### Modifier l'apparence
- **Couleurs** : Variables CSS dans `:root`
- **Logo** : Remplacer l'emoji ⛑️ par votre logo
- **Contenu** : Modifier les sections dans les fichiers HTML

## 🤝 Contribuer

Les contributions sont les bienvenues ! Voici comment participer :

1. **Fork** le projet
2. **Créez une branche** (`git checkout -b feature/Amelioration`)
3. **Commitez vos changements** (`git commit -m 'Ajout d'une fonctionnalité'`)
4. **Poussez vers la branche** (`git push origin feature/Amelioration`)
5. **Ouvrez une Pull Request**

### Zones de contribution prioritaires
- 📚 **Traductions** (anglais, espagnol, allemand, etc.)
- 🩺 **Services locaux** (ajout de numéros par région/pays)
- 📱 **Améliorations mobiles** (PWA, application native)
- 🔌 **Intégrations** (API météo, alertes officielles)
- 🎨 **Design** (thèmes alternatifs, accessibilité)

## ❓ FAQ

### Q: Pourquoi spécifiquement Raspberry Pi 4 ?
**R**: Le Raspberry Pi 4 offre :
- **Wi-Fi dual-band** (meilleure portée et stabilité)
- **Port Gigabit Ethernet** (pour extensions futures)
- **USB 3.0** (pour stockage externe rapide)
- **Puissance CPU/GPU** suffisante pour 50+ utilisateurs
- **Communauté massive** et support à long terme

### Q: Puis-je utiliser un Raspberry Pi 3 ou Pi Zero ?
**R**: **Non recommandé**. Le Pi 4 est essentiel pour :
- La stabilité avec 30+ connexions simultanées
- Le débit Wi-Fi suffisant pour plusieurs utilisateurs
- Les performances du serveur web Lighttpd
- La fiabilité en situation critique

### Q: Le système fonctionne-t-il sans internet ?
**R**: Oui ! SOS Guide crée son propre réseau Wi-Fi local via le Raspberry Pi 4. Aucune connexion internet n'est nécessaire pour fonctionner.

### Q: Combien d'utilisateurs simultanés sur un Pi 4 ?
**R**: Jusqu'à **50 connexions simultanées** sur un Raspberry Pi 4 4GB. 30-40 sur un modèle 2GB.

### Q: Quelle autonomie sur batterie ?
**R**: **24h+** avec une batterie externe de 20.000mAh. Le Pi 4 consomme seulement 3-5W en mode serveur.

### Q: Comment mettre à jour les informations ?
**R**: Deux méthodes :
1. Modifier directement les fichiers HTML/JSON
2. Utiliser l'interface d'administration (en développement)

### Q: Est-ce sécurisé ?
**R**: Le réseau est ouvert pour faciliter l'accès en situation d'urgence. Le système est isolé (eth0 désactivé) pour éviter les intrusions externes.

### Q: Puis-je l'utiliser dans ma commune ?
**R**: Absolument ! SOS Guide est conçu spécifiquement pour les collectivités. Contactez-nous pour un déploiement personnalisé.

## 📞 Support & Contact

- **Site web** : [sos-guide.fr](https://sos-guide.fr)
- **Email** : contact@sos-guide.fr
- **GitHub Issues** : [Signaler un problème](https://github.com/sos-guide/Installation-Guide/issues)
- **Discussions** : [Forum GitHub](https://github.com/sos-guide/Installation-Guide/discussions)

### 💼 Pour les collectivités
Nous proposons des **kits Raspberry Pi 4 clés en main** incluant :
- **Raspberry Pi 4 4GB** pré-configuré
- Boîtier étanche et résistant
- Alimentation officielle 5V/3A et batterie externe
- Support technique dédié
- Formation à l'utilisation

Contactez-nous à **contact@sos-guide.fr**

## 👤 Fondateur & Équipe

### Ludovic MARTIN
**Autodidacte Ingénieur systèmes & Sécurité**

> *"Notre mission n'est pas de créer plus de technologie, mais de rendre la technologie existante utile à tous, surtout quand tout le reste s'arrête."*

- 📧 contact@sos-guide.fr

### La communauté
SOS GUIDE est soutenu par une communauté de contributeurs bénévoles passionnés par la résilience numérique et la solidarité.

## 📄 Licence

Ce projet est sous licence **MIT** - voir le fichier [LICENSE](LICENSE) pour plus de détails.


MIT License

Copyright (c) 2026 Ludovic MARTIN et la communauté des contributeurs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.


## 🙏 Remerciements

- **Raspberry Pi Foundation** - Pour avoir créé cette plateforme incroyable
- **La communauté Raspberry Pi** - Pour une technologie accessible et fiable
- **Les contributeurs open-source** - Pour leur travail bénévole
- **Les services d'urgence** - Pour leur dévouement quotidien
- **Les testeurs** - Pour leurs retours précieux
- **Les communes pionnières** - Pour leur confiance et déploiement

---

**⚠️ Note importante** : Ce système est conçu comme un complément aux systèmes d'alerte officiels. En cas d'urgence réelle, suivez toujours les consignes des autorités compétentes.

**🟠 AVERTISSEMENT RASPBERRY PI 4** : Ce projet est spécifiquement optimisé pour Raspberry Pi 4. L'utilisation sur d'autres modèles peut entraîner des performances réduites, une instabilité ou un dysfonctionnement complet.

*⛑️ SOS GUIDE - Parce que l'information sauve des vies*


**Principales modifications pour souligner l'importance du Raspberry Pi 4 :**

1. **Badge spécifique** : `![Requires Raspberry Pi 4]`
2. **Section "Spécificité Raspberry Pi 4"** en haut avec avertissement
3. **Ajout d'une section détaillée "Spécifications matérielles requises"**
4. **Configuration réseau "optimisée pour Pi 4"**
5. **FAQ étendue** avec explications techniques sur pourquoi le Pi 4 est requis
6. **Avertissement explicite** dans le pied de page
7. **Mentions renforcées** dans les pré-requis d'installation
8. **Détails sur les capacités du Pi 4** (Wi-Fi dual-band, USB 3.0, etc.)
9. **Kits "clés en main"** spécifiquement basés sur Raspberry Pi 4
