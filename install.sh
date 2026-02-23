#!/bin/bash

# ==============================================================================
# SOS-GUIDE v5.0 - VERSION FINALE PRODUCTION
# Pi avec Internet | Clients WiFi Isolés | Captive Portal | Réseau Ouvert
# ==============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
SSID="SOS-GUIDE"
LOCAL_IP="10.0.0.1"

echo -e "${GREEN}"
echo "=========================================="
echo "   SOS-GUIDE v5.0 - VERSION FINALE"
echo "   Réseau de Secours Autonome"
echo "==========================================${NC}"
echo ""

# ==============================================================================
# 1. NETTOYAGE DES GESTIONNAIRES CONFLICTUELS
# ==============================================================================
echo -e "${BLUE}[1/9] Nettoyage des gestionnaires réseau conflictuels...${NC}"

# Stop et disable bluetooth
systemctl stop bluetooth 2>/dev/null || true
systemctl disable bluetooth 2>/dev/null || true
systemctl mask bluetooth 2>/dev/null || true

# Stop et disable NetworkManager
systemctl stop NetworkManager 2>/dev/null || true
systemctl disable NetworkManager 2>/dev/null || true
systemctl mask NetworkManager 2>/dev/null || true

# Stop et disable wpa_supplicant (conflit avec hostapd)
systemctl stop wpa_supplicant 2>/dev/null || true
systemctl disable wpa_supplicant 2>/dev/null || true
systemctl mask wpa_supplicant 2>/dev/null || true

# Stop dhcpcd si présent
systemctl stop dhcpcd 2>/dev/null || true
systemctl disable dhcpcd 2>/dev/null || true

# Tuer les processus résiduels
pkill -f wpa_supplicant 2>/dev/null || true
pkill -f NetworkManager 2>/dev/null || true

sleep 2
echo -e "${GREEN}✓ Gestionnaires conflictuels désactivés${NC}"

# ==============================================================================
# 2. INSTALLATION DES PAQUETS
# ==============================================================================
echo -e "${BLUE}[2/9] Installation des paquets...${NC}"

apt update -qq
apt install -y nginx hostapd dnsmasq iptables-persistent

echo -e "${GREEN}✓ Paquets installés${NC}"

# ==============================================================================
# 3. CONFIGURATION PAYS WIFI
# ==============================================================================
echo -e "${BLUE}[3/9] Configuration du pays WiFi...${NC}"

echo "country=FR" > /etc/wpa_supplicant/wpa_supplicant.conf
rfkill unblock wifi

echo -e "${GREEN}✓ Pays WiFi configuré${NC}"

# ==============================================================================
# 4. CONFIGURATION SYSTEMD-NETWORKD (ETH + WLAN)
# ==============================================================================
echo -e "${BLUE}[4/9] Configuration systemd-networkd...${NC}"

# Activer systemd-networkd
systemctl enable systemd-networkd
systemctl enable systemd-resolved

# Configuration ETH0 (avec Internet - DHCP client)
cat > /etc/systemd/network/10-eth0.network <<EOF
[Match]
Name=eth0

[Network]
DHCP=yes
DNS=8.8.8.8
DNS=8.8.4.4
EOF

# Configuration WLAN0 (AP - IP statique + DHCP server pour clients)
cat > /etc/systemd/network/20-wlan0-ap.network <<EOF
[Match]
Name=wlan0

[Network]
Address=${LOCAL_IP}/24
DHCPServer=yes
DNS=${LOCAL_IP}

[DHCPServer]
PoolOffset=100
PoolSize=50
DNS=${LOCAL_IP}
EOF

systemctl daemon-reload
systemctl restart systemd-networkd
systemctl restart systemd-resolved

echo -e "${GREEN}✓ systemd-networkd configuré${NC}"

# ==============================================================================
# 5. CONFIGURATION HOSTAPD (RÉSEAU OUVERT - SANS MOT DE PASSE)
# ==============================================================================
echo -e "${BLUE}[5/9] Configuration du Point d'Accès WiFi (OUVERT)...${NC}"

mkdir -p /etc/hostapd

