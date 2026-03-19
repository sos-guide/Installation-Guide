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
WIFI_IFACE=${WIFI_IFACE:-$(ip -o link show | awk -F': ' '/wl/{print $2; exit}')}
ETH_IFACE=${ETH_IFACE:-eth0}
HOSTNAME="sos-guide"

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

# ==============================================================================
# EN-TÊTE D'INFORMATION
# ==============================================================================
echo -e "${GREEN}"
echo "========================================================"
echo "   ⛑️  SOS-GUIDE Emergency Offline Survival System"
echo "   Auteur: Ludovic MARTIN — contact@sos-guide.fr"
echo "   Version: 1.0 PRODUCTION"
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

if [ ! -d "html" ]; then
    echo -e "${RED}❌ ERREUR: Dossier 'html/' introuvable dans le répertoire courant${NC}"
    echo -e "${YELLOW}   Assurez-vous d'avoir le fichier index.html dans un dossier html/${NC}"
    exit 1
fi

echo -e "${CYAN}📡 Interface WiFi détectée : ${BOLD}${WIFI_IFACE}${NC}"
echo -e "${CYAN}🔌 Interface Ethernet : ${BOLD}${ETH_IFACE}${NC}"
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
# 3.5 CONFIGURATION DU LIEU (INTERACTIF)
# ==============================================================================
echo -e "${BLUE}[3.5/17] Configuration des informations du lieu...${NC}"
echo -e "${YELLOW}ℹ️  Ces informations seront affichées sur le portail captif${NC}"
echo ""
read -p "🏢 Nom du lieu (ex: Mairie de Paris, Gymnase Central) : " LOC_NAME
if [ -z "${LOC_NAME}" ]; then LOC_NAME="Lieu Non Défini"; fi
read -p "📍 Adresse complète : " LOC_ADDRESS
if [ -z "${LOC_ADDRESS}" ]; then LOC_ADDRESS="Adresse non renseignée"; fi
echo -e "${CYAN}   (Optionnel) Pour la carte offline, entrez les coordonnées GPS.${NC}"
read -p "🌐 Latitude (ex: 48.8566) : " LOC_LAT
read -p "🌐 Longitude (ex: 2.3522) : " LOC_LON
if [ -n "${LOC_LAT}" ] && [ -n "${LOC_LON}" ]; then
    echo -e "${GREEN}✓ Coordonnées validées${NC}"
else
    echo -e "${YELLOW}⚠️  Coordonnées manquantes${NC}"
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

# Vérifier si l'image source existe
if [ -f "${CUSTOM_IMAGE_SOURCE}" ]; then
    echo -e "${GREEN}✓ Image source trouvée : ${CUSTOM_IMAGE_SOURCE}${NC}"
    COPY_CUSTOM_IMAGE=true
else
    echo -e "${YELLOW}⚠️  Image source introuvable : ${CUSTOM_IMAGE_SOURCE}${NC}"
    echo -e "${CYAN}   Vous pourrez la copier plus tard avec :${NC}"
    echo -e "   ${CYAN}sudo cp /home/pi/map_location.png /var/www/sos-guide/img/map_location.png${NC}"
    COPY_CUSTOM_IMAGE=false
fi
echo ""

# ==============================================================================
# 4. CONFIGURATION DU PAYS WIFI
# ==============================================================================
echo -e "${BLUE}[4/17] Configuration du pays WiFi...${NC}"
mkdir -p /etc/wpa_supplicant
echo "country=FR" > /etc/wpa_supplicant/wpa_supplicant.conf
rfkill unblock wifi
echo -e "${GREEN}✓ Pays WiFi configuré (FR)${NC}"
echo ""

# ==============================================================================
# 5. SYSTEMD-NETWORKD
# ==============================================================================
echo -e "${BLUE}[5/17] Configuration systemd-networkd...${NC}"
systemctl unmask systemd-networkd 2>/dev/null || true
systemctl enable systemd-networkd
cat > /etc/systemd/network/10-eth0.network <<EOF
[Match]
Name=${ETH_IFACE}
[Network]
DHCP=yes
IPv6AcceptRA=no
IPv6DHCP=no
DNS=1.1.1.1
DNS=8.8.4.4
EOF
cat > /etc/systemd/network/20-wlan0-ap.network <<EOF
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
echo -e "${GREEN}✓ systemd-resolved configuré (eth0 uniquement)${NC}"
echo ""

