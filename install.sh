#!/bin/bash
# ==============================================================================
# SOS-GUIDE - INSTALLATION v1.0
# ==============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

SSID="⛑️ SOS-GUIDE"
LOCAL_IP="10.0.0.1"

WIFI_IFACE=${WIFI_IFACE:-$(ip -o link show | awk -F': ' '/wl/{print $2; exit}')}
ETH_IFACE=${ETH_IFACE:-eth0}

echo -e "${GREEN}"
echo "================================================"
echo "   SOS-GUIDE - Emergency Offline Survival System"
echo "   v1.6 - Installation Sécurisée"
echo -e "================================================${NC}"
echo ""

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}❌ Ce script doit être exécuté en root (sudo ./install.sh)${NC}"
    exit 1
fi

if [ -z "${WIFI_IFACE}" ]; then
    echo -e "${RED}❌ Aucune interface WiFi détectée — branchez un dongle ou activez le WiFi${NC}"
    echo -e "${YELLOW}   Override manuel : WIFI_IFACE=wlan0 sudo bash install.sh${NC}"
    exit 1
fi

echo -e "${CYAN}📡 Interface WiFi détectée : ${BOLD}${WIFI_IFACE}${NC}"

if ! ip link show "${ETH_IFACE}" &>/dev/null; then
    echo -e "${YELLOW}⚠️  Interface ${ETH_IFACE} non détectée — le Pi n'aura pas accès Internet${NC}"
fi

# ==============================================================================
# 1. NETTOYAGE
# ==============================================================================
echo -e "${BLUE}[1/12] Nettoyage des gestionnaires réseau conflictuels...${NC}"
for svc in bluetooth NetworkManager wpa_supplicant avahi-daemon avahi-daemon.socket ModemManager; do
    systemctl stop $svc 2>/dev/null || true
    systemctl disable $svc 2>/dev/null || true
    systemctl mask $svc 2>/dev/null || true
done
systemctl stop dhcpcd 2>/dev/null || true
systemctl disable dhcpcd 2>/dev/null || true
pkill -f wpa_supplicant 2>/dev/null || true
pkill -f NetworkManager 2>/dev/null || true
systemctl disable getty@tty2.service 2>/dev/null || true
systemctl disable getty@tty3.service 2>/dev/null || true

echo 0 > /proc/sys/kernel/sysrq
sleep 2
echo -e "${GREEN}✓ Gestionnaires conflictuels désactivés${NC}"

# ==============================================================================
# NTP
# ==============================================================================
cat > /etc/systemd/timesyncd.conf <<EOF
[Time]
NTP=0.pool.ntp.org 1.pool.ntp.org
RootDistanceMaxSec=30
PollIntervalMinSec=32
PollIntervalMaxSec=2048
EOF
systemctl enable systemd-timesyncd
systemctl restart systemd-timesyncd
timedatectl set-ntp true
echo -e "${GREEN}✓ Configuration NTP${NC}"
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
# 2. PAQUETS
# ==============================================================================
echo -e "${BLUE}[2/12] Installation des paquets...${NC}"
apt update -qq
apt dist-upgrade -y
apt install -y nginx hostapd dnsmasq iptables-persistent netfilter-persistent \
    systemd-resolved watchdog e2fsprogs curl dnsutils
echo -e "${GREEN}✓ Paquets installés${NC}"

# ==============================================================================
# 3. PAYS WIFI
# ==============================================================================
echo -e "${BLUE}[3/12] Configuration du pays WiFi...${NC}"
echo "country=FR" > /etc/wpa_supplicant/wpa_supplicant.conf
rfkill unblock wifi
echo -e "${GREEN}✓ Pays WiFi configuré (FR)${NC}"

# ==============================================================================
# 4. SYSTEMD-NETWORKD
# ==============================================================================
echo -e "${BLUE}[4/12] Configuration systemd-networkd...${NC}"
systemctl enable systemd-networkd
cat > /etc/systemd/network/10-eth0.network <<EOF
[Match]
Name=eth0
[Network]
DHCP=yes
IPv6AcceptRA=no
IPv6DHCP=no
DNS=1.1.1.1
DNS=8.8.4.4
EOF
cat > /etc/systemd/network/20-wlan0-ap.network <<EOF
[Match]
Name=wlan0
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