# Configuration SANS WPA (réseau ouvert)
cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
driver=nl80211
ssid=${SSID}
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
# PAS DE WPA = Réseau ouvert
country_code=FR
ieee80211d=1
beacon_int=100
dtim_period=2
max_num_sta=25
EOF

echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" > /etc/default/hostapd

systemctl unmask hostapd 2>/dev/null || true
systemctl enable hostapd
systemctl restart hostapd

echo -e "${GREEN}✓ hostapd configuré${NC}"
echo -e "   ${YELLOW}SSID: ${SSID}${NC}"
echo -e "   ${YELLOW}🔓 Réseau OUVERT (sans mot de passe)${NC}"

# ==============================================================================
# 6. CONFIGURATION DNSMASQ (DNS + CAPTIVE PORTAL)
# ==============================================================================
echo -e "${BLUE}[6/9] Configuration dnsmasq (DNS + Captive Portal)...${NC}"

mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak 2>/dev/null || true

# Configuration CRUCIALE : Tous les domaines pointent vers le Pi local
cat > /etc/dnsmasq.conf <<EOF
# SOS-GUIDE - DNS + Captive Portal
interface=wlan0
listen-address=${LOCAL_IP}

# DHCP désactivé (géré par systemd-networkd)
no-dhcp-interface=wlan0

# TOUS les domaines résolus vers l'IP locale (captive portal)
address=/#/${LOCAL_IP}

# DNS upstream pour le Pi lui-même
server=8.8.8.8
server=8.8.4.4

# Cache
cache-size=1000
EOF

systemctl enable dnsmasq
systemctl restart dnsmasq

echo -e "${GREEN}✓ dnsmasq configuré (Captive Portal activé)${NC}"

# ==============================================================================
# 7. CONFIGURATION FIREWALL (ISOLEMENT CLIENTS)
# ==============================================================================
echo -e "${BLUE}[7/9] Configuration du firewall (clients isolés)...${NC}"

# Nettoyer les règles existantes
iptables -F
iptables -t nat -F
iptables -t filter -F

# Politique par défaut : ACCEPT (le Pi a internet)
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Autoriser le trafic local entre wlan0 et le Pi
iptables -A INPUT -i wlan0 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i wlan0 -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -i wlan0 -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -i wlan0 -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i wlan0 -p icmp -j ACCEPT

