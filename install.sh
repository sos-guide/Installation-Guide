#!/bin/bash
# ==============================================================================
# SOS-GUIDE v1.0 PRODUCTION — Raspberry Pi OS Trixie
# ==============================================================================
# DESCRIPTION: Emergency Offline Survival System
# AUTEUR: Ludovic MARTIN — contact@sos-guide.fr
# ==============================================================================
set -e

# ==============================================================================
# COULEURS POUR LA SORTIE CONSOLE
# ==============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# ==============================================================================
# CONFIGURATION GLOBALE
# ==============================================================================
SSID="⛑️ SOS-GUIDE"
LOCAL_IP="10.0.0.1"
# Auto-détection WiFi
WIFI_IFACE=${WIFI_IFACE:-$(ip -o link show | awk -F': ' '/wl/{print $2; exit}')}
# Auto-détection ETH : en* (Pi5 end0/enp*) ou eth* (Pi4)
ETH_IFACE=${ETH_IFACE:-$(ip -o link show | awk -F': ' '/^[0-9]+: (en|eth)/{print $2; exit}')}
HOSTNAME_SET="sos-guide"

LOC_NAME="Lieu Non Défini"
LOC_ADDRESS="Adresse non renseignée"
LOC_LAT=""
LOC_LON=""
ESTABLISHMENT_TYPE="erp"
LOCAL_CRISIS_NUMBER=""
LOCAL_RISK=""

COPY_CUSTOM_IMAGE=false
CUSTOM_IMAGE_SOURCE="/home/pi/map_location.png"
CUSTOM_IMAGE_DEST="map_location.png"
LEAFLET_DOWNLOADED=false

# ==============================================================================
# EN-TÊTE D'INFORMATION
# ==============================================================================
echo -e "${GREEN}"
echo "========================================================"
echo "   ⛑️  SOS-GUIDE Emergency Offline Survival System"
echo "   Auteur: Ludovic MARTIN — contact@sos-guide.fr"
echo "   Version: 1.1 PRODUCTION"
echo -e "========================================================${NC}"
echo ""

# ==============================================================================
# VÉRIFICATIONS PRÉALABLES
# ==============================================================================
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}❌ ERREUR: Ce script doit être exécuté en root (sudo ./install.sh)${NC}"
    exit 1
fi

if [ -z "${WIFI_IFACE}" ]; then
    echo -e "${RED}❌ ERREUR: Aucune interface WiFi détectée${NC}"
    echo -e "${YELLOW}   Solution: WIFI_IFACE=wlan0 sudo bash install.sh${NC}"
    exit 1
fi

if [ -z "${ETH_IFACE}" ]; then
    echo -e "${YELLOW}⚠️  Interface Ethernet non détectée — fallback eth0${NC}"
    ETH_IFACE="eth0"
fi

if [ ! -d "html" ]; then
    echo -e "${RED}❌ ERREUR: Dossier 'html/' introuvable dans le répertoire courant${NC}"
    echo -e "${YELLOW}   Assurez-vous d'avoir le fichier index.html dans un dossier html/${NC}"
    exit 1
fi

echo -e "${CYAN}📡 Interface WiFi détectée : ${BOLD}${WIFI_IFACE}${NC}"
echo -e "${CYAN}🔌 Interface Ethernet      : ${BOLD}${ETH_IFACE}${NC}"
echo ""

# ==============================================================================
# 1. NETTOYAGE DES SERVICES CONFLICTUELS
# ==============================================================================
echo -e "${BLUE}[1/17] Nettoyage des gestionnaires réseau conflictuels...${NC}"
for svc in bluetooth NetworkManager wpa_supplicant avahi-daemon avahi-daemon.socket ModemManager dhcpcd; do
    systemctl stop "$svc" 2>/dev/null || true
    systemctl disable "$svc" 2>/dev/null || true
    systemctl mask "$svc" 2>/dev/null || true
done
pkill -f wpa_supplicant 2>/dev/null || true
pkill -f NetworkManager 2>/dev/null || true
systemctl disable getty@tty2.service 2>/dev/null || true
systemctl disable getty@tty3.service 2>/dev/null || true
echo 0 > /proc/sys/kernel/sysrq
sleep 2
echo -e "${GREEN}✓ Gestionnaires conflictuels désactivés${NC}"
echo ""

# ==============================================================================
# 2. SYNCHRONISATION NTP
# ==============================================================================
echo -e "${BLUE}[2/17] Synchronisation NTP...${NC}"
cat > /etc/systemd/timesyncd.conf <<EOF
[Time]
NTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org
RootDistanceMaxSec=30
PollIntervalMinSec=32
PollIntervalMaxSec=2048
EOF
systemctl enable systemd-timesyncd
systemctl restart systemd-timesyncd
timedatectl set-ntp true
echo "⏳ Attente synchronisation NTP (max 60s)..."
for i in $(seq 1 12); do
    if timedatectl show --property=NTPSynchronized --value 2>/dev/null | grep -q "yes"; then
        echo -e "${GREEN}✓ Heure synchronisée${NC}"
        break
    fi
    sleep 5
done
echo "📅 Date actuelle : $(date '+%a %d/%m/%Y %H:%M:%S')"
echo ""

# ==============================================================================
# 3. INSTALLATION DES PAQUETS REQUIS
# ==============================================================================
echo -e "${BLUE}[3/17] Installation des paquets...${NC}"
apt update -qq
apt dist-upgrade -y -qq
apt install -y -qq nginx hostapd dnsmasq iptables-persistent netfilter-persistent \
    systemd-resolved watchdog e2fsprogs curl dnsutils openssl
echo -e "${GREEN}✓ Paquets installés${NC}"
echo ""

# ==============================================================================
# 3.1 TÉLÉCHARGEMENT LEAFLET (DNS encore intact — avant reconfiguration réseau)
# ==============================================================================
echo -e "${BLUE}[3.1/17] Téléchargement Leaflet OSM (carte offline)...${NC}"
LEAFLET_VER="1.9.4"
LTMP="/tmp/sos-leaflet-$$"
mkdir -p "${LTMP}"

# 3 CDN en cascade : jsDelivr (le plus fiable) → cdnjs → unpkg
_try_cdn() {
    local BASE="$1"
    local IMG_BASE="$2"
    echo -e "   ${CYAN}Essai : ${BASE}${NC}"
    curl -sf --connect-timeout 10 --max-time 40         -o "${LTMP}/leaflet.min.js"     "${BASE}/leaflet.min.js"          &&     curl -sf --connect-timeout 8  --max-time 20         -o "${LTMP}/leaflet.min.css"    "${BASE}/leaflet.min.css"         &&     curl -sf --connect-timeout 6  --max-time 10         -o "${LTMP}/marker-icon.png"    "${IMG_BASE}/marker-icon.png"     &&     curl -sf --connect-timeout 6  --max-time 10         -o "${LTMP}/marker-icon-2x.png" "${IMG_BASE}/marker-icon-2x.png"  &&     curl -sf --connect-timeout 6  --max-time 10         -o "${LTMP}/marker-shadow.png"  "${IMG_BASE}/marker-shadow.png"
}

CDN_JSDELIVR="https://cdn.jsdelivr.net/npm/leaflet@${LEAFLET_VER}/dist"
CDN_JSDELIVR_IMG="${CDN_JSDELIVR}/images"
CDN_CDNJS="https://cdnjs.cloudflare.com/ajax/libs/leaflet/${LEAFLET_VER}"
CDN_CDNJS_IMG="${CDN_CDNJS}/images"
CDN_UNPKG="https://unpkg.com/leaflet@${LEAFLET_VER}/dist"
CDN_UNPKG_IMG="${CDN_UNPKG}/images"

