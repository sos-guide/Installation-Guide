# ⛑️ SOS-GUIDE - Système d'Information Citoyen Résilient

**Solution basée sur Raspberry Pi pour situations d'urgence et zones sans connexion internet**

[![Version](https://img.shields.io/badge/version-1.0-blue.svg)](https://github.com/sos-guide/Installation-Guide)
[![Debian](https://img.shields.io/badge/Debian-Trixie-red.svg)](https://www.debian.org/)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-4%20%7C%205-green.svg)](https://www.raspberrypi.com/)

---

## 🎯 Présentation

**SOS-GUIDE** est une solution innovante permettant de diffuser des informations essentielles aux citoyens en situation de crise, coupure réseau, ou dans des zones sans accès internet. Le système crée son propre réseau Wi-Fi local sécurisé diffusant une page web contenant tous les services d'urgence et informations vitales.

### 🔧 Compatibilité Matérielle

| Modèle | Support | Notes |
|--------|---------|-------|
| **Raspberry Pi 5** | ✅ **Recommandé** | Meilleures performances, plus de RAM |
| **Raspberry Pi 4** | ✅ **Supporté** | 2GB, 4GB ou 8GB |
| **Raspberry Pi 3B+** | ⚠️ **Limité** | Fonctionne mais performances réduites |
| **Raspberry Pi 3A/B** | ⚠️ **Limité** | Nécessite alimentation stable |
| **Pi Zero/2W** | ❌ **Non supporté** | Puissance insuffisante |

> **💡 RECOMMANDATION :** Utilisez un **Raspberry Pi 4 (4GB)** ou **Pi 5** pour une expérience optimale en production.

---

## ✨ Fonctionnalités principales

### 🌐 Réseau & Connectivité
- ✅ **Fonctionne 100% hors-ligne** - Aucune connexion internet nécessaire pour les clients
- ✅ **SSID personnalisé** : `⛑️ SOS-GUIDE`
- ✅ **Interface web moderne et responsive** - Compatible mobile/tablete/ordinateur
- ✅ **Multi-utilisateurs** - Jusqu'à 50 connexions simultanées
- ✅ **Captive Portal auto-détecté** - iOS, Android, Windows, Samsung

### 🔒 Sécurité Renforcée
- ✅ **Isolation totale Internet** - Les clients WiFi ne peuvent PAS accéder à Internet
- ✅ **Isolation client-client** - Les utilisateurs ne se voient pas entre eux
- ✅ **Firewall configuré** - Rate-limiting SSH, anti-spoofing, DROP par défaut
- ✅ **IPv6 désactivé** - Évite les fuites et problèmes de détection
- ✅ **Watchdog matériel** - Auto-redémarrage en cas de plantage
- ✅ **Intégrité fichiers** - Hash SHA256 vérifié au démarrage

### ⚡ Performance & Fiabilité
- ✅ **Faible consommation** - 3-5 watts (fonctionne sur batterie externe)
- ✅ **Nginx optimisé** - Réponse ultra-rapide, ~5MB RAM
- ✅ **Lecture seule** - `/var/www` monté en read-only après installation
- ✅ **Aucun log** - RGPD compliant, pas de traces utilisateurs
- ✅ **Installation rapide** - Moins de 15 minutes

---

## 🛠️ Installation sur Raspberry Pi

### 🟠 **PRÉ-REQUIS OBLIGATOIRES**

| Élément | Spécification | Importance |
|---------|--------------|------------|
| **Raspberry Pi** | Pi 4 (2GB+) ou Pi 5 | 🔴 Critique |
| **Carte microSD** | 16GB+ (classe 10) | 🔴 Critique |
| **Alimentation** | Officielle 5V/3A (Pi 4) ou 5V/5A (Pi 5) | 🔴 Critique |
| **OS** | Debian Trixie (Bookworm) | 🔴 Critique |
| **Boîtier** | Avec ventilation | 🟡 Recommandé |
| **Dissipateur** | Heat sinks ou ventilateur | 🟡 Recommandé |
| **Batterie** | Powerbank/EcoFlow | 🟢 Optionnel |

---

### 📦 Méthode 1 : Script d'installation (Recommandé)

```bash
# 1. Télécharger le script
git clone https://github.com/sos-guide/Installation-Guide.git

# 2. Entrer dans le dossier
cd Installation-Guide

# 3. Rendre exécutable
chmod +x install.sh

# 4. Exécuter en root
sudo ./install.sh
```

**⏱️ Temps d'installation :** 10-15 minutes (inclut mise à jour système)

---

## 📶 Se connecter au réseau SOS-GUIDE

### Pour les utilisateurs finaux :

1. **Ouvrir les paramètres Wi-Fi** de votre appareil (téléphone, tablette, ordinateur)
2. **Rechercher le réseau** : `⛑️ SOS-GUIDE`
3. **Se connecter**
4. **Le portail s'ouvre automatiquement** dans votre navigateur
5. **Si non automatique** : Ouvrir un navigateur et aller sur `http://10.0.0.1` ou `http://sos.guide`

### Pour l'administrateur :

```bash
# Logs en temps réel
sudo journalctl -u hostapd -f
sudo journalctl -u dnsmasq -f
sudo journalctl -u nginx -f
```

---

## 🔧 Commandes utiles

### Vérification du système

```bash
# État des services
sudo systemctl status hostapd dnsmasq nginx

# Adresses IP
ip addr show wlan0
ip addr show eth0

# Règles firewall
sudo iptables -L -n -v

# Ports ouverts
sudo ss -tulpn

# Test isolation Internet (doit échouer)
ping -I wlan0 8.8.8.8

# Test DNS spoofing
nslookup google.com 10.0.0.1

# Vérification intégrité
sha256sum -c /root/integrity.hash

# Température CPU
vcgencmd measure_temp
```

### Redémarrage et maintenance

```bash
# Redémarrer un service
sudo systemctl restart nginx
sudo systemctl restart hostapd
sudo systemctl restart dnsmasq

# Redémarrer le Pi
sudo reboot

# Arrêter le Pi
sudo shutdown now

# Mettre à jour le système
sudo apt update && sudo apt upgrade -y
```

### Le Pi ne démarre pas correctement

```bash
# 1. Vérifier l'alimentation
# → LED rouge doit être stable (pas de clignotement)

# 2. Vérifier la carte SD
sudo fsck /dev/mmcblk0p2

# 3. Consulter les logs
sudo dmesg | tail -50
```

---

## 🔒 Sécurité

### Ce qui est protégé

| Protection | Statut | Description |
|------------|--------|-------------|
| **Isolation Internet** | ✅ Active | Clients WiFi ne peuvent pas sortir |
| **Isolation client-client** | ✅ Active | Les utilisateurs ne se voient pas |

### Ce qu'il faut savoir

- ⚠️ **Le Pi PEUT accéder à Internet** via eth0 (pour mises à jour)
- ⚠️ **Les clients WiFi NE PEUVENT PAS accéder à Internet**
- ⚠️ **SSH n'est accessible QUE depuis eth0** (pas depuis wlan0)

---

## 📊 Architecture technique

```
┌─────────────────────────────────────────────────────────────┐
│                    INTERNET (eth0)                          │
│                         ↓                                   │
│                    ┌─────────┐                              │
│                    │   Pi 4  │                              │
│                    │  ou Pi 5│                              │
│                    └────┬────┘                              │
│                         │                                   │
│              ┌──────────┴──────────┐                        │
│              │                     │                        │
│         [hostapd]            [dnsmasq]                      │
│        Open + AP              DHCP + DNS                    │
│              │                     │                        │
│              └──────────┬──────────┘                        │
│                         │                                   │
│                    [nginx:80]                               │
│                   Portail Captif                            │
│                         │                                   │
│              ┌──────────┴──────────┐                        │
│              ↓                     ↓                        │
│         📱 iPhone            📱 Android                     │
│         💻 Windows           📱 Samsung                     │
│         (Jusqu'à 50 clients simultanés)                     │
└─────────────────────────────────────────────────────────────┘
```

### Flux réseau

1. **Client se connecte** → Open (hostapd)
2. **Client reçoit IP** → DHCP (dnsmasq) + Option 114 (URL portail)
3. **Client teste Internet** → DNS spoofing vers 10.0.0.1
4. **Portail s'affiche** → HTTP 304 selon sonde (nginx)
5. **Client navigue** → Contenu local uniquement ( FORWARD DROP)

---

## 📈 Performances

| Métrique | Valeur | Notes |
|----------|--------|-------|
| **Consommation** | 3-5W | Pi 4 idle, sans périphériques |
| **RAM utilisée** | ~200MB | Système + services |
| **Clients max** | 50 | Limité par configuration |
| **Température** | 40-60°C | Avec dissipateur |
| **Boot time** | 30-45s | Debian Trixie |
| **Portail load** | <100ms | Nginx optimisé |

---

## 🤝 Contribuer

### Signaler un bug
Ouvrez une issue sur GitHub avec :
- Modèle de Raspberry Pi
- Version de l'OS
- Logs d'erreur (`journalctl -u hostapd -n 100`)
- Étapes pour reproduire

---

## 🙏 Remerciements

- **Communauté Raspberry Pi** pour le matériel et le support
- **Debian** pour l'OS stable et sécurisé
- **Contributeurs open-source** pour les outils utilisés (nginx, dnsmasq, hostapd)
- **Utilisateurs et testeurs** pour les retours et améliorations

---

## 📞 Contact & Support

- **Site web** : [sos-guide.fr](https://sos-guide.fr)
- **GitHub** : [github.com/sos-guide](https://github.com/sos-guide)
- **Email** : contact@sos-guide.fr

---

## ⚠️ Avertissements légaux

1. **Usage responsable** : Ce système est conçu pour des situations d'urgence et un usage légitime
2. **Respect de la vie privée** : Aucun log n'est conservé (RGPD compliant)
3. **Fréquences WiFi** : Respectez la réglementation locale (canal 11, puissance max 100mW en France)
4. **Ne pas utiliser** pour intercepter ou modifier du trafic sans consentement

---

<div align="center">

**⛑️ SOS-GUIDE - Information résiliente, partout, tout le temps.**

[![Raspberry Pi](https://www.raspberrypi.org/app/uploads/2020/11/branding-guidelines-desktop-1.png)](https://www.raspberrypi.com/)

</div>