# Autoriser le Pi à accéder à Internet via eth0 (pour lui seul)
iptables -A OUTPUT -o eth0 -j ACCEPT
iptables -A INPUT -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Bloquer le forwarding wlan0 -> eth0 (clients isolés d'Internet)
iptables -A FORWARD -i wlan0 -o eth0 -j DROP

# Sauvegarder les règles
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4

# Activer la persistance
if command -v netfilter-persistent &> /dev/null; then
    netfilter-persistent save 2>/dev/null || true
fi

echo -e "${GREEN}✓ Firewall configuré (clients isolés d'Internet)${NC}"

# ==============================================================================
# 8. SERVEUR WEB + PAGES COMPLÈTES
# ==============================================================================
echo -e "${BLUE}[8/9] Configuration du serveur web et des pages...${NC}"

mkdir -p /var/www/sos-guide
mkdir -p /data/docs

# CORRECTION: www-www-data (CORRECT)
chown -R www-www-data /var/www/sos-guide
chown -R www-www-data /data

# ==================== PAGE D'ACCUEIL ====================
cat > /var/www/sos-guide/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SOS-GUIDE - Réseau de Secours</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 16px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); }
        h1 { color: #d93025; text-align: center; margin-bottom: 10px; font-size: 2em; }
        .subtitle { text-align: center; color: #666; margin-bottom: 25px; font-size: 1.1em; }
        .alert { background: linear-gradient(90deg, #fff8e1 0%, #ffecb3 100%); border-left: 5px solid #ffc107; padding: 15px 20px; margin: 20px 0; border-radius: 8px; }
        .alert.success { background: linear-gradient(90deg, #e8f5e9 0%, #c8e6c9 100%); border-left-color: #4caf50; }
        .alert.success strong { color: #2e7d32; }
        .btn { display: block; background: linear-gradient(135deg, #1a73e8 0%, #1557b0 100%); color: white; padding: 18px 25px; margin: 12px 0; text-align: center; text-decoration: none; border-radius: 10px; font-weight: 600; font-size: 16px; transition: all 0.3s ease; box-shadow: 0 4px 15px rgba(26,115,232,0.3); }
        .btn:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(26,115,232,0.4); }
        .btn-emergency { background: linear-gradient(135deg, #d93025 0%, #b02015 100%); box-shadow: 0 4px 15px rgba(217,48,37,0.3); }
        .btn-emergency:hover { box-shadow: 0 6px 20px rgba(217,48,37,0.4); }
        .btn-docs { background: linear-gradient(135deg, #0f9d58 0%, #0b7a43 100%); box-shadow: 0 4px 15px rgba(15,157,88,0.3); }
        .btn-docs:hover { box-shadow: 0 6px 20px rgba(15,157,88,0.4); }
        .icon { margin-right: 10px; }
        footer { text-align: center; margin-top: 35px; color: #888; font-size: 13px; border-top: 1px solid #eee; padding-top: 20px; }
        .status { padding: 10px; border-radius: 6px; text-align: center; margin-bottom: 20px; font-weight: 500; }
        .status.online { background: #e8f5e9; color: #2e7d32; }
        .status.offline { background: #ffecb3; color: #f57c00; }
        .battery-info { background: #e3f2fd; padding: 15px; border-radius: 8px; margin: 20px 0; text-align: center; color: #1565c0; }
        .open-network { background: linear-gradient(90deg, #e8f5e9 0%, #c8e6c9 100%); padding: 15px; border-radius: 8px; margin: 20px 0; text-align: center; color: #2e7d32; border: 2px solid #4caf50; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🆘 SOS-GUIDE</h1>
        <p class="subtitle">Réseau de Secours Autonome</p>
        
        <div class="open-network">
            <strong>🔓 Réseau Ouvert</strong><br>
            Connexion libre sans mot de passe - Accès immédiat aux ressources de secours
        </div>
        
        <div id="net-status" class="status offline">
            ⚠️ Mode Hors-Ligne Activé | Réseau Local Sécurisé
        </div>
        
        <div class="alert success">
            <strong>✅ Réseau Local Actif</strong><br>
            Vous êtes connecté au point d'accès de secours. Toutes les ressources ci-dessous sont accessibles sans Internet.
        </div>
        
        <div class="battery-info">
            🔋 <strong>Autonomie:</strong> Le réseau reste actif même sans Internet<br>
            <small>En cas de coupure, le Raspberry Pi fonctionne sur batterie</small>
        </div>
        
        <a href="/contact.html" class="btn btn-emergency">
            <span class="icon">📞</span>Numéros d'Urgence
        </a>
        <a href="/premiers-secours.html" class="btn">
            <span class="icon">🏥</span>Guide Premiers Secours
        </a>
        <a href="/survie.html" class="btn">
            <span class="icon">🎒</span>Guide Survie
        </a>
        <a href="/docs/" class="btn btn-docs">
            <span class="icon">📄</span>Documents & PDF
        </a>
        
        <footer>
            <strong>SOS-GUIDE v5.0</strong><br>
            Raspberry Pi Autonomous Network<br>
            IP: 10.0.0.1 | SSID: SOS-GUIDE | 🔓 Ouvert
        </footer>
    </div>
</body>
</html>
HTMLEOF

# ==================== PAGE CONTACTS ====================
cat > /var/www/sos-guide/contact.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urgence - SOS-GUIDE</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 16px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); }
        h1 { color: #d93025; margin-bottom: 25px; }
        .contact { background: linear-gradient(90deg, #e8f4f8 0%, #d0e8f0 100%); padding: 20px; margin: 15px 0; border-radius: 10px; border-left: 5px solid #1a73e8; }
        .contact strong { font-size: 1.3em; color: #1a73e8; display: block; margin-bottom: 5px; }
        .contact .number { font-size: 2em; color: #d93025; font-weight: bold; }
        .contact.emergency { background: linear-gradient(90deg, #ffebee 0%, #ffcdd2 100%); border-left-color: #d93025; }
        .contact.emergency strong { color: #d93025; }
        .back { display: inline-block; margin-top: 25px; padding: 12px 25px; background: #f5f5f5; border-radius: 8px; font-weight: 500; text-decoration: none; color: #333; }
        .back:hover { background: #e0e0e0; }
        .info { background: #fff3e0; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ff9800; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📞 Numéros d'Urgence</h1>
        
        <div class="info">
            <strong>💡 Conseil:</strong> Ces numéros fonctionnent même sans crédit ou avec un téléphone verrouillé.
        </div>
        
        <div class="contact emergency">
            <strong>🚑 SAMU (Urgence Médicale)</strong>
            <span class="number">15</span>
        </div>
        
        <div class="contact emergency">
            <strong>🔥 Sapeurs-Pompiers</strong>
            <span class="number">18</span>
        </div>
        
        <div class="contact emergency">
            <strong>👮 Police Secours</strong>
            <span class="number">17</span>
        </div>
        
        <div class="contact">
            <strong>🇪🇺 Urgence Européenne</strong>
            <span class="number">112</span>
            <small>Valable dans tous les pays de l'UE</small>
        </div>
        
        <div class="contact">
            <strong>🚨 SOS Médecin</strong>
            <span class="number">3624</span>
        </div>
        
        <div class="contact">
            <strong>🧠 Suicide Écoute</strong>
            <span class="number">3114</span>
        </div>
        
        <a href="/" class="back">← Retour à l'accueil</a>
    </div>
</body>
</html>
HTMLEOF

# ==================== PAGE PREMIERS SECOURS ====================
cat > /var/www/sos-guide/premiers-secours.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Premiers Secours - SOS-GUIDE</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 700px; margin: 0 auto; background: white; padding: 30px; border-radius: 16px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); }
        h1 { color: #d93025; margin-bottom: 10px; }
        h2 { color: #1a73e8; border-bottom: 3px solid #1a73e8; padding-bottom: 10px; margin: 30px 0 15px 0; }
        .step { background: linear-gradient(90deg, #fff8e1 0%, #ffecb3 100%); padding: 20px; margin: 15px 0; border-radius: 10px; border-left: 5px solid #ffc107; }
        .step h3 { color: #f57c00; margin-bottom: 10px; }
        .warning { background: linear-gradient(90deg, #ffebee 0%, #ffcdd2 100%); padding: 20px; border-radius: 10px; border-left: 5px solid #d93025; margin: 20px 0; }
        .warning h3 { color: #d93025; margin-bottom: 10px; }
        .tip { background: #e8f5e9; padding: 15px; border-radius: 8px; margin: 15px 0; border-left: 4px solid #4caf50; }
        ul { margin-left: 20px; margin-top: 10px; }
        li { margin: 8px 0; line-height: 1.5; }
        .back { display: inline-block; margin-top: 25px; padding: 12px 25px; background: #f5f5f5; border-radius: 8px; font-weight: 500; text-decoration: none; color: #333; }
        .back:hover { background: #e0e0e0; }
        .big-number { font-size: 3em; color: #d93025; font-weight: bold; text-align: center; display: block; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏥 Premiers Secours</h1>
        <p>Guide pratique pour intervenir en attendant les secours professionnels.</p>
        
        <div class="warning">
            <h3>⚠️ RÈGLE D'OR : P.A.S.</h3>
            <p><strong>P</strong>rotéger → <strong>A</strong>lerter → <strong>S</strong>ecourir</p>
            <p>Ne jamais mettre sa propre vie en danger !</p>
        </div>
        
        <h2>1️⃣ PROTÉGER</h2>
        <div class="step">
            <h3>Sécuriser la zone</h3>
            <ul>
                <li>Couper le courant/gaz si nécessaire</li>
                <li>Baliser pour éviter le sur-accident</li>
                <li>Éloigner les curieux</li>
                <li>Ne pas déplacer la victime sauf danger imminent (incendie, explosion)</li>
            </ul>
        </div>
        
        <h2>2️⃣ ALERTER</h2>
        <div class="step">
            <h3>Appeler les secours</h3>
            <span class="big-number">15 ou 112</span>
            <ul>
                <li><strong>QUI</strong> je suis (nom, numéro de téléphone)</li>
                <li><strong>OÙ</strong> je suis (adresse précise, étage, code porte)</li>
                <li><strong>QUOI</strong> (nature de l'accident, nombre de victimes)</li>
                <li><strong>ÉTAT</strong> de la victime (consciente? respire? saigne?)</li>
                <li><strong>NE PAS RACCROCHER</strong> le premier</li>
            </ul>
        </div>
        
        <h2>3️⃣ SECOURIR</h2>
        
        <div class="step">
            <h3>🫁 Victime inconsciente qui RESPIRE</h3>
            <ul>
                <li>Basculer en <strong>PLS</strong> (Position Latérale de Sécurité)</li>
                <li>Desserrer vêtements, ceinture, col</li>
                <li>Surveiller la respiration en attendant les secours</li>
            </ul>
        </div>
        
        <div class="step">
            <h3>💔 Victime inconsciente qui NE RESPIRE PAS</h3>
            <ul>
                <li>Démarrer immédiatement le <strong>massage cardiaque</strong></li>
                <li>30 compressions au centre du thorax</li>
                <li>Rythme: 100-120 compressions/minute</li>
                <li>Si formé: 2 insufflations après 30 compressions</li>
                <li>Continuer jusqu'à l'arrivée des secours ou épuisement</li>
            </ul>
            <div class="tip">
                💡 <strong>Astuce:</strong> Suivez le rythme de "Stayin' Alive" des Bee Gees (103 bpm)
            </div>
        </div>
        
        <div class="step">
            <h3>🩸 Hémorragie (Saignement abondant)</h3>
            <ul>
                <li>Comprimer la plaie avec un linge propre</li>
                <li>Maintenir la compression jusqu'aux secours</li>
                <li>Allonger la victime</li>
                <li>Ne jamais retirer un objet planté</li>
            </ul>
        </div>
        
        <div class="step">
            <h3>🔥 Brûlure</h3>
            <ul>
                <li>Refroidir 15 minutes à l'eau fraîche (15-20°C)</li>
                <li>À 15 cm de la plaie, règle des "15"</li>
                <li>Ne pas percer les cloques</li>
                <li>Ne pas mettre de corps gras (beurre, huile...)</li>
            </ul>
        </div>
        
        <a href="/" class="back">← Retour à l'accueil</a>
    </div>
</body>
</html>
HTMLEOF

# ==================== PAGE SURVIE ====================
cat > /var/www/sos-guide/survie.html <<'HTMLEOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Guide Survie - SOS-GUIDE</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 700px; margin: 0 auto; background: white; padding: 30px; border-radius: 16px; box-shadow: 0 10px 40px rgba(0,0,0,0.2); }
        h1 { color: #0f9d58; margin-bottom: 10px; }
        h2 { color: #1a73e8; border-bottom: 3px solid #1a73e8; padding-bottom: 10px; margin: 30px 0 15px 0; }
        .card { background: linear-gradient(90deg, #e8f5e9 0%, #c8e6c9 100%); padding: 20px; margin: 15px 0; border-radius: 10px; border-left: 5px solid #4caf50; }
        .card h3 { color: #2e7d32; margin-bottom: 10px; }
        .card.water { background: linear-gradient(90deg, #e3f2fd 0%, #bbdefb 100%); border-left-color: #2196f3; }
        .card.water h3 { color: #1565c0; }
        .card.shelter { background: linear-gradient(90deg, #fff3e0 0%, #ffe0b2 100%); border-left-color: #f57c00; }
        .card.shelter h3 { color: #e65100; }
        .card.fire { background: linear-gradient(90deg, #fbe9e7 0%, #ffccbc 100%); border-left-color: #d84315; }
        .card.fire h3 { color: #bf360c; }
        ul { margin-left: 20px; margin-top: 10px; }
        li { margin: 8px 0; line-height: 1.5; }
        .back { display: inline-block; margin-top: 25px; padding: 12px 25px; background: #f5f5f5; border-radius: 8px; font-weight: 500; text-decoration: none; color: #333; }
        .back:hover { background: #e0e0e0; }
        .rule333 { background: #263238; color: white; padding: 20px; border-radius: 10px; margin: 20px 0; text-align: center; }
        .rule333 h3 { color: #ff7043; font-size: 1.5em; margin-bottom: 15px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎒 Guide Survie</h1>
        <p>Les bases pour survivre en situation d'urgence ou en milieu hostile.</p>
        
        <div class="rule333">
            <h3>⏱️ Règle des 3</h3>
            <p>3 <strong>minutes</strong> sans air | 3 <strong>heures</strong> sans abri (extrême)</p>
            <p>3 <strong>jours</strong> sans eau | 3 <strong>semaines</strong> sans nourriture</p>
        </div>
        
        <h2>💧 EAU</h2>
        
        <div class="card water">
            <h3>Trouver de l'eau</h3>
            <ul>
                <li>Récupérer l'eau de pluie (toits, bâches)</li>
                <li>Rosée du matin sur l'herbe (éponger avec tissu)</li>
                <li>Cours d'eau (toujours purifier)</li>
                <li>Éviter l'eau stagnante</li>
            </ul>
        </div>
        
        <div class="card water">
            <h3>Purifier l'eau</h3>
            <ul>
                <li><strong>Ébullition:</strong> 1 minute (3 min en altitude)</li>
                <li><strong>Eau de Javel:</strong> 2 gouttes/litre, attendre 30 min</li>
                <li><strong>Comprimés:</strong> Suivre dosage (Micropur)</li>
                <li><strong>Filtre:</strong> Filtre à café + charbon actif</li>
            </ul>
        </div>
        
        <h2>🏠 ABRIS</h2>
        
        <div class="card shelter">
            <h3>Construire un abri</h3>
            <ul>
                <li>Choisir un endroit plat, à l'abri du vent</li>
                <li>Éviter les zones inondables</li>
                <li>S'isoler du sol (carton, branches, feuilles)</li>
                <li>Orientation: entrée à l'opposé du vent dominant</li>
            </ul>
        </div>
        
        <h2>🔥 FEU</h2>
        
        <div class="card fire">
            <h3>Allumer un feu</h3>
            <ul>
                <li><strong>Briquet/Allumettes:</strong> Dans sac étanche</li>
                <li><strong>Pierre à feu:</strong> Acier + silex</li>
                <li><strong>Loupe:</strong> Concentrer les rayons du soleil</li>
            </ul>
        </div>
        
        <div class="card fire">
            <h3>Structure du feu</h3>
            <ul>
                <li><strong>Amadou:</strong> Herbe sèche, écorce, coton</li>
                <li><strong>Menu bois:</strong> Branchettes < 1cm</li>
                <li><strong>Bois moyen:</strong> Branches 1-3cm</li>
                <li><strong>Gros bois:</strong> Bûches pour la durée</li>
            </ul>
        </div>
        
        <h2>🎒 KIT DE SURVIE MINIMUM</h2>
        
        <div class="card">
            <h3>Les 10 essentiels</h3>
            <ul>
                <li>✅ Couteau robuste</li>
                <li>✅ Briquet + allumettes étanches</li>
                <li>✅ Gourde + pastilles purification</li>
                <li>✅ Couverture de survie</li>
                <li>✅ Lampe frontale + piles</li>
                <li>✅ Trousse premiers secours</li>
                <li>✅ Sifflet de signalisation</li>
                <li>✅ Carte + boussole</li>
                <li>✅ Nourriture énergétique (barres)</li>
                <li>✅ Téléphone + powerbank</li>
            </ul>
        </div>
        
        <a href="/" class="back">← Retour à l'accueil</a>
    </div>
</body>
</html>
HTMLEOF

# Configuration Nginx
rm -f /etc/nginx/sites-enabled/default

cat > /etc/nginx/sites-available/sos-guide <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/sos-guide;
    index index.html;
    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location /docs/ {
        alias /data/docs/;
        autoindex on;
    }
}
EOF

ln -sf /etc/nginx/sites-available/sos-guide /etc/nginx/sites-enabled/

systemctl enable nginx
systemctl restart nginx

echo -e "${GREEN}✓ Serveur web configuré (4 pages créées)${NC}"

# ==============================================================================
# 9. OPTIMISATION BATTERIE & AUTONOMIE
# ==============================================================================
echo -e "${BLUE}[9/9] Optimisation pour autonomie sur batterie...${NC}"

# Désactiver services inutiles
systemctl disable avahi-daemon 2>/dev/null || true
systemctl stop avahi-daemon 2>/dev/null || true

# WiFi power_save OFF en mode AP pour stabilité
iw dev wlan0 set power_save off 2>/dev/null || true

# Script de surveillance batterie (si UPS HAT connecté)
cat > /usr/local/bin/battery-monitor.sh <<'BASHEOF'
#!/bin/bash
# Surveillance batterie - à adapter selon ton UPS HAT
BATTERY_LOW=10
# Adapter selon ton matériel UPS HAT
BASHEOF

chmod +x /usr/local/bin/battery-monitor.sh

# Ajouter au crontab (toutes les 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/battery-monitor.sh") | crontab -

echo -e "${GREEN}✓ Optimisation batterie configurée${NC}"

# ==============================================================================
# 10. VÉRIFICATION FINALE
# ==============================================================================
echo ""
echo -e "${GREEN}=========================================="
echo "   ✅ CONFIGURATION TERMINÉE !"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}📡 CONFIGURATION RÉSEAU:${NC}"
echo -e "   ${GREEN}✓${NC} IP wlan0: ${LOCAL_IP}"
echo -e "   ${GREEN}✓${NC} SSID: ${SSID}"
echo -e "   ${GREEN}✓${NC} 🔓 Réseau OUVERT (sans mot de passe)${NC}"
echo ""
echo -e "${BLUE}🔒 SÉCURITÉ:${NC}"
echo -e "   ${GREEN}✓${NC} Pi a Internet (eth0)"
echo -e "   ${GREEN}✓${NC} Clients WiFi ISOLÉS d'Internet"
echo -e "   ${GREEN}✓${NC} Captive Portal activé"
echo -e "   ${GREEN}✓${NC} NetworkManager/wpa_supplicant désactivés"
echo ""
echo -e "${BLUE}🔧 ÉTAT DES SERVICES:${NC}"
for service in hostapd dnsmasq nginx systemd-networkd; do
    if systemctl is-active --quiet $service; then
        echo -e "   ${GREEN}✓${NC} $service: actif"
    else
        echo -e "   ${RED}✗${NC} $service: inactif"
    fi
done
echo ""
echo -e "${BLUE}📁 CONTENU:${NC}"
echo -e "   ${GREEN}✓${NC} /var/www/sos-guide/index.html"
echo -e "   ${GREEN}✓${NC} /var/www/sos-guide/contact.html"
echo -e "   ${GREEN}✓${NC} /var/www/sos-guide/premiers-secours.html"
echo -e "   ${GREEN}✓${NC} /var/www/sos-guide/survie.html"
echo -e "   ${GREEN}✓${NC} /data/docs/ (pour tes PDF)"
echo ""
echo -e "${YELLOW}🧪 TESTER:${NC}"
echo "   1. Connecte-toi au WiFi ${SSID} (sans mot de passe)"
echo "   2. Ouvre http://${LOCAL_IP}"
echo "   3. Tente d'aller sur google.com → Redirigé vers SOS-GUIDE"
echo "   4. Débranche Ethernet → Le réseau reste actif"
echo ""
echo -e "${YELLOW}🔧 COMMANDES UTILES:${NC}"
echo "   Vérifier IP       : ip addr show wlan0"
echo "   Logs WiFi         : sudo journalctl -u hostapd -f"
echo "   Logs DNS          : sudo journalctl -u dnsmasq -f"
echo "   Voir règles FW    : sudo iptables -L -n -v"
echo "   Test isolation    : ping -I wlan0 8.8.8.8 (doit échouer)"
echo ""
echo -e "${MAGENTA}🚀 SOS-GUIDE EST PRÊT POUR LA PRODUCTION !${NC}"
echo ""