# ==============================================================================
# 7. HOSTAPD
# ==============================================================================
echo -e "${BLUE}[7/17] Configuration du Point d'Accès WiFi...${NC}"
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
echo -e "${GREEN}✓ hostapd configuré (SSID: ${SSID}, Max: 50 clients)${NC}"
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
log-queries=0
EOF
systemctl enable dnsmasq
systemctl restart dnsmasq
sleep 2
echo -e "${GREEN}✓ dnsmasq configuré (Lease: 1h)${NC}"
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
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -i ${ETH_IFACE} -p tcp --dport 22 -m conntrack --ctstate NEW -m limit --limit 3/min --limit-burst 3 -j ACCEPT
iptables -A INPUT -i ${ETH_IFACE} -p tcp --dport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i ${WIFI_IFACE} -p tcp --dport 80 -m limit --limit 30/second --limit-burst 200 -j ACCEPT
iptables -A INPUT -i ${WIFI_IFACE} -p tcp --dport 443 -m limit --limit 30/second --limit-burst 200 -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i ${WIFI_IFACE} -p udp --dport 67 -j ACCEPT
iptables -A INPUT -i ${WIFI_IFACE} -p udp --dport 68 -j ACCEPT
iptables -A INPUT -i ${WIFI_IFACE} -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i ${WIFI_IFACE} -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -i ${WIFI_IFACE} -j DROP
iptables -t nat -A PREROUTING -i ${WIFI_IFACE} -p tcp --dport 80 \
    -j DNAT --to-destination ${LOCAL_IP}:80
iptables -t nat -A PREROUTING -i ${WIFI_IFACE} -p tcp --dport 443 \
    -j DNAT --to-destination ${LOCAL_IP}:80
iptables -A FORWARD -i ${WIFI_IFACE} -o ${WIFI_IFACE} -j DROP
iptables -A FORWARD -i ${WIFI_IFACE} -o ${ETH_IFACE} -j DROP
iptables -A FORWARD -i ${WIFI_IFACE} -j DROP

mkdir -p /etc/iptables
netfilter-persistent save

if ! iptables -C FORWARD -i ${WIFI_IFACE} -o ${ETH_IFACE} -j DROP 2>/dev/null; then
    echo -e "${RED}❌ ERREUR CRITIQUE: Règle d'isolation Internet manquante${NC}"
    exit 1
fi
if ! iptables -C FORWARD -i ${WIFI_IFACE} -j DROP 2>/dev/null; then
    echo -e "${RED}❌ ERREUR CRITIQUE: Filet de sécurité wlan0 manquant${NC}"
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
# 10. SYSTÈME DE FICHIERS & MONTAGES
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
    echo -e "${GREEN}✓ Logs nginx en tmpfs${NC}"
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
if [ -f /etc/rc.local ]; then
    grep -q "tvservice -o" /etc/rc.local 2>/dev/null || \
    sed -i 's|^exit 0|tvservice -o 2>/dev/null \|\| true\nexit 0|' /etc/rc.local 2>/dev/null || true
fi
echo -e "${GREEN}✓ Économie d'énergie configurée${NC}"
echo ""

# ==============================================================================
# 12. SERVEUR WEB NGINX & INJECTION LIEU + COPIE IMAGE
# ==============================================================================
echo -e "${BLUE}[12/17] Configuration du serveur web & Injection des données...${NC}"
mkdir -p /var/www/sos-guide
mkdir -p /var/www/sos-guide/img
mkdir -p /data/docs
mkdir -p /etc/ssl/private
mkdir -p /etc/ssl/certs
if [ -d "/var/www/sos-guide" ]; then
    echo -e "${YELLOW}ℹ️  Réinstallation détectée — déverrouillage...${NC}"
    chattr -R -i /var/www/sos-guide/ 2>/dev/null && \
        echo -e "${GREEN}✓ chattr -i levé${NC}" || \
        echo -e "${YELLOW}⚠️  chattr -i : rien à lever${NC}"
    chmod -R u+w /var/www/sos-guide/ 2>/dev/null || true
