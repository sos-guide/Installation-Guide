#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                  SOS-GUIDE — Installation                                   ║
# ║                  Raspberry Pi OS — Production                                ║
# ║                  Version 3.1 (avec contenu.json)                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

# ── Couleurs & helpers ────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'

ok()   { echo -e "  ${GREEN}✔${NC}  $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "  ${RED}✘${NC}  $1"; }
section() { echo -e "\n${CYAN}${BOLD}▶ $1${NC}"; }

# ── Bannière ──────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
cat <<'BANNER'
  ╔══════════════════════════════════════════╗
  ║        SOS-GUIDE — Installation v3.1    ║
  ║        Portail captif offline            ║
  ╚══════════════════════════════════════════╝
BANNER
echo -e "${NC}"

# ── Vérifications initiales ───────────────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
    err "Ce script doit être exécuté en root (sudo bash install.sh)"
    exit 1
fi

if [ ! -f "index.html" ]; then
    err "Fichier index.html introuvable dans le répertoire courant"
    err "Lancez le script depuis le dossier contenant index.html"
    exit 1
fi

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ok "Répertoire source : $SRC_DIR"

# ── Détection des interfaces réseau ───────────────────────────────────────────
WIFI_IFACE=$(ip -o link show | awk -F': ' '/wl/{print $2; exit}')
ETH_IFACE=$(ip -o link show | awk -F': ' '/^[0-9]+: (en|eth)/{print $2; exit}')

if [ -z "$WIFI_IFACE" ]; then
    err "Aucune interface WiFi détectée — impossible de continuer"
    exit 1
fi
ok "Interface WiFi  : $WIFI_IFACE"
if [ -n "$ETH_IFACE" ]; then
    ok "Interface ETH   : $ETH_IFACE (SSH + admin)"
else
    warn "Aucune interface Ethernet — accès SSH indisponible"
fi

# ── Paquets ───────────────────────────────────────────────────────────────────
section "Installation des paquets"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq \
    nginx hostapd dnsmasq \
    iptables-persistent netfilter-persistent \
    systemd-resolved iw wireless-tools curl 
ok "Paquets installés"

# ── Désactivation des services conflictuels ───────────────────────────────────
section "Nettoyage des services conflictuels"
for svc in dhcpcd wpa_supplicant NetworkManager ModemManager avahi-daemon; do
    systemctl stop    "$svc" 2>/dev/null || true
    systemctl disable "$svc" 2>/dev/null || true
    systemctl mask    "$svc" 2>/dev/null || true
done
pkill -f wpa_supplicant 2>/dev/null || true
ok "Services conflictuels désactivés"

# ── Pays WiFi ─────────────────────────────────────────────────────────────────
rfkill unblock wifi 2>/dev/null || true
iw reg set FR
ok "Région WiFi : FR"

# ── Réseau systemd-networkd ───────────────────────────────────────────────────
section "Configuration réseau (systemd-networkd)"
systemctl unmask systemd-networkd
systemctl enable systemd-networkd

# Ethernet : DHCP simple (admin + internet si câblé)
if [ -n "$ETH_IFACE" ]; then
    cat > /etc/systemd/network/10-eth.network <<EOF
[Match]
Name=${ETH_IFACE}

[Network]
DHCP=yes
IPv6AcceptRA=no
MulticastDNS=yes
EOF
    ok "ETH $ETH_IFACE : DHCP activé"
fi

# WiFi : IP statique — point d'accès
cat > /etc/systemd/network/20-wlan-ap.network <<EOF
[Match]
Name=${WIFI_IFACE}

[Network]
Address=10.0.0.1/24
IPv6AcceptRA=no
EOF

systemctl restart systemd-networkd
sleep 2
ok "WiFi : IP statique 10.0.0.1/24 configurée"

# ── DNS système (systemd-resolved) ────────────────────────────────────────────
section "Configuration DNS système"
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/dns.conf <<EOF
[Resolve]
DNS=1.1.1.1 8.8.4.4
FallbackDNS=9.9.9.9
DNSStubListener=no
EOF
systemctl restart systemd-resolved
rm -f /etc/resolv.conf
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
ok "systemd-resolved : DNS 1.1.1.1, stub désactivé (pas de conflit port 53)"

# ── PowerSave WiFi — désactivation réelle ────────────────────────────────────
section "Désactivation PowerSave WiFi"
iw dev "${WIFI_IFACE}" set power_save off 2>/dev/null || true
ok "PowerSave WiFi désactivé (session courante)"

# Service systemd pour persister après chaque reboot
cat > /etc/systemd/system/wifi-powersave-off.service <<EOF
[Unit]
Description=Disable WiFi PowerSave for SOS-GUIDE
After=network.target hostapd.service

[Service]
Type=oneshot
ExecStart=/sbin/iw dev ${WIFI_IFACE} set power_save off
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable wifi-powersave-off
ok "Service wifi-powersave-off créé et activé (persistant au reboot)"

# ── hostapd — point d'accès WiFi ─────────────────────────────────────────────
section "Configuration du point d'accès WiFi (hostapd)"
cat > /etc/hostapd/hostapd.conf <<EOF
interface=${WIFI_IFACE}
driver=nl80211
ssid=⛑️ SOS-GUIDE
hw_mode=g
channel=11
wmm_enabled=1
beacon_int=100
dtim_period=2
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

systemctl unmask hostapd
systemctl enable hostapd
systemctl restart hostapd
sleep 2

# Vérification que l'AP est bien actif
if systemctl is-active --quiet hostapd; then
    ok "SSID : SOS-GUIDE (ouvert, ap_isolate=1, canal 6)"
else
    err "hostapd a échoué — vérifiez : journalctl -u hostapd -n 30"
    exit 1
fi

# ── dnsmasq — DHCP + DNS wildcard ────────────────────────────────────────────
section "Configuration dnsmasq (DHCP + portail captif)"
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak 2>/dev/null || true
cat > /etc/dnsmasq.conf <<EOF
# Interface exclusive
interface=${WIFI_IFACE}
bind-interfaces
listen-address=10.0.0.1

# DHCP
dhcp-range=10.0.0.100,10.0.0.200,255.255.255.0,1h
dhcp-option=option:router,10.0.0.1
dhcp-option=option:dns-server,10.0.0.1
dhcp-option=option:netmask,255.255.255.0

# DNS wildcard — tout domaine → 10.0.0.1 (portail captif)
address=/#/10.0.0.1

# Pas de résolution externe (offline)
no-resolv
no-hosts
cache-size=0
EOF

systemctl enable dnsmasq
systemctl restart dnsmasq
sleep 1

if systemctl is-active --quiet dnsmasq; then
    ok "dnsmasq : DHCP 10.0.0.100-200, DNS wildcard → 10.0.0.1"
else
    err "dnsmasq a échoué — vérifiez : journalctl -u dnsmasq -n 30"
    exit 1
fi

# ── Firewall iptables ─────────────────────────────────────────────────────────
section "Configuration firewall iptables"
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  ACCEPT

# Loopback
iptables -A INPUT -i lo -j ACCEPT

# Connexions établies
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH : ETH uniquement
if [ -n "$ETH_IFACE" ]; then
    iptables -A INPUT -i "${ETH_IFACE}" -p tcp --dport 22 -j ACCEPT
    ok "SSH autorisé sur $ETH_IFACE uniquement"
else
    warn "Pas d'ETH — aucun accès SSH"
fi

# Portail captif sur WiFi
iptables -A INPUT -i "${WIFI_IFACE}" -p udp --dport 67 -j ACCEPT   # DHCP
iptables -A INPUT -i "${WIFI_IFACE}" -p udp --dport 53 -j ACCEPT   # DNS
iptables -A INPUT -i "${WIFI_IFACE}" -p tcp --dport 53 -j ACCEPT   # DNS/TCP
iptables -A INPUT -i "${WIFI_IFACE}" -p tcp --dport 80 -j ACCEPT   # HTTP
iptables -A INPUT -i "${WIFI_IFACE}" -p tcp --dport 443 -j ACCEPT  # HTTPS → redirigé

# Interception DNS (tous ports → 10.0.0.1)
iptables -t nat -A PREROUTING -i "${WIFI_IFACE}" -p udp --dport 53 \
    -j DNAT --to-destination 10.0.0.1
iptables -t nat -A PREROUTING -i "${WIFI_IFACE}" -p tcp --dport 53 \
    -j DNAT --to-destination 10.0.0.1

# HTTPS → HTTP (navigateurs modernes)
iptables -t nat -A PREROUTING -i "${WIFI_IFACE}" -p tcp --dport 443 \
    -j DNAT --to-destination 10.0.0.1:80

# Isolation totale : clients WiFi ne peuvent pas aller ailleurs
iptables -A FORWARD -i "${WIFI_IFACE}" -j DROP

# Sauvegarde persistante
netfilter-persistent save
ok "Firewall : WiFi isolé, SSH ETH seul, HTTPS redirigé"

# ── Contenu web ───────────────────────────────────────────────────────────────
section "Installation du contenu web"
WEB_DIR="/var/www/sos-guide"
mkdir -p "$WEB_DIR"

# Copie des fichiers
cp index.html "$WEB_DIR/"
if [ -f "contenu.json" ]; then
    cp contenu.json "$WEB_DIR/"
    ok "contenu.json copié"
else
    warn "contenu.json non trouvé, l'application utilisera le contenu par défaut"
fi

# Permissions
chown -R www-data:www-data "$WEB_DIR"
find "$WEB_DIR" -type d -exec chmod 755 {} \;
find "$WEB_DIR" -type f -exec chmod 644 {} \;
ok "Contenu copié dans $WEB_DIR"

FILE_COUNT=$(find "$WEB_DIR" -type f | wc -l)
ok "$FILE_COUNT fichier(s) installé(s)"

# ── nginx — serveur web ───────────────────────────────────────────────────────
section "Configuration nginx"
cat > /etc/nginx/sites-available/sos-guide <<'NGINXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    root  /var/www/sos-guide;
    index index.html;

    charset utf-8;

    sendfile       on;
    tcp_nopush     on;
    tcp_nodelay    on;
    keepalive_timeout 30;
    client_max_body_size 1M;

    gzip              on;
    gzip_vary         on;
    gzip_comp_level   5;
    gzip_min_length   256;
    gzip_types
        text/css
        text/plain
        text/xml
        application/json
        application/javascript
        image/svg+xml;

    # Portail captif — détection multi-OS
    location = /hotspot-detect.html {
        return 302 http://10.0.0.1/;
    }
    location = /library/test/success.html {
        return 302 http://10.0.0.1/;
    }
    location = /generate_204 {
        return 204;
    }
    location = /gen_204 {
        return 204;
    }
    location = /connecttest.txt {
        add_header Content-Type text/plain;
        return 200 "Microsoft Connect Test";
    }
    location = /ncsi.txt {
        add_header Content-Type text/plain;
        return 200 "Microsoft NCSI";
    }
    location = /canonical.html {
        return 302 http://10.0.0.1/;
    }

    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff2?|ttf|eot|otf|webp)$ {
        expires 7d;
        add_header Cache-Control "public, must-revalidate";
        add_header X-Content-Type-Options nosniff;
    }

    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
    }
}
NGINXEOF

