#!/bin/bash

#================================================================================
#
#          FILE:  gaming_xray_install.sh
#
#   DESCRIPTION:  Gaming-optimized Xray-core installation script with low-latency
#                 configurations for VLESS-XTLS-Reality protocol optimized for gaming.
#
#       VERSION:  1.2.1 (Gaming Performance Optimized)
#        AUTHOR:  Team AviterX
#
#================================================================================

# --- Color Codes ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Global Variables ---
XRAY_INSTALL_DIR="/usr/local/etc/xray"
XRAY_CONFIG_FILE="${XRAY_INSTALL_DIR}/config.json"
XRAY_BINARY_PATH="/usr/local/bin/xray"
SERVICE_FILE_PATH="/etc/systemd/system/xray.service"

# --- Helper Functions ---
function print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}🎮 ${message}${NC}"
}

function check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        print_message "$RED" "This script must be run as root. Please use 'sudo' or run as the root user."
        exit 1
    fi
}

function optimize_system_for_gaming() {
    print_message "$PURPLE" "Applying gaming-specific system optimizations..."
    
    # Network optimizations for low latency
    cat > /etc/sysctl.d/99-gaming-network.conf << EOF
# Gaming Network Optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_no_delay = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
EOF

    sysctl -p /etc/sysctl.d/99-gaming-network.conf
    print_message "$GREEN" "Gaming network optimizations applied!"
}

function update_system() {
    print_message "$BLUE" "Updating system packages for optimal performance..."
    if ! apt-get update && apt-get upgrade -y; then
        print_message "$RED" "Failed to update system packages. Please check your network connection."
        exit 1
    fi
    print_message "$GREEN" "System packages updated successfully."
}

function install_dependencies() {
    print_message "$BLUE" "Installing gaming-optimized dependencies..."
    if ! apt-get install -y curl socat wget unzip git openssl htop iftop iperf3 net-tools; then
        print_message "$RED" "Failed to install dependencies."
        exit 1
    fi
    print_message "$GREEN" "Dependencies installed successfully."
}

function install_xray() {
    print_message "$BLUE" "Installing latest Xray-core for maximum performance..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    if [[ ! -f "$XRAY_BINARY_PATH" ]]; then
        print_message "$RED" "Xray installation failed."
        exit 1
    fi
    print_message "$GREEN" "Xray-core installed successfully."
}