LEAFLET_DOWNLOADED=false
if _try_cdn "${CDN_JSDELIVR}" "${CDN_JSDELIVR_IMG}"; then
    LEAFLET_DOWNLOADED=true
    echo -e "${GREEN}✓ Leaflet ${LEAFLET_VER} téléchargé (jsDelivr)${NC}"
elif _try_cdn "${CDN_CDNJS}" "${CDN_CDNJS_IMG}"; then
    LEAFLET_DOWNLOADED=true
    echo -e "${GREEN}✓ Leaflet ${LEAFLET_VER} téléchargé (cdnjs)${NC}"
elif _try_cdn "${CDN_UNPKG}" "${CDN_UNPKG_IMG}"; then
    LEAFLET_DOWNLOADED=true
    echo -e "${GREEN}✓ Leaflet ${LEAFLET_VER} téléchargé (unpkg)${NC}"
else
    LEAFLET_DOWNLOADED=false
    echo -e "${YELLOW}⚠️  Tous les CDN inaccessibles. Installer après :${NC}"
    echo -e "   ${CYAN}sudo bash /usr/local/bin/sos-guide-install-leaflet.sh${NC}"
fi
echo ""

# ==============================================================================
# 3.5 CONFIGURATION DU LIEU (INTERACTIF)
# ==============================================================================
echo -e "${BLUE}[3.5/17] Configuration des informations du lieu...${NC}"
echo -e "${YELLOW}ℹ️  Ces informations seront affichées sur le portail captif${NC}"
echo ""
read -p "🏢 Nom du lieu (ex: Mairie de Paris, Gymnase Central) : " LOC_NAME
if [ -z "${LOC_NAME}" ]; then LOC_NAME="Lieu Non Défini"; fi
read -p "📍 Adresse complète : " LOC_ADDRESS
if [ -z "${LOC_ADDRESS}" ]; then LOC_ADDRESS="Adresse non renseignée"; fi
echo -e "${CYAN}   (Optionnel) Pour la carte Leaflet offline, entrez les coordonnées GPS.${NC}"
read -p "🌐 Latitude (ex: 48.8566) : " LOC_LAT
read -p "🌐 Longitude (ex: 2.3522) : " LOC_LON
if [ -n "${LOC_LAT}" ] && [ -n "${LOC_LON}" ]; then
    echo -e "${GREEN}✓ Coordonnées validées${NC}"
else
    echo -e "${YELLOW}⚠️  Coordonnées manquantes — carte désactivée${NC}"
fi

echo ""
echo -e "${BLUE}   Personnalisation des consignes :${NC}"
echo "   1) ecole"
echo "   2) mairie"
echo "   3) erp (établissement recevant du public, par défaut)"
echo "   4) ehpad"
read -p "🏫 Type d'établissement (1-4) : " type_choice
case "$type_choice" in
    1) ESTABLISHMENT_TYPE="ecole" ;;
    2) ESTABLISHMENT_TYPE="mairie" ;;
    3) ESTABLISHMENT_TYPE="erp" ;;
    4) ESTABLISHMENT_TYPE="ehpad" ;;
    *) ESTABLISHMENT_TYPE="erp" ;;
esac
echo -e "${GREEN}✓ Type d'établissement : ${ESTABLISHMENT_TYPE}${NC}"

read -p "📞 Numéro de crise local (ex: 01 23 45 67 89) : " LOCAL_CRISIS_NUMBER
if [ -z "${LOCAL_CRISIS_NUMBER}" ]; then
    LOCAL_CRISIS_NUMBER="non communiqué"
    echo -e "${YELLOW}⚠️  Numéro non renseigné${NC}"
else
    echo -e "${GREEN}✓ Numéro enregistré${NC}"
fi

read -p "⚠️  Risque local spécifique (ex: 'inondation', 'usine chimique') : " LOCAL_RISK
if [ -z "${LOCAL_RISK}" ]; then
    LOCAL_RISK="non spécifié"
    echo -e "${YELLOW}⚠️  Risque non précisé${NC}"
else
    echo -e "${GREEN}✓ Risque enregistré${NC}"
fi
echo ""

# ==============================================================================
# 3.6 COPIE D'IMAGE PERSONNALISÉE (MANUELLE - SANS INTERNET)
# ==============================================================================
echo -e "${BLUE}[3.6/17] Configuration de l'image personnalisée...${NC}"
echo -e "${CYAN}ℹ️  Copie de l'image depuis /home/pi/map_location.png${NC}"
echo ""

if [ -f "${CUSTOM_IMAGE_SOURCE}" ]; then
    echo -e "${GREEN}✓ Image source trouvée : ${CUSTOM_IMAGE_SOURCE}${NC}"
    COPY_CUSTOM_IMAGE=true
else
    echo -e "${YELLOW}⚠️  Image source introuvable : ${CUSTOM_IMAGE_SOURCE}${NC}"
    echo -e "${CYAN}   Vous pourrez la copier plus tard avec :${NC}"
    echo -e "   ${CYAN}sudo bash /usr/local/bin/sos-guide-copy-image.sh /chemin/vers/image.png${NC}"
    COPY_CUSTOM_IMAGE=false
fi
echo ""

# ==============================================================================
# 4. CONFIGURATION DU PAYS WIFI
# ==============================================================================
echo -e "${BLUE}[4/17] Configuration du pays WiFi...${NC}"
rfkill unblock wifi
# Définir le pays via iw (systemd-networkd ne gère pas ça directement)
iw reg set FR 2>/dev/null || true
echo -e "${GREEN}✓ Pays WiFi configuré (FR)${NC}"
echo ""

# ==============================================================================
# 5. SYSTEMD-NETWORKD
# ==============================================================================
echo -e "${BLUE}[5/17] Configuration systemd-networkd...${NC}"
systemctl unmask systemd-networkd 2>/dev/null || true
systemctl enable systemd-networkd

# Fichier réseau ETH — nommé selon l'interface réelle
ETH_NET_FILE="10-${ETH_IFACE}.network"
cat > /etc/systemd/network/${ETH_NET_FILE} <<EOF
[Match]
Name=${ETH_IFACE}
[Network]
DHCP=yes
IPv6AcceptRA=no
IPv6DHCP=no
DNS=1.1.1.1
DNS=8.8.4.4
EOF

cat > /etc/systemd/network/20-wlan-ap.network <<EOF
[Match]
Name=${WIFI_IFACE}
[Network]
Address=${LOCAL_IP}/24
IPv6AcceptRA=no
IPv6LinkLocalAddressGenerationMode=none
IPv6Token=none
IPv6Disable=1
[Link]
WakeOnLan=off
[WLAN]
PowerSave=off
EOF

systemctl daemon-reload
systemctl restart systemd-networkd
echo -e "${GREEN}✓ systemd-networkd configuré${NC}"
echo ""

# ==============================================================================
# 6. SYSTEMD-RESOLVED
# ==============================================================================
echo -e "${BLUE}[6/17] Configuration systemd-resolved...${NC}"
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/dns.conf <<EOF
[Resolve]
DNS=1.1.1.1 8.8.4.4
FallbackDNS=
DNSStubListener=no
DNSOverTLS=no
LLMNR=no
MulticastDNS=no
EOF
systemctl daemon-reload
systemctl restart systemd-resolved
rm -f /etc/resolv.conf
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
echo -e "${GREEN}✓ systemd-resolved configuré (${ETH_IFACE} uniquement)${NC}"
echo ""

