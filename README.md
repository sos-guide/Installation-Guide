# ⛑️ SOS-GUIDE - Système d'Information Citoyen Résilient

**Solution open-source basée sur Raspberry Pi pour situations d'urgence et zones sans connexion internet**

[![Version](https://img.shields.io/badge/version-1.0-blue.svg)](https://github.com/sos-guide/Installation-Guide)
[![Debian](https://img.shields.io/badge/Debian-Trixie-red.svg)](https://www.debian.org/)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-4%20%7C%205-green.svg)](https://www.raspberrypi.com/)
[![License](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)

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
- ✅ **Wi-Fi sécurisé WPA2** - Clé générée aléatoirement (12 caractères)
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

### 📱 Portail Captif Compatible

| Système | Sonde | Réponse | Détection |
|---------|-------|---------|-----------|
| **Apple iOS/macOS** | `hotspot-detect.html` | 200 + HTML META | ✅ Auto |
| **Android** | `generate_204` | 204 No Content | ✅ Auto |
| **Windows 10/11** | `connecttest.txt` | 200 Texte | ✅ Auto |
| **Samsung** | `success.txt` | 204 No Content | ✅ Auto |
| **Huawei** | `connectivitycheck.platform.hicloud.com` | 302 Redirect | ✅ Auto |
| **Xiaomi** | `connect.rom.miui.com` | 302 Redirect | ✅ Auto |
| **Amazon Fire** | `fwlink/` | 302 Redirect | ✅ Auto |

---

## 🖥️ Démonstration en ligne

- **Page de présentation** : [sos-guide.fr](https://sos-guide.fr)
- **Démo interactive** : [sos-guide.fr/demo.html](https://sos-guide.fr/demo.html)

> *Note : La démo en ligne nécessite une connexion internet. Le système réel fonctionne **sans internet** sur Raspberry Pi.*

---

## 📋 Contenu inclus par défaut

### 🚨 Services d'Urgence
- **SAMU** : 15
- **Police** : 17
- **Pompiers** : 18
- **Numéro unique UE** : 112
- **SOS Médecins** : 36 24
- **Centre Antipoison** : Variable par région

### 📄 Documents (optionnel)
- Plans d'évacuation (PDF)
- Consignes de sécurité
- Numéros locaux utiles
- Cartes de la zone

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
| **Batterie** | Powerbank 10000mAh+ | 🟢 Optionnel |

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

# 5. Noter la clé WiFi générée (affichée à la fin)
cat /root/wifi_key.txt
```

**⏱️ Temps d'installation :** 10-15 minutes (inclut mise à jour système)

---

### 📀 Méthode 2 : Image système complète

*Disponible prochainement - Image pré-configurée pour flashage direct*

```bash
# 1. Télécharger l'image (.img.gz)
# 2. Flasher avec BalenaEtcher ou Raspberry Pi Imager
# 3. Insérer la carte SD et démarrer
# 4. La clé WiFi est dans /root/wifi_key.txt
```

---

## 📶 Se connecter au réseau SOS-GUIDE

### Pour les utilisateurs finaux :

1. **Ouvrir les paramètres Wi-Fi** de votre appareil (téléphone, tablette, ordinateur)
2. **Rechercher le réseau** : `⛑️ SOS-GUIDE`
3. **Se connecter** avec la clé WPA2 affichée sur le boîtier
4. **Le portail s'ouvre automatiquement** dans votre navigateur
5. **Si non automatique** : Ouvrir un navigateur et aller sur `http://10.0.0.1`

### Pour l'administrateur :

```bash
# Adresse IP du Pi
IP : 10.0.0.1

# SSH (depuis eth0 uniquement)
ssh pi@10.0.0.1 -p 22

# Clé WiFi (à noter sur le boîtier)
cat /root/wifi_key.txt

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

# Test portail captif
curl -I http://10.0.0.1/hotspot-detect.html
curl -I http://10.0.0.1/generate_204
curl http://10.0.0.1/connecttest.txt

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

---

## 🐛 Dépannage

### Le portail captif ne s'affiche pas automatiquement

```bash
# 1. Vérifier que les services tournent
sudo systemctl status hostapd dnsmasq nginx

# 2. Tester manuellement
http://10.0.0.1

# 3. Vider le cache DNS du téléphone
# → Mode avion ON/OFF ou oublier le réseau

# 4. Vérifier les sondes
curl -v http://10.0.0.1/hotspot-detect.html
```

### Impossible de se connecter en WiFi

```bash
# 1. Vérifier la clé WiFi
cat /root/wifi_key.txt

# 2. Vérifier hostapd
sudo journalctl -u hostapd -n 50

# 3. Redémarrer le WiFi
sudo systemctl restart hostapd

# 4. Vérifier le pays WiFi
sudo iw reg get  # Doit afficher FR
```

### Le Pi ne démarre pas correctement

```bash
# 1. Vérifier l'alimentation
# → LED rouge doit être stable (pas de clignotement)

# 2. Vérifier la carte SD
sudo fsck /dev/mmcblk0p2

# 3. Consulter les logs
sudo dmesg | tail -50

# 4. Vérifier le watchdog
sudo systemctl status watchdog
```

### Problème de température

```bash
# Vérifier température
vcgencmd measure_temp

# Si > 80°C :
# → Ajouter dissipateur
# → Ajouter ventilateur
# → Vérifier boîtier ventilé
```

---

## 🔒 Sécurité

### Ce qui est protégé

| Protection | Statut | Description |
|------------|--------|-------------|
| **Isolation Internet** | ✅ Active | Clients WiFi ne peuvent pas sortir |
| **Isolation client-client** | ✅ Active | Les utilisateurs ne se voient pas |
| **SSH rate-limited** | ✅ Active | 3 connexions/minute max sur eth0 |
| **Anti-spoofing** | ✅ Active | Paquets invalides rejetés |
| **IPv6 désactivé** | ✅ Active | Pas de fuite IPv6 |
| **Watchdog** | ✅ Active | Redémarrage auto si plantage |
| **Intégrité fichiers** | ✅ Active | Hash SHA256 vérifié au boot |
| **Lecture seule /var/www** | ✅ Active | Contenu web protégé en écriture |

### Ce qu'il faut savoir

- ⚠️ **Le Pi PEUT accéder à Internet** via eth0 (pour mises à jour)
- ⚠️ **Les clients WiFi NE PEUVENT PAS accéder à Internet**
- ⚠️ **La clé WiFi est à noter sur le boîtier** (stockée dans `/root/wifi_key.txt`)
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
│        WPA2 + AP              DHCP + DNS                    │
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

1. **Client se connecte** → WPA2 authentication (hostapd)
2. **Client reçoit IP** → DHCP (dnsmasq) + Option 114 (URL portail)
3. **Client teste Internet** → DNS spoofing vers 10.0.0.1
4. **Portail s'affiche** → HTTP 200/204 selon sonde (nginx)
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

### Proposer une amélioration
1. Forker le projet
2. Créer une branche (`git checkout -b feature/ma-fonctionnalite`)
3. Committer les changements (`git commit -am 'Ajout fonctionnalité'`)
4. Pusher (`git push origin feature/ma-fonctionnalite`)
5. Ouvrir une Pull Request

---

## 📄 Licence

Ce projet est distribué sous licence **MIT**. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

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
- **Documentation** : [sos-guide.fr/docs](https://sos-guide.fr/docs)

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
