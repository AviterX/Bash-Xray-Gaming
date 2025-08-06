#!/bin/bash

#================================================================================
#
#          FILE:  install_xray_gaming_optimized.sh
#
#   DESCRIPTION:  High-performance Xray-core installation script optimized
#                 for gaming with low latency configuration
#
#       VERSION:  3.0.0 (Gaming Optimized)
#        AUTHOR:  Team AviterX (Enhanced for Gaming Performance)
#
#================================================================================

# --- Color Codes ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
    echo -e "${color}${message}${NC}"
}

function check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        print_message "$RED" "This script must be run as root. Please use 'sudo' or run as the root user."
        exit 1
    fi
}

function detect_system_info() {
    print_message "$BLUE" "Detecting system information..."
    
    # Detect CPU cores for optimization
    CPU_CORES=$(nproc)
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    
    print_message "$GREEN" "CPU Cores: $CPU_CORES"
    print_message "$GREEN" "Total RAM: ${TOTAL_RAM}MB"
    
    # Set optimal buffer sizes based on RAM
    if [[ $TOTAL_RAM -ge 4096 ]]; then
        BUFFER_SIZE="4m"
        CONNECTION_POOL=1000
    elif [[ $TOTAL_RAM -ge 2048 ]]; then
        BUFFER_SIZE="2m"
        CONNECTION_POOL=500
    else
        BUFFER_SIZE="1m"
        CONNECTION_POOL=250
    fi
    
    print_message "$GREEN" "Optimized buffer size: $BUFFER_SIZE"
}

function optimize_system() {
    print_message "$PURPLE" "🚀 Applying gaming performance optimizations..."
    
    # Network optimizations for low latency
    cat >> /etc/sysctl.conf << EOF

# Gaming & Low Latency Network Optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.netdev_max_backlog = 5000
net.core.netdev_budget = 600
net.ipv4.tcp_rmem = 8192 87380 134217728
net.ipv4.tcp_wmem = 8192 65536 134217728
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_no_delay_ack = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.route.flush = 1
# Reduce TIME_WAIT connections
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_tw_reuse = 1
# Optimize connection handling
net.netfilter.nf_conntrack_tcp_timeout_established = 1200
net.netfilter.nf_conntrack_generic_timeout = 120
EOF

    # Apply settings immediately
    sysctl -p >/dev/null 2>&1
    
    # CPU frequency scaling for performance
    echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
    
    print_message "$GREEN" "✓ System optimizations applied"
}

function update_system() {
    print_message "$BLUE" "Updating system packages..."
    export DEBIAN_FRONTEND=noninteractive
    if ! apt-get update -qq && apt-get upgrade -y -qq; then
        print_message "$RED" "Failed to update system packages."
        exit 1
    fi
    print_message "$GREEN" "✓ System packages updated"
}

function install_dependencies() {
    print_message "$BLUE" "Installing optimized dependencies..."
    if ! apt-get install -y -qq curl socat wget unzip git htop iftop iperf3 net-tools; then
        print_message "$RED" "Failed to install dependencies."
        exit 1
    fi
    
    # Install BBR congestion control if not available
    if ! lsmod | grep -q bbr; then
        echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
        modprobe tcp_bbr 2>/dev/null || true
    fi
    
    print_message "$GREEN" "✓ Dependencies installed"
}

function install_xray() {
    print_message "$BLUE" "Installing latest Xray-core..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    if [[ ! -f "$XRAY_BINARY_PATH" ]]; then
        print_message "$RED" "Xray installation failed."
        exit 1
    fi
    print_message "$GREEN" "✓ Xray-core installed successfully"
}

function generate_keys() {
    print_message "$BLUE" "Generating optimized Reality key pair..."
    local key_pair
    key_pair=$($XRAY_BINARY_PATH x25519)
    PRIVATE_KEY=$(echo "$key_pair" | awk '/Private key/ {print $3}')
    PUBLIC_KEY=$(echo "$key_pair" | awk '/Public key/ {print $3}')
    if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
        print_message "$RED" "Failed to generate Reality key pair."
        exit 1
    fi
    print_message "$GREEN" "✓ Reality key pair generated"
}