# ==============================================================================
# 7. HOSTAPD — RÉSEAU OUVERT (wpa=0)
# ==============================================================================
echo -e "${BLUE}[7/17] Configuration du Point d'Accès WiFi (réseau ouvert)...${NC}"
TS=$(date +%Y%m%d_%H%M%S)
[ -d /etc/hostapd ] && cp -a /etc/hostapd /etc/hostapd.bak.$TS 2>/dev/null || true
mkdir -p /etc/hostapd
cat > /etc/hostapd/hostapd.conf <<EOF
interface=${WIFI_IFACE}
driver=nl80211
ssid=${SSID}
hw_mode=g
channel=11
wmm_enabled=1
beacon_int=100
dtim_period=1
max_num_sta=50
country_code=FR
ap_isolate=1
ieee80211d=1
ieee80211n=1
auth_algs=1
wpa=0
ignore_broadcast_ssid=0
EOF
cat > /etc/default/hostapd <<EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
DAEMON_OPTS=""
EOF
systemctl unmask hostapd 2>/dev/null || true
systemctl enable hostapd
systemctl restart hostapd
sleep 3
echo -e "${GREEN}✓ hostapd configuré (SSID: ${SSID}, réseau ouvert, max: 50 clients)${NC}"
echo ""

# ==============================================================================
# 8. DNSMASQ
# ==============================================================================
echo -e "${BLUE}[8/17] Configuration dnsmasq (Captive Portal)...${NC}"
[ -f /etc/dnsmasq.conf ] && mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak.$TS 2>/dev/null || true
cat > /etc/dnsmasq.conf <<EOF
bind-dynamic
interface=${WIFI_IFACE}
listen-address=${LOCAL_IP}
dhcp-authoritative
dhcp-range=${LOCAL_IP%.*}.100,${LOCAL_IP%.*}.200,1h
dhcp-option=3,${LOCAL_IP}
dhcp-option=6,${LOCAL_IP}
dhcp-option=114,"http://${LOCAL_IP}/"
address=/sos.guide/${LOCAL_IP}
address=/#/${LOCAL_IP}
no-resolv
no-hosts
bogus-priv
domain-needed
cache-size=0
EOF
# NOTE: log-queries est absent = logs désactivés (option binaire, pas de valeur=0)
systemctl enable dnsmasq
systemctl restart dnsmasq
sleep 2
echo -e "${GREEN}✓ dnsmasq configuré (Lease: 1h, logs: désactivés)${NC}"
echo ""

# ==============================================================================
# 9. FIREWALL
# ==============================================================================
echo -e "${BLUE}[9/17] Configuration du firewall (Isolation TOTALE)...${NC}"
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Loopback
iptables -A INPUT -i lo -j ACCEPT
# Scan protection
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
# SSH depuis ETH uniquement — rate limit anti-bruteforce
iptables -A INPUT -i ${ETH_IFACE} -p tcp --dport 22 -m conntrack --ctstate NEW \
    -m limit --limit 3/min --limit-burst 3 -j ACCEPT
# HTTP/HTTPS depuis WiFi — rate limit anti-flood
iptables -A INPUT -i ${WIFI_IFACE} -p tcp --dport 80 \
    -m limit --limit 30/second --limit-burst 200 -j ACCEPT
iptables -A INPUT -i ${WIFI_IFACE} -p tcp --dport 443 \
    -m limit --limit 30/second --limit-burst 200 -j ACCEPT
# Connexions établies (couvre SSH, HTTP, etc.)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# DHCP — port 67 uniquement (le Pi est SERVEUR, pas client)
iptables -A INPUT -i ${WIFI_IFACE} -p udp --dport 67 -j ACCEPT
# DNS depuis WiFi
iptables -A INPUT -i ${WIFI_IFACE} -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i ${WIFI_IFACE} -p tcp --dport 53 -j ACCEPT
# Bloquer tout le reste depuis WiFi
iptables -A INPUT -i ${WIFI_IFACE} -j DROP

# DNAT : HTTP et HTTPS → portail local
iptables -t nat -A PREROUTING -i ${WIFI_IFACE} -p tcp --dport 80 \
    -j DNAT --to-destination ${LOCAL_IP}:80
iptables -t nat -A PREROUTING -i ${WIFI_IFACE} -p tcp --dport 443 \
    -j DNAT --to-destination ${LOCAL_IP}:80

# FORWARD : isolation totale WiFi→Internet
iptables -A FORWARD -i ${WIFI_IFACE} -o ${WIFI_IFACE} -j DROP
iptables -A FORWARD -i ${WIFI_IFACE} -o ${ETH_IFACE} -j DROP
iptables -A FORWARD -i ${WIFI_IFACE} -j DROP

mkdir -p /etc/iptables
netfilter-persistent save

# Vérifications critiques post-application
if ! iptables -C FORWARD -i ${WIFI_IFACE} -o ${ETH_IFACE} -j DROP 2>/dev/null; then
    echo -e "${RED}❌ ERREUR CRITIQUE: Règle d'isolation Internet manquante${NC}"
    exit 1
fi
if ! iptables -C FORWARD -i ${WIFI_IFACE} -j DROP 2>/dev/null; then
    echo -e "${RED}❌ ERREUR CRITIQUE: Filet de sécurité ${WIFI_IFACE} manquant${NC}"
    exit 1
fi
if ! iptables -t nat -C PREROUTING -i ${WIFI_IFACE} -p tcp --dport 80 \
    -j DNAT --to-destination ${LOCAL_IP}:80 2>/dev/null; then
    echo -e "${RED}❌ ERREUR CRITIQUE: Règle NAT port 80 manquante${NC}"
    exit 1
fi
if ! iptables -t nat -C PREROUTING -i ${WIFI_IFACE} -p tcp --dport 443 \
    -j DNAT --to-destination ${LOCAL_IP}:80 2>/dev/null; then
    echo -e "${RED}❌ ERREUR CRITIQUE: Règle NAT port 443 manquante${NC}"
    exit 1
fi

netfilter-persistent save 2>/dev/null || true
echo 1 > /proc/sys/net/ipv4/ip_forward
echo -e "${GREEN}✓ Firewall configuré + Vérifications critiques OK${NC}"
echo -e "${GREEN}✓ Clients WiFi JAMAIS Internet${NC}"
echo ""

# ==============================================================================
# 10. SYSCTL & SYSTÈME DE FICHIERS
# ==============================================================================
echo -e "${BLUE}[10/17] Optimisations système de fichiers...${NC}"
cat > /etc/sysctl.d/60-disable-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.${WIFI_IFACE}.disable_ipv6 = 1
net.ipv6.conf.${ETH_IFACE}.disable_ipv6 = 1
EOF
cat > /etc/sysctl.d/50-anti-spoofing.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.${WIFI_IFACE}.forwarding = 1
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
kernel.sysrq = 0
EOF
sysctl -p /etc/sysctl.d/50-anti-spoofing.conf 2>/dev/null || true
sysctl -p /etc/sysctl.d/60-disable-ipv6.conf 2>/dev/null || true
echo -e "${GREEN}✓ sysctl configuré (IPv6 off, sysrq=0)${NC}"

if ! grep -q "tmpfs /var/log/nginx" /etc/fstab 2>/dev/null; then
    echo "tmpfs /var/log/nginx tmpfs defaults,noatime,nosuid,mode=0755,size=10m 0 0" >> /etc/fstab
    mkdir -p /var/log/nginx
    mount -t tmpfs tmpfs /var/log/nginx 2>/dev/null || true
    echo -e "${GREEN}✓ Logs nginx en tmpfs (RGPD: pas de trace)${NC}"
fi
if ! grep -q "tmpfs /var/log/hostapd" /etc/fstab 2>/dev/null; then
    echo "tmpfs /var/log/hostapd tmpfs defaults,noatime,nosuid,mode=0755,size=5m 0 0" >> /etc/fstab
    mkdir -p /var/log/hostapd
    mount -t tmpfs tmpfs /var/log/hostapd 2>/dev/null || true
    echo -e "${GREEN}✓ Logs hostapd en tmpfs${NC}"
fi
echo ""

# ==============================================================================
# 11. ÉCONOMIE D'ÉNERGIE
# ==============================================================================
echo -e "${BLUE}[11/17] Optimisations économie d'énergie...${NC}"
if command -v tvservice &>/dev/null; then
    tvservice -o 2>/dev/null && echo -e "${GREEN}✓ HDMI désactivé (tvservice)${NC}" || true