# Activation
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/sos-guide /etc/nginx/sites-enabled/sos-guide

nginx -t
systemctl enable nginx
systemctl restart nginx
ok "Nginx configuré et actif"

# ── Optimisations système ─────────────────────────────────────────────────────
section "Optimisations système"

cat > /etc/sysctl.d/99-sos-guide.conf <<EOF
net.ipv6.conf.all.disable_ipv6     = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6      = 1
net.ipv4.conf.all.send_redirects    = 0
net.ipv4.conf.default.send_redirects= 0
net.ipv4.conf.all.accept_redirects  = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOF
sysctl -p /etc/sysctl.d/99-sos-guide.conf >/dev/null 2>&1 || true
ok "sysctl : IPv6 désactivé, sécurité réseau renforcée"

if command -v tvservice &>/dev/null; then
    tvservice -o 2>/dev/null && ok "HDMI désactivé (économie énergie)" || true
fi

# ── Tests de validation ───────────────────────────────────────────────────────
section "Tests de validation"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 http://10.0.0.1/ 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" ]]; then
    ok "HTTP 200 sur http://10.0.0.1/ ✔"
else
    warn "HTTP $HTTP_CODE sur http://10.0.0.1/ — vérifiez nginx"
fi

if [ -f "$WEB_DIR/index.html" ]; then
    ok "index.html présent dans $WEB_DIR"
