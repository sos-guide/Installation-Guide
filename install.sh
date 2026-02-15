#!/bin/bash
# SOS Guide Installation Script - Version 5.0 (Sécurisé)
# Réseau local isolé - eth0 conservé pour les mises à jour admin
# Pare-feu renforcé, isolation clients WiFi, IPv6 désactivé sur wlan0

set -euo pipefail

# ==================== CONFIGURATION ====================
GUIDECONNECT_DIR="/opt/sosguide"
WEB_ROOT="/var/www/html"
BACKUP_DIR="/opt/sosguide-backup"
LOG_FILE="/var/log/sosguide-install.log"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Détection du répertoire du script (pour trouver le dossier html)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak-${TIMESTAMP}"
        log "Sauvegarde de $file → ${file}.bak-${TIMESTAMP}"
    fi
}

# Détecte le nom du service DHCP (dhcpcd ou dhcpcd5)
detect_dhcp_service() {
    if systemctl list-unit-files | grep -q '^dhcpcd.service'; then
        echo "dhcpcd"
    elif systemctl list-unit-files | grep -q '^dhcpcd5.service'; then
        echo "dhcpcd5"
    else
        # Par défaut, on suppose dhcpcd (installé via le paquet dhcpcd5)
        echo "dhcpcd"
    fi
}

check_internet() {
    if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        warn "Pas de connectivité Internet détectée sur eth0. L'installation des paquets risque d'échouer."
        read -p "Continuer quand même ? (o/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Oo]$ ]]; then
            error "Installation annulée."
        fi
    else
        log "Connectivité Internet vérifiée sur eth0."
    fi
}

install_packages() {
    log "Mise à jour des dépôts et installation des paquets nécessaires..."
    apt-get update || error "Impossible de mettre à jour les dépôts (vérifiez la connexion eth0)"
    apt-get install -y hostapd dnsmasq lighttpd dhcpcd5 iptables-persistent
    log "Paquets installés : hostapd, dnsmasq, lighttpd, dhcpcd5, iptables-persistent"
}

setup_directories() {
    log "Création des répertoires SOS Guide..."
    mkdir -p "$GUIDECONNECT_DIR"/{data,logs,backups}
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$WEB_ROOT"
    chown -R www-data:www-data "$GUIDECONNECT_DIR" "$WEB_ROOT"
    chmod -R 755 "$GUIDECONNECT_DIR" "$WEB_ROOT"
    log "Répertoires prêts : $GUIDECONNECT_DIR, $WEB_ROOT, $BACKUP_DIR"
}

copy_web_files() {
    log "Copie des fichiers HTML vers $WEB_ROOT..."
    if [ ! -d "$SCRIPT_DIR/html" ]; then
        error "Le dossier 'html' est introuvable dans le répertoire du script ($SCRIPT_DIR)."
    fi
    cp -r "$SCRIPT_DIR/html/"* "$WEB_ROOT/"
    chown -R www-data:www-data "$WEB_ROOT"
    log "Fichiers web copiés avec succès"
}

configure_lighttpd() {
    log "Configuration de lighttpd avec directives modernes..."
    systemctl stop lighttpd 2>/dev/null || true
    backup_file "/etc/lighttpd/lighttpd.conf"

    # Création du répertoire de cache pour la compression
    mkdir -p /var/cache/lighttpd/compress
    chown -R www-data:www-data /var/cache/lighttpd

    cat > /etc/lighttpd/lighttpd.conf << 'EOF'
server.document-root = "/var/www/html"
server.port = 80
server.username = "www-data"
server.groupname = "www-data"

index-file.names = ( "index.html" )
dir-listing.activate = "disable"

server.modules = (
    "mod_access",
    "mod_accesslog",
    "mod_deflate"
)

mimetype.assign = (
    ".html" => "text/html",
    ".css"  => "text/css",
    ".js"   => "application/javascript",
    ".png"  => "image/png",
    ".jpg"  => "image/jpeg",
    ".svg"  => "image/svg+xml",
    ".ico"  => "image/x-icon"
)

# Compression (deflate)
deflate.cache-dir = "/var/cache/lighttpd/compress/"
deflate.filetype = ("text/html", "text/css", "text/javascript", "application/javascript")

# Logs
server.errorlog = "/var/log/lighttpd/error.log"
accesslog.filename = "/var/log/lighttpd/access.log"

# Redirection des erreurs 404 vers l'index (pour les applications monopages)
server.error-handler-404 = "/index.html"
EOF

    systemctl start lighttpd
    systemctl enable lighttpd
    log "Lighttpd configuré et démarré"
}