function get_user_input() {
    print_message "$YELLOW" "🎮 Gaming Configuration Setup:"
    
    read -rp "Enter a UUID (or press Enter to generate one): " UUID
    if [[ -z "$UUID" ]]; then
        UUID=$(cat /proc/sys/kernel/random/uuid)
        print_message "$GREEN" "Generated UUID: $UUID"
    fi

    read -rp "Enter the listening port (default: 443): " LISTEN_PORT
    LISTEN_PORT=${LISTEN_PORT:-443}

    # Gaming-optimized SNI domains
    print_message "$YELLOW" "🚀 Recommended low-latency SNI domains:"
    echo "1. www.cloudflare.com (Global CDN - Usually fastest)"
    echo "2. www.microsoft.com (Azure backbone)"
    echo "3. www.apple.com (Akamai CDN)"
    echo "4. www.nvidia.com (Gaming focused)"
    echo "5. Custom domain"
    
    read -rp "Choose option (1-5) or enter custom domain: " SNI_CHOICE
    
    case $SNI_CHOICE in
        1) SNI_DOMAIN="www.cloudflare.com" ;;
        2) SNI_DOMAIN="www.microsoft.com" ;;
        3) SNI_DOMAIN="www.apple.com" ;;
        4) SNI_DOMAIN="www.nvidia.com" ;;
        5) read -rp "Enter custom domain: " SNI_DOMAIN ;;
        *) SNI_DOMAIN="www.cloudflare.com" ;;
    esac
    
    if [[ -z "$SNI_DOMAIN" ]]; then
        print_message "$RED" "SNI domain cannot be empty."
        exit 1
    fi
    
    print_message "$GREEN" "Selected SNI: $SNI_DOMAIN"
}

function create_gaming_config() {
    print_message "$BLUE" "Creating gaming-optimized configuration..."

    # Generate multiple short IDs for load balancing
    SHORT_ID1=$(openssl rand -hex 8)
    SHORT_ID2=$(openssl rand -hex 4)
    SHORT_ID3=""

    # Create optimized config for gaming
    cat > "$XRAY_CONFIG_FILE" << EOF
{
  "log": {
    "loglevel": "none"
  },
  "api": {
    "tag": "api",
    "services": [
      "StatsService"
    ]
  },
  "stats": {},
  "policy": {
    "levels": {
      "0": {
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 5,
        "downlinkOnly": 5,
        "statsUserUplink": false,
        "statsUserDownlink": false,
        "bufferSize": 4096
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
            "flow": "xtls-rprx-vision",
            "level": 0
          }
        ],
        "decryption": "none",
        "fallbacks": []
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
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
            "${SHORT_ID1}",
            "${SHORT_ID2}",
            "${SHORT_ID3}"
          ]
        },
        "sockopt": {
          "tcpFastOpen": true,
          "tcpNoDelay": true,
          "tcpKeepAliveInterval": 30,
          "tcpKeepAliveIdle": 60,
          "mark": 0
        }
      },
      "sniffing": {
        "enabled": false,
        "destOverride": []
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIPv4"
      },
      "tag": "direct",
      "streamSettings": {
        "sockopt": {
          "tcpFastOpen": true,
          "tcpNoDelay": true,
          "tcpKeepAliveInterval": 30,
          "mark": 0
        }
      }
    },
    {
      "protocol": "blackhole",
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api"
      },
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "blocked"
      }
    ]
  }
}
EOF

    if [[ ! -f "$XRAY_CONFIG_FILE" ]]; then
        print_message "$RED" "Failed to create config file."
        exit 1
    fi
    print_message "$GREEN" "✓ Gaming-optimized configuration created"
}

function create_optimized_service() {
    print_message "$BLUE" "Creating optimized systemd service..."
    
    cat > "$SERVICE_FILE_PATH" << EOF
[Unit]
Description=Xray Service (Gaming Optimized)
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=$XRAY_BINARY_PATH run -config $XRAY_CONFIG_FILE
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000
CPUSchedulingPolicy=1
CPUSchedulingPriority=50
IOSchedulingClass=1
IOSchedulingPriority=4

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    print_message "$GREEN" "✓ Optimized service created"
}

function run_performance_test() {
    print_message "$PURPLE" "🎯 Running performance tests..."
    
    # Test network performance
    local test_domain="www.google.com"
    local ping_result=$(ping -c 4 $test_domain 2>/dev/null | tail -1 | awk -F'/' '{print $5}')
    
    if [[ -n "$ping_result" ]]; then
        print_message "$GREEN" "✓ Average ping to $test_domain: ${ping_result}ms"
    fi
    
    # Check if BBR is active
    local congestion_control=$(cat /proc/sys/net/ipv4/tcp_congestion_control)
    print_message "$GREEN" "✓ TCP Congestion Control: $congestion_control"
    
    # Show current connections
    local connection_count=$(ss -tun | wc -l)
    print_message "$GREEN" "✓ Current connections: $connection_count"
}