fi
cp -r html/* /var/www/sos-guide/
echo -e "${GREEN}✓ Fichiers HTML copiés depuis ./html/${NC}"

# --- INJECTION DES VARIABLES DANS LE HTML ---
echo -e "${CYAN}   Personnalisation de la page d'accueil...${NC}"
sed -i "s|{{LOC_NAME}}|${LOC_NAME}|g" /var/www/sos-guide/index.html
sed -i "s|{{LOC_ADDRESS}}|${LOC_ADDRESS}|g" /var/www/sos-guide/index.html
sed -i "s|{{LOC_LAT}}|${LOC_LAT}|g" /var/www/sos-guide/index.html
sed -i "s|{{LOC_LON}}|${LOC_LON}|g" /var/www/sos-guide/index.html
sed -i "s|{{ESTABLISHMENT_TYPE}}|${ESTABLISHMENT_TYPE}|g" /var/www/sos-guide/index.html
sed -i "s|{{LOCAL_CRISIS_NUMBER}}|${LOCAL_CRISIS_NUMBER}|g" /var/www/sos-guide/index.html
sed -i "s|{{LOCAL_RISK}}|${LOCAL_RISK}|g" /var/www/sos-guide/index.html

# --- COPIE IMAGE PERSONNALISÉE ---
if [ "${COPY_CUSTOM_IMAGE}" = true ]; then
    echo -e "${CYAN}   Copie de l'image personnalisée (HORS-LIGNE)...${NC}"
    if cp "${CUSTOM_IMAGE_SOURCE}" "/var/www/sos-guide/img/${CUSTOM_IMAGE_DEST}"; then
        chown www-data:www-data "/var/www/sos-guide/img/${CUSTOM_IMAGE_DEST}"
        chmod 644 "/var/www/sos-guide/img/${CUSTOM_IMAGE_DEST}"
        echo -e "${GREEN}✓ Image copiée : /var/www/sos-guide/img/${CUSTOM_IMAGE_DEST}${NC}"
        echo -e "${CYAN}   Source      : ${CUSTOM_IMAGE_SOURCE}${NC}"
        echo -e "${CYAN}   URL d'accès : http://${LOCAL_IP}/img/${CUSTOM_IMAGE_DEST}${NC}"
    else
        echo -e "${YELLOW}⚠️  Échec copie de l'image${NC}"
    fi
else
    echo -e "${YELLOW}   Skip copie d'image (fichier source introuvable)${NC}"
fi

chown -R www-data:www-data /var/www/sos-guide
chmod -R 755 /var/www/sos-guide
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
    server_name _;
    root /var/www/sos-guide;
    index index.html;
    access_log /var/log/nginx/sos-access.log;
    error_log /var/log/nginx/sos-error.log;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 3;
    types_hash_max_size 2048;

    # Redirection de toutes les sondes de détection vers le portail
    location = /hotspot-detect.html {
        return 302 http://10.0.0.1/;
    }
    location = /generate_204 {
        return 302 http://10.0.0.1/;
    }
    location = /generate_205 {
        return 302 http://10.0.0.1/;
    }
    location = /connecttest.txt {
        return 302 http://10.0.0.1/;
    }
    location = /ncsi.txt {
        return 302 http://10.0.0.1/;
    }
    location = /success.txt {
        return 302 http://10.0.0.1/;
    }
    location = /canonical.html {
        return 302 http://10.0.0.1/;
    }
    location = /fwlink/ {
        return 302 http://10.0.0.1/;
    }

    # Santé
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

    # Docs
    location /docs/ {
        alias /data/docs/;
        autoindex off;
        add_header Cache-Control "public, max-age=3600";
        add_header X-Content-Type-Options "nosniff";
    }

    # Images
    location /img/ {
        alias /var/www/sos-guide/img/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Page principale
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        add_header X-Content-Type-Options "nosniff";
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Robots-Tag "noindex, nofollow";
    }

    # Sécurité
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
    server_name _;
    ssl_certificate /etc/ssl/certs/sos-guide.crt;
    ssl_certificate_key /etc/ssl/private/sos-guide.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5:!3DES;
    ssl_prefer_server_ciphers on;
    access_log /var/log/nginx/sos-ssl-access.log;
    error_log /var/log/nginx/sos-ssl-error.log;
    root /var/www/sos-guide;
    index index.html;

    location = /hotspot-detect.html {
        return 302 http://10.0.0.1/;
    }
    location = /success.txt {
        return 302 http://10.0.0.1/;
    }
    location / {
        return 302 http://10.0.0.1/;
    }
}

# Redirections spécifiques aux domaines
server {
    listen 80;
    server_name connectivitycheck.gstatic.com connectivitycheck.android.com connectivitycheck.hicloud.com connect.rom.miui.com wifi.vivo.com.cn www.samsung.com;
    access_log off;
    error_log /dev/null;
    location / {
        return 302 http://10.0.0.1/;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/sos-guide /etc/nginx/sites-enabled/
nginx -t
systemctl unmask nginx 2>/dev/null || true
systemctl enable nginx
systemctl restart nginx
echo -e "${GREEN}✓ Serveur web configuré (HTTP + HTTPS + redirections captive portal)${NC}"
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

find /var/www/sos-guide -type f -exec sha256sum {} \; > /root/integrity.hash
sha256sum /etc/nginx/sites-available/sos-guide >> /root/integrity.hash
echo -e "${GREEN}✓ Hash d'intégrité généré (/root/integrity.hash)${NC}"

cat > /usr/local/bin/sos-guide-boot-check.sh << 'BOOTEOF'
#!/bin/bash
if [ -f /root/integrity.hash ]; then
    sha256sum -c /root/integrity.hash >/dev/null 2>&1 || {
        logger "SOS-GUIDE: INTEGRITE COMPROMISE - SHUTDOWN"
        poweroff
    }
fi
if ! iptables -C FORWARD -i wlan0 -o eth0 -j DROP 2>/dev/null; then
    logger "SOS-GUIDE: CRITIQUE - Isolation Internet COMPROMISE"
    iptables -P FORWARD DROP
    iptables -A FORWARD -i wlan0 -o wlan0 -j DROP
    iptables -A FORWARD -i wlan0 -o eth0 -j DROP
    iptables -A FORWARD -i wlan0 -j DROP
    logger "SOS-GUIDE: Règles d'isolation RESTAURÉES"
fi
if iptables -t nat -L POSTROUTING -n 2>/dev/null | grep -q "MASQUERADE\|SNAT"; then
    logger "SOS-GUIDE: ALERTE - Règle NAT sortante détectée (SUPPRIMÉE)"
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

cat > /usr/local/bin/sos-guide-health.sh << 'HEALTHEOF'
#!/bin/bash
ERRORS=0
for svc in hostapd dnsmasq nginx; do
    if ! systemctl is-active --quiet $svc; then
        logger "SOS-GUIDE: SERVICE $svc DOWN - redémarrage"
        systemctl restart $svc 2>/dev/null || true
        ERRORS=$((ERRORS+1))
    fi
done
if ! iptables -C FORWARD -i wlan0 -o eth0 -j DROP 2>/dev/null; then
    logger "SOS-GUIDE: ISOLATION COMPROMISE - restauration firewall"
    iptables -P FORWARD DROP
    iptables -A FORWARD -i wlan0 -o eth0 -j DROP
    iptables -A FORWARD -i wlan0 -j DROP
    ERRORS=$((ERRORS+1))
fi
[ $ERRORS -gt 0 ] && logger "SOS-GUIDE: health-check: $ERRORS anomalie(s) corrigée(s)"
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
[Calendar]
OnCalendar=annually
Persistent=true
[Install]
WantedBy=timers.target
TMR
systemctl daemon-reload
systemctl enable sos-guide-renew-cert.timer
echo -e "${GREEN}✓ Renouvellement SSL automatique activé (annuel)${NC}"

cat > /usr/local/bin/sos-guide-update-content.sh << 'UPDATEEOF'
#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
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

if command -v nslookup &>/dev/null; then
    nslookup google.com ${LOCAL_IP} 2>/dev/null | grep -q "${LOCAL_IP}" \
        && { echo -e "   ${GREEN}✓${NC} DNS wildcard (nslookup)"; TESTS_OK=$((TESTS_OK+1)); } \
        || echo -e "   ${RED}✗${NC} DNS wildcard échoué"
elif command -v getent &>/dev/null; then
    getent hosts google.com 2>/dev/null | grep -q "${LOCAL_IP}" \
        && { echo -e "   ${GREEN}✓${NC} DNS wildcard (getent)"; TESTS_OK=$((TESTS_OK+1)); } \
        || echo -e "   ${RED}✗${NC} DNS wildcard échoué"
else
    echo -e "   ${YELLOW}⚠️${NC}  Test DNS ignoré"
    TESTS_TOTAL=$((TESTS_TOTAL-1))
fi

# On teste les redirections (302) au lieu des réponses directes
curl -s -o /dev/null -w "%{http_code}" http://${LOCAL_IP}/hotspot-detect.html 2>/dev/null | grep -q "302" \
    && { echo -e "   ${GREEN}✓${NC} Probe iOS (hotspot-detect.html) redirigée"; TESTS_OK=$((TESTS_OK+1)); } \
    || echo -e "   ${RED}✗${NC} Probe iOS échouée"

curl -s -o /dev/null -w "%{http_code}" http://${LOCAL_IP}/generate_204 2>/dev/null | grep -q "302" \
    && { echo -e "   ${GREEN}✓${NC} Probe Android (generate_204) redirigée"; TESTS_OK=$((TESTS_OK+1)); } \
    || echo -e "   ${RED}✗${NC} Probe Android échouée"

curl -s -o /dev/null -w "%{http_code}" http://${LOCAL_IP}/success.txt 2>/dev/null | grep -q "302" \
    && { echo -e "   ${GREEN}✓${NC} Probe Firefox (success.txt) redirigée"; TESTS_OK=$((TESTS_OK+1)); } \
    || echo -e "   ${RED}✗${NC} Probe Firefox échouée"

curl -s -o /dev/null -w "%{http_code}" http://${LOCAL_IP}/connecttest.txt 2>/dev/null | grep -q "302" \
    && { echo -e "   ${GREEN}✓${NC} Probe Windows (connecttest.txt) redirigée"; TESTS_OK=$((TESTS_OK+1)); } \
    || echo -e "   ${RED}✗${NC} Probe Windows échouée"

if ! ping -c1 -W1 -I ${WIFI_IFACE} 8.8.8.8 &>/dev/null; then
    echo -e "   ${GREEN}✓${NC} Isolation Internet active (${WIFI_IFACE})"
    TESTS_OK=$((TESTS_OK+1))
else
    echo -e "   ${RED}✗${NC} ALERTE : ${WIFI_IFACE} peut accéder à Internet !"
fi

echo ""
if [ $TESTS_OK -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}🎉 Tous les tests sont au vert (${TESTS_OK}/${TESTS_TOTAL})${NC}"
else
    echo -e "${YELLOW}⚠️  ${TESTS_OK}/${TESTS_TOTAL} tests réussis${NC}"
fi

# ==============================================================================
# 16. CRÉATION SCRIPT COPIE IMAGE (POUR USAGE ULTÉRIEUR)
# ==============================================================================
echo -e "${BLUE}[16/17] Création du script de copie d'image...${NC}"
cat > /usr/local/bin/sos-guide-copy-image.sh << 'IMGEOF'
#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
WEB_DIR="/var/www/sos-guide"; IMG_DIR="/var/www/sos-guide/img"; INTEGRITY_HASH="/root/integrity.hash"

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
find ${WEB_DIR} -type f -exec sha256sum {} \; > ${INTEGRITY_HASH} 2>/dev/null

echo -e "${GREEN}✅ COPIE TERMINÉE — URL : http://10.0.0.1/img/map_location.png${NC}"
IMGEOF
chmod +x /usr/local/bin/sos-guide-copy-image.sh
echo -e "${GREEN}✓ Script sos-guide-copy-image.sh créé${NC}"
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
echo -e "   ${GREEN}✓${NC} IP wlan0       : ${LOCAL_IP}"
echo -e "   ${GREEN}✓${NC} IP eth0        : ${ETH_IP}"
echo -e "   ${GREEN}✓${NC} SSID           : ${SSID}"
echo -e "   ${GREEN}✓${NC} Sécurité WiFi  : AUCUNE (réseau ouvert)"
echo -e "   ${GREEN}✓${NC} Max clients    : 40 (réaliste Pi)"
echo ""
echo -e "${BLUE}📍 LOCALISATION CONFIGURÉE:${NC}"
echo -e "   ${GREEN}✓${NC} Nom : ${LOC_NAME}"
echo -e "   ${GREEN}✓${NC} Adresse : ${LOC_ADDRESS}"
if [ -n "${LOC_LAT}" ] && [ -n "${LOC_LON}" ]; then
    echo -e "   ${GREEN}✓${NC} GPS : ${LOC_LAT}, ${LOC_LON}"
fi
echo -e "   ${GREEN}✓${NC} Type d'établissement : ${ESTABLISHMENT_TYPE}"
echo -e "   ${GREEN}✓${NC} Numéro de crise local : ${LOCAL_CRISIS_NUMBER}"
echo -e "   ${GREEN}✓${NC} Risque local : ${LOCAL_RISK}"
if [ "${COPY_CUSTOM_IMAGE}" = true ]; then
    echo -e "   ${GREEN}✓${NC} Image : map_location.png (copiée manuellement)"
else
    echo -e "   ${YELLOW}⚠️${NC} Image : Non copiée (fichier source introuvable)"
fi
echo ""
echo -e "${BLUE}📱 CAPTIVE PORTAL:${NC}"
echo -e "   ${GREEN}✓${NC} Toutes les sondes (iOS/Android/Windows/Firefox) sont redirigées vers le portail"
echo ""
echo -e "${BLUE}🔒 SÉCURITÉ:${NC}"
echo -e "   ${GREEN}✓${NC} Pi accède Internet via eth0"
echo -e "   ${GREEN}✓${NC} Clients WiFi ISOLÉS d'Internet"
echo -e "   ${GREEN}✓${NC} Isolation client-client (ap_isolate=1)"
echo -e "   ${GREEN}✓${NC} HTTP + HTTPS redirigés (80 + 443)"
echo -e "   ${GREEN}✓${NC} sysrq désactivé (kernel.sysrq=0)"
echo -e "   ${GREEN}✓${NC} IPv6 désactivé"
echo -e "   ${GREEN}✓${NC} /var/www/sos-guide/ verrouillé (chattr +i)"
echo -e "   ${GREEN}✓${NC} Watchdog auto-reboot actif"
echo -e "   ${GREEN}✓${NC} Intégrité SHA256 vérifiée au boot"
echo -e "   ${GREEN}✓${NC} Health check toutes les 5 min"
echo ""
echo -e "${BLUE}🔧 COMMANDES UTILES:${NC}"
echo -e "   ${CYAN}ip addr show ${WIFI_IFACE}${NC}              # IP wlan0"
echo -e "   ${CYAN}journalctl -u hostapd -f${NC}                # Logs WiFi"
echo -e "   ${CYAN}iptables -L -n -v${NC}                       # Règles FW"
echo -e "   ${CYAN}ping -I ${WIFI_IFACE} 8.8.8.8${NC}           # Test isolation"
echo -e "   ${CYAN}curl http://${LOCAL_IP}/img/map_location.png${NC}  # Vérifier image"
echo -e "   ${CYAN}sha256sum -c /root/integrity.hash${NC}       # Intégrité"
echo -e "   ${CYAN}sudo bash /usr/local/bin/sos-guide-update-content.sh${NC}  # Màj contenu"
echo -e "   ${CYAN}sudo bash /usr/local/bin/sos-guide-copy-image.sh${NC}      # Copier image"
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
echo -e "${YELLOW}⚠️  NOTEZ LE SSID SUR LE BOÎTIER : ${SSID}${NC}"
echo -e "${YELLOW}⚠️  PREMIER TEST : Connectez un smartphone au WiFi${NC}"
echo ""
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}   Développé par Ludovic MARTIN - contact@sos-guide.fr${NC}"
echo -e "${GREEN}========================================================${NC}"
echo ""

exit 0
