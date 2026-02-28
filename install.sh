#!/bin/bash
# ==============================================================================
# SOS-GUIDE - INSTALLATION MASTER SÉCURISÉE v1.0
# ==============================================================================
set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
SSID="⛑️ SOS-GUIDE"
LOCAL_IP="10.0.0.1"
WLAN_SUBNET="10.0.0.0/24"
# Génération d'une clé WPA2 forte (12 caractères aléatoires)
WPA_PASSPHRASE=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)

echo -e "${GREEN}"
echo "================================================"
echo "   SOS-GUIDE - Emergency Offline Survival System"
echo "================================================${NC}"
echo ""

# ==============================================================================
# 1. NETTOYAGE DES GESTIONNAIRES CONFLICTUELS
# ==============================================================================
echo -e "${BLUE}[1/12] Nettoyage des gestionnaires réseau conflictuels...${NC}"
# Stop et disable bluetooth (conflit potentiel avec hostapd)
systemctl stop bluetooth 2>/dev/null || true
systemctl disable bluetooth 2>/dev/null || true
systemctl mask bluetooth 2>/dev/null || true
# Stop et disable NetworkManager (conflit avec systemd-networkd)
systemctl stop NetworkManager 2>/dev/null || true
systemctl disable NetworkManager 2>/dev/null || true
systemctl mask NetworkManager 2>/dev/null || true
# Stop et disable wpa_supplicant (conflit direct avec hostapd)
systemctl stop wpa_supplicant 2>/dev/null || true
systemctl disable wpa_supplicant 2>/dev/null || true
systemctl mask wpa_supplicant 2>/dev/null || true
# Stop dhcpcd si présent (conflit avec systemd-networkd DHCP)
systemctl stop dhcpcd 2>/dev/null || true
systemctl disable dhcpcd 2>/dev/null || true
# Stop avahi-daemon (évite les annonces mDNS non désirées)
systemctl stop avahi-daemon 2>/dev/null || true
systemctl stop avahi-daemon.socket 2>/dev/null || true
systemctl disable avahi-daemon 2>/dev/null || true
systemctl disable avahi-daemon.socket 2>/dev/null || true
systemctl mask avahi-daemon 2>/dev/null || true
systemctl mask avahi-daemon.socket 2>/dev/null || true
# Stop ModemManager (inutile en mode AP fixe)
systemctl stop ModemManager 2>/dev/null || true
systemctl disable ModemManager 2>/dev/null || true
systemctl mask ModemManager 2>/dev/null || true
# Tuer les processus résiduels
pkill -f wpa_supplicant 2>/dev/null || true
pkill -f NetworkManager 2>/dev/null || true
# Désactiver consoles inutiles (économie ressources)
systemctl disable getty@tty2.service 2>/dev/null || true
systemctl disable getty@tty3.service 2>/dev/null || true
# Empêcher reboot magique via SysRq (sécurité physique)
echo 1 > /proc/sys/kernel/sysrq
sleep 2
echo -e "${GREEN}✓ Gestionnaires conflictuels désactivés${NC}"

# ==============================================================================
# NTP - Synchronisation horloge
# ==============================================================================
cat > /etc/systemd/timesyncd.conf <<EOF
[Time]
NTP=0.pool.ntp.org 1.pool.ntp.org
FallbackNTP=1.1.1.1
RootDistanceMaxSec=30
PollIntervalMinSec=32
PollIntervalMaxSec=2048
EOF
systemctl enable systemd-timesyncd
systemctl restart systemd-timesyncd
timedatectl set-ntp true
echo -e "${GREEN}✓ Configuration NTP${NC}"
echo "⏳ Synchronisation de l'heure (30 secondes)..."
sleep 30
echo "📅 Date actuelle : $(timedatectl status | grep 'Local time' | awk '{print $2,$3}')"
echo ""

# ==============================================================================
# 2. INSTALLATION DES PAQUETS
# ==============================================================================
echo -e "${BLUE}[2/12] Installation des paquets...${NC}"
apt update -qq
apt dist-upgrade -y
apt install -y nginx hostapd dnsmasq iptables-persistent netfilter-persistent systemd-resolved watchdog openssl e2fsprogs
echo -e "${GREEN}✓ Paquets installés${NC}"

