#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# SOS-GUIDE - INSTALLATION MINIMALE & FONCTIONNELLE
# Version 4.1 - Production Ready
# ═══════════════════════════════════════════════════════════════
set -u
# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════
readonly IP_GATEWAY="10.0.0.1"
readonly HOSTNAME_CUSTOM="sosguide"
readonly GUIDE_DIR="/opt/sosguide"
readonly WEB_ROOT="/var/www/html"
readonly LOG_FILE="/var/log/sosguide-install.log"
SSID_DEFAULT="⛑️ SOS-GUIDE"
WIFI_COUNTRY="FR"
WIFI_CHANNEL="6"
WIFI_IFACE="wlan0"
# Couleurs
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GREEN}[+]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"; exit 1; }
# ═══════════════════════════════════════════════════════════════
# VÉRIFICATIONS
# ═══════════════════════════════════════════════════════════════
check_root() { [ "$EUID" -ne 0 ] && error "Exécuter en root: sudo ./install.sh"; }
check_internet() {
ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1 || error "Internet requis sur eth0"
log "✅ Internet OK"
}
# ═══════════════════════════════════════════════════════════════
# CONFIGURATION INTERACTIVE
# ═══════════════════════════════════════════════════════════════
ask_config() {
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  SOS-GUIDE - CONFIGURATION                                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
read -e -p "SSID Wi-Fi [défaut: $SSID_DEFAULT] : " -i "$SSID_DEFAULT" ssid_input
SSID_CUSTOM="$ssid_input"
read -e -p "Code Pays [défaut: $WIFI_COUNTRY] : " -i "$WIFI_COUNTRY" country_input
WIFI_COUNTRY="$country_input"
# CHOIX DU CANAL
echo -e "${YELLOW}Canaux recommandés (2.4GHz): 1, 6, 11${NC}"
read -e -p "Canal Wi-Fi [défaut: $WIFI_CHANNEL] : " -i "$WIFI_CHANNEL" channel_input
WIFI_CHANNEL="$channel_input"
}
# ═══════════════════════════════════════════════════════════════
# INSTALLATION
# ═══════════════════════════════════════════════════════════════
install_packages() {
log "📦 Installation des paquets..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq hostapd dnsmasq lighttpd dhcpcd iptables-persistent
log "✅ Paquets installés"
}
setup_directories() {
log "📁 Création des répertoires..."
mkdir -p "$GUIDE_DIR"/{logs,backups} "$WEB_ROOT" /var/lib/misc
touch /var/lib/misc/dnsmasq.leases
chmod 666 /var/lib/misc/dnsmasq.leases
# Fichiers portail captif
echo -n "" > "$WEB_ROOT/generate_204"
echo '<html><meta http-equiv="refresh" content="0;url=http://10.0.0.1/"/></html>' > "$WEB_ROOT/hotspot-detect.html"
echo '{"captive":true}' > "$WEB_ROOT/captive.json"
chown -R www-data "$WEB_ROOT"
log "✅ Répertoires créés"
}
configure_hostname() {
echo "$HOSTNAME_CUSTOM" > /etc/hostname
sed -i "s/raspberrypi/$HOSTNAME_CUSTOM/g" /etc/hosts 2>/dev/null || true
hostname "$HOSTNAME_CUSTOM"
log "✅ Hostname: $HOSTNAME_CUSTOM"
}
configure_network() {
log "🌐 Configuration réseau..."
cp /etc/dhcpcd.conf "$GUIDE_DIR/backups/dhcpcd.conf.bak" 2>/dev/null || true
sed -i '/^interface wlan0/,/^$/d' /etc/dhcpcd.conf
cat >> /etc/dhcpcd.conf << EOF
# SOS-GUIDE
interface $WIFI_IFACE
static ip_address=$IP_GATEWAY/24
nohook wpa_supplicant
EOF
log "✅ IP statique: $IP_GATEWAY/24"
}
configure_hostapd() {
log "📡 Configuration Wi-Fi..."
# CRITIQUE: Débloquer Wi-Fi
rfkill unblock wlan
cp /etc/hostapd/hostapd.conf "$GUIDE_DIR/backups/hostapd.conf.bak" 2>/dev/null || true
cat > /etc/hostapd/hostapd.conf << EOF
interface=$WIFI_IFACE
driver=nl80211
ssid=$SSID_CUSTOM
country_code=$WIFI_COUNTRY
hw_mode=g
channel=$WIFI_CHANNEL
wmm_enabled=1
ap_isolate=1
EOF
# CRITIQUE: Variable DAEMON_CONF
echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' > /etc/default/hostapd
# Désactiver conflits
systemctl stop wpa_supplicant NetworkManager 2>/dev/null || true
systemctl disable wpa_supplicant NetworkManager 2>/dev/null || true
systemctl unmask hostapd 2>/dev/null || true
systemctl enable hostapd
log "✅ hostapd configuré (Canal: $WIFI_CHANNEL)"
}
configure_dnsmasq() {
log "🔖 Configuration DNS/DHCP..."
# CRITIQUE: Désactiver systemd-resolved (conflit port 53)
systemctl stop systemd-resolved 2>/dev/null || true
systemctl disable systemd-resolved 2>/dev/null || true
cp /etc/dnsmasq.conf "$GUIDE_DIR/backups/dnsmasq.conf.bak" 2>/dev/null || true
cat > /etc/dnsmasq.conf << EOF
interface=$WIFI_IFACE
bind-interfaces
dhcp-range=10.0.0.10,10.0.0.100,255.255.255.0,24h
dhcp-leasefile=/var/lib/misc/dnsmasq.leases
dhcp-option=3,$IP_GATEWAY
dhcp-option=6,$IP_GATEWAY
address=/#/10.0.0.1
no-resolv
log-facility=$GUIDE_DIR/logs/dnsmasq.log
EOF
# CRITIQUE: Override systemd avec délai
mkdir -p /etc/systemd/system/dnsmasq.service.d
cat > /etc/systemd/system/dnsmasq.service.d/override.conf << 'EOF'
[Unit]
After=hostapd.service
Wants=hostapd.service
[Service]
ExecStartPre=/bin/sleep 3
EOF
systemctl daemon-reload
systemctl enable dnsmasq
log "✅ dnsmasq configuré (systemd-resolved désactivé)"
}
configure_lighttpd() {
log "🌍 Configuration serveur web..."
cat > /etc/lighttpd/lighttpd.conf << 'EOF'
server.document-root = "/var/www/html"
server.port = 80
server.username = "www-data"
server.groupname = "www-data"
index-file.names = ( "index.html" )
server.errorlog = "/var/log/lighttpd/error.log"
accesslog.filename = "/var/log/lighttpd/access.log"
server.modules = ( "mod_access", "mod_accesslog" )
EOF
systemctl enable lighttpd
log "✅ lighttpd configuré"
}
configure_firewall() {
log "🔥 Configuration pare-feu..."
iptables -F
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -i $WIFI_IFACE -p udp --dport 67:68 -j ACCEPT
iptables -A INPUT -i $WIFI_IFACE -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i $WIFI_IFACE -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i $WIFI_IFACE -p icmp -j ACCEPT
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4
log "✅ Pare-feu configuré"
}
create_scripts() {
log "🔧 Scripts utilitaires..."
cat > "$GUIDE_DIR/uninstall.sh" << 'EOF'
#!/bin/bash
systemctl stop hostapd dnsmasq lighttpd
systemctl disable hostapd dnsmasq lighttpd
systemctl enable systemd-resolved 2>/dev/null
rm -rf /opt/sosguide /var/www/html/*
apt-get install --reinstall -y hostapd dnsmasq lighttpd dhcpcd 2>/dev/null
echo "✅ Désinstallé. Redémarrez: sudo reboot"
EOF
chmod +x "$GUIDE_DIR/uninstall.sh"
cat > "$GUIDE_DIR/enable-ssh.sh" << 'EOF'
#!/bin/bash
systemctl enable ssh && systemctl start ssh
echo "✅ SSH activé"
EOF
chmod +x "$GUIDE_DIR/enable-ssh.sh"
log "✅ Scripts créés"
}
validate() {
log "🔍 Validation..."
sleep 5
local pass=0 fail=0
for svc in hostapd dnsmasq lighttpd; do
if systemctl is-active --quiet $svc; then
echo -e "  ${GREEN}●${NC} $svc OK"
((pass++))
else
echo -e "  ${RED}●${NC} $svc ÉCHEC"
((fail++))
fi
done
log "Résultats: $pass OK | $fail échec"
return $fail
}
show_summary() {
clear
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ SOS-GUIDE INSTALLÉ                                       ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${NC}║  📡 Wi-Fi: ${SSID_CUSTOM}"
echo -e "${NC}║  📶 Canal: ${WIFI_CHANNEL}"
echo -e "${NC}║  🌐 URL: http://10.0.0.1"
echo -e "${NC}║  🔒 Isolation: ACTIVÉE"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${YELLOW}║  ⚠️  À FAIRE :                                               ║${NC}"
echo -e "${NC}║  1. sudo reboot"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
}
# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════
main() {
echo -e "${GREEN}SOS-GUIDE - Installation${NC}"
check_root
> "$LOG_FILE"
log "Début installation: $(date)"
check_internet
ask_config
install_packages
setup_directories
configure_hostname
configure_network
configure_hostapd
configure_dnsmasq
configure_lighttpd
configure_firewall
create_scripts
# Démarrage avec délais
log "🚀 Démarrage services..."
systemctl restart dhcpcd
sleep 2
systemctl restart hostapd
sleep 3
systemctl restart dnsmasq
sleep 2
systemctl restart lighttpd
validate
show_summary
log "Installation terminée"
}
main "$@"