elif [ -f /sys/class/drm/card0/enabled ]; then
    echo off > /sys/class/drm/card0/enabled 2>/dev/null || true
    echo -e "${GREEN}✓ HDMI désactivé (sysfs)${NC}"
fi
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
    echo -e "${GREEN}✓ CPU governor → ondemand${NC}"
fi
echo -e "${GREEN}✓ Économie d'énergie configurée${NC}"
echo ""

# ==============================================================================
# 12. SERVEUR WEB NGINX & INJECTION LIEU + COPIE IMAGE
# ==============================================================================
echo -e "${BLUE}[12/17] Configuration du serveur web & Injection des données...${NC}"
mkdir -p /var/www/sos-guide/img /var/www/sos-guide/js /var/www/sos-guide/css \
         /var/www/sos-guide/img/leaflet /data/docs /etc/ssl/private /etc/ssl/certs

# Déverrouillage si réinstallation
if [ -d "/var/www/sos-guide" ]; then
    echo -e "${YELLOW}ℹ️  Réinstallation détectée — déverrouillage...${NC}"
    chattr -R -i /var/www/sos-guide/ 2>/dev/null && \
        echo -e "${GREEN}✓ chattr -i levé${NC}" || \
        echo -e "${YELLOW}⚠️  chattr -i : rien à lever${NC}"
    chmod -R u+w /var/www/sos-guide/ 2>/dev/null || true
fi

# Copie des fichiers HTML
cp -r html/* /var/www/sos-guide/
echo -e "${GREEN}✓ Fichiers HTML copiés depuis ./html/${NC}"

# Copie Leaflet si téléchargé
if [ "${LEAFLET_DOWNLOADED}" = true ]; then
    cp "${LTMP}/leaflet.min.js"     /var/www/sos-guide/js/
    cp "${LTMP}/leaflet.min.css"    /var/www/sos-guide/css/
    cp "${LTMP}/marker-icon.png"    /var/www/sos-guide/img/leaflet/
    cp "${LTMP}/marker-icon-2x.png" /var/www/sos-guide/img/leaflet/
    cp "${LTMP}/marker-shadow.png"  /var/www/sos-guide/img/leaflet/
    echo -e "${GREEN}✓ Leaflet installé dans /var/www/sos-guide/js/ et css/${NC}"
fi
rm -rf "${LTMP}"

# --- INJECTION DES VARIABLES DANS LE HTML ---
echo -e "${CYAN}   Personnalisation de la page d'accueil (Python3 UTF-8)...${NC}"

SOS_LOC_NAME="${LOC_NAME}" \
SOS_LOC_ADDRESS="${LOC_ADDRESS}" \
SOS_LOC_LAT="${LOC_LAT}" \
SOS_LOC_LON="${LOC_LON}" \
SOS_ESTABLISHMENT_TYPE="${ESTABLISHMENT_TYPE}" \
SOS_LOCAL_CRISIS_NUMBER="${LOCAL_CRISIS_NUMBER}" \
SOS_LOCAL_RISK="${LOCAL_RISK}" \
python3 -c "
import os
f = '/var/www/sos-guide/index.html'
m = {
    '{{LOC_NAME}}':            os.environ.get('SOS_LOC_NAME',''),
    '{{LOC_ADDRESS}}':         os.environ.get('SOS_LOC_ADDRESS',''),
    '{{LOC_LAT}}':             os.environ.get('SOS_LOC_LAT',''),
    '{{LOC_LON}}':             os.environ.get('SOS_LOC_LON',''),
    '{{ESTABLISHMENT_TYPE}}':  os.environ.get('SOS_ESTABLISHMENT_TYPE','erp'),
    '{{LOCAL_CRISIS_NUMBER}}': os.environ.get('SOS_LOCAL_CRISIS_NUMBER',''),
    '{{LOCAL_RISK}}':          os.environ.get('SOS_LOCAL_RISK',''),
}
with open(f, 'r', encoding='utf-8') as fh:
    c = fh.read()
for k, v in m.items():
    c = c.replace(k, v)
with open(f, 'w', encoding='utf-8') as fh:
    fh.write(c)
" && echo -e "${GREEN}✓ Variables injectées (UTF-8 safe)${NC}" \
  || { echo -e "${RED}❌ Erreur injection Python3${NC}"; exit 1; }

# --- COPIE IMAGE PERSONNALISÉE ---
if [ "${COPY_CUSTOM_IMAGE}" = true ]; then
    echo -e "${CYAN}   Copie de l'image personnalisée (HORS-LIGNE)...${NC}"
    if cp "${CUSTOM_IMAGE_SOURCE}" "/var/www/sos-guide/img/${CUSTOM_IMAGE_DEST}"; then
        chown www-data:www-data "/var/www/sos-guide/img/${CUSTOM_IMAGE_DEST}"
        chmod 644 "/var/www/sos-guide/img/${CUSTOM_IMAGE_DEST}"
        echo -e "${GREEN}✓ Image copiée : /var/www/sos-guide/img/${CUSTOM_IMAGE_DEST}${NC}"
        echo -e "${CYAN}   URL d'accès : http://${LOCAL_IP}/img/${CUSTOM_IMAGE_DEST}${NC}"
    else
        echo -e "${YELLOW}⚠️  Échec copie de l'image${NC}"
    fi
else
    echo -e "${YELLOW}   Skip copie d'image (fichier source introuvable)${NC}"
fi

chown -R www-data:www-data /var/www/sos-guide
chmod -R 755 /var/www/sos-guide

# Certificat SSL auto-signé
echo "🔐 Génération certificat SSL auto-signé..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/sos-guide.key \
    -out /etc/ssl/certs/sos-guide.crt \
    -subj "/C=FR/ST=Emergency/L=Local/O=SOS-GUIDE/CN=${LOCAL_IP}" 2>/dev/null
chmod 600 /etc/ssl/private/sos-guide.key
echo -e "${GREEN}✓ Certificat SSL généré${NC}"

rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/sos-guide <<'NGINXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root /var/www/sos-guide;
    index index.html;

    # Logs en tmpfs (RGPD) — off par défaut, activer si debug
    access_log off;
    error_log off;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 3;
    types_hash_max_size 2048;

    # ══════════════════════════════════════════════════════════
    # SONDES CAPTIVE PORTAL — toutes en 302 vers le portail
    # LOGIQUE : l'OS attend une réponse SPÉCIFIQUE qui prouve
    # que l'internet fonctionne. Un 302 inattendu = portail détecté
    # ══════════════════════════════════════════════════════════

    # Apple iOS / macOS (attend 200 + "Success" → reçoit 302 → portail)
    location = /hotspot-detect.html {
        return 302 http://10.0.0.1/;
    }
    location = /library/test/success.html {
        return 302 http://10.0.0.1/;
    }

    # Android Google (attend 204 → reçoit 302 → portail)
    location = /generate_204 {
        return 302 http://10.0.0.1/;
    }
    location = /generate_205 {
        return 302 http://10.0.0.1/;
    }
    location = /gen_204 {
        return 302 http://10.0.0.1/;
    }

    # Windows 10/11 (attend 200 + "Microsoft Connect Test" → reçoit 302 → portail)
    location = /connecttest.txt {
        return 302 http://10.0.0.1/;
    }
    location = /ncsi.txt {
        return 302 http://10.0.0.1/;
    }

    # Firefox / Samsung (attend 200 "success" → reçoit 302 → portail)
    location = /success.txt {
        return 302 http://10.0.0.1/;
    }

    # Autres sondes
    location = /canonical.html {
        return 302 http://10.0.0.1/;
    }
    location = /fwlink/ {
        return 302 http://10.0.0.1/;
    }

    # ── Santé interne (Pi → Pi uniquement, pas exposé aux clients WiFi) ──
    location = /health {
        access_log off;
        default_type text/plain;
        add_header Cache-Control "no-store";
        return 200 "OK\n";
    }
    location = /ping {
        access_log off;
        default_type text/plain;
        add_header Cache-Control "no-store";
        return 200 "SOS-GUIDE reachable\n";
    }

    # ── Ressources statiques ──
    location /img/ {
        alias /var/www/sos-guide/img/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    location /js/ {
        alias /var/www/sos-guide/js/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    location /css/ {
        alias /var/www/sos-guide/css/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    location /data/ {
        alias /var/www/sos-guide/data/;
        add_header Cache-Control "no-store";
    }
    location /docs/ {
        alias /data/docs/;
        autoindex off;
        add_header Cache-Control "public, max-age=3600";
        add_header X-Content-Type-Options "nosniff";
    }

    # ── Page principale du portail ──
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        add_header X-Content-Type-Options "nosniff";
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Robots-Tag "noindex, nofollow";
    }

    # ── Sécurité fichiers sensibles ──
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    location ~* \.(env|ini|log|sh|sql|conf|cfg)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}

server {
    listen 443 ssl default_server;
    listen [::]:443 default_server;
    server_name _;

    ssl_certificate /etc/ssl/certs/sos-guide.crt;
    ssl_certificate_key /etc/ssl/private/sos-guide.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5:!3DES;
    ssl_prefer_server_ciphers on;

    access_log off;
    error_log off;
    root /var/www/sos-guide;
    index index.html;

    # Toutes les sondes HTTPS → 302 vers portail HTTP
    # (le navigateur suit la redirection vers http://10.0.0.1/)
    location = /hotspot-detect.html {
        return 302 http://10.0.0.1/;
    }
    location = /library/test/success.html {
        return 302 http://10.0.0.1/;
    }
    location = /generate_204 {
        return 302 http://10.0.0.1/;
    }
    location = /gen_204 {
        return 302 http://10.0.0.1/;
    }
    location / {
        return 302 http://10.0.0.1/;
    }
}

# Vhosts pour domaines de détection Android alternatifs
# (DNS spoofé par dnsmasq → ces domaines arrivent ici)
server {
    listen 80;
    server_name connectivitycheck.gstatic.com connectivitycheck.android.com
                connectivitycheck.hicloud.com connect.rom.miui.com
                wifi.vivo.com.cn www.samsung.com;
    access_log off;
    error_log /dev/null;
    location = /generate_204 { return 302 http://10.0.0.1/; }
    location / { return 302 http://10.0.0.1/; }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/sos-guide /etc/nginx/sites-enabled/
nginx -t
systemctl unmask nginx 2>/dev/null || true
systemctl enable nginx
systemctl restart nginx
echo -e "${GREEN}✓ Serveur web configuré (HTTP + HTTPS + portail captif multi-OS)${NC}"
echo ""

# ==============================================================================
# 13. VERROUILLAGE WEB
# ==============================================================================
echo -e "${BLUE}[13/17] Verrouillage du contenu Web...${NC}"
sed -i '/\/var\/www.*bind/d' /etc/fstab 2>/dev/null || true
chmod -R a-w /var/www/sos-guide/
echo -e "${GREEN}✓ /var/www/sos-guide/ protégé (chmod a-w)${NC}"
if command -v chattr &>/dev/null; then
    chattr -R +i /var/www/sos-guide/ 2>/dev/null && \
        echo -e "${GREEN}✓ /var/www/sos-guide/ verrouillé (chattr +i)${NC}" || \
        echo -e "${YELLOW}⚠️  chattr non supporté sur ce FS${NC}"
else
    echo -e "${YELLOW}⚠️  chattr non disponible — protection chmod uniquement${NC}"
fi
echo ""
echo -e "${YELLOW}   ℹ️  Pour modifier le contenu web :${NC}"
echo -e "   ${CYAN}sudo bash /usr/local/bin/sos-guide-update-content.sh${NC}"
echo ""

# ==============================================================================
# 14. WATCHDOG + INTÉGRITÉ
# ==============================================================================
echo -e "${BLUE}[14/17] Watchdog + Intégrité système...${NC}"
for cfg in /boot/firmware/config.txt /boot/config.txt; do
    [ -f "$cfg" ] || continue
    if grep -q "^dtparam=watchdog" "$cfg"; then
        sed -i 's/^dtparam=watchdog=.*/dtparam=watchdog=on/' "$cfg"
    else
        echo "dtparam=watchdog=on" >> "$cfg"
    fi
    break