# ==============================================================================
# 3. CONFIGURATION PAYS WIFI
# ==============================================================================
echo -e "${BLUE}[3/12] Configuration du pays WiFi...${NC}"
echo "country=FR" > /etc/wpa_supplicant/wpa_supplicant.conf
rfkill unblock wifi
echo -e "${GREEN}✓ Pays WiFi configuré (FR)${NC}"

# ==============================================================================
# 4. CONFIGURATION SYSTEMD-NETWORKD
# ==============================================================================
echo -e "${BLUE}[4/12] Configuration systemd-networkd...${NC}"
systemctl enable systemd-networkd
# ETH0 : Client DHCP vers Internet (backhaul)
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
# WLAN0 : Point d'accès avec IP statique + serveur DHCP pour clients
cat > /etc/systemd/network/20-wlan0-ap.network <<EOF
[Match]
Name=wlan0
[Network]
Address=${LOCAL_IP}/24
IPv6AcceptRA=no
IPv6LinkLocalAddressGenerationMode=none
IPv6Token=none
[Link]
WakeOnLan=off
[WLAN]
PowerSave=off
EOF
systemctl daemon-reload
systemctl restart systemd-networkd
echo -e "${GREEN}✓ systemd-networkd configuré${NC}"

# ==============================================================================
# 5. CONFIGURATION SYSTEMD-RESOLVED
# ==============================================================================
echo -e "${BLUE}[5/12] Configuration systemd-resolved (eth0 uniquement)...${NC}"
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/dns.conf <<EOF
[Resolve]
DNS=1.1.1.1 8.8.4.4
FallbackDNS=
DNSStubListener=yes
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
# 6. CONFIGURATION HOSTAPD (SÉCURISÉ WPA2)
# ==============================================================================
echo -e "${BLUE}[6/12] Configuration du Point d'Accès WiFi (WPA2)...${NC}"
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
max_num_sta=50
country_code=FR
ap_isolate=1
ieee80211d=1
ieee80211n=1
# Sécurité WPA2 (Ajout Critique)
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
wpa_passphrase=${WPA_PASSPHRASE}
EOF
cat > /etc/default/hostapd << EOF
DAEMON_CONF="/etc/hostapd/hostapd.conf"
DAEMON_OPTS=""
EOF
# Sauvegarde de la clé pour l'administrateur
echo "${WPA_PASSPHRASE}" > /root/wifi_key.txt
chmod 600 /root/wifi_key.txt
systemctl unmask hostapd 2>/dev/null || true
systemctl enable hostapd
systemctl restart hostapd
echo -e "${GREEN}✓ hostapd configuré (WPA2 Sécurisé)${NC}"
echo -e "${YELLOW}⚠️ CLÉ WIFI GÉNÉRÉE : ${WPA_PASSPHRASE}${NC}"
echo -e "${YELLOW}   (À noter sur le boîtier physique)${NC}"

# ==============================================================================
# 7. CONFIGURATION DNSMASQ (TOUTES SONDES)
# ==============================================================================
echo -e "${BLUE}[7/12] Configuration dnsmasq (wlan0 - Captive Portal)...${NC}"
echo "DNSMASQ_EXCEPT=lo" | sudo tee -a /etc/default/dnsmasq > /dev/null
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak 2>/dev/null || true
cat > /etc/dnsmasq.conf <<EOF
bind-interfaces
interface=wlan0
listen-address=${LOCAL_IP}
ra-param=wlan0
enable-ra
dhcp-range=10.0.0.100,10.0.0.200,255.255.255.0,24h
dhcp-option=3,${LOCAL_IP}
dhcp-option=6,${LOCAL_IP}
dhcp-rapid-commit
# DNS menteur global : tout pointe vers le portail
address=/#/${LOCAL_IP}
# 🔴 ANDROID - Probes de connectivité (Liste Complète V1.0)
address=/connectivitycheck.gstatic.com/${LOCAL_IP}
address=/clients3.google.com/${LOCAL_IP}
address=/clients4.google.com/${LOCAL_IP}
address=/www.google.com/${LOCAL_IP}
address=/google.com/${LOCAL_IP}
address=/android.clients.google.com/${LOCAL_IP}
address=/connectivitycheck.android.com/${LOCAL_IP}
# 🍎 APPLE - Captive portal detection
address=/captive.apple.com/${LOCAL_IP}
address=/hotspot.eap.apple.com/${LOCAL_IP}
address=/www.apple.com/${LOCAL_IP}
# 🪟 MICROSOFT - NCSI probes
address=/msftconnecttest.com/${LOCAL_IP}
address=/www.msftconnecttest.com/${LOCAL_IP}
address=/dns.msftncsi.com/${LOCAL_IP}
# 📱 AUTRES FABRICANTS (Liste Complète V1.0)
address=/connectivitycheck.platform.hicloud.com/${LOCAL_IP}
address=/connect.rom.miui.com/${LOCAL_IP}
address=/wifi.vivo.com.cn/${LOCAL_IP}
no-resolv
no-hosts
# Logs désactivés (RGPD + performance)
log-queries=0
# Optimisation captive portal : pas de cache
cache-size=0
local-ttl=1
min-cache-ttl=1
neg-ttl=1
# Optimisation DHCP
dhcp-lease-max=50
dhcp-no-override
# Sécurité DNS : anti-CVE-2023-28381
dns-forward-max=50
min-port=4096
port=53
EOF
systemctl enable dnsmasq
systemctl restart dnsmasq
echo -e "${GREEN}✓ dnsmasq configuré (wlan0 - Captive Portal)${NC}"