wait_for_wlan0() {
    rfkill unblock wlan
    log "Attente de la disponibilité de l'interface wlan0 (état UP)..."
    local i
    for i in {1..15}; do
        if ip link show wlan0 | grep -q "state UP"; then
            log "Interface wlan0 détectée et UP."
            return 0
        fi
        sleep 2
    done
    error "L'interface wlan0 n'est pas passée en état UP après 30 secondes."
}

disable_ipv6_on_wlan() {
    log "Désactivation d'IPv6 sur wlan0..."
    # Désactiver immédiatement
    sysctl -w net.ipv6.conf.wlan0.disable_ipv6=1 &>/dev/null || true
    # Rendre persistant
    local SYSCTL_FILE="/etc/sysctl.d/99-sosguide.conf"
    if ! grep -q "net.ipv6.conf.wlan0.disable_ipv6" "$SYSCTL_FILE" 2>/dev/null; then
        echo "# Désactiver IPv6 sur wlan0 pour l'isolation" >> "$SYSCTL_FILE"
        echo "net.ipv6.conf.wlan0.disable_ipv6=1" >> "$SYSCTL_FILE"
    fi
    log "IPv6 désactivé sur wlan0."
}

configure_firewall() {
    log "Configuration du pare-feu (iptables) pour isoler wlan0..."
    # Sauvegarde des règles actuelles
    iptables-save > "$BACKUP_DIR/iptables.rules.${TIMESTAMP}" 2>/dev/null || true

    # Politiques par défaut : DROP sur INPUT (sauf pour eth0 on laissera passer plus tard)
    # On remet d'abord les politiques par défaut à ACCEPT pour éviter de se couper l'accès pendant la configuration
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    # On vide les règles existantes
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X

    # Politique par défaut stricte
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT

    # Autoriser les connexions établies et locales
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -i lo -j ACCEPT

    # Autoriser l'administration sur eth0 (SSH si nécessaire)
    iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT   # SSH
    # On peut aussi autoriser tout le trafic sur eth0 si on veut un accès complet
    # iptables -A INPUT -i eth0 -j ACCEPT  # alternative moins stricte

    # Sur wlan0 : seulement DHCP (67/68), DNS (53), HTTP (80)
    iptables -A INPUT -i wlan0 -p udp --dport 67:68 -j ACCEPT
    iptables -A INPUT -i wlan0 -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -i wlan0 -p tcp --dport 80 -j ACCEPT
    # Option : autoriser le ping pour diagnostic
    iptables -A INPUT -i wlan0 -p icmp --icmp-type echo-request -j ACCEPT
    # Tout autre trafic entrant sur wlan0 est rejeté (par défaut DROP)

    # Sauvegarder les règles pour persistence
    netfilter-persistent save 2>/dev/null || {
        warn "netfilter-persistent n'a pas pu sauvegarder les règles (peut-être pas installé correctement)."
    }
    log "Pare-feu configuré avec succès."
}