function generate_keys() {
    print_message "$BLUE" "Generating Reality key pair for secure gaming..."
    
    local temp_file=$(mktemp)
    
    if ! "$XRAY_BINARY_PATH" x25519 > "$temp_file" 2>&1; then
        print_message "$RED" "Failed to execute xray x25519 command."
        rm -f "$temp_file"
        exit 1
    fi
    
    # Parse keys with multiple fallback methods
    PRIVATE_KEY=$(grep -i "private" "$temp_file" | awk '{print $NF}' | head -1)
    PUBLIC_KEY=$(grep -i "public" "$temp_file" | awk '{print $NF}' | head -1)
    
    if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ [Pp]rivate.*key:?[[:space:]]*([A-Za-z0-9+/=_-]+) ]]; then
                PRIVATE_KEY="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ [Pp]ublic.*key:?[[:space:]]*([A-Za-z0-9+/=_-]+) ]]; then
                PUBLIC_KEY="${BASH_REMATCH[1]}"
            fi
        done < "$temp_file"
    fi
    
    if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
        local keys=($(grep -oE '[A-Za-z0-9+/=_-]{40,}' "$temp_file"))
        if [[ ${#keys[@]} -ge 2 ]]; then
            PRIVATE_KEY="${keys[0]}"
            PUBLIC_KEY="${keys[1]}"
        fi
    fi
    
    rm -f "$temp_file"
    
    if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
        print_message "$RED" "Failed to generate Reality key pair."
        exit 1
    fi
    
    print_message "$GREEN" "Reality key pair generated successfully."
}

function get_gaming_input() {
    print_message "$CYAN" "🎮 Gaming Configuration Setup 🎮"
    echo
    
    read -rp "Enter a UUID (or press Enter to generate one): " UUID
    if [[ -z "$UUID" ]]; then
        UUID=$(cat /proc/sys/kernel/random/uuid)
        print_message "$GREEN" "Generated UUID: $UUID"
    fi

    print_message "$YELLOW" "Recommended gaming ports: 443 (most stable), 80, 8080, 2053, 2083, 2087, 2096"
    read -rp "Enter the listening port for gaming (default: 443): " LISTEN_PORT
    LISTEN_PORT=${LISTEN_PORT:-443}

    print_message "$YELLOW" "Popular gaming-friendly SNI domains:"
    print_message "$CYAN" "• www.cloudflare.com (fastest CDN)"
    print_message "$CYAN" "• www.microsoft.com (gaming services)"
    print_message "$CYAN" "• discord.com (gaming community)"
    print_message "$CYAN" "• www.nvidia.com (gaming hardware)"
    print_message "$CYAN" "• store.steampowered.com (gaming platform)"
    echo
    read -rp "Enter SNI domain (default: www.cloudflare.com): " SNI_DOMAIN
    SNI_DOMAIN=${SNI_DOMAIN:-www.cloudflare.com}

    print_message "$YELLOW" "Gaming optimization level:"
    print_message "$CYAN" "1. Ultra Low Latency (competitive gaming)"
    print_message "$CYAN" "2. Balanced Performance (general gaming)"
    print_message "$CYAN" "3. High Throughput (downloads/streaming)"
    read -rp "Choose optimization level (1-3, default: 1): " OPT_LEVEL
    OPT_LEVEL=${OPT_LEVEL:-1}
}

function create_gaming_config() {
    print_message "$BLUE" "Creating gaming-optimized Xray configuration..."

    SHORT_ID=$(openssl rand -hex 8)
    mkdir -p "$XRAY_INSTALL_DIR"

    # Set flow based on optimization level
    case $OPT_LEVEL in
        1) FLOW_TYPE="xtls-rprx-vision" ;;
        2) FLOW_TYPE="xtls-rprx-vision" ;;
        3) FLOW_TYPE="" ;;
    esac

    # Create optimized config
    cat > "$XRAY_CONFIG_FILE" << EOF
{
  "log": {
    "loglevel": "warning"
  },
  "stats": {},
  "api": {
    "tag": "api",
    "services": ["HandlerService", "LoggerService", "StatsService"]
  },
  "policy": {
    "levels": {
      "0": {
        "handshake": 2,
        "connIdle": 120,
        "uplinkOnly": 0,
        "downlinkOnly": 0,
        "bufferSize": 65536,
        "statsUserUplink": false,
        "statsUserDownlink": false
      }
    },
    "system": {
      "statsInboundUplink": false,
      "statsInboundDownlink": false,
      "statsOutboundUplink": false,
      "statsOutboundDownlink": false
    }
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": ${LISTEN_PORT},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "flow": "${FLOW_TYPE}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "tcpSettings": {
          "acceptProxyProtocol": false,
          "noDelay": true,
          "keepAlive": true
        },
        "realitySettings": {
          "show": false,
          "dest": "${SNI_DOMAIN}:443",
          "xver": 0,
          "serverNames": [
            "${SNI_DOMAIN}"
          ],
          "privateKey": "${PRIVATE_KEY}",
          "minClientVer": "",
          "maxClientVer": "",
          "maxTimeDiff": 0,
          "shortIds": [
            "${SHORT_ID}",
            ""
          ]
        }
      },
      "sniffing": {
        "enabled": false
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIPv4"
      },
      "streamSettings": {
        "sockopt": {
          "tcpNoDelay": true,
          "tcpKeepAlive": true,
          "tcpFastOpen": true,
          "mark": 0
        }
      }
    },
    {
      "tag": "blocked",
      "protocol": "blackhole",
      "settings": {}
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "domain": [
          "geosite:ads"
        ],
        "outboundTag": "blocked"
      }
    ]
  }
}
EOF

    chmod 644 "$XRAY_CONFIG_FILE"
    print_message "$GREEN" "Gaming-optimized Xray configuration created!"
}

function create_gaming_service() {
    print_message "$BLUE" "Creating gaming-optimized systemd service..."
    
    cat > "$SERVICE_FILE_PATH" << EOF
[Unit]
Description=Xray Gaming Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
Type=notify
User=root
ExecStart=${XRAY_BINARY_PATH} run -config ${XRAY_CONFIG_FILE}
ExecReload=/bin/kill -HUP \$MAINPID
KillSignal=SIGTERM
Restart=on-failure
RestartSec=2
LimitNOFILE=1000000
LimitNPROC=1000000
# Gaming optimizations
Nice=-10
IOSchedulingClass=1
IOSchedulingPriority=4
CPUSchedulingPolicy=1
CPUSchedulingPriority=50

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    print_message "$GREEN" "Gaming-optimized service created!"
}

function configure_gaming_firewall() {
    print_message "$BLUE" "Configuring gaming-friendly firewall..."
    
    if command -v ufw >/dev/null 2>&1; then
        # Gaming ports
        ufw allow "$LISTEN_PORT"/tcp
        # Common gaming ports
        ufw allow 3074/tcp  # Xbox Live
        ufw allow 3074/udp  # Xbox Live
        ufw allow 1935/tcp  # PlayStation
        ufw allow 80/tcp    # HTTP
        ufw allow 53/udp    # DNS
        print_message "$GREEN" "Gaming firewall configured!"
    else
        print_message "$YELLOW" "UFW not found. Please manually configure firewall."
    fi
}