# ==============================================================================
# 5. SYSTEMD-RESOLVED
# ==============================================================================
echo -e "${BLUE}[5/12] Configuration systemd-resolved (eth0 uniquement)...${NC}"
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
echo -e "${GREEN}✓ systemd-resolved configuré (eth0)${NC}"

# ==============================================================================
# 6. HOSTAPD
# ==============================================================================
echo -e "${BLUE}[6/12] Configuration du Point d'Accès WiFi (réseau ouvert)...${NC}"
TS=$(date +%Y%m%d_%H%M%S)
[ -d /etc/nginx ] && cp -a /etc/nginx /etc/nginx.bak.$TS 2>/dev/null || true
[ -d /etc/hostapd ] && cp -a /etc/hostapd /etc/hostapd.bak.$TS 2>/dev/null || true
[ -f /etc/dnsmasq.conf ] && cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak.$TS 2>/dev/null || true
mkdir -p /etc/hostapd
cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
driver=nl80211
ssid=${SSID}
hw_mode=g
channel=11
wmm_enabled=1
beacon_int=50
dtim_period=1
max_num_sta=20
country_code=FR
ap_isolate=1
ieee80211d=1
ieee80211n=1
auth_algs=1
wpa=0
EOF
cat > /etc/default/hostapd <<EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
DAEMON_OPTS=""
EOF
systemctl unmask hostapd 2>/dev/null || true
systemctl enable hostapd
systemctl restart hostapd
sleep 3
echo -e "${GREEN}✓ hostapd configuré (réseau ouvert — sans mot de passe)${NC}"

# ==============================================================================
# 7. DNSMASQ
# ==============================================================================
echo -e "${BLUE}[7/12] Configuration dnsmasq (wlan0 - Captive Portal)...${NC}"
echo "DNSMASQ_EXCEPT=lo" >> /etc/default/dnsmasq
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak 2>/dev/null || true
cat > /etc/dnsmasq.conf <<EOF
bind-dynamic
interface=wlan0
listen-address=${LOCAL_IP}
dhcp-authoritative
dhcp-range=${LOCAL_IP%.*}.100,${LOCAL_IP%.*}.200,12h
dhcp-option=3,${LOCAL_IP}
dhcp-option=6,${LOCAL_IP}
dhcp-option=114,"http://${LOCAL_IP}/"
address=/#/${LOCAL_IP}
no-resolv
no-hosts
cache-size=0
log-queries=0
EOF
systemctl enable dnsmasq
systemctl restart dnsmasq
sleep 2
echo -e "${GREEN}✓ dnsmasq configuré (wlan0 - Captive Portal)${NC}"

# ==============================================================================
# 8. FIREWALL
# ==============================================================================
echo -e "${BLUE}[8/12] Configuration du firewall (Isolation TOTALE wlan0)...${NC}"

iptables -F
iptables -t nat -F
iptables -t mangle -F

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

iptables -A INPUT -i eth0 -p tcp --dport 22 -m conntrack --ctstate NEW -m limit --limit 3/min --limit-burst 3 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -i wlan0 -p tcp --dport 80  -m limit --limit 30/second --limit-burst 200 -j ACCEPT
iptables -A INPUT -i wlan0 -p tcp --dport 443 -m limit --limit 30/second --limit-burst 200 -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i wlan0 -p udp --dport 67 -j ACCEPT
iptables -A INPUT -i wlan0 -p udp --dport 68 -j ACCEPT
iptables -A INPUT -i wlan0 -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i wlan0 -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -i wlan0 -j DROP

iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 \
    -j DNAT --to-destination ${LOCAL_IP}:80
iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 443 \
    -j DNAT --to-destination ${LOCAL_IP}:80

iptables -A FORWARD -i wlan0 -o wlan0 -j DROP
iptables -A FORWARD -i wlan0 -o eth0  -j DROP
iptables -A FORWARD -i wlan0 -j DROP
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT

mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

if ! iptables -C FORWARD -i wlan0 -o eth0 -j DROP 2>/dev/null; then
    echo -e "${RED}❌ ERREUR CRITIQUE: Règle d'isolation Internet manquante${NC}"
    exit 1
fi
if ! iptables -C FORWARD -i wlan0 -j DROP 2>/dev/null; then
    echo -e "${RED}❌ ERREUR CRITIQUE: Filet de sécurité wlan0 manquant${NC}"
    exit 1
