# 🌍 QWV Multi-Environment Deployment Guide

This guide explains how to deploy and manage multiple VPN servers across different regions using a single GitHub repository.

## 🏗️ Architecture Overview

### Multi-Environment Setup
```
GitHub Repository (QWV)
├── 🌏 Asia Environment (vpn-asia.917420.xyz)
│   ├── Server: GCP Asia-Pacific
│   └── Clients: Asia-based devices
├── 🇺🇸 US Environment (vpn-us.917420.xyz)
│   ├── Server: GCP US
│   └── Clients: Americas-based devices
└── 🇪🇺 EU Environment (vpn-eu.917420.xyz)
    ├── Server: GCP Europe
    └── Clients: Europe-based devices
```

### Benefits
- ✅ **Low Latency**: Connect to nearest server
- ✅ **Redundancy**: Backup servers available
- ✅ **Single Management**: One GitHub repo manages all
- ✅ **Cost Optimization**: Deploy only needed regions
- ✅ **Selective Deployment**: Deploy to specific environments

## 📊 Required GitHub Secrets

Configure the following secrets in your GitHub repository:
`Settings` → `Secrets and variables` → `Actions` → `New repository secret`

### Asia Environment Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `VPN_HOST_ASIA` | Asia server IP address | `35.200.123.45` |
| `VPN_USER_ASIA` | SSH username for Asia server | `ubuntu` |
| `VPN_SSH_KEY_ASIA` | SSH private key for Asia server | `-----BEGIN OPENSSH PRIVATE KEY-----\n...` |
| `VPN_PORT_ASIA` | SSH port (optional) | `22` |
| `VPN_DEPLOY_PATH_ASIA` | Deployment path on Asia server | `/home/ubuntu/QWV` |
| `CF_API_TOKEN_ASIA` | Cloudflare API token for Asia | `cf_token_asia...` |
| `CF_ZONE_ASIA` | Domain for Asia | `917420.xyz` |
| `CF_SUBDOMAIN_ASIA` | Subdomain for Asia | `vpn-asia` |

### US Environment Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `VPN_HOST_US` | US server IP address | `34.102.136.180` |
| `VPN_USER_US` | SSH username for US server | `ubuntu` |
| `VPN_SSH_KEY_US` | SSH private key for US server | `-----BEGIN OPENSSH PRIVATE KEY-----\n...` |
| `VPN_PORT_US` | SSH port (optional) | `22` |
| `VPN_DEPLOY_PATH_US` | Deployment path on US server | `/home/ubuntu/QWV` |
| `CF_API_TOKEN_US` | Cloudflare API token for US | `cf_token_us...` |
| `CF_ZONE_US` | Domain for US | `917420.xyz` |
| `CF_SUBDOMAIN_US` | Subdomain for US | `vpn-us` |

### EU Environment Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `VPN_HOST_EU` | EU server IP address | `34.76.123.89` |
| `VPN_USER_EU` | SSH username for EU server | `ubuntu` |
| `VPN_SSH_KEY_EU` | SSH private key for EU server | `-----BEGIN OPENSSH PRIVATE KEY-----\n...` |
| `VPN_PORT_EU` | SSH port (optional) | `22` |
| `VPN_DEPLOY_PATH_EU` | Deployment path on EU server | `/home/ubuntu/QWV` |
| `CF_API_TOKEN_EU` | Cloudflare API token for EU | `cf_token_eu...` |
| `CF_ZONE_EU` | Domain for EU | `917420.xyz` |
| `CF_SUBDOMAIN_EU` | Subdomain for EU | `vpn-eu` |

## 🚀 Setup Process

### Step 1: Prepare GCP Servers

Create three GCP instances in different regions:

```bash
# Asia Pacific (Taiwan)
gcloud compute instances create qwv-asia \
    --zone=asia-east1-a \
    --machine-type=e2-small \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --tags=vpn-server

# US Central
gcloud compute instances create qwv-us \
    --zone=us-central1-a \
    --machine-type=e2-small \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --tags=vpn-server

# Europe West
gcloud compute instances create qwv-eu \
    --zone=europe-west1-b \
    --machine-type=e2-small \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --tags=vpn-server
```

### Step 2: Configure Firewall Rules

```bash
# Create firewall rule for all VPN servers
gcloud compute firewall-rules create wireguard-vpn-multi \
    --allow udp:51820 \
    --source-ranges 0.0.0.0/0 \
    --target-tags vpn-server \
    --description "WireGuard VPN for multi-environment"
```

### Step 3: Generate SSH Keys for Each Environment

```bash
# Asia SSH keys
ssh-keygen -t ed25519 -f ~/.ssh/qwv_asia -C "qwv-asia@917420.xyz" -N ""

# US SSH keys  
ssh-keygen -t ed25519 -f ~/.ssh/qwv_us -C "qwv-us@917420.xyz" -N ""

# EU SSH keys
ssh-keygen -t ed25519 -f ~/.ssh/qwv_eu -C "qwv-eu@917420.xyz" -N ""
```

