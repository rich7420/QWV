# QWV - QuickWireguardVpn

🚀 使用 Docker、WireGuard 與 Cloudflare 建構現代化、安全且可維護的個人 VPN

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![WireGuard](https://img.shields.io/badge/WireGuard-88171A?style=flat&logo=wireguard&logoColor=white)](https://www.wireguard.com/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=flat&logo=cloudflare&logoColor=white)](https://www.cloudflare.com/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=github-actions&logoColor=white)](https://github.com/features/actions)

## 📋 專案概述

QWV 是一個完整的企業級 WireGuard VPN 解決方案，採用現代化的 DevOps 最佳實踐：

- **🔒 現代化安全性**: 採用 WireGuard 協定，提供比 OpenVPN 快 3.2 倍的性能和更小的攻擊面
- **🐳 容器化部署**: 使用 Docker 實現環境隔離、依賴管理和一鍵部署
- **🌐 動態 DNS**: 整合 Cloudflare DDNS 自動處理動態 IP，支援家庭網路環境
- **⚙️ 設定即程式碼**: 完全透過版本控制管理基礎設施，實現可追蹤、可重複的部署
- **🔄 GitOps 工作流程**: 使用 GitHub Actions 實現推送即部署的自動化工作流程
- **🛠️ 自動化管理**: 內建完整的管理腳本，簡化日常維運工作
- **📊 CGNAT 支援**: 提供 CGNAT 環境的替代解決方案

## 🏗️ 專案架構

```
QWV-QuickWireguardVpn/
├── 📋 規劃書.md                 # 完整的技術文檔和設計理念
├── 🔧 docker-compose.yml        # 服務編排設定
├── ⚙️ env.example              # 環境變數範本
├── 📝 README.md                # 專案文檔
├── 🔐 .gitignore               # Git 忽略設定
├── 🤖 .github/workflows/       # GitHub Actions 工作流程
│   └── deploy.yml              # 自動部署腳本
├── 📂 scripts/                 # 管理腳本
│   ├── setup.sh               # 初始環境設定
│   └── manage.sh               # 服務管理工具
├── 📁 config/                  # WireGuard 設定檔 (自動生成)
├── 💾 backup/                  # 備份檔案目錄
└── 📊 logs/                    # 日誌檔案目錄
```

### 核心服務架構

```
Internet → Router → Server → Docker → [WireGuard + DDNS]
    ↓
    └─ Client Devices (手機、筆電等)
```

## 🚀 快速開始

### ⚠️ 重要：CGNAT 檢測

**在開始之前，請先檢查您的網路環境是否支援：**

1. 登入路由器管理介面，記錄 WAN IP 位址
2. 訪問 [whatismyipaddress.com](https://whatismyipaddress.com) 查看公網 IP
3. 如果兩者不同，您可能處於 CGNAT 環境，需要使用 VPS 反向代理方案

### 系統需求

| 項目 | 最低需求 | 推薦配置 |
|------|----------|----------|
| 作業系統 | Ubuntu 20.04+ / Debian 11+ | Ubuntu 22.04 LTS |
| CPU | 1 核心 | 2 核心 |
| 記憶體 | 512MB | 1GB |
| 儲存空間 | 2GB | 5GB |
| 網路 | 10Mbps | 100Mbps |

### 前置需求

- ✅ Linux 伺服器（支援 Ubuntu/Debian）
- ✅ 具有 sudo 權限的使用者帳戶
- ✅ 擁有管理權限的域名（推薦使用 Cloudflare）
- ✅ 路由器管理權限（用於連接埠轉送）
- ✅ SSH 存取伺服器的能力
- ⚠️ 確認非 CGNAT 環境

## 📥 安裝指南

### 方法一：全自動安裝（推薦）

```bash
# 1. 克隆專案到伺服器
git clone https://github.com/yourusername/QWV-QuickWireguardVpn.git
cd QWV-QuickWireguardVpn

# 2. 執行一鍵安裝腳本
chmod +x scripts/*.sh
./scripts/setup.sh

# 3. 登出並重新登入以使 Docker 群組生效
exit
# 重新 SSH 連線

# 4. 配置環境變數
cp env.example .env
nano .env

# 5. 啟動服務
./scripts/manage.sh start
```

### 方法二：手動安裝

<details>
<summary>點擊展開手動安裝步驟</summary>

```bash
# 更新系統
sudo apt update && sudo apt upgrade -y

# 安裝 Docker 官方最新版本
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# 安裝其他依賴
sudo apt install -y ufw git curl

# 設定 Docker 權限
sudo usermod -aG docker $USER

# 設定防火牆
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 51820/udp
sudo ufw --force enable

# 啟用 IP 轉送
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 啟動 Docker
sudo systemctl enable docker
sudo systemctl start docker

# 克隆專案
git clone https://github.com/yourusername/QWV-QuickWireguardVpn.git
cd QWV-QuickWireguardVpn

# 建立目錄
mkdir -p config logs backup
```

</details>

## ⚙️ 詳細設定說明

### 1. Cloudflare 設定

#### 建立 API 權杖（遵循最小權限原則）

1. 登入 [Cloudflare 儀表板](https://dash.cloudflare.com)
2. 點擊右上角頭像 → 「我的設定檔」
3. 選擇「API 權杖」頁籤
4. 點擊「建立權杖」
5. 選擇「編輯區域 DNS」範本
6. 設定權限：
   ```
   權限：Zone:DNS:Edit
   區域資源：Include - Specific zone - yourdomain.com
   
   權限：Zone:Zone:Read  
   區域資源：Include - Specific zone - yourdomain.com
   ```
7. 複製生成的權杖並妥善保存

#### 設定 DNS 記錄

在 Cloudflare 中為您的域名新增一個 A 記錄：
- **名稱**: `vpn`
- **內容**: 您的當前公網 IP（DDNS 會自動更新）
- **Proxy 狀態**: 🌐（灰雲，關閉代理）

### 2. 環境變數設定

編輯 `.env` 檔案：

```bash
# 必要設定
CF_API_TOKEN=your_cloudflare_api_token_here
CF_ZONE=yourdomain.com
CF_SUBDOMAIN=vpn

# 可選設定（進階用戶）
# WIREGUARD_PORT=51820
# WIREGUARD_PEERS=laptop,phone,tablet
# INTERNAL_SUBNET=10.13.13.0
```

### 3. 路由器設定

#### 連接埠轉送設定

1. 登入路由器管理介面（通常是 192.168.1.1 或 192.168.0.1）
2. 尋找「連接埠轉送」、「虛擬伺服器」或「Port Forwarding」設定
3. 新增規則：
   ```
   服務名稱: WireGuard
   協定: UDP
   外部連接埠: 51820
   內部 IP: 您的伺服器內網 IP (例如 192.168.1.100)
   內部連接埠: 51820
   狀態: 啟用
   ```

#### 常見路由器品牌設定位置

| 品牌 | 設定路徑 |
|------|----------|
| TP-Link | 進階 → NAT 轉送 → 虛擬伺服器 |
| ASUS | 進階設定 → WAN → 虛擬伺服器/連接埠轉送 |
| Netgear | 進階 → 進階設定 → 連接埠轉送/連接埠觸發 |
| D-Link | 進階 → 連接埠轉送 |

### 4. 服務自訂設定

#### 修改 WireGuard 設定

編輯 `docker-compose.yml` 中的環境變數：

```yaml
environment:
  - PEERS=laptop,phone,tablet,work_computer  # 客戶端列表
  - SERVERPORT=51820                         # VPN 連接埠
  - PEERDNS=1.1.1.1,8.8.8.8                # 自訂 DNS 伺服器
  - ALLOWEDIPS=0.0.0.0/0, ::/0              # 全隧道模式
  - PERSISTENTKEEPALIVE_PEERS=all           # 保持連線活躍
```

#### 分割隧道設定（僅路由特定流量）

若只想透過 VPN 存取內網資源：

```yaml
- ALLOWEDIPS=192.168.1.0/24,10.13.13.0/24
```

## 📱 客戶端設定與連線

### 1. 手機客戶端設定（Android/iOS）

#### 安裝 WireGuard 應用程式

- **Android**: [Google Play Store](https://play.google.com/store/apps/details?id=com.wireguard.android)
- **iOS**: [App Store](https://apps.apple.com/app/wireguard/id1441195209)

#### 設定步驟

```bash
# 1. 顯示客戶端 QR Code
./scripts/manage.sh qr phone

# 2. 在手機應用程式中：
#    - 點擊「+」→「從 QR code 建立」
#    - 掃描終端顯示的 QR Code
#    - 為隧道命名（例如：Home VPN）
#    - 點擊「建立隧道」
```

### 2. 桌面客戶端設定

#### 下載 WireGuard 客戶端

- **Windows**: [官方下載](https://download.wireguard.com/windows-client/wireguard-installer.exe)
- **macOS**: [App Store](https://apps.apple.com/app/wireguard/id1451685025) 或 `brew install wireguard-tools`
- **Linux**: `sudo apt install wireguard` 或包管理器安裝

#### 設定步驟

```bash
# 1. 獲取設定檔
./scripts/manage.sh qr laptop  # 查看設定檔位置

# 2. 複製設定檔到本機
scp user@server:/path/to/config/peer_laptop/peer_laptop.conf ~/wireguard.conf

# 3. 在 WireGuard 客戶端中匯入設定檔
```

### 3. 新增客戶端

```bash
# 1. 編輯 docker-compose.yml
nano docker-compose.yml

# 2. 修改 PEERS 環境變數
- PEERS=laptop,phone,tablet,work_computer

# 3. 重新啟動服務
./scripts/manage.sh restart

# 4. 獲取新客戶端的 QR Code
./scripts/manage.sh qr work_computer
```

## 🛠️ 服務管理指令

### 基本操作

```bash
# 啟動所有服務
./scripts/manage.sh start

# 停止所有服務  
./scripts/manage.sh stop

# 重啟服務
./scripts/manage.sh restart

# 查看服務狀態和資源使用
./scripts/manage.sh status
```

### 監控與除錯

```bash
# 即時查看日誌
./scripts/manage.sh logs

# 顯示已連線的客戶端
./scripts/manage.sh peers

# 全面系統檢查
./scripts/manage.sh check

# 執行專案完整驗證
./scripts/manage.sh validate

# 顯示特定客戶端的 QR Code
./scripts/manage.sh qr <客戶端名稱>
```

### 維護操作

```bash
# 更新服務映像檔
./scripts/manage.sh update

# 備份設定檔（包含所有金鑰）
./scripts/manage.sh backup

# 查看可用指令
./scripts/manage.sh --help
```

### 進階管理

```bash
# 手動 Docker 操作
docker compose ps                    # 查看容器狀態
docker compose logs -f wireguard     # 查看 WireGuard 日誌
docker compose logs -f cloudflare-ddns # 查看 DDNS 日誌

# 進入 WireGuard 容器
docker exec -it wireguard bash

# 查看 WireGuard 介面狀態
docker exec wireguard wg show

# 查看網路設定
docker exec wireguard ip addr show wg0
```

## 🔍 故障排除指南

### 診斷工具

```bash
# 一鍵系統檢查
./scripts/manage.sh check

# 查看詳細日誌
./scripts/manage.sh logs | grep -i error

# 檢查網路連通性
ping vpn.yourdomain.com
nslookup vpn.yourdomain.com
```

### 常見問題與解決方案

#### 🚫 問題 1：無法建立握手

**症狀**: 客戶端顯示「最後握手：從未」

**可能原因與解決方案**:

<details>
<summary>🔥 防火牆阻擋</summary>

```bash
# 檢查 UFW 狀態
sudo ufw status numbered

# 確認 WireGuard 連接埠已開放
sudo ufw allow 51820/udp

# 檢查 iptables 規則
sudo iptables -L -n | grep 51820
```

</details>

<details>
<summary>🌐 路由器連接埠轉送問題</summary>

1. 重新檢查路由器設定：
   - 協定：UDP（不是 TCP）
   - 外部連接埠：51820
   - 內部 IP：正確的伺服器 IP
   - 內部連接埠：51820

2. 測試連接埠是否開放：
```bash
# 從外部網路測試（使用其他網路）
nc -u vpn.yourdomain.com 51820
```

</details>

<details>
<summary>⚠️ CGNAT 檢測</summary>

```bash
# 自動檢測腳本
curl -s https://ipinfo.io/ip > /tmp/external_ip
cat /tmp/external_ip

# 比較路由器 WAN IP
# 如果不同，可能有 CGNAT 問題
```

</details>

#### 🌍 問題 2：有握手但無法上網

**症狀**: WireGuard 顯示已連線，但無法瀏覽網頁

<details>
<summary>🔍 DNS 解析問題</summary>

```bash
# 在客戶端測試
ping 8.8.8.8        # 如果成功，IP 路由正常
ping google.com     # 如果失敗，DNS 問題

# 修復方法：編輯 docker-compose.yml
- PEERDNS=1.1.1.1,8.8.8.8
- ALLOWEDIPS=0.0.0.0/0, ::/0  # 確保包含 DNS 流量
```

</details>

<details>
<summary>🔄 IP 轉送問題</summary>

```bash
# 檢查 IP 轉送是否啟用
cat /proc/sys/net/ipv4/ip_forward  # 應該顯示 1

# 如果顯示 0，啟用 IP 轉送
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 重啟服務
./scripts/manage.sh restart
```

</details>

#### 🔧 問題 3：DDNS 更新失敗

<details>
<summary>📡 Cloudflare API 問題</summary>

```bash
# 檢查 DDNS 容器日誌
docker compose logs cloudflare-ddns

# 測試 API 權杖
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_API_TOKEN" \
     -H "Content-Type:application/json"

# 確認權杖權限：Zone:DNS:Edit 和 Zone:Zone:Read
```

</details>

#### 💻 問題 4：Docker 相關問題

<details>
<summary>🐳 Docker 權限問題</summary>

```bash
# 檢查 Docker 權限
groups $USER | grep docker

# 如果沒有 docker 群組，重新加入
sudo usermod -aG docker $USER
# 登出並重新登入

# 重啟 Docker 服務
sudo systemctl restart docker
```

</details>

### 進階除錯

#### 📊 效能監控

```bash
# 監控容器資源使用
docker stats

# 檢查網路延遲
ping -c 4 vpn.yourdomain.com

# 測試 VPN 速度
docker exec wireguard speedtest-cli
```

#### 🔬 網路診斷

```bash
# 查看 WireGuard 介面詳情
docker exec wireguard wg show all

# 檢查路由表
docker exec wireguard ip route

# 抓取網路封包
docker exec wireguard tcpdump -i wg0 -n
```

#### 📋 日誌分析

```bash
# 查看特定時間段的日誌
docker compose logs --since="2024-01-01T10:00:00" wireguard

# 過濾錯誤訊息
docker compose logs wireguard | grep -i "error\|fail\|unable"

# 匯出日誌到檔案
docker compose logs > vpn_logs_$(date +%Y%m%d).txt
```

## 🔐 安全最佳實踐

- ✅ 使用最小權限 API 權杖
- ✅ 定期備份設定檔
- ✅ 啟用 UFW 防火牆
- ✅ 將敏感資訊存於 `.env` 檔案（勿提交至 Git）
- ✅ 使用私有 Git 儲存庫

## 🚀 GitOps 工作流程

### 設定自動化部署

本專案支援完整的 GitOps 工作流程，實現「推送即部署」的自動化體驗。

#### 1. 設定 GitHub Secrets

在 GitHub 儲存庫中設定以下 Secrets（Settings → Secrets and variables → Actions）：

| Secret 名稱 | 說明 | 範例值 | 必要性 |
|-------------|------|--------|---------|
| `VPN_HOST` | 伺服器 IP 或域名 | `123.456.789.012` | ✅ 必要 |
| `VPN_USER` | SSH 用戶名 | `ubuntu` | ✅ 必要 |
| `VPN_SSH_KEY` | SSH 私鑰 | `-----BEGIN OPENSSH PRIVATE KEY-----...` | ✅ 必要 |
| `VPN_PORT` | SSH 連接埠 | `22` | ⚪ 可選 |
| `VPN_DEPLOY_PATH` | 部署路徑 | `/home/ubuntu/QWV-QuickWireguardVpn` | ✅ 必要 |
| `CF_API_TOKEN` | Cloudflare API 權杖 | `abc123...` | ✅ 必要 |
| `CF_ZONE` | 域名 | `yourdomain.com` | ✅ 必要 |
| `CF_SUBDOMAIN` | 子域名 | `vpn` | ✅ 必要 |

#### 2. 生成 SSH 金鑰對

```bash
# 在本機生成 SSH 金鑰對
ssh-keygen -t ed25519 -f ~/.ssh/vpn_deploy -N ""

# 將公鑰複製到伺服器
ssh-copy-id -i ~/.ssh/vpn_deploy.pub user@your-server

# 將私鑰內容複製到 GitHub Secrets 的 VPN_SSH_KEY
cat ~/.ssh/vpn_deploy
```

#### 3. 自動部署工作流程

推送到 `main` 分支時，GitHub Actions 會自動：

1. ✅ SSH 連線到您的伺服器
2. ✅ 拉取最新程式碼
3. ✅ 停止現有服務
4. ✅ 更新 Docker 映像檔
5. ✅ 使用新設定啟動服務
6. ✅ 清理舊映像檔
7. ✅ 驗證服務狀態

#### 4. 觸發部署

```bash
# 修改設定後推送
git add .
git commit -m "feat: 更新 VPN 設定"
git push origin main

# 檢查部署狀態
# 前往 GitHub → Actions 頁籤查看執行結果
```

#### 5. GitHub Actions 故障排除

<details>
<summary>🚨 常見 GitHub Actions 錯誤及解決方案</summary>

##### ❌ SSH 連線失敗

**錯誤訊息**: `ssh-keyscan` 或 `Permission denied`

**解決方案**:
1. 檢查 `VPN_SSH_KEY` 是否正確（包含完整的私鑰內容）
2. 確認 `VPN_HOST` 和 `VPN_USER` 設定正確
3. 如果使用非標準 SSH 連接埠，設定 `VPN_PORT`

```bash
# 測試 SSH 連線
ssh -i ~/.ssh/your_key user@host

# 檢查 SSH 金鑰格式
cat ~/.ssh/your_key | head -1  # 應顯示 -----BEGIN...
```

##### ❌ Git 操作失敗

**錯誤訊息**: `Git fetch 失敗` 或 `Permission denied`

**解決方案**:
1. 確認伺服器上的 Git 儲存庫狀態
2. 檢查部署路徑是否正確

```bash
# 在伺服器上手動檢查
cd /path/to/deploy/directory
git status
git remote -v
```

##### ❌ Docker 權限問題

**錯誤訊息**: `permission denied while trying to connect to the Docker daemon`

**解決方案**:
```bash
# 在伺服器上執行
sudo usermod -aG docker $USER
# 重新登入生效
```

##### ❌ 服務啟動失敗

**錯誤訊息**: `啟動服務失敗`

**解決方案**:
1. 檢查 `.env` 檔案內容
2. 查看 Docker 服務狀態
3. 檢查連接埠是否被占用

```bash
# 手動診斷
./scripts/manage.sh check
docker compose logs
sudo ss -tulpn | grep 51820
```

</details>

## 📚 進階主題與最佳實踐

### 🔧 客戶端管理

#### 新增客戶端

```bash
# 方法 1：編輯 docker-compose.yml（推薦）
nano docker-compose.yml
# 修改: - PEERS=laptop,phone,tablet,work_laptop

# 方法 2：使用環境變數
echo "PEERS=laptop,phone,tablet,work_laptop" >> .env

# 重新啟動服務
./scripts/manage.sh restart

# 獲取新客戶端設定
./scripts/manage.sh qr work_laptop
```

#### 移除客戶端

```bash
# 從 PEERS 列表中移除客戶端名稱
nano docker-compose.yml

# 重新啟動服務（舊的設定檔會被自動清理）
./scripts/manage.sh restart
```

### 🔐 安全強化

#### 變更預設連接埠

```yaml
# docker-compose.yml
environment:
  - SERVERPORT=12345  # 變更為非標準連接埠
ports:
  - "12345:51820/udp"  # 對應修改對外連接埠
```

#### 啟用客戶端金鑰輪換

```bash
# 定期備份舊設定
./scripts/manage.sh backup

# 清除所有客戶端設定（將重新生成新金鑰）
rm -rf config/peer_*

# 重新啟動服務
./scripts/manage.sh restart
```

#### 限制客戶端網路存取

```yaml
# 僅允許存取內網資源（分割隧道）
- ALLOWEDIPS=192.168.1.0/24,10.13.13.0/24

# 自訂 DNS 伺服器（使用內網 Pi-hole）
- PEERDNS=192.168.1.100
```

### 📊 監控與日誌

#### 設定日誌輪換

```bash
# 安裝 logrotate
sudo apt install logrotate

# 建立 VPN 日誌輪換設定
sudo tee /etc/logrotate.d/qwv-vpn << EOF
/home/ubuntu/QWV-QuickWireguardVpn/logs/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
}
EOF
```

#### 設定監控告警

```bash
# 建立簡單的健康檢查腳本
cat > scripts/health_check.sh << 'EOF'
#!/bin/bash
if ! docker exec wireguard wg show | grep -q "peer:"; then
    echo "WARNING: No WireGuard peers connected"
    # 可以在此處添加通知邏輯（如發送 email 或 Slack 訊息）
fi
EOF

chmod +x scripts/health_check.sh

# 設定 cron 定期檢查
echo "*/15 * * * * /path/to/scripts/health_check.sh" | crontab -
```

### 🌐 多地部署

#### 地理分散式 VPN

```bash
# 為不同地區建立分支
git checkout -b asia-server
git checkout -b europe-server

# 各分支使用不同的 CF_SUBDOMAIN
# Asia: vpn-asia.yourdomain.com
# Europe: vpn-eu.yourdomain.com
```

### 🔄 備份與災難復原

#### 自動化備份腳本

```bash
# 建立自動備份腳本
cat > scripts/auto_backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/path/to/backup/location"
DATE=$(date +%Y%m%d_%H%M%S)

# 建立備份
./scripts/manage.sh backup

# 同步到遠端
rsync -av backup/ user@backup-server:$BACKUP_DIR/

# 清理本地舊備份（保留 7 天）
find backup/ -name "*.tar.gz" -mtime +7 -delete
EOF

# 設定每日自動備份
echo "0 2 * * * /path/to/scripts/auto_backup.sh" | crontab -
```

#### 災難復原程序

```bash
# 1. 在新伺服器上克隆專案
git clone https://github.com/yourusername/QWV-QuickWireguardVpn.git
cd QWV-QuickWireguardVpn

# 2. 執行初始設定
./scripts/setup.sh

# 3. 還原備份的設定檔
tar -xzf backup/wireguard_backup_YYYYMMDD_HHMMSS.tar.gz

# 4. 設定環境變數
cp env.example .env
nano .env

# 5. 啟動服務
./scripts/manage.sh start
```

## 📈 效能最佳化

### 調整 WireGuard 參數

```yaml
# docker-compose.yml - 針對高流量環境的最佳化
environment:
  - ALLOWEDIPS=0.0.0.0/0, ::/0
  - PERSISTENTKEEPALIVE_PEERS=25  # 保持連線穩定
  - LOG_CONFS=false              # 關閉 QR code 日誌以節省資源
```

### 系統調整

```bash
# 增加 UDP 緩衝區大小
echo 'net.core.rmem_max = 26214400' | sudo tee -a /etc/sysctl.conf
echo 'net.core.rmem_default = 26214400' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 重啟服務以套用變更
./scripts/manage.sh restart
```

## 🔧 開發與維護指南

### 專案結構說明

```
QWV-QuickWireguardVpn/
├── 📋 規劃書.md                 # 完整技術文檔（603行專業分析）
├── 🔧 docker-compose.yml        # 服務編排（WireGuard + DDNS）
├── ⚙️ env.example              # 環境變數範本（安全設定）
├── 🔐 .gitignore               # Git 忽略規則（保護敏感資訊）
├── 🤖 .github/workflows/       # CI/CD 自動化
│   └── deploy.yml              # GitOps 部署流程
├── 📂 scripts/                 # 管理工具集
│   ├── setup.sh               # 環境初始化（一鍵安裝）
│   └── manage.sh               # 服務管理（20+ 功能）
├── 📁 config/                  # WireGuard 設定（自動生成）
├── 💾 backup/                  # 備份檔案
└── 📊 logs/                    # 系統日誌
```

### 代碼貢獻流程

#### Fork 並設定開發環境

```bash
# 1. Fork 此儲存庫到您的 GitHub 帳戶

# 2. 克隆您的 Fork
git clone https://github.com/YOUR_USERNAME/QWV-QuickWireguardVpn.git
cd QWV-QuickWireguardVpn

# 3. 設定上游儲存庫
git remote add upstream https://github.com/ORIGINAL_OWNER/QWV-QuickWireguardVpn.git

# 4. 建立功能分支
git checkout -b feature/your-feature-name
```

#### 開發規範

- ✅ 所有腳本必須通過 ShellCheck 檢查
- ✅ Docker Compose 檔案應使用最新的語法版本
- ✅ 新增功能需包含相應的文檔更新
- ✅ 遵循既有的程式碼風格和命名慣例

#### 測試檢查清單

```bash
# 語法檢查
shellcheck scripts/*.sh

# 功能測試
./scripts/setup.sh --dry-run
./scripts/manage.sh check

# Docker 語法驗證
docker compose config
```

#### 提交 Pull Request

```bash
# 1. 確保程式碼是最新的
git fetch upstream
git rebase upstream/main

# 2. 提交變更
git add .
git commit -m "feat: 新增 XXX 功能"

# 3. 推送到您的 Fork
git push origin feature/your-feature-name

# 4. 在 GitHub 上建立 Pull Request
```

### 版本發布流程

#### 語義化版本控制

我們使用 [語義化版本控制](https://semver.org/lang/zh-TW/)：

- `MAJOR.MINOR.PATCH` (例如：`1.2.3`)
- **MAJOR**：不相容的 API 變更
- **MINOR**：向後相容的功能新增
- **PATCH**：向後相容的問題修正

#### 發布步驟

```bash
# 1. 更新版本號
echo "v1.2.3" > VERSION

# 2. 更新 CHANGELOG
# 記錄此版本的所有變更

# 3. 建立發布標籤
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3

# 4. 在 GitHub 建立 Release
# 包含變更摘要和升級指引
```

## 🆘 技術支援

### 社群支援

- 🐛 **Bug 回報**: [GitHub Issues](https://github.com/yourusername/QWV-QuickWireguardVpn/issues)
- 💡 **功能建議**: [GitHub Discussions](https://github.com/yourusername/QWV-QuickWireguardVpn/discussions)
- 📖 **文件問題**: 透過 Pull Request 直接修正

### 專業服務

如果您需要：
- 🏢 企業級部署諮詢
- 🔧 客製化功能開發
- 🎓 WireGuard 技術培訓
- 🛡️ 安全性評估

歡迎通過 GitHub Issues 聯繫我們，標註 `[Commercial]`。

## 📄 授權條款

本專案採用 **MIT 授權條款**。詳細條款請參考 [LICENSE](LICENSE) 檔案。

### 簡述

- ✅ **商業使用**: 允許用於商業目的
- ✅ **修改**: 允許修改程式碼
- ✅ **分發**: 允許分發原始或修改後的程式碼
- ✅ **私人使用**: 允許私人使用
- ⚠️ **責任限制**: 不提供任何擔保，使用風險自負

## 🤝 貢獻者

感謝所有為此專案做出貢獻的開發者：

<!-- 這裡會自動列出貢獻者 -->

## 🌟 致謝

本專案的實現得益於以下優秀的開源專案：

- [WireGuard](https://www.wireguard.com/) - 現代化的 VPN 協定
- [LinuxServer.io](https://linuxserver.io/) - 優秀的 Docker 映像檔
- [Docker](https://www.docker.com/) - 容器化平台
- [Cloudflare](https://www.cloudflare.com/) - DNS 服務提供商

## 📖 延伸閱讀

- 📋 **[規劃書.md](規劃書.md)** - 完整的技術分析和設計理念（603行專業文檔）
- 🔗 **[WireGuard 官方文檔](https://www.wireguard.com/quickstart/)**
- 🐳 **[Docker Compose 參考](https://docs.docker.com/compose/)**
- 🌐 **[Cloudflare API 文檔](https://developers.cloudflare.com/api/)**

---

<div align="center">

**⭐ 如果這個專案對您有幫助，請給我們一個 Star！**

**🔗 [GitHub Repository](https://github.com/yourusername/QWV-QuickWireguardVpn)**

Made with ❤️ by the QWV Team

</div> 