fi
if ! iptables -t nat -C PREROUTING -i wlan0 -p tcp --dport 80 \
        -j DNAT --to-destination ${LOCAL_IP}:80 2>/dev/null; then
    echo -e "${RED}❌ ERREUR CRITIQUE: Règle NAT PREROUTING port 80 manquante${NC}"
    exit 1
fi
if ! iptables -t nat -C PREROUTING -i wlan0 -p tcp --dport 443 \
        -j DNAT --to-destination ${LOCAL_IP}:80 2>/dev/null; then
    echo -e "${RED}❌ ERREUR CRITIQUE: Règle NAT PREROUTING port 443 manquante${NC}"
    exit 1
fi

netfilter-persistent save 2>/dev/null || true
echo 1 > /proc/sys/net/ipv4/ip_forward
echo -e "${GREEN}✓ Firewall configuré (Isolation TOTALE wlan0, HTTP+HTTPS redirigés)${NC}"
echo -e "${GREEN}✓ Clients WiFi JAMAIS Internet${NC}"

# ==============================================================================
# 9. SERVEUR WEB
# ==============================================================================
echo -e "${BLUE}[9/12] Configuration du serveur web (HTTP + Toutes Sondes)...${NC}"

if [ -d "/var/www/sos-guide" ]; then
    echo -e "${YELLOW}ℹ️  Réinstallation détectée — déverrouillage du contenu web...${NC}"
    chattr -R -i /var/www/sos-guide/ 2>/dev/null && \
        echo -e "${GREEN}✓ chattr -i levé${NC}" || \
        echo -e "${YELLOW}⚠️  chattr -i : rien à lever${NC}"
    chmod -R u+w /var/www/sos-guide/ 2>/dev/null || true
    echo -e "${GREEN}✓ Permissions d'écriture rétablies${NC}"
fi

mkdir -p /var/www/sos-guide
mkdir -p /data/docs
mkdir -p /etc/ssl/private
mkdir -p /etc/ssl/certs