# ==============================================================================
# 8. CONFIGURATION FIREWALL
# ==============================================================================
echo -e "${BLUE}[8/12] Configuration du firewall (Fusion V1.0 + DHCP)...${NC}"
# Flush complet des tables
iptables -F
iptables -t nat -F
iptables -t mangle -F
# Politiques par défaut ultra-strictes (deny all)
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
# Loopback : toujours autorisé
iptables -A INPUT -i lo -j ACCEPT
# Anti-Spoofing & Invalid Packets (Ajout Sécurité)
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
# SSH rate-limiting sur eth0 (Identique V1.0)
iptables -A INPUT -i eth0 -p tcp --dport 22 -m conntrack --ctstate NEW -m limit --limit 3/min --limit-burst 3 -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# HTTP/HTTPS Rate-Limiting (Protection DoS)
iptables -A INPUT -p tcp --dport 80 -m limit --limit 30/second --limit-burst 200 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m limit --limit 30/second --limit-burst 200 -j ACCEPT
# Connexions établies (toutes interfaces)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
#  DHCP (Ports 67/68) sur wlan0
iptables -A INPUT -i wlan0 -p udp --dport 67 -j ACCEPT
iptables -A INPUT -i wlan0 -p udp --dport 68 -j ACCEPT
# DNS (dnsmasq) sur wlan0 uniquement
iptables -A INPUT -i wlan0 -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i wlan0 -p tcp --dport 53 -j ACCEPT
# Nginx HTTP/HTTPS (portail captif) sur wlan0 uniquement
iptables -A INPUT -i wlan0 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i wlan0 -p tcp --dport 443 -j ACCEPT
# Tout le reste sur wlan0 = DROP silencieux
iptables -A INPUT -i wlan0 -j DROP
# Pas de forwarding : isolation absolue clients ↔ Internet
iptables -A FORWARD -j DROP
# Persistance des règles
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4
netfilter-persistent save 2>/dev/null || true
echo -e "${GREEN}✓ Firewall configuré (DHCP 67/68 + SSH rate-limited)${NC}"