### Step 4: Deploy Public Keys to Servers

```bash
# Upload to Asia server
gcloud compute scp ~/.ssh/qwv_asia.pub qwv-asia:~/.ssh/authorized_keys --zone=asia-east1-a

# Upload to US server
gcloud compute scp ~/.ssh/qwv_us.pub qwv-us:~/.ssh/authorized_keys --zone=us-central1-a

# Upload to EU server
gcloud compute scp ~/.ssh/qwv_eu.pub qwv-eu:~/.ssh/authorized_keys --zone=europe-west1-b
```

### Step 5: Install QWV on Each Server

```bash
# Asia server
gcloud compute ssh qwv-asia --zone=asia-east1-a --command="
git clone https://github.com/rich7420/QWV.git
cd QWV
chmod +x scripts/*.sh
./scripts/setup.sh
"

# US server
gcloud compute ssh qwv-us --zone=us-central1-a --command="
git clone https://github.com/rich7420/QWV.git
cd QWV
chmod +x scripts/*.sh
./scripts/setup.sh
"

# EU server
gcloud compute ssh qwv-eu --zone=europe-west1-b --command="
git clone https://github.com/rich7420/QWV.git
cd QWV
chmod +x scripts/*.sh
./scripts/setup.sh
"
```

### Step 6: Configure Cloudflare DNS Records

Add DNS records for each environment:

| Name | Type | Content | Proxy |
|------|------|---------|-------|
| `vpn-asia` | A | `ASIA_SERVER_IP` | 🌐 (DNS only) |
| `vpn-us` | A | `US_SERVER_IP` | 🌐 (DNS only) |
| `vpn-eu` | A | `EU_SERVER_IP` | 🌐 (DNS only) |

### Step 7: Set GitHub Secrets

Copy private key contents to GitHub Secrets:

```bash
# Get private keys for GitHub Secrets
echo "=== VPN_SSH_KEY_ASIA ==="
cat ~/.ssh/qwv_asia

echo "=== VPN_SSH_KEY_US ==="
cat ~/.ssh/qwv_us

echo "=== VPN_SSH_KEY_EU ==="
cat ~/.ssh/qwv_eu
```

## 🎯 Deployment Options

### Deploy to All Environments (Default)

```bash
git add .
git commit -m "feat: update VPN configuration"
git push origin main
```

### Deploy to Specific Environment

Via GitHub Actions UI:
1. Go to `Actions` tab
2. Click `Multi-Environment QWV VPN Deployment`
3. Click `Run workflow`
4. Select environment: `asia`, `us`, or `eu`
5. Click `Run workflow`

### Manual Deployment Commands

```bash
# Deploy only to Asia
gh workflow run deploy.yml -f environment=asia

# Deploy only to US
gh workflow run deploy.yml -f environment=us

# Deploy only to EU  
gh workflow run deploy.yml -f environment=eu
```

## 📱 Client Configuration

### Get Client Configurations

Connect to each server to generate client configs:

```bash
# Asia clients
gcloud compute ssh qwv-asia --zone=asia-east1-a --command="
cd QWV
./scripts/manage.sh qr asia-phone
./scripts/manage.sh qr asia-laptop
"

# US clients
gcloud compute ssh qwv-us --zone=us-central1-a --command="
cd QWV
./scripts/manage.sh qr us-phone
./scripts/manage.sh qr us-laptop
"

# EU clients
gcloud compute ssh qwv-eu --zone=europe-west1-b --command="
cd QWV
./scripts/manage.sh qr eu-phone
./scripts/manage.sh qr eu-laptop
"
```

### Client Naming Strategy

Use environment-specific naming:

```yaml
# Asia environment - docker-compose.yml
environment:
  - PEERS=asia-phone,asia-laptop,asia-tablet,asia-work

# US environment - docker-compose.yml  
environment:
  - PEERS=us-phone,us-laptop,us-tablet,us-work

# EU environment - docker-compose.yml
environment:
  - PEERS=eu-phone,eu-laptop,eu-tablet,eu-work
```

## 🔧 Management Commands

### Check All Environment Status

```bash
# Asia environment
gcloud compute ssh qwv-asia --zone=asia-east1-a --command="cd QWV && ./scripts/manage.sh status"

# US environment
gcloud compute ssh qwv-us --zone=us-central1-a --command="cd QWV && ./scripts/manage.sh status"

# EU environment
gcloud compute ssh qwv-eu --zone=europe-west1-b --command="cd QWV && ./scripts/manage.sh status"
```

### Backup All Environments