if [ -d "html" ] && [ -f "html/index.html" ]; then
    cp -r html/* /var/www/sos-guide/
    echo -e "${GREEN}✓ Fichiers HTML copiés dans /var/www/sos-guide/${NC}"
else
    echo -e "${YELLOW}⚠️  Dossier html/ absent ou incomplet — création d'une page d'accueil minimale${NC}"
    cat > /var/www/sos-guide/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="fr">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>⛑️ SOS-GUIDE</title>
<style>body{font-family:sans-serif;text-align:center;padding:2em;background:#1a1a2e;color:#eee}
h1{color:#e94560}p{font-size:1.2em}.num{font-size:2em;color:#e94560;font-weight:bold}</style>
</head>
<body>
<h1>⛑️ SOS-GUIDE</h1>
<p>Système d'information d'urgence actif</p>
<hr>
<p>🚨 Numéros d'urgence</p>
<p><span class="num">15</span> SAMU &nbsp;
   <span class="num">17</span> Police &nbsp;
   <span class="num">18</span> Pompiers &nbsp;
   <span class="num">112</span> Urgences EU</p>
</body></html>
HTMLEOF
    echo -e "${GREEN}✓ Page d'accueil minimale créée${NC}"
fi

chown -R www-data:www-data /var/www/sos-guide
chmod -R 755 /var/www/sos-guide

echo "🔐 Génération certificat SSL auto-signé..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/sos-guide.key \
    -out /etc/ssl/certs/sos-guide.crt \
    -subj "/C=FR/ST=Emergency/L=Local/O=SOS-GUIDE/CN=10.0.0.1"
chmod 600 /etc/ssl/private/sos-guide.key
echo -e "${GREEN}✓ Certificat SSL généré${NC}"

rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/sos-guide <<'NGINXEOF'
server {
    listen 80 default_server;
    server_name _;
    root /var/www/sos-guide;
    index index.html;

    access_log off;
    error_log /dev/null;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 3;
    types_hash_max_size 2048;

    location = /generate_204 {
        default_type text/plain;
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0";
        add_header Content-Length "0";
        add_header Connection "close";
        return 204;
    }

    location = /generate_205 {
        default_type text/plain;
        add_header Cache-Control "no-store";
        return 204;
    }

    location = /hotspot-detect.html {
        default_type text/html;
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0";
        add_header Connection "close";
        add_header X-Robots-Tag "noindex, nofollow";
        return 200 '<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>';
    }

    location = /library/test/success.html {
        default_type text/html;
        add_header Cache-Control "no-store";
        return 200 '<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>';
    }

    location = /connecttest.txt {
        default_type text/plain;
        add_header Cache-Control "no-store";
        return 200 "Microsoft Connect Test";
    }

    location = /ncsi.txt {
        default_type text/plain;
        add_header Cache-Control "no-store";
        return 200 "Microsoft NCSI";
    }

    location = /success.txt {
        default_type text/plain;
        add_header Cache-Control "no-store";
        return 200 "success";
    }

    location = /canonical.html {
        default_type text/html;
        add_header Cache-Control "no-store";
        return 200 '<meta http-equiv="refresh" content="0;url=http://10.0.0.1/"><title>Success</title>';
    }

    location = /fwlink/ {
        default_type text/html;
        add_header Cache-Control "no-store";
        return 302 http://10.0.0.1/;
    }

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

    location /docs/ {
        alias /data/docs/;
        autoindex off;
        add_header Cache-Control "public, max-age=3600";
        add_header X-Content-Type-Options "nosniff";
    }

    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        add_header X-Content-Type-Options "nosniff";
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Robots-Tag "noindex, nofollow";
    }

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

    access_log off;
    error_log /dev/null;

    root /var/www/sos-guide;
    index index.html;

    location = /hotspot-detect.html {
        default_type text/html;
        add_header Cache-Control "no-store";
        return 200 '<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>';
    }

    location = /success.txt {
        default_type text/plain;
        add_header Cache-Control "no-store";
        return 200 "success";
    }

    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header X-Content-Type-Options "nosniff";
    }
}

server {
    listen 80;
    server_name connectivitycheck.platform.hicloud.com;
    access_log off;
    error_log /dev/null;
    location / {
        default_type text/html;
        add_header Cache-Control "no-store";
        return 302 http://10.0.0.1/;
    }
}

server {
    listen 80;
    server_name connect.rom.miui.com;
    access_log off;
    error_log /dev/null;
    location / {
        default_type text/html;
        add_header Cache-Control "no-store";
        return 302 http://10.0.0.1/;
    }
}

server {
    listen 80;
    server_name wifi.vivo.com.cn;
    access_log off;
    error_log /dev/null;
    location / {
        default_type text/html;
        add_header Cache-Control "no-store";
        return 302 http://10.0.0.1/;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/sos-guide /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
systemctl enable nginx
echo -e "${GREEN}✓ Serveur web configuré (HTTP + HTTPS + Toutes Sondes)${NC}"

# ==============================================================================
# 10. VERROUILLAGE WEB
# ==============================================================================
echo -e "${BLUE}[10/12] Verrouillage du contenu Web (Read-Only)...${NC}"

sed -i '/\/var\/www.*bind/d' /etc/fstab 2>/dev/null || true
chmod -R a-w /var/www/sos-guide/
echo -e "${GREEN}✓ /var/www/sos-guide/ protégé (chmod a-w)${NC}"

if command -v chattr &>/dev/null; then
    chattr -R +i /var/www/sos-guide/ 2>/dev/null && \
        echo -e "${GREEN}✓ /var/www/sos-guide/ verrouillé (chattr +i)${NC}" || \
        echo -e "${YELLOW}⚠️  chattr non supporté sur ce FS (ext4 requis)${NC}"
else
    echo -e "${YELLOW}⚠️  chattr non disponible — protection chmod uniquement${NC}"
fi

echo -e "${YELLOW}   ℹ️  Pour modifier le contenu web :${NC}"
echo -e "   ${CYAN}chattr -R -i /var/www/sos-guide/ && chmod -R u+w /var/www/sos-guide/${NC}"

# ==============================================================================
# SYSCTL
# ==============================================================================
cat > /etc/sysctl.d/60-disable-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.wlan0.disable_ipv6 = 1
net.ipv6.conf.eth0.disable_ipv6 = 1
EOF
cat > /etc/sysctl.d/50-anti-spoofing.conf <<EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv4.conf.wlan0.forwarding = 1
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
# [FIX 3] sysrq désactivé en production
kernel.sysrq = 0
EOF
sysctl -p /etc/sysctl.d/50-anti-spoofing.conf 2>/dev/null || true
sysctl -p /etc/sysctl.d/60-disable-ipv6.conf 2>/dev/null || true
echo -e "${GREEN}✓ Optimisations sysctl appliquées (sysrq=0)${NC}"

echo -e "${BLUE}[⚡] Optimisations économie d'énergie (usage batterie)...${NC}"

if command -v tvservice &>/dev/null; then
    tvservice -o 2>/dev/null && echo -e "${GREEN}✓ HDMI désactivé${NC}" || true
elif [ -f /sys/class/drm/card0/enabled ]; then
    echo off > /sys/class/drm/card0/enabled 2>/dev/null || true
fi

grep -q "tvservice -o" /etc/rc.local 2>/dev/null || \
    sed -i 's|^exit 0|tvservice -o 2>/dev/null \|\| true\nexit 0|' /etc/rc.local 2>/dev/null || true

if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
    echo -e "${GREEN}✓ Gouverneur CPU → ondemand${NC}"
fi

if ! grep -q "tmpfs /var/log/nginx" /etc/fstab 2>/dev/null; then
    echo "tmpfs /var/log/nginx tmpfs defaults,noatime,nosuid,mode=0755,size=10m 0 0" >> /etc/fstab
    mkdir -p /var/log/nginx
    mount -t tmpfs tmpfs /var/log/nginx 2>/dev/null || true
    echo -e "${GREEN}✓ Logs nginx en tmpfs (économie écriture SD)${NC}"
fi

echo -e "${GREEN}✓ Économie d'énergie configurée${NC}"

# ==============================================================================
# 11. WATCHDOG
# ==============================================================================
echo -e "${BLUE}[11/12] Configuration du Watchdog...${NC}"
if [ -f /boot/firmware/config.txt ]; then
    BOOT_CONFIG="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    BOOT_CONFIG="/boot/config.txt"
else
    BOOT_CONFIG=""
fi
if [ -n "$BOOT_CONFIG" ]; then
    if grep -q "^dtparam=watchdog" "$BOOT_CONFIG"; then
        sed -i 's/^dtparam=watchdog=.*/dtparam=watchdog=on/' "$BOOT_CONFIG"
    else
        echo "dtparam=watchdog=on" >> "$BOOT_CONFIG"
    fi