done
modprobe bcm2835_wdt 2>/dev/null || true

if [ -e /dev/watchdog ]; then
    cat > /etc/watchdog.conf <<'EOF'
watchdog-device = /dev/watchdog
watchdog-timeout = 14
max-load-1 = 24
max-load-5 = 18
max-load-15 = 12
realtime = yes
priority = 1
EOF
    systemctl unmask watchdog 2>/dev/null || true
    systemctl enable watchdog 2>/dev/null || true
    systemctl start watchdog 2>/dev/null || true
    echo -e "${GREEN}✓ Watchdog hardware configuré${NC}"
else
    echo -e "${YELLOW}⚠️  Watchdog hardware non disponible — fallback logiciel${NC}"
    mkdir -p /etc/systemd/system.conf.d
    cat > /etc/systemd/system.conf.d/watchdog.conf <<EOF
[Manager]
RuntimeWatchdogSec=14s
ShutdownWatchdogSec=10min
EOF
    systemctl daemon-reload
fi

# Hash d'intégrité
find /var/www/sos-guide -type f -exec sha256sum {} \; > /root/integrity.hash
sha256sum /etc/nginx/sites-available/sos-guide >> /root/integrity.hash
echo -e "${GREEN}✓ Hash d'intégrité généré (/root/integrity.hash)${NC}"

# --- SCRIPT DE BOOT-CHECK (interfaces résolues à l'écriture) ---
WFACE="${WIFI_IFACE}"
EFACE="${ETH_IFACE}"

cat > /usr/local/bin/sos-guide-boot-check.sh << BOOTEOF
#!/bin/bash
# Script généré par install.sh — interfaces résolues à l'installation
# WiFi: ${WFACE}  ETH: ${EFACE}

if [ -f /root/integrity.hash ]; then
    if ! sha256sum -c /root/integrity.hash >/dev/null 2>&1; then
        logger "SOS-GUIDE: INTEGRITE COMPROMISE - SHUTDOWN"
        poweroff
    fi
fi

if ! iptables -C FORWARD -i ${WFACE} -o ${EFACE} -j DROP 2>/dev/null; then
    logger "SOS-GUIDE: CRITIQUE - Isolation Internet COMPROMISE"
    iptables -P FORWARD DROP
    iptables -A FORWARD -i ${WFACE} -o ${WFACE} -j DROP
    iptables -A FORWARD -i ${WFACE} -o ${EFACE} -j DROP
    iptables -A FORWARD -i ${WFACE} -j DROP
    logger "SOS-GUIDE: Regles d'isolation RESTAUREES"
fi

if iptables -t nat -L POSTROUTING -n 2>/dev/null | grep -q "MASQUERADE\|SNAT"; then
    logger "SOS-GUIDE: ALERTE - Regle NAT sortante detectee (SUPPRIMEE)"
    iptables -t nat -F POSTROUTING
fi
BOOTEOF
chmod +x /usr/local/bin/sos-guide-boot-check.sh

cat > /etc/systemd/system/sos-guide-boot.service << 'SVC'
[Unit]
Description=SOS-GUIDE Boot Integrity & Firewall Check
After=network.target iptables.service netfilter-persistent.service
Wants=network.target
[Service]
Type=oneshot
ExecStartPre=/bin/sleep 5
ExecStart=/usr/local/bin/sos-guide-boot-check.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
SVC
systemctl daemon-reload
systemctl enable sos-guide-boot.service 2>/dev/null || true
echo -e "${GREEN}✓ Service sos-guide-boot.service activé${NC}"