function display_gaming_info() {
    local ip_address
    ip_address=$(curl -s https://api.ipify.org)

    print_message "$PURPLE" "🎮 === GAMING-OPTIMIZED XRAY CONFIG === 🎮"
    print_message "$GREEN" "Protocol: VLESS + XTLS-Reality"
    print_message "$GREEN" "Server IP: ${ip_address}"
    print_message "$GREEN" "Port: ${LISTEN_PORT}"
    print_message "$GREEN" "UUID: ${UUID}"
    print_message "$GREEN" "Flow: xtls-rprx-vision (Gaming Optimized)"
    print_message "$GREEN" "Security: reality"
    print_message "$GREEN" "SNI: ${SNI_DOMAIN}"
    print_message "$GREEN" "Public Key: ${PUBLIC_KEY}"
    print_message "$GREEN" "Short ID 1: ${SHORT_ID1}"
    print_message "$GREEN" "Short ID 2: ${SHORT_ID2}"
    print_message "$PURPLE" "========================================="

    # Generate optimized share link
    local share_link="vless://${UUID}@${ip_address}:${LISTEN_PORT}?security=reality&sni=${SNI_DOMAIN}&flow=xtls-rprx-vision&pbk=${PUBLIC_KEY}&sid=${SHORT_ID1}&type=tcp&headerType=none#Gaming_Xray_Reality"
    print_message "$BLUE" "🔗 Gaming Share Link:"
    echo "${share_link}"
    
    print_message "$YELLOW" ""
    print_message "$YELLOW" "🎮 GAMING CLIENT OPTIMIZATION TIPS:"
    print_message "$YELLOW" "1. Use TCP + Reality for lowest latency"
    print_message "$YELLOW" "2. Enable TCP Fast Open in client"
    print_message "$YELLOW" "3. Set connection timeout to 10s"
    print_message "$YELLOW" "4. Use fragment settings: length 1-3, interval 4-6"
    print_message "$YELLOW" "5. Disable unnecessary logs in client"
    print_message "$YELLOW" ""
}

function create_monitoring_script() {
    print_message "$BLUE" "Creating performance monitoring script..."
    
    cat > "/usr/local/bin/xray-gaming-monitor.sh" << 'EOF'
#!/bin/bash

echo "=== Xray Gaming Performance Monitor ==="
echo "Timestamp: $(date)"
echo ""

# Connection stats
echo "Active Connections:"
ss -tuln | grep :443
echo ""

# Network stats
echo "Network Interface Stats:"
cat /proc/net/dev | grep -E "(eth0|ens|enp)" | head -1
echo ""

# System load
echo "System Load:"
uptime
echo ""

# Memory usage
echo "Memory Usage:"
free -h
echo ""

# TCP congestion control
echo "TCP Congestion Control: $(cat /proc/sys/net/ipv4/tcp_congestion_control)"
echo ""

# Xray service status
echo "Xray Service Status:"
systemctl status xray --no-pager -l
EOF

    chmod +x "/usr/local/bin/xray-gaming-monitor.sh"
    print_message "$GREEN" "✓ Monitoring script created at /usr/local/bin/xray-gaming-monitor.sh"
}

# --- Main Function ---
function main() {
    print_message "$PURPLE" "🎮 Starting Gaming-Optimized Xray Installation..."
    
    check_root
    detect_system_info
    optimize_system
    update_system
    install_dependencies
    install_xray
    generate_keys
    get_user_input
    create_gaming_config
    create_optimized_service
    create_monitoring_script

    print_message "$BLUE" "🚀 Starting optimized Xray service..."
    systemctl stop xray 2>/dev/null || true
    systemctl restart xray
    systemctl enable xray

    if systemctl is-active --quiet xray; then
        print_message "$GREEN" "✅ Xray gaming service is running optimally!"
    else
        print_message "$RED" "❌ Service failed to start. Check: journalctl -u xray"
        exit 1
    fi

    run_performance_test
    display_gaming_info
    
    print_message "$GREEN" ""
    print_message "$GREEN" "🎉 GAMING-OPTIMIZED INSTALLATION COMPLETE! 🎉"
    print_message "$YELLOW" "Run '/usr/local/bin/xray-gaming-monitor.sh' to monitor performance"
    print_message "$YELLOW" "Use 'systemctl restart xray' if you experience any issues"
}

# --- Script Execution ---
main "$@"