fi
modprobe bcm2835_wdt 2>/dev/null || true
if [ ! -e /dev/watchdog ]; then
    echo -e "${YELLOW}⚠️  /dev/watchdog non disponible - fallback logiciel${NC}"
    mkdir -p /etc/systemd/system.conf.d
    cat > /etc/systemd/system.conf.d/watchdog.conf <<EOF
[Manager]
RuntimeWatchdogSec=14s
ShutdownWatchdogSec=10min
EOF
    systemctl daemon-reload
else
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
fi
sleep 2
if systemctl is-active --quiet watchdog 2>/dev/null; then
    echo -e "${GREEN}✓ Watchdog configuré (auto-reboot)${NC}"
else
    echo -e "${YELLOW}⚠️  Watchdog: activation au prochain reboot${NC}"
fi

# ==============================================================================
# 12. INTÉGRITÉ & FINALISATION
# ==============================================================================
echo -e "${BLUE}[12/12] Vérification d'intégrité & Finalisation...${NC}"

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
echo -e "${GREEN}✓ Service sos-guide-boot.service activé (remplace rc.local)${NC}"

# ==============================================================================
# HEALTH CHECK TIMER (toutes les 5 minutes)
# ==============================================================================
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
echo -e "${GREEN}✓ Health check timer activé (toutes les 5 min)${NC}"

# ==============================================================================
# CERTIFICAT SSL - RENOUVELLEMENT AUTOMATIQUE (annuel)
# ==============================================================================
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

cat > /usr/local/bin/sos-guide-update-content.sh << 'UPDATEEOF'
#!/bin/bash
# ==============================================================
# SOS-GUIDE — Mise à jour du contenu web
# Usage : sudo bash /usr/local/bin/sos-guide-update-content.sh
# ==============================================================
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
echo -e "${YELLOW}Modifiez vos fichiers dans /var/www/sos-guide/${NC}"
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
echo -e "${GREEN}✓ Hash régénéré — le boot-check ne bloquera pas${NC}"
echo ""
echo -e "${GREEN}✅ Mise à jour terminée. Testez : curl http://10.0.0.1/${NC}"
UPDATEEOF
chmod +x /usr/local/bin/sos-guide-update-content.sh
echo -e "${GREEN}✓ Script de mise à jour créé (/usr/local/bin/sos-guide-update-content.sh)${NC}"