# --- HEALTH CHECK (interfaces résolues à l'écriture) ---
cat > /usr/local/bin/sos-guide-health.sh << HEALTHEOF
#!/bin/bash
# Script généré par install.sh — interfaces résolues à l'installation
# WiFi: ${WFACE}  ETH: ${EFACE}
ERRORS=0
for svc in hostapd dnsmasq nginx; do
    if ! systemctl is-active --quiet \$svc; then
        logger "SOS-GUIDE: SERVICE \$svc DOWN - redemarrage"
        systemctl restart \$svc 2>/dev/null || true
        ERRORS=\$((ERRORS+1))
    fi
done

if ! iptables -C FORWARD -i ${WFACE} -o ${EFACE} -j DROP 2>/dev/null; then
    logger "SOS-GUIDE: ISOLATION COMPROMISE - restauration firewall"
    iptables -P FORWARD DROP
    iptables -A FORWARD -i ${WFACE} -o ${EFACE} -j DROP
    iptables -A FORWARD -i ${WFACE} -j DROP
    ERRORS=\$((ERRORS+1))
fi

[ \$ERRORS -gt 0 ] && logger "SOS-GUIDE: health-check: \$ERRORS anomalie(s) corrigee(s)"
exit 0
HEALTHEOF
chmod +x /usr/local/bin/sos-guide-health.sh

cat > /etc/systemd/system/sos-guide-health.service << 'SVC'
[Unit]
Description=SOS-GUIDE Health Check
[Service]
Type=oneshot
ExecStart=/usr/local/bin/sos-guide-health.sh
SVC

cat > /etc/systemd/system/sos-guide-health.timer << 'TMR'
[Unit]
Description=SOS-GUIDE Health Check toutes les 5 minutes
[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=sos-guide-health.service
[Install]
WantedBy=timers.target
TMR
systemctl daemon-reload
systemctl enable sos-guide-health.timer
systemctl start sos-guide-health.timer
echo -e "${GREEN}✓ Health check timer activé (5 min)${NC}"

# --- RENOUVELLEMENT CERTIFICAT SSL ---
cat > /usr/local/bin/sos-guide-renew-cert.sh << 'CERTEOF'
#!/bin/bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/sos-guide.key \
    -out /etc/ssl/certs/sos-guide.crt \
    -subj "/C=FR/ST=Emergency/L=Local/O=SOS-GUIDE/CN=10.0.0.1" 2>/dev/null
chmod 600 /etc/ssl/private/sos-guide.key
systemctl reload nginx 2>/dev/null || true
logger "SOS-GUIDE: Certificat SSL renouvelé"
CERTEOF
chmod +x /usr/local/bin/sos-guide-renew-cert.sh

cat > /etc/systemd/system/sos-guide-renew-cert.service << 'SVC'
[Unit]
Description=SOS-GUIDE SSL Certificate Renewal
[Service]
Type=oneshot
ExecStart=/usr/local/bin/sos-guide-renew-cert.sh
SVC

cat > /etc/systemd/system/sos-guide-renew-cert.timer << 'TMR'
[Unit]
Description=Renouvellement certificat SSL SOS-GUIDE (annuel)
[Timer]
OnCalendar=annually
Persistent=true
[Install]
WantedBy=timers.target
TMR
systemctl daemon-reload
systemctl enable sos-guide-renew-cert.timer
echo -e "${GREEN}✓ Renouvellement SSL automatique activé (annuel)${NC}"

# --- SCRIPT MISE À JOUR CONTENU ---
cat > /usr/local/bin/sos-guide-update-content.sh << 'UPDATEEOF'
#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Root requis : sudo bash $0${NC}"
    exit 1
fi
echo -e "${YELLOW}[1/3] Déverrouillage du contenu web...${NC}"
chattr -R -i /var/www/sos-guide/ 2>/dev/null || true
chmod -R u+w /var/www/sos-guide/
echo -e "${GREEN}✓ Contenu déverrouillé${NC}"
echo ""
echo -e "${YELLOW}📝 Modifiez vos fichiers dans /var/www/sos-guide/${NC}"
echo -e "Appuyez sur [Entrée] quand vous avez terminé..."
read -r
echo -e "${YELLOW}[2/3] Reverrouillage...${NC}"
chown -R www-data:www-data /var/www/sos-guide/
chmod -R a-w /var/www/sos-guide/
chattr -R +i /var/www/sos-guide/ 2>/dev/null || true
echo -e "${GREEN}✓ Contenu reverrouillé${NC}"
echo -e "${YELLOW}[3/3] Régénération du hash d'intégrité...${NC}"
find /var/www/sos-guide -type f -exec sha256sum {} \; > /root/integrity.hash
sha256sum /etc/nginx/sites-available/sos-guide >> /root/integrity.hash
echo -e "${GREEN}✓ Hash régénéré${NC}"
echo ""
echo -e "${GREEN}✅ Mise à jour terminée. Testez : curl http://10.0.0.1/${NC}"
UPDATEEOF
chmod +x /usr/local/bin/sos-guide-update-content.sh
echo -e "${GREEN}✓ Script de mise à jour créé${NC}"
echo ""

# ==============================================================================
# 15. TESTS DE VALIDATION
# ==============================================================================
echo -e "${BLUE}[15/17] Lancement des tests de validation...${NC}"
echo ""
TESTS_OK=0
TESTS_TOTAL=6

# Test DNS wildcard (corrigé : cherche l'IP dans la section résolution, pas la ligne Server)
if command -v nslookup &>/dev/null; then
    DNS_RESULT=$(nslookup google.com ${LOCAL_IP} 2>/dev/null \
        | awk '/^Address/ && !/^Address:.*#/{print $2; exit}')
    if [ "${DNS_RESULT}" = "${LOCAL_IP}" ]; then
        echo -e "   ${GREEN}✓${NC} DNS wildcard → ${LOCAL_IP} (spoofing OK)"
        TESTS_OK=$((TESTS_OK+1))
    else
        echo -e "   ${RED}✗${NC} DNS wildcard échoué (résolu: ${DNS_RESULT:-aucun})"
    fi
else
    echo -e "   ${YELLOW}⚠️${NC}  Test DNS ignoré (nslookup absent)"
    TESTS_TOTAL=$((TESTS_TOTAL-1))
fi

# Test Apple iOS (doit répondre 302 pour déclencher la CNA)
CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${LOCAL_IP}/hotspot-detect.html 2>/dev/null)
if [ "${CODE}" = "302" ]; then
    echo -e "   ${GREEN}✓${NC} Probe iOS (hotspot-detect.html) → 302 → portail détecté ✅"
    TESTS_OK=$((TESTS_OK+1))
else
    echo -e "   ${RED}✗${NC} Probe iOS — code inattendu: ${CODE} (attendu: 302)"
fi

# Test Android (doit répondre 302 pour déclencher la notification)
CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${LOCAL_IP}/generate_204 2>/dev/null)
if [ "${CODE}" = "302" ]; then
    echo -e "   ${GREEN}✓${NC} Probe Android (generate_204) → 302 → portail détecté ✅"
    TESTS_OK=$((TESTS_OK+1))
else
    echo -e "   ${RED}✗${NC} Probe Android — code inattendu: ${CODE} (attendu: 302)"
fi

# Test Windows (doit répondre 302)
CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${LOCAL_IP}/connecttest.txt 2>/dev/null)
if [ "${CODE}" = "302" ]; then
    echo -e "   ${GREEN}✓${NC} Probe Windows (connecttest.txt) → 302 → portail détecté ✅"
    TESTS_OK=$((TESTS_OK+1))
else
    echo -e "   ${RED}✗${NC} Probe Windows — code inattendu: ${CODE} (attendu: 302)"