function display_gaming_info() {
    local ip_address
    ip_address=$(curl -s https://api.ipify.org || curl -s https://ipinfo.io/ip)

    echo
    print_message "$PURPLE" "🎮 ═══════════════════════════════════════════════════════════════ 🎮"
    print_message "$CYAN" "                    GAMING XRAY REALITY SETUP COMPLETE                    "
    print_message "$PURPLE" "🎮 ═══════════════════════════════════════════════════════════════ 🎮"
    echo
    print_message "$GREEN" "🌐 Protocol: VLESS + XTLS Reality (Gaming Optimized)"
    print_message "$GREEN" "🎯 Server IP: ${ip_address}"
    print_message "$GREEN" "🔌 Port: ${LISTEN_PORT}"
    print_message "$GREEN" "🆔 UUID: ${UUID}"
    print_message "$GREEN" "⚡ Flow: ${FLOW_TYPE:-none} (Level ${OPT_LEVEL} optimization)"
    print_message "$GREEN" "🔒 Security: Reality"
    print_message "$GREEN" "🌍 SNI: ${SNI_DOMAIN}"
    print_message "$GREEN" "🔑 Public Key: ${PUBLIC_KEY}"
    print_message "$GREEN" "📋 Short ID: ${SHORT_ID}"
    echo
    
    # Gaming performance indicators
    case $OPT_LEVEL in
        1) print_message "$CYAN" "⚡ Optimization: Ultra Low Latency (Best for FPS/MOBA games)" ;;
        2) print_message "$CYAN" "⚡ Optimization: Balanced Performance (General gaming)" ;;
        3) print_message "$CYAN" "⚡ Optimization: High Throughput (Downloads/Streaming)" ;;
    esac
    
    echo
    print_message "$YELLOW" "🔗 Gaming Share Link (Import into your client):"
    local encoded_sni=$(printf '%s' "$SNI_DOMAIN" | sed 's/ /%20/g')
    local share_link="vless://${UUID}@${ip_address}:${LISTEN_PORT}?security=reality&sni=${encoded_sni}&flow=${FLOW_TYPE}&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#Gaming_Xray_${OPT_LEVEL}"
    echo "${share_link}"
    echo
    
    # Save gaming connection info
    cat > "/root/gaming_xray_info.txt" << EOF
🎮 Gaming Xray Reality Connection Info 🎮
==========================================
Protocol: VLESS + XTLS Reality
Server IP: ${ip_address}
Port: ${LISTEN_PORT}
UUID: ${UUID}
Flow: ${FLOW_TYPE}
Security: Reality
SNI: ${SNI_DOMAIN}
Public Key: ${PUBLIC_KEY}
Short ID: ${SHORT_ID}
Optimization Level: ${OPT_LEVEL}

Gaming Share Link:
${share_link}

Gaming Tips:
- Use UDP acceleration in your client if available
- Connect to the nearest server location
- Close unnecessary background apps while gaming
- Consider using gaming mode in your client
==========================================
EOF
    
    print_message "$GREEN" "📄 Connection info saved to /root/gaming_xray_info.txt"
    print_message "$PURPLE" "🎮 ═══════════════════════════════════════════════════════════════ 🎮"
}

function run_speed_test() {
    print_message "$BLUE" "Running connection speed test..."
    if command -v iperf3 >/dev/null 2>&1; then
        print_message "$CYAN" "You can test your connection speed with:"
        print_message "$YELLOW" "iperf3 -s (on server)"
        print_message "$YELLOW" "iperf3 -c YOUR_SERVER_IP (on client)"
    fi
}

# --- Main Function ---
function main() {
    clear
    print_message "$PURPLE" "🎮 Welcome to Gaming Xray Reality Installer! 🎮"
    print_message "$CYAN" "Optimized for low-latency gaming performance"
    echo
    
    check_root
    optimize_system_for_gaming
    update_system
    install_dependencies
    install_xray
    generate_keys
    get_gaming_input
    create_gaming_config
    create_gaming_service
    configure_gaming_firewall

    print_message "$BLUE" "🚀 Starting gaming-optimized Xray service..."
    systemctl daemon-reload
    systemctl restart xray
    systemctl enable xray
    
    sleep 3

    if systemctl is-active --quiet xray; then
        print_message "$GREEN" "✅ Xray gaming service is running perfectly!"
    else
        print_message "$RED" "❌ Service failed to start. Checking logs..."
        journalctl -u xray --no-pager -n 20
        exit 1
    fi

    display_gaming_info
    run_speed_test
    
    echo
    print_message "$GREEN" "🎉 Gaming Xray setup complete!"
    print_message "$YELLOW" "💡 Gaming Tips:"
    print_message "$CYAN" "   • systemctl status xray (check status)"
    print_message "$CYAN" "   • journalctl -u xray -f (view logs)"
    print_message "$CYAN" "   • htop (monitor system performance)"
    print_message "$CYAN" "   • iftop (monitor network usage)"
    echo
    print_message "$PURPLE" "🎮 Happy Gaming! May your ping be low and FPS high! 🎮"
}

# --- Script Execution ---
main