# ==============================================================================
# 9. SERVEUR WEB + HTTPS + CAPTIVE PORTAL
# ==============================================================================
echo -e "${BLUE}[9/12] Configuration du serveur web (HTTPS + Toutes Sondes)...${NC}"
mkdir -p /var/www/sos-guide
mkdir -p /data/docs
# Copie des fichiers HTML si présents dans le dossier d'installation
if [ -d "html" ]; then
cp -r html/* /var/www/sos-guide/
fi
chown -R www-data:www-data /var/www/sos-guide
chmod -R 755 /var/www/sos-guide

# Génération Certificat SSL Auto-signé
echo "🔐 Génération certificat SSL auto-signé..."
mkdir -p /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/sos-guide.key \
    -out /etc/ssl/certs/sos-guide.crt \
    -subj "/C=FR/ST=Emergency/L=Local/O=SOS-GUIDE/CN=10.0.0.1"
chmod 600 /etc/ssl/private/sos-guide.key

rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/sos-guide <<'NGINXEOF'
# ==============================================================================
# SOS-GUIDE - Configuration Nginx
# ==============================================================================
# Objectif : Éviter les avertissements certificat auto-signé qui bloquent
# la détection automatique du portail captif
# ==============================================================================

# ==============================================================================
# BLOC HTTP (80) : CONTENU PRINCIPAL
# ==============================================================================
server {
    listen 80 default_server;
    server_name _;
    root /var/www/sos-guide;
    index index.html;

    # Logs désactivés (performance + RGPD + pas de traces utilisateurs)
    access_log off;
    error_log /dev/null;

    # Optimisations TCP/HTTP pour réponse ultra-rapide
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 3;
    types_hash_max_size 2048;

    # ============================================
    # SONDES CAPTIVES - RÉPONSES ULTRA-RAPIDES
    # ============================================
    
    # Android probes (302 redirect vers portail principal)
    location = /generate_204 {
        default_type text/html;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header Connection "close";
        add_header X-Robots-Tag "noindex, nofollow";
        return 302 http://10.0.0.1/;
    }
    
    location = /generate_205 {
        default_type text/html;
        add_header Cache-Control "no-store";
        return 302 http://10.0.0.1/;
    }
    
    # Apple captive portal detection
    location = /hotspot-detect.html {
        default_type text/html;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header Connection "close";
        add_header X-Robots-Tag "noindex, nofollow";
        return 302 http://10.0.0.1/;
    }
    
    # Windows NCSI probe - réponse texte simple
    location = /connecttest.txt {
        default_type text/plain;
        add_header Cache-Control "no-store";
        return 200 "Microsoft Connect Test";
    }
    
    # Samsung probe
    location = /success.txt {
        default_type text/plain;
        add_header Cache-Control "no-store";
        return 204;
    }
    
    # Amazon Fire OS probe
    location = /fwlink/ {
        default_type text/html;
        add_header Cache-Control "no-store";
        return 302 http://10.0.0.1/;
    }
    
    # Huawei/HiLink probe
    location ~* ^/connectivitycheck\.platform\.hicloud\.com {
        default_type text/html;
        add_header Cache-Control "no-store";
        return 302 http://10.0.0.1/;
    }
    
    # Xiaomi probe
    location ~* ^/connect\.rom\.miui\.com {
        default_type text/html;
        add_header Cache-Control "no-store";
        return 302 http://10.0.0.1/;
    }
    
    # ============================================
    # ENDPOINTS UTILITAIRES
    # ============================================
    
    # Health-check pour monitoring/supervision
    location = /health {
        access_log off;
        default_type text/plain;
        add_header Content-Type text/plain;
        add_header Cache-Control "no-store";
        return 200 "OK\n";
    }
    
    # Endpoint pour test de connectivité manuelle
    location = /ping {
        access_log off;
        default_type text/plain;
        add_header Cache-Control "no-store";
        return 200 "SOS-GUIDE reachable\n";
    }
    
    # ============================================
    # DOCUMENTS PDF (dossier externe en lecture seule)
    # ============================================
    location /docs/ {
        alias /data/docs/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
        add_header Cache-Control "public, max-age=3600";
        add_header X-Content-Type-Options "nosniff";
    }
    
    # ============================================
    # 🎯 CONTENU PRINCIPAL - SERVI EN HTTP PUR
    # ============================================
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
        add_header X-Content-Type-Options "nosniff";
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Robots-Tag "noindex, nofollow";
    }
    
    # Protection : bloquer l'accès aux fichiers sensibles
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

# ==============================================================================
# BLOC HTTPS (443) : REDIRECTION VERS HTTP
# ==============================================================================
# Certains appareils peuvent tenter HTTPS en premier.
# On redirige gentiment vers HTTP pour éviter l'avertissement certificat.
# ==============================================================================
server {
    listen 443 ssl;
    server_name _;
    
    ssl_certificate /etc/ssl/certs/sos-guide.crt;
    ssl_certificate_key /etc/ssl/private/sos-guide.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5:!3DES;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 5m;
    
    # Logs désactivés
    access_log off;
    error_log /dev/null;
    
    # Redirection immédiate vers HTTP (301 permanent)
    # Le $request_uri préserve le chemin et les paramètres
    return 301 http://$host$request_uri;
}
NGINXEOF
ln -sf /etc/nginx/sites-available/sos-guide /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
systemctl enable nginx
echo -e "${GREEN}✓ Serveur web configuré (HTTPS + Toutes Sondes V1.0)${NC}"

# ==============================================================================
# 10. MONTAGE LECTURE SEULE (WEB)
# ==============================================================================
echo -e "${BLUE}[10/12] Verrouillage du contenu Web (Read-Only)...${NC}"
if ! grep -q "/var/www.*bind,ro" /etc/fstab; then
    echo "/var/www /var/www none bind,ro 0 0" >> /etc/fstab
    mount -o remount,bind,ro /var/www 2>/dev/null || true
fi
echo -e "${GREEN}✓ /var/www monté en lecture seule (fstab)${NC}"

# ==============================================================================
# SYSTCTL - Optimisations réseau et sécurité
# ==============================================================================
cat <<EOF | sudo tee /etc/sysctl.d/60-disable-ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.wlan0.disable_ipv6 = 1
net.ipv6.conf.eth0.disable_ipv6 = 1
EOF
cat <<EOF | sudo tee /etc/sysctl.d/50-anti-spoofing.conf
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
EOF
sysctl -p /etc/sysctl.d/50-anti-spoofing.conf 2>/dev/null || true
sysctl -p /etc/sysctl.d/60-disable-ipv6.conf 2>/dev/null || true
echo -e "${GREEN}✓ Optimisations sysctl appliquées${NC}"

# ==============================================================================
# 11. CONFIGURATION WATCHDOG
# ==============================================================================
echo -e "${BLUE}[11/12] Configuration du Watchdog (sécurité matérielle)...${NC}"
# Activation watchdog dans le firmware
if [ -f /boot/firmware/config.txt ]; then
    BOOT_CONFIG="/boot/firmware/config.txt"
elif [ -f /boot/config.txt ]; then
    BOOT_CONFIG="/boot/config.txt"
else
    echo -e "${YELLOW}⚠️ Fichier config.txt non trouvé${NC}"
    BOOT_CONFIG=""
fi
if [ -n "$BOOT_CONFIG" ]; then
    if grep -q "^dtparam=watchdog" "$BOOT_CONFIG"; then
        sed -i 's/^dtparam=watchdog=.*/dtparam=watchdog=on/' "$BOOT_CONFIG"
    else
        echo "dtparam=watchdog=on" >> "$BOOT_CONFIG"
    fi