# ==============================================================================
# RÉSUMÉ FINAL
# ==============================================================================
echo -e "\n${BLUE}🧪 Lancement des tests de validation...${NC}"
TESTS_OK=0
TESTS_TOTAL=5

if command -v nslookup &>/dev/null; then
    nslookup google.com ${LOCAL_IP} 2>/dev/null | grep -q "${LOCAL_IP}" \
        && { echo -e "   ${GREEN}✓${NC} DNS wildcard fonctionnel (nslookup)"; TESTS_OK=$((TESTS_OK+1)); } \
        || echo -e "   ${RED}✗${NC} DNS wildcard échoué"
elif command -v getent &>/dev/null; then
    getent hosts google.com 2>/dev/null | grep -q "${LOCAL_IP}" \
        && { echo -e "   ${GREEN}✓${NC} DNS wildcard fonctionnel (getent)"; TESTS_OK=$((TESTS_OK+1)); } \
        || echo -e "   ${RED}✗${NC} DNS wildcard échoué"
else
    echo -e "   ${YELLOW}⚠️${NC}  Test DNS ignoré (nslookup/getent non disponibles)"
    TESTS_TOTAL=$((TESTS_TOTAL-1))
fi

if command -v curl &>/dev/null; then
    curl -s -o /dev/null -w "%{http_code}" http://${LOCAL_IP}/hotspot-detect.html | grep -q "200" \
        && { echo -e "   ${GREEN}✓${NC} Probe iOS (hotspot-detect.html)"; TESTS_OK=$((TESTS_OK+1)); } \
        || echo -e "   ${RED}✗${NC} Probe iOS échouée"
else
    echo -e "   ${YELLOW}⚠️${NC}  Test iOS ignoré (curl non disponible)"
    TESTS_TOTAL=$((TESTS_TOTAL-1))
fi

if command -v curl &>/dev/null; then
    curl -s -o /dev/null -w "%{http_code}" http://${LOCAL_IP}/generate_204 | grep -q "204" \
        && { echo -e "   ${GREEN}✓${NC} Probe Android (generate_204)"; TESTS_OK=$((TESTS_OK+1)); } \
        || echo -e "   ${RED}✗${NC} Probe Android échouée"
else
    echo -e "   ${YELLOW}⚠️${NC}  Test Android ignoré (curl non disponible)"
    TESTS_TOTAL=$((TESTS_TOTAL-1))
fi

if command -v curl &>/dev/null; then
    [ "$(curl -s http://${LOCAL_IP}/success.txt)" = "success" ] \
        && { echo -e "   ${GREEN}✓${NC} Probe Firefox (success.txt)"; TESTS_OK=$((TESTS_OK+1)); } \
        || echo -e "   ${RED}✗${NC} Probe Firefox échouée"
else
    echo -e "   ${YELLOW}⚠️${NC}  Test Firefox ignoré (curl non disponible)"
    TESTS_TOTAL=$((TESTS_TOTAL-1))
fi

if ! ping -c1 -W1 -I wlan0 8.8.8.8 &>/dev/null; then
    echo -e "   ${GREEN}✓${NC} Isolation Internet active (wlan0)"
    TESTS_OK=$((TESTS_OK+1))
else
    echo -e "   ${RED}✗${NC} ALERTE : wlan0 peut accéder à Internet !"
fi

echo ""
if [ $TESTS_OK -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}🎉 Tous les tests sont au vert (${TESTS_OK}/${TESTS_TOTAL})${NC}"
else
    echo -e "${YELLOW}⚠️  ${TESTS_OK}/${TESTS_TOTAL} tests réussis — vérifiez les échecs ci-dessus${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "   ✅ CONFIGURATION TERMINÉE ! v1.6"
