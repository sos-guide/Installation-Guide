#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# SOS-GUIDE - INSTALLATION
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

# Dossier source HTML (relatif au script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HTML_SOURCE="$SCRIPT_DIR/html"

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
    apt-get install -y -qq hostapd dnsmasq lighttpd dhcpcd iptables-persistent logrotate
    log "✅ Paquets installés"
}

setup_directories() {
    log "📁 Création des répertoires..."
    mkdir -p "$GUIDE_DIR"/{logs,backups} "$WEB_ROOT" /var/lib/misc
    touch /var/lib/misc/dnsmasq.leases
    chmod 666 /var/lib/misc/dnsmasq.leases
    log "✅ Répertoires créés"
}

deploy_web_content() {
    log "📄 Déploiement du contenu web..."
    
    # ✅ FICHIERS PORTAIL CAPTIF - REDIRECTION VERS index.html
    cat > "$WEB_ROOT/generate_204" << 'EOF'
<html><meta http-equiv="refresh" content="0;url=http://10.0.0.1/index.html"/></html>
EOF

    cat > "$WEB_ROOT/hotspot-detect.html" << 'EOF'
<html><meta http-equiv="refresh" content="0;url=http://10.0.0.1/index.html"/></html>
EOF

    cat > "$WEB_ROOT/captive.json" << 'EOF'
{"captive":true}
EOF

    # ✅ FICHIERS DE DÉTECTION SYSTÈME (réponse "OK" pour code 200)
    echo -n "OK" > "$WEB_ROOT/success.txt"
    echo -n "OK" > "$WEB_ROOT/canonical.html"
    echo -n "OK" > "$WEB_ROOT/nm-check.txt"
    echo -n "OK" > "$WEB_ROOT/connectivity.txt"
    echo -n "OK" > "$WEB_ROOT/generate_204"

    # Copie du contenu HTML personnalisé si présent
    if [ -d "$HTML_SOURCE" ] && [ "$(ls -A "$HTML_SOURCE" 2>/dev/null)" ]; then
        cp -r "$HTML_SOURCE"/. "$WEB_ROOT"/
        log "✅ Contenu copié depuis $HTML_SOURCE"
    else
        # Page par défaut si aucun contenu fourni
        cat > "$WEB_ROOT/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>⛑️ SOS-GUIDE</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 8px; text-align: center; }
        .content { background: white; padding: 20px; margin-top: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .alert { background: #e74c3c; color: white; padding: 15px; border-radius: 4px; margin: 10px 0; }
        .info { background: #3498db; color: white; padding: 15px; border-radius: 4px; margin: 10px 0; }
        h1 { margin: 0; }
        h2 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        ul { line-height: 1.8; }
        .footer { text-align: center; margin-top: 20px; color: #7f8c8d; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="header">
        <h1>⛑️ SOS-GUIDE</h1>
        <p>Réseau d'Information d'Urgence</p>
    </div>
    <div class="content">
        <div class="alert">
            ⚠️ <strong>Mode Hors-Ligne Activé</strong> - Ce réseau est local et ne fournit pas d'accès Internet.
        </div>
        <div class="info">
            ℹ️ <strong>Informations Essentielles</strong> - Consultez les ressources disponibles ci-dessous.
        </div>
        <h2>📋 Ressources Disponibles</h2>
        <ul>
            <li>📍 Numéros d'urgence locaux</li>
            <li>🏥 Points de secours à proximité</li>
            <li>📢 Informations de la collectivité</li>
            <li>🔄 Mises à jour en temps réel</li>
        </ul>
        <h2>🔧 Informations Techniques</h2>
        <ul>
            <li>Passerelle: 10.0.0.1</li>
            <li>Réseau: Local isolé</li>
            <li>Statut: Opérationnel</li>
        </ul>
    </div>
    <div class="footer">
        <p>SOS-GUIDE v1.0 | Système Autonome d'Information</p>
    </div>
</body>
</html>
EOF
        log "✅ Page index.html par défaut créée"
    fi

    chown -R www-data:www-data "$WEB_ROOT"
    chmod 644 "$WEB_ROOT"/*.txt "$WEB_ROOT"/*.html "$WEB_ROOT"/*.json 2>/dev/null || true
    log "✅ Contenu web déployé"
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
ignore_broadcast_ssid=0
EOF

    echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' > /etc/default/hostapd

    systemctl stop wpa_supplicant NetworkManager 2>/dev/null || true
    systemctl disable wpa_supplicant NetworkManager 2>/dev/null || true
    systemctl unmask hostapd 2>/dev/null || true
    systemctl enable hostapd
    log "✅ hostapd configuré (Canal: $WIFI_CHANNEL)"
}

configure_dnsmasq() {
    log "🔖 Configuration DNS/DHCP..."
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

    log "🕒 Création du script d'attente pour l'interface $WIFI_IFACE..."
    cat > /usr/local/bin/wait-for-wlan0.sh << 'EOF'
#!/bin/bash
for i in {1..30}; do
    if ip link show wlan0 >/dev/null 2>&1; then
        if ip addr show wlan0 | grep -q "10.0.0.1/24"; then
            exit 0
        fi
    fi
    sleep 1
done
exit 1
EOF
    chmod +x /usr/local/bin/wait-for-wlan0.sh

    mkdir -p /etc/systemd/system/dnsmasq.service.d
    cat > /etc/systemd/system/dnsmasq.service.d/override.conf << 'EOF'
[Unit]
After=hostapd.service dhcpcd.service
Wants=hostapd.service dhcpcd.service

[Service]
ExecStartPre=/usr/local/bin/wait-for-wlan0.sh
EOF

    systemctl daemon-reload
    systemctl enable dnsmasq
    log "✅ dnsmasq configuré"
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

    # Créer les répertoires de logs s'ils n'existent pas
    mkdir -p /var/log/lighttpd
    chown www-data:www-data /var/log/lighttpd

    systemctl enable lighttpd
    log "✅ lighttpd configuré"
}

# ═══════════════════════════════════════════════════════════════
# ✅ NOUVEAU: CONFIGURATION LOGROTATE
# ═══════════════════════════════════════════════════════════════
configure_logrotate() {
    log "📋 Configuration logrotate..."
    
    # Logrotate pour Lighttpd
    cat > /etc/logrotate.d/lighttpd << 'EOF'
/var/log/lighttpd/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 www-data www-data
    postrotate
        /usr/bin/systemctl reload lighttpd > /dev/null 2>&1 || true
    endscript
}
EOF

    # Logrotate pour SOS-GUIDE (dnsmasq + install)
    cat > /etc/logrotate.d/sosguide << EOF
$GUIDE_DIR/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}

/var/log/sosguide-install.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    create 640 root root
}
EOF

    # Test de la configuration logrotate
    logrotate -d /etc/logrotate.d/lighttpd >/dev/null 2>&1 && log "✅ logrotate lighttpd validé"
    logrotate -d /etc/logrotate.d/sosguide >/dev/null 2>&1 && log "✅ logrotate sosguide validé"
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

    cat > "$GUIDE_DIR/status.sh" << 'EOF'
#!/bin/bash
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  SOS-GUIDE - ÉTAT DU SYSTÈME                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📡 Services:"
for svc in hostapd dnsmasq lighttpd; do
    if systemctl is-active --quiet $svc; then
        echo -e "  ✅ $svc"
    else
        echo -e "  ❌ $svc"
    fi
done
echo ""
echo "📱 Clients connectés:"
cat /var/lib/misc/dnsmasq.leases 2>/dev/null || echo "  Aucun client"
echo ""
echo "📊 Espace disque:"
df -h / | tail -1
EOF
    chmod +x "$GUIDE_DIR/status.sh"

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
    echo -e "${NC}║  🌐 URL: http://10.0.0.1/index.html"
    echo -e "${NC}║  🔒 Isolation: ACTIVÉE"
    echo -e "${NC}║  📋 Logrotate: CONFIGURÉ"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║  ⚠️  À FAIRE :                                               ║${NC}"
    echo -e "${NC}║  1. sudo reboot"
    echo -e "${NC}║  2. Connectez-vous au Wi-Fi: ${SSID_CUSTOM}"
    echo -e "${NC}║  3. Test: http://10.0.0.1"
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
    deploy_web_content
    configure_hostname
    configure_network
    configure_hostapd
    configure_dnsmasq
    configure_lighttpd
    configure_logrotate      # ✅ NOUVEAU
    configure_firewall
    create_scripts

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