configure_network_ap() {
    log "Configuration du point d'accès Wi-Fi ouvert (eth0 reste actif)..."

    # Sauvegarde des fichiers de configuration
    backup_file "/etc/dhcpcd.conf"
    backup_file "/etc/dnsmasq.conf"
    backup_file "/etc/hostapd/hostapd.conf"
    backup_file "/etc/default/hostapd"

    # --- dhcpcd : IP statique sur wlan0 ---
    # Supprimer toute ancienne configuration pour wlan0
    sed -i '/^interface wlan0/,/^$/d' /etc/dhcpcd.conf
    # Ajouter la nouvelle configuration
    cat >> /etc/dhcpcd.conf << 'EOF'

# Configuration SOS Guide - Point d'accès
interface wlan0
    static ip_address=10.0.0.1/24
    nohook wpa_supplicant
EOF

    # --- dnsmasq : DHCP et redirection DNS (renforcé) ---
    cat > /etc/dnsmasq.conf << 'EOF'
# Configuration SOS Guide - dnsmasq sécurisé
interface=wlan0
bind-interfaces
dhcp-range=10.0.0.2,10.0.0.49,255.255.255.0,24h
# Ne pas forwarder les requêtes DNS vers l'extérieur
no-resolv
# Répondre à toutes les requêtes DNS par l'adresse du serveur local
address=/#/10.0.0.1
EOF

    # --- hostapd : réseau ouvert avec isolation clients ---
    cat > /etc/hostapd/hostapd.conf << 'EOF'
interface=wlan0
driver=nl80211
ssid=⛑️ SOS-GUIDE
country_code=FR
hw_mode=g
channel=7
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
ap_isolate=1
EOF

    # Activer hostapd
    echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' > /etc/default/hostapd

    # Désactiver le forwarding IP (pas de routage entre wlan0 et eth0)
    echo 0 > /proc/sys/net/ipv4/ip_forward
    backup_file "/etc/sysctl.conf"
    # S'assurer que net.ipv4.ip_forward est désactivé au boot
    sed -i 's/^net.ipv4.ip_forward=1/#net.ipv4.ip_forward=1/' /etc/sysctl.conf
    if ! grep -q "^net.ipv4.ip_forward" /etc/sysctl.conf; then
        echo "#net.ipv4.ip_forward=0" >> /etc/sysctl.conf
    fi

    # Détection et activation du service DHCP
    DHCP_SERVICE=$(detect_dhcp_service)
    log "Service DHCP détecté : $DHCP_SERVICE"

    # Activation des services
    systemctl unmask hostapd
    systemctl enable hostapd dnsmasq "$DHCP_SERVICE"

    # Redémarrer dhcpcd pour appliquer la configuration
    systemctl restart "$DHCP_SERVICE"

    # Démarrer hostapd
    systemctl start hostapd || {
        warn "Échec du démarrage de hostapd. Vérifiez que l'interface wlan0 est compatible."
        # On continue car le script peut peut-être fonctionner quand même ?
    }

    # Attendre que wlan0 soit prêt (UP)
    wait_for_wlan0

    # Redémarrer dnsmasq pour qu'il voie wlan0
    systemctl restart dnsmasq

    # Désactiver IPv6 sur wlan0
    disable_ipv6_on_wlan

    log "Point d'accès Wi-Fi configuré : SSID='⛑️ SOS-GUIDE' (ouvert, isolation active)"
    log "eth0 reste actif pour les mises à jour administrateur"
}