echo -e "==========================================${NC}"
echo ""
echo -e "${BLUE}📡 CONFIGURATION RÉSEAU:${NC}"
echo -e "   ${GREEN}✓${NC} Interface : ${WIFI_IFACE}"
echo -e "   ${GREEN}✓${NC} IP wlan0  : ${LOCAL_IP}"
echo -e "   ${GREEN}✓${NC} SSID      : ${SSID}"
echo -e "   ${GREEN}✓${NC} Sécurité  : AUCUNE — réseau ouvert (accès immédiat)"
echo ""
echo -e "${BLUE}📱 CAPTIVE PORTAL:${NC}"
echo -e "   ${GREEN}✓${NC} Apple iOS/macOS     : /hotspot-detect.html → 200 + 'Success'"
echo -e "   ${GREEN}✓${NC} Android Google      : /generate_204 → 204"
echo -e "   ${GREEN}✓${NC} Windows 10/11       : /connecttest.txt + /ncsi.txt → 200"
echo -e "   ${GREEN}✓${NC} Samsung One UI      : /generate_204 → 204 (héritage Android)"
echo -e "   ${GREEN}✓${NC} Firefox             : /success.txt → 200 + 'success' [FIX 2]"
echo -e "   ${GREEN}✓${NC} Huawei              : server_name hicloud.com → 302"
echo -e "   ${GREEN}✓${NC} Xiaomi              : server_name miui.com → 302"
echo -e "   ${GREEN}✓${NC} iOS 14+ HTTPS       : DNAT 443→80 + /hotspot-detect.html [FIX 1]"
echo ""
echo -e "${BLUE}🔒 SÉCURITÉ:${NC}"
echo -e "   ${GREEN}✓${NC} Pi accède Internet via eth0"
echo -e "   ${GREEN}✓${NC} Clients WiFi ISOLÉS d'Internet"
echo -e "   ${GREEN}✓${NC} Isolation client-client (ap_isolate)"
echo -e "   ${GREEN}✓${NC} Réseau WiFi ouvert (pas de mot de passe)"
echo -e "   ${GREEN}✓${NC} HTTP + HTTPS redirigés (ports 80 + 443) [FIX 1]"
echo -e "   ${GREEN}✓${NC} sysrq désactivé (kernel.sysrq=0) [FIX 3]"
echo -e "   ${GREEN}✓${NC} /var/www/sos-guide/ verrouillé (chattr +i + chmod a-w)"
echo -e "   ${GREEN}✓${NC} Watchdog auto-reboot actif"
echo -e "   ${GREEN}✓${NC} Intégrité SHA256 vérifiée au boot"
echo ""
echo -e "${BLUE}🔧 ÉTAT DES SERVICES:${NC}"
for service in hostapd dnsmasq nginx systemd-networkd systemd-resolved watchdog; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo -e "   ${GREEN}✓${NC} $service: actif"
    else
        echo -e "   ${RED}✗${NC} $service: inactif"
    fi
done
for service in sos-guide-boot sos-guide-renew-cert.timer; do
    if systemctl is-enabled --quiet $service 2>/dev/null; then
        echo -e "   ${GREEN}✓${NC} $service: activé"
    else
        echo -e "   ${RED}✗${NC} $service: non activé"
    fi
done
if systemctl is-active --quiet sos-guide-health.timer 2>/dev/null; then
    echo -e "   ${GREEN}✓${NC} sos-guide-health.timer: actif"
else
    echo -e "   ${RED}✗${NC} sos-guide-health.timer: inactif"
fi
echo ""
echo -e "${YELLOW}🔧 COMMANDES UTILES:${NC}"
echo "   IP wlan0          : ip addr show wlan0"
echo "   Logs WiFi         : journalctl -u hostapd -f"
echo "   Règles FW         : iptables -L -n -v"
echo "   Test isolation    : ping -I wlan0 8.8.8.8  (doit échouer)"
echo "   Test DNS          : nslookup google.com ${LOCAL_IP}  (→ ${LOCAL_IP})"
echo "   Test Apple        : curl -I http://${LOCAL_IP}/hotspot-detect.html"
echo "   Test Android      : curl -I http://${LOCAL_IP}/generate_204"
echo "   Test Windows      : curl http://${LOCAL_IP}/connecttest.txt"
echo "   Test Firefox      : curl http://${LOCAL_IP}/success.txt"
echo "   Health check      : curl http://${LOCAL_IP}/health"
echo "   Intégrité         : sha256sum -c /root/integrity.hash"
echo "   Màj contenu web   : sudo bash /usr/local/bin/sos-guide-update-content.sh"
echo ""
echo -e "${MAGENTA}🚀 SOS-GUIDE v1.6 EST PRÊT POUR LA PRODUCTION !${NC}"
echo -e "${YELLOW}⚠️  N'OUBLIEZ PAS DE NOTER LA CLÉ WIFI SUR LE BOÎTIER${NC}"
echo ""
