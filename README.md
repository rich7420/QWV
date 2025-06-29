# QWV - QuickWireguardVpn

🚀 Build a modern, secure, and maintainable personal VPN using Docker, WireGuard, and Cloudflare

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![WireGuard](https://img.shields.io/badge/WireGuard-88171A?style=flat&logo=wireguard&logoColor=white)](https://www.wireguard.com/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=flat&logo=cloudflare&logoColor=white)](https://www.cloudflare.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=github-actions&logoColor=white)](https://github.com/features/actions)

## 📋 Project Overview

QWV is a complete enterprise-grade WireGuard VPN solution that adopts modern DevOps best practices:

- **🔒 Modern Security**: Uses WireGuard protocol, providing 3.2x faster performance than OpenVPN with a smaller attack surface
- **🐳 Containerized Deployment**: Docker-based environment isolation, dependency management, and one-click deployment
- **🌐 Dynamic DNS**: Integrated Cloudflare DDNS automatically handles dynamic IPs, supports home network environments
- **⚙️ Infrastructure as Code**: Fully manage infrastructure through version control, enabling traceable and repeatable deployments
- **🔄 GitOps Workflow**: GitHub Actions enables push-to-deploy automation workflow with intelligent mode detection
- **🛠️ Automated Management**: Built-in comprehensive management scripts to simplify daily operations
- **📊 CGNAT Support**: Provides alternative solutions for CGNAT environments
- **🌍 Multi-Environment Support**: Supports both single-environment (legacy) and multi-environment (enterprise) deployments
- **🔄 Backward Compatible**: Seamless upgrade path for existing users without configuration changes

## 🏗️ Project Architecture

```
QWV-QuickWireguardVpn/
├── 📋 規劃書.md                 # Complete technical documentation and design concepts
├── 🔧 docker-compose.yml        # Service orchestration configuration
├── ⚙️ env.example              # Environment variable template
├── 📝 README.md                # Project documentation
├── 🔐 .gitignore               # Git ignore configuration
├── 🤖 .github/workflows/       # GitHub Actions workflows
│   └── deploy.yml              # Automated deployment script
├── 📂 scripts/                 # Management scripts
│   ├── setup.sh               # Initial environment setup
│   ├── manage.sh               # Service management tool
│   └── validate.sh             # Project validation script
├── 📁 config/                  # WireGuard configuration files (auto-generated)
├── 💾 backup/                  # Backup files directory
└── 📊 logs/                    # Log files directory
```

### Core Service Architecture

```
Internet → Router → Server → Docker → [WireGuard + DDNS]
    ↓
    └─ Client Devices (Mobile, Laptop, etc.)
```

## 🚀 Quick Start

### 🌍 Multi-Environment Architecture

QWV now supports professional multi-environment deployment across regions:

| Environment | Region | Best For | Example Domain |
|-------------|--------|----------|----------------|
| 🌏 **Asia** | Asia-Pacific | Users in Asia, Australia | `vpn-asia.917420.xyz` |
| 🇺🇸 **US** | Americas | Users in North/South America | `vpn-us.917420.xyz` |
| 🇪🇺 **EU** | Europe | Users in Europe, Africa | `vpn-eu.917420.xyz` |

**Deployment Options:**
- **Single Environment** (Recommended for beginners): Choose one region
- **Multi-Environment** (Advanced): Deploy to multiple regions for global coverage

> 📖 **For multi-environment setup**, see: **[Multi-Environment Deployment Guide](MULTI-ENVIRONMENT.md)**

### ⚠️ Important: CGNAT Detection

**Before starting, please check if your network environment is supported:**

1. Log into your router management interface and record the WAN IP address
2. Visit [whatismyipaddress.com](https://whatismyipaddress.com) to check your public IP
3. If they differ, you may be in a CGNAT environment and need a VPS reverse proxy solution

### System Requirements

| Item | Minimum Requirement | Recommended |
|------|-------------------|-------------|
| Operating System | Ubuntu 20.04+ / Debian 11+ | Ubuntu 22.04 LTS |
| CPU | 1 core | 2 cores |
| Memory | 512MB | 1GB |
| Storage | 2GB | 5GB |
| Network | 10Mbps | 100Mbps |

### Prerequisites

- ✅ Linux server (supports Ubuntu/Debian)
- ✅ User account with sudo privileges
- ✅ Domain with management permissions (Cloudflare recommended)
- ✅ Router management permissions (for port forwarding)
- ✅ SSH access to the server
- ⚠️ Confirmed non-CGNAT environment

## 📥 Installation Guide

### Method 1: Fully Automated Installation (Recommended)

```bash
# 1. Clone the project to your server
git clone https://github.com/rich7420/QWV.git
cd QWV

# 2. Run one-click installation script
chmod +x scripts/*.sh
./scripts/setup.sh

# 3. Log out and back in for Docker group to take effect
exit
# Reconnect via SSH

# 4. Configure environment variables
cp env.example .env
nano .env

# 5. Start services
./scripts/manage.sh start
```

### Method 2: Manual Installation

<details>
<summary>Click to expand manual installation steps</summary>

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install official latest Docker version
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Install other dependencies
sudo apt install -y ufw git curl

# Set up Docker permissions
sudo usermod -aG docker $USER

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 51820/udp
sudo ufw --force enable

# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Clone project
git clone https://github.com/rich7420/QWV.git
cd QWV

# Create directories
mkdir -p config logs backup
```

</details>

## ⚙️ Detailed Configuration

### 1. Cloudflare Configuration

#### Create API Token (Following Principle of Least Privilege)

1. Log into [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Click profile avatar in top right → "My Profile"
3. Select "API Tokens" tab
4. Click "Create Token"
5. Select "Edit zone DNS" template
6. Configure permissions:
   ```
   Permissions: Zone:DNS:Edit
   Zone resources: Include - Specific zone - yourdomain.com
   
   Permissions: Zone:Zone:Read  
   Zone resources: Include - Specific zone - yourdomain.com
   ```
7. Copy the generated token and store it securely

#### Set up DNS Record

Add an A record in Cloudflare for your domain:
- **Name**: `vpn`
- **Content**: Your current public IP (DDNS will auto-update)
- **Proxy status**: 🌐 (Gray cloud, proxy disabled)

### 2. Environment Variable Configuration

Edit the `.env` file:

```bash
# Required settings
CF_API_TOKEN=your_cloudflare_api_token_here
CF_ZONE=yourdomain.com
CF_SUBDOMAIN=vpn

# 🤖 WireGuard Client Configuration (Three Modes Available)
# Mode 1: Auto-detection (Recommended) - Automatically detects current user and device
WIREGUARD_PEERS=auto
AUTO_PEER_FORMAT=username-hostname  # Options: username, hostname, username-hostname, hostname-username

# Mode 2: Manual specification - Traditional comma-separated client names
# WIREGUARD_PEERS=laptop,phone,tablet

# Mode 3: Hybrid mode - Combines auto-detection with manual specification
# WIREGUARD_PEERS=auto,work_laptop,family_tablet

# Optional settings (for advanced users)
# WIREGUARD_PORT=51820
# INTERNAL_SUBNET=10.13.13.0
```

#### 🤖 Auto-Detection Feature

**Benefits of Auto-Detection:**
- ✅ **Automatic**: No need to manually think of client names
- ✅ **Personalized**: Each user gets unique device names (e.g., `john-laptop`, `mary-desktop`)
- ✅ **Flexible**: Supports hybrid mode combining auto-detection with manual naming
- ✅ **Collision-free**: Avoids duplicate or conflicting names

**Format Options:**

| Format | Description | Example Result |
|--------|-------------|----------------|
| `username` | User name only | `john` |
| `hostname` | Host name only | `laptop` |
| `username-hostname` | User-hostname (default) | `john-laptop` |
| `hostname-username` | Hostname-user | `laptop-john` |

**Setup with Auto-Detection:**

```bash
# Use the new setup command to handle auto-detection
./scripts/manage.sh setup

# Expected output:
# 🔧 Setting up environment variables...
# ✅ Configured clients: john-laptop,work_tablet
# 🤖 Auto-detected device: john-laptop
#    - User: john
#    - Hostname: laptop
#    - Format: username-hostname

# Check the generated configuration
cat .env | grep WIREGUARD_PEERS
# Output: WIREGUARD_PEERS=john-laptop,work_tablet
```

### 3. Router Configuration

#### Port Forwarding Setup

1. Log into router management interface (usually 192.168.1.1 or 192.168.0.1)
2. Find "Port Forwarding", "Virtual Server", or "Port Forwarding" settings
3. Add rule:
   ```
   Service Name: WireGuard
   Protocol: UDP
   External Port: 51820
   Internal IP: Your server's LAN IP (e.g., 192.168.1.100)
   Internal Port: 51820
   Status: Enabled
   ```

#### Common Router Brand Configuration Paths

| Brand | Configuration Path |
|-------|-------------------|
| TP-Link | Advanced → NAT Forwarding → Virtual Servers |
| ASUS | Advanced Settings → WAN → Virtual Server/Port Forwarding |
| Netgear | Advanced → Advanced Setup → Port Forwarding/Port Triggering |
| D-Link | Advanced → Port Forwarding |

### 4. Service Customization

#### Modify WireGuard Configuration

Edit environment variables in `docker-compose.yml`:

```yaml
environment:
  - PEERS=laptop,phone,tablet,work_computer  # Client list
  - SERVERPORT=51820                         # VPN port
  - PEERDNS=1.1.1.1,8.8.8.8                # Custom DNS servers
  - ALLOWEDIPS=0.0.0.0/0, ::/0              # Full tunnel mode
  - PERSISTENTKEEPALIVE_PEERS=all           # Keep connections alive
```

#### Split Tunnel Configuration (Route only specific traffic)

To only route internal network traffic through VPN:

```yaml
- ALLOWEDIPS=192.168.1.0/24,10.13.13.0/24
```

## 📱 Client Configuration and Connection

### 1. Mobile Client Setup (Android/iOS)

#### Install WireGuard App

- **Android**: [Google Play Store](https://play.google.com/store/apps/details?id=com.wireguard.android)
- **iOS**: [App Store](https://apps.apple.com/app/wireguard/id1441195209)

#### Setup Steps

```bash
# 1. 🤖 If using auto-detection, first check detected client names
./scripts/manage.sh setup
# Output: ✅ Configured clients: john-laptop,shared_tablet

# 2. Display client QR Code
./scripts/manage.sh qr john-laptop  # Auto-detected client
# OR for traditional naming:
./scripts/manage.sh qr phone

# 3. In mobile app:
#    - Tap "+" → "Create from QR code"
#    - Scan the QR code displayed in terminal
#    - Name the tunnel (e.g., "Home VPN - john-laptop")
#    - Tap "Create tunnel"
```

### 2. Desktop Client Setup

#### Download WireGuard Client

- **Windows**: [Official Download](https://download.wireguard.com/windows-client/wireguard-installer.exe)
- **macOS**: [App Store](https://apps.apple.com/app/wireguard/id1451685025) or `brew install wireguard-tools`
- **Linux**: `sudo apt install wireguard` or install via package manager

#### Setup Steps

```bash
# 1. 🤖 Check auto-detected client names and get configuration file
./scripts/manage.sh setup
./scripts/manage.sh qr john-laptop  # Auto-detected client
# OR for traditional naming:
./scripts/manage.sh qr laptop

# 2. Copy config file to local machine
# For auto-detected client:
scp user@server:~/QWV/config/peer_john-laptop/peer_john-laptop.conf ~/wireguard-home.conf
# OR for traditional naming:
scp user@server:~/QWV/config/peer_laptop/peer_laptop.conf ~/wireguard-home.conf

# 3. Import config file in WireGuard client
```

### 3. Add New Client

#### 🤖 Method 1: Using Auto-Detection (Recommended)

```bash
# 1. Edit .env file to add new manual clients to auto-detection
nano .env

# 2. Modify WIREGUARD_PEERS using hybrid mode
WIREGUARD_PEERS=auto,work_computer,family_tablet

# 3. Setup environment and restart service
./scripts/manage.sh setup
./scripts/manage.sh restart

# 4. Get QR code for new client
./scripts/manage.sh qr work_computer
./scripts/manage.sh qr john-laptop  # Auto-detected client name
```

#### 📝 Method 2: Traditional Manual Mode

```bash
# 1. Edit .env file
nano .env

# 2. Modify WIREGUARD_PEERS with manual specification
WIREGUARD_PEERS=laptop,phone,tablet,work_computer

# 3. Restart service
./scripts/manage.sh restart

# 4. Get QR code for new client
./scripts/manage.sh qr work_computer
```

## 🛠️ Service Management Commands

### Basic Operations

```bash
# 🤖 Setup environment variables with auto-detection
./scripts/manage.sh setup

# Start all services
./scripts/manage.sh start

# Stop all services  
./scripts/manage.sh stop

# Restart services
./scripts/manage.sh restart

# View service status and resource usage
./scripts/manage.sh status
```

### Monitoring and Debugging

```bash
# View logs in real-time
./scripts/manage.sh logs

# Show connected clients
./scripts/manage.sh peers

# Comprehensive system check
./scripts/manage.sh check

# Run complete project validation
./scripts/manage.sh validate

# Display QR code for specific client
./scripts/manage.sh qr <client_name>
```

### Maintenance Operations

```bash
# Update service images
./scripts/manage.sh update

# Backup configuration files (including all keys)
./scripts/manage.sh backup

# View available commands
./scripts/manage.sh --help
```

### Advanced Management

```bash
# Manual Docker operations
docker compose ps                    # View container status
docker compose logs -f wireguard     # View WireGuard logs
docker compose logs -f cloudflare-ddns # View DDNS logs

# Enter WireGuard container
docker exec -it wireguard bash

# View WireGuard interface status
docker exec wireguard wg show

# View network configuration
docker exec wireguard ip addr show wg0
```

## 🔍 Troubleshooting Guide

### Diagnostic Tools

```bash
# One-click system check
./scripts/manage.sh check

# View detailed logs
./scripts/manage.sh logs | grep -i error

# Check network connectivity
ping vpn.yourdomain.com
nslookup vpn.yourdomain.com
```

### Common Issues and Solutions

#### 🚫 Issue 1: Cannot Establish Handshake

**Symptom**: Client shows "latest handshake: never"

**Possible Causes and Solutions**:

<details>
<summary>🔥 Firewall Blocking</summary>

```bash
# Check UFW status
sudo ufw status numbered

# Ensure WireGuard port is open
sudo ufw allow 51820/udp

# Check iptables rules
sudo iptables -L -n | grep 51820
```

</details>

<details>
<summary>🌐 Router Port Forwarding Issues</summary>

1. Re-check router settings:
   - Protocol: UDP (not TCP)
   - External port: 51820
   - Internal IP: Correct server IP
   - Internal port: 51820

2. Test if port is open:
```bash
# Test from external network (use different network)
nc -u vpn.yourdomain.com 51820
```

</details>

<details>
<summary>⚠️ CGNAT Detection</summary>

```bash
# Automatic detection script
curl -s https://ipinfo.io/ip > /tmp/external_ip
cat /tmp/external_ip

# Compare with router WAN IP
# If different, may have CGNAT issues
```

</details>

#### 🌍 Issue 2: Handshake Works but No Internet

**Symptom**: WireGuard shows connected, but cannot browse web

<details>
<summary>🔍 DNS Resolution Issues</summary>

```bash
# Test on client
ping 8.8.8.8        # If successful, IP routing works
ping google.com     # If fails, DNS issue

# Fix: Edit docker-compose.yml
- PEERDNS=1.1.1.1,8.8.8.8
```

</details>

<details>
<summary>🛣️ Routing Issues</summary>

```bash
# Check server IP forwarding
cat /proc/sys/net/ipv4/ip_forward
# Should output: 1

# Check WireGuard interface
docker exec wireguard ip route show table main
```

</details>

#### 🌐 Issue 3: DDNS Not Updating

**Symptom**: Domain doesn't resolve to current IP

<details>
<summary>🔑 API Token Issues</summary>

```bash
# Test API token validity
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_API_TOKEN" \
     -H "Content-Type:application/json"

# Should return: {"success": true}
```

</details>

<details>
<summary>📡 Network Connection Issues</summary>

```bash
# Check DDNS container logs
docker logs cloudflare-ddns

# Test DNS propagation
dig vpn.yourdomain.com
nslookup vpn.yourdomain.com 8.8.8.8
```

</details>

#### 🤖 Issue 4: GitHub Actions Deployment Fails

**Symptom**: Automated deployment fails in GitHub Actions

<details>
<summary>🔐 GitHub Secrets Configuration Issues</summary>

```bash
# Common errors and solutions:

# Error 1: VPN_SSH_KEY format incorrect
# Symptom: SSH connection fails, shows "invalid format" or "bad permissions"
# Solution: Ensure private key includes complete BEGIN and END lines
cat ~/.ssh/github_actions_key | pbcopy  # macOS
cat ~/.ssh/github_actions_key | xclip -selection clipboard  # Linux

# Error 2: VPN_HOST cannot connect
# Symptom: Connection timeout or host unreachable
# Solution: Confirm server IP or domain is correct
ping $VPN_HOST  # Local connectivity test
nslookup $VPN_HOST  # If using domain

# Error 3: VPN_USER insufficient permissions
# Symptom: SSH connection succeeds but Docker commands fail
# Solution: Confirm user is in docker group
ssh user@host "groups \$USER | grep docker"

# Error 4: VPN_PORT setting error
# Symptom: SSH connection refused
# Solution: Confirm SSH port setting
ssh -p $VPN_PORT user@host "echo 'Connection successful'"
```

</details>

<details>
<summary>🔧 SSH Key Issues Diagnosis</summary>

```bash
# Local SSH connection test (simulate GitHub Actions environment)
ssh -i ~/.ssh/github_actions_key -o StrictHostKeyChecking=no user@your-server-ip

# Check server-side SSH configuration
ssh user@host "cat ~/.ssh/authorized_keys | grep github-actions"

# Check key permissions
ssh user@host "ls -la ~/.ssh/"
# Expected: drwx------ .ssh/ and -rw------- authorized_keys

# Test Docker permissions
ssh -i ~/.ssh/github_actions_key user@host "docker ps"
# Expected: Able to execute Docker commands
```

</details>

## 🤖 GitHub Actions Automated Deployment

### GitHub Configuration

QWV uses both **Variables** (public) and **Secrets** (encrypted) for configuration. The system automatically detects your deployment mode based on configured Variables.

#### 🔧 Single Environment Setup (Legacy Compatible)

**Navigate to**: Settings → Secrets and variables → Actions

**Variables Tab (Public Configuration):**
| Variable Name | Description | Example Value | Required |
|---------------|-------------|---------------|----------|
| `VPN_DOMAIN` | Complete VPN domain | `vpn.917420.xyz` | ✅ Required |

**Secrets Tab (Sensitive Information):**
| Secret Name | Description | Example Value | Required |
|-------------|-------------|---------------|----------|
| `VPN_HOST` | VPN server IP address | `203.0.113.1` | ✅ Required |
| `VPN_USER` | Login username for server | `ubuntu` or `user` | ✅ Required |
| `VPN_SSH_KEY` | SSH private key content (complete file) | `-----BEGIN OPENSSH PRIVATE KEY-----\n...` | ✅ Required |
| `VPN_PORT` | SSH port (if not default 22) | `2222` or `22` | ⚪ Optional |
| `VPN_DEPLOY_PATH` | Deployment path on server | `/home/ubuntu/QWV` | ⚪ Optional |
| `CF_API_TOKEN` | Cloudflare API token | `cf_token_here...` | ✅ Required |

**Legacy Fallback (Deprecated):**
For existing users, the old `CF_ZONE` and `CF_SUBDOMAIN` secrets are still supported but will be migrated to the new `VPN_DOMAIN` variable format.

**Configuration Example (Your Setup):**
```
Variables:
  VPN_DOMAIN = "vpn.917420.xyz"

Secrets:
  VPN_HOST = "YOUR_GCP_EXTERNAL_IP"
  VPN_USER = "ubuntu" 
  VPN_SSH_KEY = "-----BEGIN OPENSSH PRIVATE KEY-----..."
  CF_API_TOKEN = "YOUR_CLOUDFLARE_TOKEN"
```

#### 🌍 Multi-Environment Setup (DNS-Based Service Routing)

**The system automatically switches to multi-environment mode when any multi-environment Variables are detected.**

**Variables Tab (DNS Service Discovery):**
| Variable Name | Description | Example Value | Purpose |
|---------------|-------------|---------------|---------|
| `VPN_DOMAIN_ASIA` | Asia VPN service domain | `vpn-asia.917420.xyz` | 🌏 Asia routing |
| `VPN_DOMAIN_US` | US VPN service domain | `vpn-us.917420.xyz` | 🇺🇸 US routing |
| `VPN_DOMAIN_EU` | EU VPN service domain | `vpn-eu.917420.xyz` | 🇪🇺 EU routing |

**Secrets Tab (Per-Environment Sensitive Data):**

**Asia Environment:**
- `VPN_HOST_ASIA`, `VPN_USER_ASIA`, `VPN_SSH_KEY_ASIA`, `VPN_PORT_ASIA`, `VPN_DEPLOY_PATH_ASIA`
- `CF_API_TOKEN_ASIA`

**US Environment:**
- `VPN_HOST_US`, `VPN_USER_US`, `VPN_SSH_KEY_US`, `VPN_PORT_US`, `VPN_DEPLOY_PATH_US`  
- `CF_API_TOKEN_US`

**EU Environment:**
- `VPN_HOST_EU`, `VPN_USER_EU`, `VPN_SSH_KEY_EU`, `VPN_PORT_EU`, `VPN_DEPLOY_PATH_EU`
- `CF_API_TOKEN_EU`

**Multi-Environment Configuration Example:**
```
Variables:
  VPN_DOMAIN_ASIA = "vpn-asia.917420.xyz"
  VPN_DOMAIN_US = "vpn-us.917420.xyz"  
  VPN_DOMAIN_EU = "vpn-eu.917420.xyz"

Secrets:
  # Asia Environment
  VPN_HOST_ASIA = "ASIA_GCP_IP"
  VPN_USER_ASIA = "ubuntu"
  VPN_SSH_KEY_ASIA = "-----BEGIN OPENSSH PRIVATE KEY-----..."
  CF_API_TOKEN_ASIA = "ASIA_CLOUDFLARE_TOKEN"
  
  # US Environment  
  VPN_HOST_US = "US_GCP_IP"
  VPN_USER_US = "ubuntu"
  VPN_SSH_KEY_US = "-----BEGIN OPENSSH PRIVATE KEY-----..."
  CF_API_TOKEN_US = "US_CLOUDFLARE_TOKEN"
  
  # EU Environment
  VPN_HOST_EU = "EU_GCP_IP"
  VPN_USER_EU = "ubuntu"
  VPN_SSH_KEY_EU = "-----BEGIN OPENSSH PRIVATE KEY-----..."
  CF_API_TOKEN_EU = "EU_CLOUDFLARE_TOKEN"
```

#### 🌐 DNS-Based Service Routing Architecture

This multi-environment setup implements **DNS-based service routing**:

```
Client Request Flow:
├── vpn-asia.917420.xyz  → 🌏 Asia VPN Server (Optimal for APAC users)
├── vpn-us.917420.xyz    → 🇺🇸 US VPN Server (Optimal for Americas users)  
└── vpn-eu.917420.xyz    → 🇪🇺 EU VPN Server (Optimal for EMEA users)
```

**Benefits:**
- 🚀 **Geographic Optimization**: Users connect to nearest server for better performance
- 🛡️ **High Availability**: If one region fails, others remain operational
- 📈 **Load Distribution**: Traffic distributed across multiple servers
- 🔧 **Easy Management**: Single GitHub Actions manages all environments

#### 🎛️ Deployment Control Options

When using GitHub Actions UI (`Actions` → `Run workflow`):

| Option | Description | Use Case |
|--------|-------------|----------|
| `auto` | Auto-detect mode and deploy accordingly | Default behavior |
| `single` | Force single-environment mode | Force legacy mode even with multi-env secrets |
| `asia` | Deploy only to Asia environment | Target specific region |
| `us` | Deploy only to US environment | Target specific region |
| `eu` | Deploy only to EU environment | Target specific region |
| `all` | Deploy to all multi-environments | Deploy to all regions at once |

> 📖 **Complete multi-environment guide**: [MULTI-ENVIRONMENT.md](MULTI-ENVIRONMENT.md)

### SSH Key Preparation Steps

**On your local computer:**

```bash
# 1. Generate SSH key pair (if you don't have one)
ssh-keygen -t ed25519 -C "github-actions@yourdomain.com" -f ~/.ssh/github_actions_key

# 2. Copy private key content (for GitHub Secret)
cat ~/.ssh/github_actions_key
# ⚠️ Copy complete output (including BEGIN and END lines)

# 3. Copy public key to server
ssh-copy-id -i ~/.ssh/github_actions_key.pub user@your-server-ip

# Or manually add public key
cat ~/.ssh/github_actions_key.pub
# Copy output to server's ~/.ssh/authorized_keys
```

### Deployment Workflow

The GitHub Actions workflow automatically:

1. ✅ Validates project configuration
2. ✅ Connects to your server via SSH
3. ✅ Pulls latest code changes
4. ✅ Stops existing services
5. ✅ Updates Docker images
6. ✅ Starts services with new configuration
7. ✅ Cleans up old images
8. ✅ Verifies service status

#### Trigger Deployment

**Automatic Deployment:**
```bash
# Push changes to trigger automatic deployment
git add .
git commit -m "feat: Update VPN configuration"
git push origin main

# System auto-detects deployment mode and deploys accordingly
# Check deployment status: GitHub → Actions tab
```

**Manual Deployment Control:**
```bash
# For selective deployment control:
# 1. Go to GitHub → Actions → "Multi-Environment QWV VPN Deployment"
# 2. Click "Run workflow"
# 3. Select deployment option:
#    - auto: Auto-detect and deploy (default)
#    - single: Force single-environment deployment
#    - asia/us/eu: Deploy to specific region only
#    - all: Deploy to all multi-environments

# Example: Deploy only to Asia environment
# Select "asia" from dropdown and click "Run workflow"
```

## 📚 Advanced Topics and Best Practices

### 🔧 Client Management

#### Add New Client

```bash
# Method 1: Edit docker-compose.yml (recommended)
nano docker-compose.yml
# Modify: - PEERS=laptop,phone,tablet,work_laptop

# Method 2: Use environment variables
echo "PEERS=laptop,phone,tablet,work_laptop" >> .env

# Restart service
./scripts/manage.sh restart

# Get new client configuration
./scripts/manage.sh qr work_laptop
```

#### Remove Client

```bash
# Remove client name from PEERS list
nano docker-compose.yml

# Restart service (old config files will be automatically cleaned)
./scripts/manage.sh restart
```

### 🔐 Security Hardening

#### Change Default Port

```yaml
# docker-compose.yml
environment:
  - SERVERPORT=12345  # Change to non-standard port
ports:
  - "12345:51820/udp"  # Update external port mapping
```

#### Enable Client Key Rotation

```bash
# Regular backup of old configuration
./scripts/manage.sh backup

# Clear all client configurations (will regenerate new keys)
rm -rf config/peer_*

# Restart service
./scripts/manage.sh restart
```

#### Restrict Client Network Access

```yaml
# Only allow access to internal network resources (split tunnel)
- ALLOWEDIPS=192.168.1.0/24,10.13.13.0/24

# Custom DNS server (use internal Pi-hole)
- PEERDNS=192.168.1.100
```

### 📊 Monitoring and Logging

#### Set up Log Rotation

```bash
# Install logrotate
sudo apt install logrotate

# Create VPN log rotation configuration
sudo tee /etc/logrotate.d/qwv-vpn << EOF
/home/ubuntu/QWV/logs/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
EOF
```

#### Set up Monitoring Alerts

```bash
# Create simple health check script
cat > scripts/health_check.sh << 'EOF'
#!/bin/bash
if ! docker exec wireguard wg show | grep -q "peer:"; then
    echo "WARNING: No WireGuard peers connected"
    # Add notification logic here (email or Slack)
fi
EOF

chmod +x scripts/health_check.sh

# Set up periodic cron check
echo "*/15 * * * * /path/to/scripts/health_check.sh" | crontab -
```

### 🌐 Multi-Region Deployment

#### Geographically Distributed VPN

```bash
# Create branches for different regions
git checkout -b asia-server
git checkout -b europe-server

# Different CF_SUBDOMAIN for each branch
# Asia: vpn-asia.yourdomain.com
# Europe: vpn-eu.yourdomain.com
```

### 🔄 Backup and Disaster Recovery

#### Automated Backup Script

```bash
# Create automated backup script
cat > scripts/auto_backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/path/to/backup/location"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
./scripts/manage.sh backup

# Sync to remote
rsync -av backup/ user@backup-server:$BACKUP_DIR/

# Clean local old backups (keep 7 days)
find backup/ -name "*.tar.gz" -mtime +7 -delete
EOF

# Set up daily automated backup
echo "0 2 * * * /path/to/scripts/auto_backup.sh" | crontab -
```

#### Disaster Recovery Procedure

```bash
# 1. Clone project on new server
git clone https://github.com/rich7420/QWV.git
cd QWV

# 2. Run initial setup
./scripts/setup.sh

# 3. Restore backup configuration
tar -xzf backup/wireguard_backup_YYYYMMDD_HHMMSS.tar.gz

# 4. Configure environment variables
cp env.example .env
nano .env

# 5. Start services
./scripts/manage.sh start
```

## 📈 Performance Optimization

### Adjust WireGuard Parameters

```yaml
# docker-compose.yml - Optimization for high traffic environments
environment:
  - ALLOWEDIPS=0.0.0.0/0, ::/0
  - PERSISTENTKEEPALIVE_PEERS=25  # Maintain connection stability
  - LOG_CONFS=false              # Disable QR code logging to save resources
```

### System Adjustments

```bash
# Increase UDP buffer size
echo 'net.core.rmem_max = 26214400' | sudo tee -a /etc/sysctl.conf
echo 'net.core.rmem_default = 26214400' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Restart service to apply changes
./scripts/manage.sh restart
```

## 🔧 Development and Maintenance Guide

### Project Structure Explanation

```
QWV-QuickWireguardVpn/
├── 📋 規劃書.md                 # Complete technical documentation (603 lines of professional analysis)
├── 🔧 docker-compose.yml        # Service orchestration (WireGuard + DDNS)
├── ⚙️ env.example              # Environment variable template (security configuration)
├── 🔐 .gitignore               # Git ignore rules (protect sensitive information)
├── 🤖 .github/workflows/       # CI/CD automation
│   └── deploy.yml              # GitOps deployment workflow
├── 📂 scripts/                 # Management toolkit
│   ├── setup.sh               # Environment initialization (one-click install)
│   ├── manage.sh               # Service management (20+ features)
│   └── validate.sh             # Project validation (7 modules)
├── 📁 config/                  # WireGuard configuration (auto-generated)
├── 💾 backup/                  # Backup files
└── 📊 logs/                    # System logs
```

### Code Contribution Workflow

#### Fork and Set up Development Environment

```bash
# 1. Fork this repository to your GitHub account

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/QWV.git
cd QWV

# 3. Set up upstream repository
git remote add upstream https://github.com/rich7420/QWV.git

# 4. Create feature branch
git checkout -b feature/your-feature-name
```

#### Development Standards

- ✅ All scripts must pass ShellCheck validation
- ✅ Docker Compose files should use latest syntax version
- ✅ New features need corresponding documentation updates
- ✅ Follow existing code style and naming conventions

#### Testing Checklist

```bash
# Syntax check
shellcheck scripts/*.sh

# Function testing
./scripts/setup.sh --dry-run
./scripts/manage.sh check

# Docker syntax validation
docker compose config
```

#### Submit Pull Request

```bash
# 1. Ensure code is up to date
git fetch upstream
git rebase upstream/main

# 2. Commit changes
git add .
git commit -m "feat: Add XXX feature"

# 3. Push to your fork
git push origin feature/your-feature-name

# 4. Create Pull Request on GitHub
```

### Version Release Process

#### Semantic Versioning

We use [Semantic Versioning](https://semver.org/):

- `MAJOR.MINOR.PATCH` (e.g., `1.2.3`)
- **MAJOR**: Incompatible API changes
- **MINOR**: Backward-compatible feature additions
- **PATCH**: Backward-compatible bug fixes

#### Release Steps

```bash
# 1. Update version number
echo "v1.2.3" > VERSION

# 2. Update CHANGELOG
# Record all changes for this version

# 3. Create release tag
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3

# 4. Create Release on GitHub
# Include change summary and upgrade instructions
```

## 🆘 Technical Support

### Community Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/rich7420/QWV/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/rich7420/QWV/discussions)
- 📖 **Documentation Issues**: Direct fixes via Pull Request

### Professional Services

If you need:
- 🏢 Enterprise deployment consulting
- 🔧 Custom feature development
- 🎓 WireGuard technical training
- 🛡️ Security assessment

Contact us through GitHub Issues with `[Commercial]` tag.

## 📄 License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) file for details.

### Summary

- ✅ **Commercial Use**: Allowed for commercial purposes
- ✅ **Modification**: Allowed to modify code
- ✅ **Distribution**: Allowed to distribute original or modified code
- ✅ **Private Use**: Allowed for private use
- ⚠️ **Liability Limitation**: No warranty provided, use at your own risk

## 🤝 Contributors

Thanks to all developers who contributed to this project:

<!-- Contributors will be automatically listed here -->

## 🌟 Acknowledgments

This project's implementation benefits from the following excellent open source projects:

- [WireGuard](https://www.wireguard.com/) - Modern VPN protocol
- [LinuxServer.io](https://linuxserver.io/) - Excellent Docker images
- [Docker](https://www.docker.com/) - Containerization platform
- [Cloudflare](https://www.cloudflare.com/) - DNS service provider

## 📖 Further Reading

- 📋 **[規劃書.md](規劃書.md)** - Complete technical analysis and design concepts (603 lines of professional documentation)
- 🧪 **[TESTING.md](TESTING.md)** - Comprehensive testing guide and validation procedures
- 🔗 **[WireGuard Official Documentation](https://www.wireguard.com/quickstart/)**
- 🐳 **[Docker Compose Reference](https://docs.docker.com/compose/)**
- 🌐 **[Cloudflare API Documentation](https://developers.cloudflare.com/api/)**

---

<div align="center">

**⭐ If this project helps you, please give us a Star!**

**🔗 [GitHub Repository](https://github.com/rich7420/QWV)**

Made with ❤️ by the QWV Team

</div> 