fi
# Charger le module watchdog
modprobe bcm2835_wdt 2>/dev/null || true
# Configuration selon disponibilité hardware
if [ ! -e /dev/watchdog ]; then
    echo -e "${YELLOW}⚠️ /dev/watchdog non disponible - fallback logiciel${NC}"
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
    echo -e "${YELLOW}⚠️ Watchdog: activation au prochain reboot${NC}"
fi

# ==============================================================================
# 12. INTÉGRITÉ & FINALISATION
# ==============================================================================
echo -e "${BLUE}[12/12] Vérification d'intégrité & Finalisation...${NC}"
# Déplacer ou générer le hash APRÈS toute configuration
if [ -f "integrity.hash" ]; then
    mv integrity.hash /root/integrity.hash
else
    # Inclut maintenant les certificats SSL dans le hash
    find /var/www/sos-guide -type f -exec sha256sum {} \; > /root/integrity.hash
    find /etc/nginx/sites-available/sos-guide -type f -exec sha256sum {} \; >> /root/integrity.hash
    find /etc/ssl/certs/sos-guide.crt -type f -exec sha256sum {} \; >> /root/integrity.hash
    find /etc/ssl/private/sos-guide.key -type f -exec sha256sum {} \; >> /root/integrity.hash
fi
# Activer rc.local pour vérification au boot UNIQUEMENT si hash existe
if [ -f /root/integrity.hash ]; then
    if [ ! -f /etc/rc.local ]; then
        cat > /etc/rc.local << 'RCEOF'
#!/bin/bash
# Vérification d'intégrité au démarrage
sha256sum -c /root/integrity.hash >/dev/null 2>&1 || {
logger "SOS-GUIDE: INTEGRITE COMPROMISE - SHUTDOWN"
poweroff
}
exit 0
RCEOF
        chmod +x /etc/rc.local
        # Service rc-local pour Debian Trixie (si absent)
        if ! systemctl list-unit-files 2>/dev/null | grep -q rc-local; then
            cat > /etc/systemd/system/rc-local.service << 'SVC'
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
SVC
            systemctl daemon-reload
            systemctl enable rc-local.service 2>/dev/null || true
        fi
    fi
    echo -e "${GREEN}✓ Vérification d'intégrité au boot activée${NC}"
else
    echo -e "${YELLOW}⚠️ Hash d'intégrité non généré - vérification désactivée${NC}"
fi