fi

# Test page principale du portail (doit répondre 200 — c'est la destination finale)
CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${LOCAL_IP}/ 2>/dev/null)
if [ "${CODE}" = "200" ]; then
    echo -e "   ${GREEN}✓${NC} Portail principal (/) → 200 OK ✅"
    TESTS_OK=$((TESTS_OK+1))
else
    echo -e "   ${RED}✗${NC} Portail principal — code inattendu: ${CODE} (attendu: 200)"
fi

# Test isolation Internet (wlan0 ne doit PAS pinger 8.8.8.8)
if ! ping -c1 -W1 -I ${WIFI_IFACE} 8.8.8.8 &>/dev/null; then
    echo -e "   ${GREEN}✓${NC} Isolation Internet active (${WIFI_IFACE} → 8.8.8.8 : BLOQUÉ) ✅"
    TESTS_OK=$((TESTS_OK+1))
else
    echo -e "   ${RED}✗${NC} ALERTE CRITIQUE : ${WIFI_IFACE} peut accéder à Internet !"
fi

echo ""
if [ $TESTS_OK -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}🎉 Tous les tests sont au vert (${TESTS_OK}/${TESTS_TOTAL})${NC}"
else
    echo -e "${YELLOW}⚠️  ${TESTS_OK}/${TESTS_TOTAL} tests réussis — vérifiez les erreurs ci-dessus${NC}"
fi

# ==============================================================================
# 16. SCRIPT DE COPIE D'IMAGE
# ==============================================================================
echo -e "${BLUE}[16/17] Création du script de copie d'image...${NC}"
cat > /usr/local/bin/sos-guide-copy-image.sh << 'IMGEOF'
#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
WEB_DIR="/var/www/sos-guide"
IMG_DIR="/var/www/sos-guide/img"
INTEGRITY_HASH="/root/integrity.hash"

echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}   🖼️  SOS-GUIDE — Copie d'Image Personnalisée${NC}"
echo -e "${GREEN}========================================================${NC}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}❌ ERREUR: Ce script doit être exécuté en root${NC}"
    exit 1
fi

IMAGE_SOURCE="$1"
[ -z "${IMAGE_SOURCE}" ] && IMAGE_SOURCE="/home/pi/map_location.png"

if [ ! -f "${IMAGE_SOURCE}" ]; then
    echo -e "${RED}❌ Fichier introuvable : ${IMAGE_SOURCE}${NC}"
    echo -e "${CYAN}   Usage : sudo bash $0 /chemin/vers/image.png${NC}"
    exit 1
fi

echo -e "${BLUE}[1/4] Validation : ${IMAGE_SOURCE}${NC}"
echo -e "${BLUE}[2/4] Déverrouillage...${NC}"
chattr -R -i ${WEB_DIR}/ 2>/dev/null || true
chmod -R u+w ${WEB_DIR}/ 2>/dev/null

echo -e "${BLUE}[3/4] Copie...${NC}"
mkdir -p ${IMG_DIR}
cp "${IMAGE_SOURCE}" "${IMG_DIR}/map_location.png"
chown www-data:www-data "${IMG_DIR}/map_location.png"
chmod 644 "${IMG_DIR}/map_location.png"

echo -e "${BLUE}[4/4] Verrouillage + Hash...${NC}"
chmod -R a-w ${WEB_DIR}/ 2>/dev/null
chattr -R +i ${WEB_DIR}/ 2>/dev/null || true
# IMPORTANT: régénère le hash COMPLET (web + nginx config)
find ${WEB_DIR} -type f -exec sha256sum {} \; > ${INTEGRITY_HASH} 2>/dev/null
sha256sum /etc/nginx/sites-available/sos-guide >> ${INTEGRITY_HASH} 2>/dev/null

echo -e "${GREEN}✅ COPIE TERMINÉE${NC}"
echo -e "${CYAN}   URL : http://10.0.0.1/img/map_location.png${NC}"
IMGEOF
chmod +x /usr/local/bin/sos-guide-copy-image.sh
echo -e "${GREEN}✓ Script sos-guide-copy-image.sh créé${NC}"
echo ""

# ==============================================================================
# 16.5 SCRIPT INSTALLATION LEAFLET
# ==============================================================================
cat > /usr/local/bin/sos-guide-install-leaflet.sh << 'LFEOF'
#!/bin/bash
set -e
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
WEB_DIR="/var/www/sos-guide"
JS_DIR="${WEB_DIR}/js"
CSS_DIR="${WEB_DIR}/css"
IMG_DIR="${WEB_DIR}/img/leaflet"
INTEGRITY_HASH="/root/integrity.hash"
VER="1.9.4"

echo -e "${GREEN}=== SOS-GUIDE : Installation Leaflet OSM ===${NC}"
if [ "$(id -u)" -ne 0 ]; then echo -e "${RED}Root requis${NC}"; exit 1; fi

# Test DNS basique avant de commencer
if ! curl -sf --connect-timeout 5 --max-time 8 -o /dev/null https://cdn.jsdelivr.net/ 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Test connectivité : vérifiez que eth0 a accès à Internet${NC}"
    echo -e "   ip addr show eth0"
    echo -e "   ping -c3 1.1.1.1"
    echo -e "   curl -v https://cdn.jsdelivr.net/"
fi

echo -e "${CYAN}[1/4] Déverrouillage...${NC}"
chattr -R -i "${WEB_DIR}/" 2>/dev/null || true
chmod -R u+w "${WEB_DIR}/"

echo -e "${CYAN}[2/4] Téléchargement Leaflet ${VER} (3 CDN en cascade)...${NC}"
mkdir -p "${JS_DIR}" "${CSS_DIR}" "${IMG_DIR}"

# Fonction multi-CDN : essaie jsDelivr → cdnjs → unpkg
_dl_multi() {
    local DEST="$1" FILE="$2"
    local URLS=(
        "https://cdn.jsdelivr.net/npm/leaflet@${VER}/dist/${FILE}"
        "https://cdnjs.cloudflare.com/ajax/libs/leaflet/${VER}/${FILE}"
        "https://unpkg.com/leaflet@${VER}/dist/${FILE}"
    )
    for URL in "${URLS[@]}"; do
        if curl -sf --connect-timeout 10 --max-time 40 -o "${DEST}" "${URL}"; then
            echo -e "  ${GREEN}✓${NC} $(basename ${DEST})  ← $(echo ${URL} | cut -d/ -f3)"
            return 0
        fi
    done
    echo -e "  ${RED}✗${NC} $(basename ${DEST}) — tous les CDN ont échoué"
    return 1
}

_dl_img() {
    local DEST="$1" FILE="$2"
    local URLS=(
        "https://cdn.jsdelivr.net/npm/leaflet@${VER}/dist/images/${FILE}"
        "https://cdnjs.cloudflare.com/ajax/libs/leaflet/${VER}/images/${FILE}"
        "https://unpkg.com/leaflet@${VER}/dist/images/${FILE}"
    )
    for URL in "${URLS[@]}"; do
        if curl -sf --connect-timeout 8 --max-time 15 -o "${DEST}" "${URL}"; then
            echo -e "  ${GREEN}✓${NC} $(basename ${DEST})"
            return 0
        fi
    done
    echo -e "  ${YELLOW}⚠${NC} $(basename ${DEST}) — image non critique, continuons"
    return 0
}

_dl_multi "${JS_DIR}/leaflet.min.js"      "leaflet.min.js"       || { echo -e "${RED}❌ Impossible de télécharger Leaflet JS. Vérifiez la connexion.${NC}"; exit 1; }
_dl_multi "${CSS_DIR}/leaflet.min.css"    "leaflet.min.css"      || { echo -e "${RED}❌ Impossible de télécharger Leaflet CSS.${NC}"; exit 1; }
_dl_img   "${IMG_DIR}/marker-icon.png"    "marker-icon.png"
_dl_img   "${IMG_DIR}/marker-icon-2x.png" "marker-icon-2x.png"
_dl_img   "${IMG_DIR}/marker-shadow.png"  "marker-shadow.png"