else
    err "index.html absent de $WEB_DIR"
fi

if systemctl is-active --quiet hostapd; then
    ok "hostapd : actif"
else
    err "hostapd : inactif — vérifiez journalctl -u hostapd"
fi

if systemctl is-active --quiet dnsmasq; then
    ok "dnsmasq : actif"
else
    err "dnsmasq : inactif — vérifiez journalctl -u dnsmasq"
fi

FWD_RULES=$(iptables -L FORWARD -n 2>/dev/null | grep -c "DROP" || echo "0")
if [ "$FWD_RULES" -gt 0 ]; then
    ok "Isolation WiFi : règle FORWARD DROP présente ($FWD_RULES règle(s))"
else
    err "ALERTE : aucune règle DROP sur FORWARD — isolation absente"
fi

# ── Résumé final ──────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║        Installation SOS-GUIDE terminée !             ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  📡  WiFi         : ${BOLD}SOS-GUIDE${NC} (réseau ouvert)"
echo -e "  🌐  Portail      : ${BOLD}http://10.0.0.1/${NC}"
echo -e "  🔒  Isolation    : clients WiFi isolés d'Internet et entre eux"

if [ -n "$ETH_IFACE" ]; then
    ETH_IP=$(ip -4 addr show "$ETH_IFACE" 2>/dev/null \
        | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1 || echo "non attribuée")
    echo -e "  🔧  SSH (IP)     : ${BOLD}ssh pi@${ETH_IP}${NC}"
fi

echo ""
echo -e "${YELLOW}${BOLD}Sécurité obligatoire :${NC}"
echo -e "  ${YELLOW}▸ Changez le mot de passe : ${BOLD}passwd${NC}"
echo -e "  ${YELLOW}▸ Contenu web : ${BOLD}/var/www/sos-guide/${NC}"
echo -e "  ${YELLOW}▸ Logs nginx  : ${BOLD}journalctl -u nginx -f${NC}"
echo -e "  ${YELLOW}▸ Logs hostapd: ${BOLD}journalctl -u hostapd -f${NC}"
echo ""