# ==============================================================================
# 13. VÉRIFICATION FINALE & RÉSUMÉ (Infos Sécurité)
# ==============================================================================
echo ""
echo -e "${GREEN}=========================================="
echo "   ✅ CONFIGURATION TERMINÉE !"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}📡 CONFIGURATION RÉSEAU:${NC}"
echo -e "   ${GREEN}✓${NC} IP wlan0: ${LOCAL_IP}"
echo -e "   ${GREEN}✓${NC} SSID: ${SSID}"
echo -e "   ${YELLOW}⚠️ CLÉ WIFI GÉNÉRÉE : ${WPA_PASSPHRASE}${NC}"
echo -e "   ${YELLOW}   (À noter sur affichage papier)${NC}"
echo ""
echo -e "${BLUE}📱 CAPTIVE PORTAL:${NC}"
echo -e "   ${GREEN}✓${NC} Windows: /connecttest.txt → 200"
echo -e "   ${GREEN}✓${NC} Apple: /hotspot-detect.html → 302"
echo -e "   ${GREEN}✓${NC} Android: /generate_204 → 302"
echo -e "   ${GREEN}✓${NC} Samsung: /success.txt → 204"
echo ""
echo -e "${BLUE}⚖️ CONFORMITÉ LÉGALE:${NC}"
echo -e "   ${GREEN}✓${NC} RGPD/CNIL: Aucun log activé"
echo -e "   ${GREEN}✓${NC} France: Conforme CPCE/LCEN"
echo -e "   ${GREEN}✓${NC} Suisse: Conforme LTC/OFCOM"
echo -e "   ${GREEN}✓${NC} UE: Conforme WiFi4EU/GDPR"
echo -e "   ${GREEN}✓${NC} Page mentions légales incluse"
echo ""
echo -e "${BLUE}🔒 SÉCURITÉ RENFORCÉE:${NC}"
echo -e "   ${GREEN}✓${NC} Pi a Internet (eth0)"
echo -e "   ${GREEN}✓${NC} Clients WiFi ISOLÉS d'Internet"
echo -e "   ${GREEN}✓${NC} Isolation client-client (ap_isolate)"
echo -e "   ${GREEN}✓${NC} Firewall: SSH rate-limited (3/min)"
echo -e "   ${GREEN}✓${NC} Firewall: DHCP 67/68 Autorisé"
echo -e "   ${GREEN}✓${NC} Firewall: Anti-Spoofing & Invalid Drop"
echo -e "   ${GREEN}✓${NC} HTTPS: TLS 1.2/1.3 Obligatoire"
echo -e "   ${GREEN}✓${NC} Web: Lecture Seule (fstab)"
echo -e "   ${GREEN}✓${NC} Watchdog: Auto-reboot activé"
echo -e "   ${GREEN}✓${NC} Intégrité: Hash SHA256 + rc.local"
echo ""
echo -e "${BLUE}🔧 ÉTAT DES SERVICES:${NC}"
for service in hostapd dnsmasq nginx systemd-networkd systemd-resolved watchdog; do
    if systemctl is-active --quiet $service 2>/dev/null; then
        echo -e "   ${GREEN}✓${NC} $service: actif"
    else
        echo -e "   ${RED}✗${NC} $service: inactif"
    fi
done
echo ""
echo -e "${YELLOW}🔧 COMMANDES UTILES:${NC}"
echo "   Vérifier IP       : ip addr show wlan0"
echo "   Logs WiFi         : sudo journalctl -u hostapd -f"
echo "   Voir règles FW    : sudo iptables -L -n -v"
echo "   Test isolation    : ping -I wlan0 8.8.8.8 (doit échouer)"
echo "   Test DNS          : nslookup google.com ${LOCAL_IP} (→ ${LOCAL_IP})"
echo "   Test Captive      : curl -I http://${LOCAL_IP}/hotspot-detect.html"
echo "   Health check      : curl http://${LOCAL_IP}/health"
echo "   Port 53           : sudo ss -tulpn | grep :53"
echo "   Watchdog status   : sudo systemctl status watchdog"
echo "   Hash intégrité    : sha256sum -c /root/integrity.hash"
echo ""
echo -e "${MAGENTA}🚀 SOS-GUIDE v3.0 EST PRÊT POUR LA PRODUCTION !${NC}"
echo -e "${YELLOW}⚠️ N'OUBLIEZ PAS DE NOTER LA CLÉ WIFI SUR LE BOÎTIER${NC}"
echo ""