chown -R www-data:www-data "${JS_DIR}" "${CSS_DIR}" "${IMG_DIR}"

echo -e "${CYAN}[3/4] Reverrouillage...${NC}"
chmod -R a-w "${WEB_DIR}/"
chattr -R +i "${WEB_DIR}/" 2>/dev/null || true

echo -e "${CYAN}[4/4] Régénération du hash d'intégrité...${NC}"
find "${WEB_DIR}" -type f -exec sha256sum {} \; > "${INTEGRITY_HASH}" 2>/dev/null
sha256sum /etc/nginx/sites-available/sos-guide >> "${INTEGRITY_HASH}" 2>/dev/null

echo ""
echo -e "${GREEN}✅ Leaflet installé ! La carte interactive est maintenant disponible.${NC}"
echo -e "${CYAN}   Rechargez le portail sur votre smartphone pour voir la carte.${NC}"
echo -e "   Vérifier : ls -la /var/www/sos-guide/js/leaflet.min.js"

LFEOF
chmod +x /usr/local/bin/sos-guide-install-leaflet.sh
echo -e "${GREEN}✓ Script sos-guide-install-leaflet.sh créé${NC}"
echo ""

# ==============================================================================
# 17. RÉSUMÉ FINAL
# ==============================================================================
ETH_IP=$(ip -4 addr show "${ETH_IFACE}" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1 || echo "?")
echo ""
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}   ✅ SOS-GUIDE v1.0 PRODUCTION — CONFIGURATION TERMINÉE${NC}"
echo -e "${GREEN}========================================================${NC}"
echo ""
echo -e "${BLUE}📡 CONFIGURATION RÉSEAU:${NC}"
echo -e "   ${GREEN}✓${NC} Interface WiFi : ${WIFI_IFACE}"
echo -e "   ${GREEN}✓${NC} Interface ETH  : ${ETH_IFACE}"
echo -e "   ${GREEN}✓${NC} IP wlan        : ${LOCAL_IP}"
echo -e "   ${GREEN}✓${NC} IP eth         : ${ETH_IP}"
echo -e "   ${GREEN}✓${NC} SSID           : ${SSID}"
echo -e "   ${GREEN}✓${NC} Sécurité WiFi  : RÉSEAU OUVERT (ap_isolate=1 actif)"
echo -e "   ${GREEN}✓${NC} Max clients    : 50"
echo ""
echo -e "${BLUE}📍 LOCALISATION CONFIGURÉE:${NC}"
echo -e "   ${GREEN}✓${NC} Nom : ${LOC_NAME}"
echo -e "   ${GREEN}✓${NC} Adresse : ${LOC_ADDRESS}"
if [ -n "${LOC_LAT}" ] && [ -n "${LOC_LON}" ]; then
    echo -e "   ${GREEN}✓${NC} GPS : ${LOC_LAT}, ${LOC_LON}"
fi
echo -e "   ${GREEN}✓${NC} Type : ${ESTABLISHMENT_TYPE}"
echo -e "   ${GREEN}✓${NC} Numéro crise : ${LOCAL_CRISIS_NUMBER}"
echo -e "   ${GREEN}✓${NC} Risque local : ${LOCAL_RISK}"
if [ "${LEAFLET_DOWNLOADED}" = true ]; then
    echo -e "   ${GREEN}✓${NC} Carte Leaflet OSM : installée"
else
    echo -e "   ${YELLOW}⚠️${NC} Carte Leaflet OSM : non installée (pas de connexion lors de l'install)"
fi
echo ""
echo -e "${BLUE}📱 CAPTIVE PORTAL (302 → détection portail sur tous les OS):${NC}"
echo -e "   ${GREEN}✓${NC} iOS/macOS    → /hotspot-detect.html → 302 → popup CNA"
echo -e "   ${GREEN}✓${NC} Android      → /generate_204        → 302 → notification"
echo -e "   ${GREEN}✓${NC} Windows      → /connecttest.txt     → 302 → popup"
echo -e "   ${GREEN}✓${NC} Samsung/FF   → /success.txt         → 302 → portail"
echo -e "   ${GREEN}✓${NC} Huawei/Xiaomi → domaines DNS spoofés → 302 → portail"
echo -e "   ${CYAN}ℹ️${NC}  Portail principal → http://10.0.0.1/ → 200 OK (destination finale)"
echo ""
echo -e "${BLUE}🔒 SÉCURITÉ:${NC}"
echo -e "   ${GREEN}✓${NC} Pi accède Internet via ${ETH_IFACE}"
echo -e "   ${GREEN}✓${NC} Clients WiFi ISOLÉS d'Internet"
echo -e "   ${GREEN}✓${NC} Isolation client-client (ap_isolate=1)"
echo -e "   ${GREEN}✓${NC} HTTP + HTTPS redirigés (80 + 443→80)"
echo -e "   ${GREEN}✓${NC} sysrq désactivé (kernel.sysrq=0)"
echo -e "   ${GREEN}✓${NC} IPv6 désactivé"
echo -e "   ${GREEN}✓${NC} /var/www/sos-guide/ verrouillé (chattr +i)"
echo -e "   ${GREEN}✓${NC} Watchdog auto-reboot actif"
echo -e "   ${GREEN}✓${NC} Intégrité SHA256 vérifiée au boot"
echo -e "   ${GREEN}✓${NC} Health check toutes les 5 min"
echo ""
echo -e "${BLUE}🔧 COMMANDES UTILES:${NC}"
echo -e "   ${CYAN}ip addr show ${WIFI_IFACE}${NC}              # IP wlan"
echo -e "   ${CYAN}journalctl -u hostapd -f${NC}               # Logs WiFi"
echo -e "   ${CYAN}iptables -L -n -v${NC}                      # Règles FW"
echo -e "   ${CYAN}ping -I ${WIFI_IFACE} 8.8.8.8${NC}          # Test isolation"
echo -e "   ${CYAN}sha256sum -c /root/integrity.hash${NC}      # Intégrité"
echo -e "   ${CYAN}sudo bash /usr/local/bin/sos-guide-update-content.sh${NC}  # Màj contenu"
echo -e "   ${CYAN}sudo bash /usr/local/bin/sos-guide-copy-image.sh${NC}      # Copier image"
echo -e "   ${CYAN}sudo bash /usr/local/bin/sos-guide-install-leaflet.sh${NC} # Carte Leaflet"
echo ""
echo -e "${BLUE}📊 ÉTAT DES SERVICES:${NC}"
for service in hostapd dnsmasq nginx systemd-networkd systemd-resolved watchdog; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo -e "   ${GREEN}✓${NC} $service: actif"
    else
        echo -e "   ${RED}✗${NC} $service: inactif"
    fi
done
for service in sos-guide-boot sos-guide-health.timer sos-guide-renew-cert.timer; do
    if systemctl is-enabled --quiet $service 2>/dev/null; then
        echo -e "   ${GREEN}✓${NC} $service: activé"
    else
        echo -e "   ${RED}✗${NC} $service: non activé"
    fi
done
echo ""
echo -e "${MAGENTA}🚀 SOS-GUIDE v1.0 EST PRÊT POUR LA PRODUCTION !${NC}"
echo -e "${YELLOW}⚠️  PREMIER TEST : Connectez un smartphone au WiFi '${SSID}'${NC}"
echo -e "${YELLOW}⚠️  Le portail doit s'ouvrir automatiquement${NC}"
echo ""
echo -e "${GREEN}========================================================"
echo -e "   Développé par Ludovic MARTIN - contact@sos-guide.fr"
echo -e "========================================================${NC}"
echo ""

exit 0