```bash
# Create backup script
cat > backup_all_environments.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="multi-env-backup-$DATE"
mkdir -p $BACKUP_DIR

echo "🌏 Backing up Asia environment..."
gcloud compute ssh qwv-asia --zone=asia-east1-a --command="cd QWV && ./scripts/manage.sh backup"
gcloud compute scp qwv-asia:~/QWV/backup/*.tar.gz $BACKUP_DIR/asia-backup.tar.gz --zone=asia-east1-a

echo "🇺🇸 Backing up US environment..."
gcloud compute ssh qwv-us --zone=us-central1-a --command="cd QWV && ./scripts/manage.sh backup"
gcloud compute scp qwv-us:~/QWV/backup/*.tar.gz $BACKUP_DIR/us-backup.tar.gz --zone=us-central1-a

echo "🇪🇺 Backing up EU environment..."
gcloud compute ssh qwv-eu --zone=europe-west1-b --command="cd QWV && ./scripts/manage.sh backup"
gcloud compute scp qwv-eu:~/QWV/backup/*.tar.gz $BACKUP_DIR/eu-backup.tar.gz --zone=europe-west1-b

echo "✅ All environments backed up to $BACKUP_DIR/"
EOF

chmod +x backup_all_environments.sh
```

## 📊 Monitoring and Maintenance

### Health Check Script

```bash
cat > check_all_environments.sh << 'EOF'
#!/bin/bash
echo "🌍 Multi-Environment Health Check"
echo "=================================="

environments=("asia:asia-east1-a" "us:us-central1-a" "eu:europe-west1-b")

for env_zone in "${environments[@]}"; do
    env=${env_zone%:*}
    zone=${env_zone#*:}
    
    echo ""
    case $env in
        "asia") echo "🌏 Checking Asia environment..." ;;
        "us") echo "🇺🇸 Checking US environment..." ;;
        "eu") echo "🇪🇺 Checking EU environment..." ;;
    esac
    
    if gcloud compute ssh qwv-$env --zone=$zone --command="cd QWV && ./scripts/manage.sh check" 2>/dev/null; then
        echo "✅ $env environment: Healthy"
    else
        echo "❌ $env environment: Issues detected"
    fi
done

echo ""
echo "📊 Health check completed"
EOF

chmod +x check_all_environments.sh
```

## 💰 Cost Optimization

### Regional Pricing (Estimated Monthly)

| Region | Instance Type | Estimated Cost |
|--------|---------------|----------------|
| Asia-East1 | e2-small | $12-18 USD |
| US-Central1 | e2-small | $10-15 USD |
| Europe-West1 | e2-small | $13-19 USD |
| **Total** | **3x e2-small** | **$35-52 USD** |

### Cost Reduction Strategies

1. **Use Spot Instances**: 60-91% cost reduction
2. **Scheduled Shutdown**: Turn off during low usage
3. **Regional Optimization**: Deploy only needed regions
4. **Resource Right-sizing**: Monitor and adjust instance sizes

## 🔒 Security Best Practices

### Per-Environment Security

```bash
# Different SSH keys per environment
# Different Cloudflare API tokens per environment  
# Separate firewall rules if needed
# Independent backup schedules
```

### Network Isolation

```bash
# Asia: 10.13.13.0/24
# US: 10.14.14.0/24  
# EU: 10.15.15.0/24
```

## 🚨 Troubleshooting

### Common Issues

#### Environment-Specific Deployment Failure

```bash
# Check specific environment logs in GitHub Actions
# Verify environment-specific secrets are set correctly
# Test SSH connection to specific server
ssh -i ~/.ssh/qwv_asia user@asia-server-ip
```

#### DNS Resolution Issues

```bash
# Check DNS propagation for each subdomain
dig vpn-asia.917420.xyz
dig vpn-us.917420.xyz  
dig vpn-eu.917420.xyz
```

#### Client Connection Issues

```bash
# Test connectivity to each environment
ping vpn-asia.917420.xyz
ping vpn-us.917420.xyz
ping vpn-eu.917420.xyz

# Check port accessibility
nc -u vpn-asia.917420.xyz 51820
nc -u vpn-us.917420.xyz 51820
nc -u vpn-eu.917420.xyz 51820
```

## 📈 Scaling Considerations

### Adding New Regions

1. Create new GCP instance
2. Add new environment secrets to GitHub
3. Update GitHub Actions matrix (optional)
4. Configure DNS records
5. Deploy using existing workflow

### Performance Optimization

```bash
# Monitor performance per region
./scripts/manage.sh status  # On each server
docker stats  # Resource usage
speedtest-cli  # Network performance
```

---

## 🎯 Quick Reference

### Essential Commands

```bash
# Deploy all environments
git push origin main

# Deploy specific environment  
gh workflow run deploy.yml -f environment=asia

# Check environment health
./check_all_environments.sh

# Backup all environments
./backup_all_environments.sh

# Get client config
gcloud compute ssh qwv-asia --zone=asia-east1-a --command="cd QWV && ./scripts/manage.sh qr phone"
```

### Key Files

- `.github/workflows/deploy.yml` - Multi-environment deployment workflow
- `docker-compose.yml` - Service configuration (per server)
- `.env` - Environment variables (per server)
- `scripts/manage.sh` - Management commands (per server)

**🔗 Repository**: [QWV Multi-Environment](https://github.com/rich7420/QWV) 