#!/bin/bash
# SOS Guide Installation Script - Version 3.0
# Réseau local 100% offline - Pour établissements

set -e

# ==================== CONFIGURATION ====================
GUIDECONNECT_DIR="/opt/sosguide"
WEB_ROOT="/var/www/html"
BACKUP_DIR="/opt/sosguide-backup"
LOG_FILE="/var/log/sosguide-install.log"
SERVICE_FILE="/etc/systemd/system/sosguide.service"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==================== FONCTIONS ====================

log() {
    echo -e "${GREEN}[+]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        error "Ce script doit être exécuté en tant que root (sudo)"
    fi
}

check_lighttpd() {
    if ! systemctl is-active --quiet lighttpd; then
        warn "Lighttpd n'est pas démarré, tentative de démarrage..."
        systemctl start lighttpd || error "Impossible de démarrer lighttpd"
    fi
    
    # Vérifier que /var/www/html existe
    if [ ! -d "$WEB_ROOT" ]; then
        mkdir -p "$WEB_ROOT"
        chown www-data:www-data "$WEB_ROOT"
    fi
}

cleanup_raspap() {
    log "Nettoyage de RaspAP..."
    
    # Arrêter les services RaspAP
    systemctl stop raspapd 2>/dev/null || true
    systemctl disable raspapd 2>/dev/null || true
    
    # Supprimer les fichiers de service
    rm -f /lib/systemd/system/raspapd.service 2>/dev/null || true
    
    # Supprimer les configurations réseau spécifiques à RaspAP
    rm -f /etc/dnsmasq.d/090_raspap.conf 2>/dev/null || true
    rm -f /etc/dnsmasq.d/090_wlan0.conf 2>/dev/null || true
    rm -f /etc/systemd/network/raspap* 2>/dev/null || true
    
    rm -f /var/www/html/* 2>/dev/null || true
    
    log "RaspAP nettoyé"
}

setup_directories() {
    log "Création des répertoires SOS Guide..."
    
    # Créer les répertoires
    mkdir -p "$GUIDECONNECT_DIR"
    mkdir -p "$GUIDECONNECT_DIR/data"
    mkdir -p "$GUIDECONNECT_DIR/logs"
    mkdir -p "$GUIDECONNECT_DIR/backups"
    
    touch /etc/sysctl.conf
    
    # Permissions
    chown -R www-data:www-data "$GUIDECONNECT_DIR"
    chown -R www-data:www-data "$WEB_ROOT"
    chmod -R 755 "$GUIDECONNECT_DIR"
    chmod -R 755 "$WEB_ROOT"
    
    log "Répertoires créés: $GUIDECONNECT_DIR, $WEB_ROOT"
}

create_homepage() {
    log "Création de la page d'accueil SOS Guide..."
    
    # Page d'accueil principale
    cp -R html/* /var/www/html

    log "Page d'accueil et blog créés"
}

configure_lighttpd_simple() {
    log "Configuration simple de Lighttpd..."
    
    # Arrêter lighttpd
    systemctl stop lighttpd 2>/dev/null || true
    
    # Configuration minimale
    cat > /etc/lighttpd/lighttpd.conf << 'EOF'
server.document-root = "/var/www/html"
server.port = 80
server.username = "www-data"
server.groupname = "www-data"

index-file.names = ( "index.html" )
dir-listing.activate = "disable"

mimetype.assign = (
    ".html" => "text/html",
    ".css" => "text/css",
    ".js" => "application/javascript",
    ".png" => "image/png",
    ".jpg" => "image/jpeg",
    ".svg" => "image/svg+xml",
    ".ico" => "image/x-icon"
)

# Rediriger les erreurs 404 vers l'index
server.error-handler-404 = "/index.html"

# Désactiver les logs pour la performance
server.errorlog = "/var/log/lighttpd/error.log"
accesslog.filename = "/var/log/lighttpd/access.log"

# Compression
compress.cache-dir = "/var/cache/lighttpd/compress/"
compress.filetype = ("text/html", "text/css", "text/javascript", "application/javascript")
EOF

    # Démarrer lighttpd
    systemctl start lighttpd
    systemctl enable lighttpd
    
    # Vérifier que ça fonctionne
    if systemctl is-active --quiet lighttpd; then
        log "✅ Lighttpd démarré avec succès"
    else
        error "❌ Lighttpd n'a pas pu démarrer"
    fi
}

configure_network_ap() {
    log "Configuration du point d'accès Wi-Fi ouvert (eth0 désactivé)..."
    
    # Désactiver eth0 complètement
    cat >> /etc/dhcpcd.conf << 'EOF'

# Configuration SOS Guide - eth0 désactivé
denyinterfaces eth0
interface wlan0
    static ip_address=10.0.0.1/24
    nohook wpa_supplicant
EOF

    # Configurer dnsmasq
    cat > /etc/dnsmasq.conf << 'EOF'
interface=wlan0
dhcp-range=10.0.0.2,10.0.0.49,255.255.255.0,24h
address=/#/10.0.0.1
EOF

    # Configurer hostapd pour réseau ouvert (sans mot de passe)
    cat > /etc/hostapd/hostapd.conf << 'EOF'
interface=wlan0
driver=nl80211
ssid=⛑️ SOS-GUIDE
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ap_isolate=1
ignore_broadcast_ssid=0
# Réseau ouvert - pas de mot de passe
EOF

    # Activer hostapd
    echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' > /etc/default/hostapd
    
    # Désactiver le forwarding IP car pas de connexion externe
    echo 0 > /proc/sys/net/ipv4/ip_forward
    
    # Vérifier si sysctl.conf existe, sinon le créer
    if [ ! -f /etc/sysctl.conf ]; then
        warn "/etc/sysctl.conf n'existe pas, création..."
        touch /etc/sysctl.conf
    fi
    
    # Désactiver IP forwarding dans sysctl.conf
    if grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        # Commenter la ligne si elle existe
        sed -i 's/net.ipv4.ip_forward=1/#net.ipv4.ip_forward=1/' /etc/sysctl.conf
    elif grep -q "#net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        # Déjà commenté, rien à faire
        :
    else
        # Ajouter la ligne commentée
        echo "#net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
    
    # Éteindre eth0 immédiatement
    ip link set eth0 down 2>/dev/null || true
    
    # Désactiver le service networking pour eth0 si nécessaire
    if [ -f /etc/systemd/system/network-online.target.wants/networking.service ]; then
        systemctl disable networking 2>/dev/null || true
    fi
    
    # Démarrer les services
    systemctl unmask hostapd
    systemctl enable hostapd
    systemctl enable dnsmasq
    
    # Redémarrer les services réseau
    systemctl restart dhcpcd
    
    log "Point d'accès configuré: SSID='SOS Guide' (ouvert sans mot de passe)"
    log "eth0 désactivé - Réseau 100% isolé"
}

check_network_services() {
    log "Vérification des services réseau..."
    
    # Vérifier si hostapd est installé
    if ! command -v hostapd &> /dev/null; then
        warn "hostapd n'est pas installé. Installation..."
        apt-get update && apt-get install -y hostapd || error "Impossible d'installer hostapd"
    fi
    
    # Vérifier si dnsmasq est installé
    if ! command -v dnsmasq &> /dev/null; then
        warn "dnsmasq n'est pas installé. Installation..."
        apt-get install -y dnsmasq || error "Impossible d'installer dnsmasq"
    fi
    
    # Vérifier si iptables est installé (même si désactivé)
    if ! command -v iptables &> /dev/null; then
        warn "iptables n'est pas installé. Installation..."
        apt-get install -y iptables || error "Impossible d'installer iptables"
    fi
    
    log "Services réseau vérifiés"
}

create_service() {
    log "Création du service SOS Guide..."
    
    cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=SOS Guide Local Network
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash -c "echo 'SOS Guide service running' && sleep infinity"
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable sosguide.service
    
    log "Service SOS Guide créé"
}

create_uninstall() {
    log "Création du script de désinstallation..."
    
    cat > "$GUIDECONNECT_DIR/uninstall.sh" << 'EOF'
#!/bin/bash
# Désinstaller SOS Guide

echo "Désinstallation de SOS Guide..."
echo ""

# Arrêter les services
systemctl stop sosguide.service 2>/dev/null
systemctl disable sosguide.service 2>/dev/null
systemctl stop hostapd 2>/dev/null
systemctl stop dnsmasq 2>/dev/null

# Supprimer les fichiers
rm -rf /opt/sosguide
rm -f /etc/systemd/system/sosguide.service

# Réinitialiser lighttpd
cat > /etc/lighttpd/lighttpd.conf << 'LIGHTTPD'
server.document-root = "/var/www/html"
server.port = 80
server.username = "www-data"
server.groupname = "www-data"
index-file.names = ( "index.html" )
LIGHTTPD

# Réinitialiser le réseau et réactiver eth0
sed -i '/# Configuration SOS Guide - eth0 désactivé/,+5d' /etc/dhcpcd.conf
sed -i '/denyinterfaces eth0/d' /etc/dhcpcd.conf

# Réactiver eth0
ip link set eth0 up 2>/dev/null || true

# Réactiver le service networking si nécessaire
systemctl enable networking 2>/dev/null || true

# Redémarrer lighttpd
systemctl restart lighttpd

echo ""
echo "✅ SOS Guide désinstallé !"
echo "Le système redémarre dans 5 secondes..."
sleep 5
reboot
EOF

    chmod +x "$GUIDECONNECT_DIR/uninstall.sh"
    log "Script de désinstallation créé: $GUIDECONNECT_DIR/uninstall.sh"
}

show_complete() {
    clear
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         ✅ SOS GUIDE INSTALLÉ AVEC SUCCÈS !                ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║                                                            ║"
    echo "║  📡 POINT D'ACCÈS WI-FI OUVERT :                           ║"
    echo "║     • SSID: SOS Guide                                      ║"
    echo "║     • Mot de passe: Aucun (réseau ouvert)                  ║"
    echo "║     • IP: 10.0.0.1                                         ║"
    echo "║     • eth0: DÉSACTIVÉ (réseau isolé)                       ║"
    echo "║                                                            ║"
    echo "║  🌐 ACCÈS IMMÉDIAT :                                       ║"
    echo "║     1. Connectez-vous au Wi-Fi '⛑️ SOS-GUIDE'              ║"
    echo "║     2. Ouvrez un navigateur web                            ║"
    echo "║     3. Vous verrez la page d'accueil SOS Guide             ║"
    echo "║                                                            ║"
    echo "║  💻 CARACTÉRISTIQUES :                                     ║"
    echo "║     • Page d'accueil moderne                               ║"
    echo "║     • 100% offline - Données locales                       ║"
    echo "║     • Interface responsive                                 ║"
    echo "║     • eth0 désactivé - Isolation réseau                    ║"
    echo "║                                                            ║"
    echo "║  ⚠️  IMPORTANT :                                           ║"
    echo "║     • Pas d'internet requis                                ║"
    echo "║     • Réseau ouvert pour accès facile                      ║"
    echo "║     • Données stockées dans le navigateur                  ║"
    echo "║     • eth0 désactivé - Réseau complètement isolé           ║"
    echo "║                                                            ║"
    echo "║  🗑️  DÉSINSTALLATION :                                     ║"
    echo "║     sudo /opt/sosguide/uninstall.sh                        ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 RÉCAPITULATIF :"
    echo "   1. Le Raspberry Pi diffuse le Wi-Fi 'SOS Guide' (ouvert)"
    echo "   2. eth0 est DÉSACTIVÉ pour isoler complètement le réseau"
    echo "   3. Les clients se connectent automatiquement au Wi-Fi"
    echo "   4. Ils voient la page d'accueil"
    echo "   5. Ils peuvent lire et poster des commentaires localement"
    echo ""
    echo "🔧 Redémarrage dans 10 secondes..."
    echo ""
}

# ==================== EXÉCUTION ====================

main() {
    clear
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                   INSTALLATION SOS GUIDE                   ║"
    echo "║                 Version 3.0 - Réseau Local                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Vérifications
    check_root
    check_lighttpd
    
    log "Début de l'installation..."
    log "IP actuelle: $(hostname -I 2>/dev/null || echo 'N/A')"
    
    # Étapes
    cleanup_raspap
    setup_directories
    create_homepage
    configure_lighttpd_simple
    check_network_services
    configure_network_ap
    create_service
    create_uninstall
    
    # Final
    show_complete
    
    # Redémarrer
    log "Installation terminée avec succès !"
    log "Redémarrage dans 10 secondes..."
    sleep 10
    reboot
}

# Exécuter
main "$@"