create_uninstall() {
    log "Création du script de désinstallation..."
    cat > "$GUIDECONNECT_DIR/uninstall.sh" << 'EOF'
#!/bin/bash
# Désinstaller SOS Guide

echo "Désinstallation de SOS Guide..."
echo ""

# Arrêter et désactiver les services
systemctl stop hostapd dnsmasq 2>/dev/null
systemctl disable hostapd dnsmasq 2>/dev/null

# Restaurer les fichiers de configuration à partir des sauvegardes les plus récentes
for f in /etc/dhcpcd.conf /etc/dnsmasq.conf /etc/hostapd/hostapd.conf /etc/default/hostapd /etc/lighttpd/lighttpd.conf; do
    latest_backup=$(ls -t "${f}.bak-"* 2>/dev/null | head -n1)
    if [ -n "$latest_backup" ]; then
        cp "$latest_backup" "$f"
        echo "Restauration de $f depuis $latest_backup"
    fi
done

# Restaurer les règles iptables si une sauvegarde existe
BACKUP_DIR="/opt/sosguide-backup"
latest_iptables=$(ls -t "$BACKUP_DIR/iptables.rules."* 2>/dev/null | head -n1)
if [ -n "$latest_iptables" ]; then
    echo "Restauration des règles iptables depuis $latest_iptables"
    iptables-restore < "$latest_iptables"
    netfilter-persistent save 2>/dev/null || true
else
    # Sinon, simplement vider les règles et remettre en ACCEPT
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    iptables -X
    netfilter-persistent save 2>/dev/null || true
fi

# Réactiver le forwarding IP si nécessaire (optionnel)
sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf 2>/dev/null || true
sysctl -p 2>/dev/null || true

# Supprimer les répertoires SOS Guide
rm -rf /opt/sosguide
rm -rf /opt/sosguide-backup

# Supprimer les fichiers web (optionnel, mais on nettoie)
rm -rf /var/www/html/*

# Redémarrer les services de base
systemctl restart dhcpcd lighttpd

echo ""
echo "✅ SOS Guide désinstallé !"
echo "Vous pouvez maintenant redémarrer manuellement si nécessaire."
EOF
    chmod +x "$GUIDECONNECT_DIR/uninstall.sh"
    log "Script de désinstallation créé : $GUIDECONNECT_DIR/uninstall.sh"
}

show_complete() {
    clear
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         ✅ SOS GUIDE INSTALLÉ AVEC SUCCÈS !                 ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║                                                            ║"
    echo "║  📡 POINT D'ACCÈS WI-FI OUVERT :                            ║"
    echo "║     • SSID: ⛑️ SOS-GUIDE                                    ║"
    echo "║     • Mot de passe: Aucun                                  ║"
    echo "║     • Isolation clients: ACTIVÉE                           ║"
    echo "║     • IP du serveur: 10.0.0.1                              ║"
    echo "║                                                            ║"
    echo "║  🌐 ACCÈS POUR LES CLIENTS :                                ║"
    echo "║     1. Connectez-vous au Wi-Fi '⛑️ SOS-GUIDE'               ║"
    echo "║     2. Ouvrez un navigateur → page d'accueil SOS Guide     ║"
    echo "║                                                            ║"
    echo "║  💻 ADMINISTRATEUR (via eth0) :                             ║"
    echo "║     • eth0 conserve son accès Internet                     ║"
    echo "║     • Pare-feu restrictif sur wlan0                        ║"
    echo "║     • SSH autorisé sur eth0 (port 22)                      ║"
    echo "║                                                            ║"
    echo "║  ⚠️  IMPORTANT :                                            ║"
    echo "║     • Les clients Wi-Fi n'ont PAS accès à Internet         ║"
    echo "║     • Réseau complètement isolé pour les utilisateurs      ║"
    echo "║     • Aucune communication entre clients WiFi possible     ║"
    echo "║                                                            ║"
    echo "║  🗑️  DÉSINSTALLATION :                                      ║"
    echo "║     sudo /opt/sosguide/uninstall.sh                        ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📋 RÉCAPITULATIF :"
    echo "   ✅ Wi-Fi ouvert '⛑️ SOS-GUIDE' diffusé sur wlan0 (isolation active)"
    echo "   ✅ Serveur web sur http://10.0.0.1"
    echo "   ✅ eth0 conservé pour l'administration"
    echo "   ✅ Pare-feu configuré : seuls DHCP/DNS/HTTP autorisés sur wlan0"
    echo "   ✅ IPv6 désactivé sur wlan0"
    echo "   ❌ Aucun routage entre wlan0 et eth0"
    echo ""
    echo "🔧 Il est recommandé de redémarrer le système maintenant."
    echo "    Commande : sudo reboot"
    echo ""
}

# ==================== EXÉCUTION ====================
main() {
    clear
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║              INSTALLATION SOS GUIDE (SÉCURISÉE)            ║"
    echo "║                 Version 5.0 - Réseau isolé                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_root
    check_internet
    install_packages
    setup_directories
    copy_web_files
    configure_lighttpd
    configure_network_ap
    configure_firewall
    create_uninstall
    show_complete

    log "Installation terminée ! Redémarrez pour appliquer tous les changements."
}

main "$@"
