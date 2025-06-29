# 🧪 QWV VPN 詳細測試步驟

## ⚡ GitHub Actions 快速配置指引

### 🎯 只想快速完成 GitHub Actions 配置？

如果您已有 GCP 伺服器和 Cloudflare 帳號，按以下順序快速配置：

#### 📝 必須收集的信息

1. **🏠 本地收集伺服器信息**：
   ```bash
   # 獲取 GCP 伺服器外部 IP
   gcloud compute instances list
   # 記錄：VPN_HOST = "YOUR_SERVER_IP"
   ```

2. **🌐 獲取 Cloudflare API 權杖**：
   - 前往：https://dash.cloudflare.com → 我的設定檔 → API 權杖
   - 建立權杖：DNS:Edit + Zone:Read 權限
   - 記錄：CF_API_TOKEN = "cf_xxxxxxxx"

3. **🏠 生成 SSH 金鑰**：
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/qwv_github_key
   # 複製私鑰：cat ~/.ssh/qwv_github_key
   # 部署公鑰到伺服器：ssh-copy-id -i ~/.ssh/qwv_github_key.pub ubuntu@YOUR_SERVER_IP
   ```

#### 🔐 GitHub 配置（2 分鐘完成）

**前往：https://github.com/rich7420/QWV → Settings → Secrets and variables → Actions**

**Variables 頁籤**：
```
VPN_DOMAIN = vpn.917420.xyz
```

**Secrets 頁籤**：
```
VPN_HOST = YOUR_SERVER_IP
VPN_USER = ubuntu
VPN_SSH_KEY = -----BEGIN OPENSSH PRIVATE KEY-----...
CF_API_TOKEN = cf_xxxxxxxxxxxxxxxxxxxxxxxx
```

✅ **完成！推送程式碼觸發自動部署**

#### 🔍 快速檢查清單

在推送程式碼前，請確認：

- [ ] ✅ **GitHub Variables**：VPN_DOMAIN 已設定
- [ ] ✅ **GitHub Secrets**：VPN_HOST, VPN_USER, VPN_SSH_KEY, CF_API_TOKEN 已設定
- [ ] ✅ **SSH 測試**：`ssh -i ~/.ssh/qwv_github_key ubuntu@YOUR_SERVER_IP "echo OK"`
- [ ] ✅ **CF API 測試**：`curl -H "Authorization: Bearer $CF_API_TOKEN" https://api.cloudflare.com/client/v4/user/tokens/verify`

---

## 🚀 快速測試指南

### 📐 專案架構

**QWV** 是基於 **DNS 服務路由** 的企業級 WireGuard VPN 解決方案：

```
📱 客戶端設備 → DNS 解析 → 對應區域的 VPN 伺服器 → 🌐 網路流量路由

單環境模式：vpn.917420.xyz → 單一 VPN 伺服器
多環境模式：
├── vpn-asia.917420.xyz → 🌏 亞洲 VPN 伺服器 (GCP Asia)
├── vpn-us.917420.xyz   → 🇺🇸 美國 VPN 伺服器 (GCP US)
└── vpn-eu.917420.xyz   → 🇪🇺 歐洲 VPN 伺服器 (GCP EU)
```

**核心組件**：
- **GitHub Actions**: 自動化部署和管理
- **Docker + WireGuard**: VPN 服務容器化
- **Cloudflare DDNS**: 動態域名解析
- **DNS 路由**: 基於域名的服務發現

---

## 🗂️ 配置總覽對照表

### 📍 執行位置圖例
- 🏠 **本地電腦**：您的個人電腦
- ☁️ **GCP 伺服器**：雲端虛擬機
- 🌐 **網頁界面**：瀏覽器操作

### 📋 重要配置分佈一覽

| 配置項目 | 🔐 GitHub Secrets | 🔓 GitHub Variables | 📁 .env 檔案 | 執行位置 |
|---------|------------------|-------------------|--------------|----------|
| **伺服器 IP** | ✅ `VPN_HOST` | ❌ | ❌ | 🏠 gcloud CLI |
| **SSH 用戶名** | ✅ `VPN_USER` | ❌ | ❌ | 🏠 本地 |
| **SSH 私鑰** | ✅ `VPN_SSH_KEY` | ❌ | ❌ | 🏠 本地生成 |
| **SSH 埠號** | ✅ `VPN_PORT` | ❌ | ❌ | 🏠 本地 |
| **VPN 域名** | ❌ | ✅ `VPN_DOMAIN` | ✅ `SERVERURL` | 🌐 Cloudflare |
| **CF API 權杖** | ✅ `CF_API_TOKEN` | ❌ | ✅ `CF_API_TOKEN` | 🌐 Cloudflare |
| **CF 域名** | ❌ | ❌ | ✅ `CF_ZONE` | 🌐 Cloudflare |
| **CF 子域名** | ❌ | ❌ | ✅ `CF_SUBDOMAIN` | 🌐 Cloudflare |
| **WG 客戶端** | ❌ | ❌ | ✅ `PEERS` | ☁️ 伺服器編輯 |

### 🔍 重要說明

⚠️ **關鍵區別**：
- **🔐 GitHub Secrets**：供 **GitHub Actions 自動部署** 使用
- **📁 .env 檔案**：供 **Docker 容器服務** 使用
- **🔓 GitHub Variables**：供 **GitHub Actions 公開配置** 使用

📝 **配置順序**：
1. 🏠 **本地準備**：生成 SSH 金鑰、收集伺服器信息
2. 🌐 **網頁配置**：設定 Cloudflare API 權杖、GitHub Variables/Secrets
3. ☁️ **伺服器配置**：編輯 .env 檔案、部署服務

---

## 📋 配置前準備清單

### 🛠️ 必要工具檢查

在開始配置前，請確保您具備以下工具：

```bash
# 檢查本機必要工具
which ssh || echo "❌ 需要安裝 SSH 客戶端"
which ssh-keygen || echo "❌ 需要安裝 SSH 工具"
which git || echo "❌ 需要安裝 Git"
which curl || echo "❌ 需要安裝 curl"

# 檢查可選工具（建議安裝）
which qrencode || echo "⚠️ 建議安裝 qrencode 用於 QR Code 顯示"
which speedtest-cli || echo "⚠️ 建議安裝 speedtest-cli 用於速度測試"
```

### 🎯 配置目標確認

**選擇您的部署架構**：

- **🔧 單環境部署（推薦新手）**：1 台伺服器，適合個人使用
- **🌍 多環境部署（企業級）**：3 台伺服器（亞洲/美國/歐洲），提供地理分佈

---

## 📝 詳細配置步驟

### 🔑 步驟一：伺服器信息收集

> 🎯 **執行位置**：🏠 本地電腦操作 + ☁️ GCP 網頁/CLI

---

## 🖥️ 伺服器信息用途說明

| 信息類型 | 儲存位置 | 用於 |
|---------|----------|------|
| **🌐 外部 IP** | 🔐 GitHub Secrets `VPN_HOST` | GitHub Actions SSH 連線 |
| **👤 用戶名** | 🔐 GitHub Secrets `VPN_USER` | GitHub Actions SSH 登入 |
| **🔌 SSH 埠** | 🔐 GitHub Secrets `VPN_PORT` | GitHub Actions SSH 連線 |

---

#### **1.1 🏠 GCP 伺服器 IP 地址獲取（本地操作）**

```bash
# 🏠 在本地電腦執行（需要安裝 gcloud CLI）
# 如果您已經有 GCP 虛擬機，獲取外部 IP
gcloud compute instances list --format="table(name,zone,status,EXTERNAL_IP)"

# 獲取特定虛擬機的外部 IP
gcloud compute instances describe YOUR_VM_NAME \
    --zone=YOUR_ZONE \
    --format="value(networkInterfaces[0].accessConfigs[0].natIP)"

# 範例輸出：203.0.113.45
```

**如果尚未建立 GCP 虛擬機**：

```bash
# 單環境：建立 1 台伺服器
gcloud compute instances create qwv-vpn-main \
    --zone=asia-east1-a \
    --machine-type=e2-micro \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=10GB \
    --tags=wireguard-server

# 多環境：建立 3 台伺服器
gcloud compute instances create qwv-vpn-asia \
    --zone=asia-east1-a \
    --machine-type=e2-micro \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=10GB \
    --tags=wireguard-server

gcloud compute instances create qwv-vpn-us \
    --zone=us-central1-a \
    --machine-type=e2-micro \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=10GB \
    --tags=wireguard-server

gcloud compute instances create qwv-vpn-eu \
    --zone=europe-west1-a \
    --machine-type=e2-micro \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=10GB \
    --tags=wireguard-server

# 開放防火牆（所有伺服器都需要）
gcloud compute firewall-rules create allow-wireguard \
    --allow udp:51820 \
    --source-ranges 0.0.0.0/0 \
    --target-tags wireguard-server \
    --description "Allow WireGuard VPN traffic"
```

#### **1.2 確認伺服器訪問權限**

```bash
# 測試 SSH 連線到每台伺服器
ssh ubuntu@YOUR_SERVER_IP "echo 'Server accessible: $(hostname)'"

# 檢查伺服器基本信息
ssh ubuntu@YOUR_SERVER_IP "
echo '=== Server Information ==='
echo 'Hostname: $(hostname)'
echo 'OS Version: $(lsb_release -d)'
echo 'Available Memory: $(free -h | grep Mem)'
echo 'Available Disk: $(df -h / | tail -1)'
echo 'Public IP: $(curl -s https://ipinfo.io/ip)'
"
```

#### **1.3 記錄伺服器信息**

**請填入您的伺服器信息**：

**單環境配置**：
```
VPN_HOST = "_______________"  # 填入：GCP 外部 IP 或域名
VPN_USER = "ubuntu"          # 通常是 ubuntu，如自訂請修改
VPN_PORT = "22"              # SSH 連接埠，預設 22
```

**多環境配置**：
```
# 亞洲環境
VPN_HOST_ASIA = "_______________"  # 填入：亞洲伺服器 IP
VPN_USER_ASIA = "ubuntu"
VPN_PORT_ASIA = "22"

# 美國環境  
VPN_HOST_US = "_______________"    # 填入：美國伺服器 IP
VPN_USER_US = "ubuntu"
VPN_PORT_US = "22"

# 歐洲環境
VPN_HOST_EU = "_______________"    # 填入：歐洲伺服器 IP
VPN_USER_EU = "ubuntu" 
VPN_PORT_EU = "22"
```

---

### 🌐 步驟二：Cloudflare API 權杖獲取

> 🎯 **執行位置**：🌐 Cloudflare 網頁界面操作 + 🏠 本地測試

---

## 🔑 Cloudflare API 權杖用途說明

| 權杖用途 | 儲存位置 | 用於 |
|---------|----------|------|
| **🔐 GitHub Secrets** | GitHub Actions `CF_API_TOKEN` | 自動部署時更新 DNS |
| **📁 .env 檔案** | GCP 伺服器 `.env` | Docker 容器 DDNS 更新 |

⚠️ **注意**：可以使用相同的 API 權杖，或為不同環境創建不同權杖

---

#### **2.1 🌐 登入 Cloudflare 並生成 API 權杖（網頁操作）**

1. **前往 Cloudflare 儀表板**：
   ```
   網址：https://dash.cloudflare.com
   使用您的 Cloudflare 帳號登入
   ```

2. **導航到 API 權杖頁面**：
   ```
   點擊右上角頭像 → "我的設定檔" → "API 權杖" 頁籤
   ```

3. **建立自訂權杖**：
   ```
   點擊 "建立權杖" → "自訂權杖" → "開始使用"
   ```

#### **2.2 配置權杖權限**

**權杖名稱**：`QWV-VPN-DNS-Manager`

**權限設定**：
```
權限 #1：
- 服務：Zone
- 操作：DNS:Edit
- 資源：Include - Specific zone - 917420.xyz

權限 #2：
- 服務：Zone  
- 操作：Zone:Read
- 資源：Include - Specific zone - 917420.xyz

權限 #3：（可選，建議）
- 服務：Zone
- 操作：Zone Settings:Read
- 資源：Include - Specific zone - 917420.xyz
```

**客戶端 IP 位址篩選**：（建議留空，允許所有 IP）

**TTL（有效期）**：建議設定為 1 年

#### **2.3 測試 API 權杖**

```bash
# 複製生成的權杖（形如：cf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx）
export CF_API_TOKEN="YOUR_ACTUAL_TOKEN_HERE"

# 測試權杖有效性
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json"

# 預期輸出：
# {
#   "success": true,
#   "result": {
#     "id": "...",
#     "status": "active"
#   }
# }
```

#### **2.4 獲取 Zone ID（用於驗證）**

```bash
# 獲取您域名的 Zone ID
curl -X GET "https://api.cloudflare.com/client/v4/zones?name=917420.xyz" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json"

# 記錄返回的 Zone ID，用於後續驗證
```

#### **2.5 記錄 API 權杖信息**

**請填入您的 Cloudflare 信息**：

**單環境配置**：
```
CF_API_TOKEN = "_______________"  # 填入：剛才生成的 API 權杖
CF_ZONE = "917420.xyz"           # 您的域名
CF_SUBDOMAIN = "vpn"             # VPN 子域名（最終：vpn.917420.xyz）
```

**多環境配置**：
```
# 可以使用相同的 API 權杖，或為每個環境生成獨立權杖
CF_API_TOKEN_ASIA = "_______________"  # 亞洲環境 API 權杖
CF_API_TOKEN_US = "_______________"    # 美國環境 API 權杖  
CF_API_TOKEN_EU = "_______________"    # 歐洲環境 API 權杖

# DNS 域名配置
VPN_DOMAIN_ASIA = "vpn-asia.917420.xyz"
VPN_DOMAIN_US = "vpn-us.917420.xyz"
VPN_DOMAIN_EU = "vpn-eu.917420.xyz"
```

---

### 🔑 步驟三：SSH 金鑰生成與部署

> 🎯 **執行位置**：🏠 本地電腦操作 + ☁️ GCP 伺服器操作

---

## 🔐 SSH 金鑰用途說明

| 金鑰用途 | 儲存位置 | 用於 |
|---------|----------|------|
| **🔑 私鑰** | 🏠 本地 `~/.ssh/` + 🔐 GitHub Secrets | GitHub Actions SSH 連線到伺服器 |
| **🔓 公鑰** | ☁️ GCP 伺服器 `~/.ssh/authorized_keys` | 允許 GitHub Actions 登入 |

---

#### **3.1 🏠 生成專用 SSH 金鑰（本地操作）**

```bash
# 🏠 在本地電腦執行
# 創建 SSH 金鑰目錄（如果不存在）
mkdir -p ~/.ssh

# 生成 SSH 金鑰對
ssh-keygen -t ed25519 -C "github-actions@917420.xyz" -f ~/.ssh/qwv_github_key

# 提示輸入 passphrase 時，直接按 Enter（GitHub Actions 需要無密碼金鑰）
# 預期輸出：
# Generating public/private ed25519 key pair.
# Enter passphrase (empty for no passphrase): [按 Enter]
# Enter same passphrase again: [按 Enter]
# Your identification has been saved in ~/.ssh/qwv_github_key
# Your public key has been saved in ~/.ssh/qwv_github_key.pub
```

#### **3.2 獲取私鑰內容（用於 GitHub Secrets）**

```bash
# 顯示私鑰內容
echo "=== 私鑰內容（用於 GitHub Secrets）==="
cat ~/.ssh/qwv_github_key

# 預期輸出格式：
# -----BEGIN OPENSSH PRIVATE KEY-----
# b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz
# c2gtZWQyNTUxOQAAACBQxXKp3gN+foooo3gN+foooo3gN+foooo3gN+foooo...
# -----END OPENSSH PRIVATE KEY-----

# 複製完整內容，包含 BEGIN 和 END 行
```

#### **3.3 部署公鑰到伺服器**

> ⚠️ **常見問題**：如果遇到 `Permission denied (publickey)` 錯誤，請先參考下方的故障排除步驟

**🔍 步驟 3.3.1：確認正確的 SSH 用戶名**

```bash
# 🏠 在本地電腦執行
# 1. 確認 GCP 虛擬機的正確用戶名
gcloud compute instances describe YOUR_VM_NAME --zone=YOUR_ZONE --format="value(metadata.items[key=ssh-keys].value)"

# 2. 或檢查您在創建虛擬機時使用的用戶名
gcloud compute ssh YOUR_VM_NAME --zone=YOUR_ZONE --dry-run
# 這會顯示 gcloud 嘗試使用的用戶名

# 3. 常見的 GCP 用戶名：
# - ubuntu (Ubuntu 映像檔)
# - debian (Debian 映像檔)  
# - 您的 Google 帳號用戶名（自訂映像檔）
```

**🔧 步驟 3.3.2：方法一 - 使用 gcloud compute ssh（推薦）**

```bash
# 🏠 在本地電腦執行
# 使用 gcloud 自動管理 SSH 金鑰
gcloud compute ssh YOUR_VM_NAME --zone=YOUR_ZONE

# 一旦成功登入，在伺服器上執行：
# ☁️ 在 GCP 伺服器上執行
cat ~/.ssh/authorized_keys
# 記錄現有的公鑰格式，我們需要添加 GitHub Actions 專用金鑰
```

**🔧 步驟 3.3.3：方法二 - 手動添加公鑰（如果方法一不可行）**

```bash
# 🏠 在本地電腦執行
# 1. 顯示公鑰內容
echo "=== 請複製以下公鑰內容 ==="
cat ~/.ssh/qwv_github_key.pub

# 2. 使用現有的 SSH 連線方式登入伺服器
# （使用您平時能成功登入的方式）

# ☁️ 登入 GCP 伺服器後執行：
# 創建 .ssh 目錄（如果不存在）
mkdir -p ~/.ssh

# 添加公鑰到 authorized_keys
echo "YOUR_PUBLIC_KEY_CONTENT_HERE" >> ~/.ssh/authorized_keys

# 設定正確權限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 檢查 authorized_keys 內容
cat ~/.ssh/authorized_keys
```

**🔧 步驟 3.3.4：方法三 - 透過 GCP Console（網頁界面）**

1. **前往 GCP Console**：
   ```
   https://console.cloud.google.com/compute/instances
   ```

2. **編輯虛擬機 SSH 金鑰**：
   ```
   點擊您的虛擬機名稱 → 點擊「編輯」→ 滾動到「SSH 金鑰」區段
   ```

3. **添加新金鑰**：
   ```bash
   # 🏠 複製本地公鑰內容
   cat ~/.ssh/qwv_github_key.pub
   
   # 在 GCP Console 中點擊「+ 新增項目」
   # 貼上公鑰內容，格式應為：
   # ssh-ed25519 AAAAC3NzaC1lZDI1... github-actions@917420.xyz
   ```

4. **儲存變更**：
   ```
   點擊「儲存」，等待幾分鐘讓變更生效
   ```

**🔧 步驟 3.3.5：故障排除常見問題**

```bash
# 問題 1：用戶名錯誤
# 症狀：Permission denied immediately
# 解決：確認正確的用戶名
ssh -v YOUR_USERNAME@YOUR_SERVER_IP  # 使用 -v 查看詳細日誌

# 問題 2：SSH 服務配置問題  
# 症狀：PasswordAuthentication disabled
# 解決：使用上述方法三透過 GCP Console 添加

# 問題 3：防火牆阻擋 SSH
# 症狀：Connection timeout
# 解決：確認防火牆規則
gcloud compute firewall-rules list --filter="name:default-allow-ssh"

# 問題 4：SSH 金鑰格式問題
# 症狀：Key format not recognized  
# 解決：檢查公鑰格式
head -1 ~/.ssh/qwv_github_key.pub  # 應該以 ssh-ed25519 開頭
```

**✅ 步驟 3.3.6：驗證部署成功**

```bash
# 🏠 在本地電腦測試新金鑰
ssh -i ~/.ssh/qwv_github_key YOUR_USERNAME@YOUR_SERVER_IP "echo 'GitHub Actions SSH key deployment successful'"

# 預期輸出：GitHub Actions SSH key deployment successful
```

**多環境部署**：
```bash
# 部署到所有伺服器
ssh-copy-id -i ~/.ssh/qwv_github_key.pub ubuntu@ASIA_SERVER_IP
ssh-copy-id -i ~/.ssh/qwv_github_key.pub ubuntu@US_SERVER_IP  
ssh-copy-id -i ~/.ssh/qwv_github_key.pub ubuntu@EU_SERVER_IP

# 或為每個環境使用不同的金鑰（更安全）
ssh-keygen -t ed25519 -C "github-actions-asia@917420.xyz" -f ~/.ssh/qwv_asia_key
ssh-keygen -t ed25519 -C "github-actions-us@917420.xyz" -f ~/.ssh/qwv_us_key
ssh-keygen -t ed25519 -C "github-actions-eu@917420.xyz" -f ~/.ssh/qwv_eu_key
```

#### **3.4 驗證 SSH 金鑰**

```bash
# 測試 SSH 連線（單環境）
ssh -i ~/.ssh/qwv_github_key ubuntu@YOUR_SERVER_IP "echo 'SSH key verification successful for $(hostname)'"

# 測試 Docker 權限
ssh -i ~/.ssh/qwv_github_key ubuntu@YOUR_SERVER_IP "docker --version"

# 多環境測試
ssh -i ~/.ssh/qwv_github_key ubuntu@ASIA_SERVER_IP "echo 'Asia server: $(hostname)'"
ssh -i ~/.ssh/qwv_github_key ubuntu@US_SERVER_IP "echo 'US server: $(hostname)'"
ssh -i ~/.ssh/qwv_github_key ubuntu@EU_SERVER_IP "echo 'EU server: $(hostname)'"
```

#### **3.5 記錄 SSH 金鑰信息**

**請確認您的 SSH 金鑰配置**：

**單環境配置**：
```
VPN_SSH_KEY = """
-----BEGIN OPENSSH PRIVATE KEY-----
[填入步驟 3.2 中複製的完整私鑰內容]
-----END OPENSSH PRIVATE KEY-----
"""
```

**多環境配置**（如使用相同金鑰）：
```
VPN_SSH_KEY_ASIA = """[相同私鑰內容]"""
VPN_SSH_KEY_US = """[相同私鑰內容]"""  
VPN_SSH_KEY_EU = """[相同私鑰內容]"""
```

**多環境配置**（如使用不同金鑰）：
```bash
# 分別獲取各環境的私鑰
echo "=== Asia SSH Key ==="
cat ~/.ssh/qwv_asia_key

echo "=== US SSH Key ==="  
cat ~/.ssh/qwv_us_key

echo "=== EU SSH Key ==="
cat ~/.ssh/qwv_eu_key
```

---

### ⚙️ 步驟四：.env 環境變數配置

> 🎯 **執行位置**：☁️ GCP 伺服器執行

---

## 📁 .env 檔案配置對照表

### 🔍 配置分類說明

| 配置項目 | 用途 | 儲存位置 | 安全性 |
|---------|------|----------|--------|
| **📁 .env** | 伺服器本地環境變數 | GCP 伺服器 `/QWV/.env` | 🔒 伺服器本地檔案 |
| **🔐 GitHub Secrets** | CI/CD 部署用敏感信息 | GitHub Actions 加密儲存 | 🔒 雲端加密 |

⚠️ **重要區別**：
- `.env` 檔案：存放在 **GCP 伺服器**，供 Docker 容器使用
- GitHub Secrets：存放在 **GitHub**，供自動部署使用

---

#### **4.1 創建伺服器端 .env 文件**

```bash
# ☁️ 在 GCP 伺服器上執行
cd QWV  # 確保在專案根目錄
cp env.example .env

# 檢查 .env 模板內容
cat env.example
```

#### **4.2 🤖 自動偵測裝置名稱功能**

**QWV 現在支援三種客戶端配置模式**：

**模式 1：自動偵測（推薦新功能）**
```bash
# 在 .env 文件中設定
WIREGUARD_PEERS=auto
AUTO_PEER_FORMAT=username-hostname  # 可選，預設值

# 這將自動偵測：
# - 使用者名稱：$(whoami) 
# - 主機名稱：$(hostname)
# - 組合格式：john-laptop、mary-desktop 等
```

**模式 2：手動指定**
```bash
# 傳統方式，手動列出所有客戶端
WIREGUARD_PEERS=laptop,phone,tablet
```

**模式 3：混合模式**
```bash
# 結合自動偵測和手動指定
WIREGUARD_PEERS=auto,work_laptop,family_tablet,guest_phone
```

**🔧 自動偵測格式選項**：

| 格式 | 說明 | 範例結果 |
|------|------|----------|
| `username` | 僅使用使用者名稱 | `john` |
| `hostname` | 僅使用主機名稱 | `laptop` |
| `username-hostname` | 使用者-主機名（預設） | `john-laptop` |
| `hostname-username` | 主機名-使用者 | `laptop-john` |

#### **4.3 填寫 .env 配置值**

**編輯 .env 文件**：
```bash
# 使用您偏好的編輯器
nano .env
# 或
vim .env
# 或
code .env
```

**單環境 .env 配置範例（使用自動偵測）**：
```bash
# Cloudflare DDNS 配置
CF_API_TOKEN=cf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
CF_ZONE=917420.xyz
CF_SUBDOMAIN=vpn

# WireGuard 配置 - 使用自動偵測
WIREGUARD_PEERS=auto
AUTO_PEER_FORMAT=username-hostname

# WireGuard 伺服器配置
SERVERURL=vpn.917420.xyz
SERVERPORT=51820
INTERNAL_SUBNET=10.13.13.0

# 安全配置
PUID=1000
PGID=1000
TZ=Asia/Taipei

# 可選配置
ALLOWEDIPS=0.0.0.0/0
LOG_CONFS=true
```

**單環境 .env 配置範例（傳統手動方式）**：
```bash
# Cloudflare DDNS 配置
CF_API_TOKEN=cf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
CF_ZONE=917420.xyz
CF_SUBDOMAIN=vpn

# WireGuard 配置 - 手動指定
WIREGUARD_PEERS=laptop,phone,tablet

# WireGuard 伺服器配置
SERVERURL=vpn.917420.xyz
SERVERPORT=51820
INTERNAL_SUBNET=10.13.13.0

# 安全配置
PUID=1000
PGID=1000
TZ=Asia/Taipei

# 可選配置
ALLOWEDIPS=0.0.0.0/0
LOG_CONFS=true
```

**多環境 .env 配置範例**（每個伺服器獨立配置）：

**亞洲伺服器 .env**：
```bash
CF_API_TOKEN=cf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
CF_ZONE=917420.xyz
CF_SUBDOMAIN=vpn-asia

# 自動偵測 + 額外客戶端
WIREGUARD_PEERS=auto,shared_tablet
AUTO_PEER_FORMAT=username-hostname

SERVERURL=vpn-asia.917420.xyz
SERVERPORT=51820
INTERNAL_SUBNET=10.13.13.0

PUID=1000
PGID=1000
TZ=Asia/Taipei
ALLOWEDIPS=0.0.0.0/0
LOG_CONFS=true
```

**美國伺服器 .env**：
```bash
CF_API_TOKEN=cf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
CF_ZONE=917420.xyz  
CF_SUBDOMAIN=vpn-us

WIREGUARD_PEERS=auto,work_laptop
AUTO_PEER_FORMAT=hostname-username

SERVERURL=vpn-us.917420.xyz
SERVERPORT=51820
INTERNAL_SUBNET=10.14.14.0  # 不同子網避免衝突

PUID=1000
PGID=1000
TZ=America/New_York
ALLOWEDIPS=0.0.0.0/0
LOG_CONFS=true
```

**歐洲伺服器 .env**：
```bash
CF_API_TOKEN=cf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
CF_ZONE=917420.xyz
CF_SUBDOMAIN=vpn-eu

WIREGUARD_PEERS=auto,family_devices
AUTO_PEER_FORMAT=username-hostname

SERVERURL=vpn-eu.917420.xyz
SERVERPORT=51820
INTERNAL_SUBNET=10.15.15.0  # 不同子網避免衝突

PUID=1000
PGID=1000
TZ=Europe/London
ALLOWEDIPS=0.0.0.0/0
LOG_CONFS=true
```

#### **4.4 🔧 使用自動環境設定功能**

```bash
# 使用新的 setup 指令來處理自動偵測
./scripts/manage.sh setup

# 預期輸出：
# 🔧 設定環境變數...
# ✅ 已設定客戶端: john-laptop,work_tablet
# 🤖 自動偵測裝置: john-laptop
#    - 使用者: john
#    - 主機名: laptop
#    - 格式: username-hostname

# 檢查生成的配置
cat .env | grep WIREGUARD_PEERS
# 輸出：WIREGUARD_PEERS=john-laptop,work_tablet
```

#### **4.5 驗證 .env 配置**

```bash
# 檢查 .env 文件語法
./scripts/validate.sh

# 檢查環境變數載入
source .env
echo "CF_API_TOKEN: ${CF_API_TOKEN:0:10}..."  # 只顯示前 10 字符
echo "CF_ZONE: $CF_ZONE"
echo "CF_SUBDOMAIN: $CF_SUBDOMAIN"
echo "SERVERURL: $SERVERURL"
echo "WIREGUARD_PEERS: $WIREGUARD_PEERS"

# 測試 Docker Compose 配置
docker compose config

# 測試自動偵測功能
echo "🤖 當前自動偵測結果："
echo "使用者: $(whoami)"
echo "主機名: $(hostname | cut -d'.' -f1)"
echo "格式: ${AUTO_PEER_FORMAT:-username-hostname}"
```

#### **4.6 環境變數安全檢查**

```bash
# 確保 .env 文件權限正確
chmod 600 .env
ls -la .env
# 預期輸出：-rw------- 1 user user ... .env

# 確保 .env 不會被提交到 Git
git status
# .env 應該不在 staged files 中（被 .gitignore 忽略）

# 驗證 .gitignore 設定
grep "^\.env$" .gitignore
# 預期輸出：.env
```

#### **4.7 🎯 自動偵測功能優勢**

✅ **自動化優勢**：
- 無需手動思考客戶端名稱
- 避免重複或衝突的命名
- 自動適應不同使用者和裝置
- 支援混合模式，靈活性更高

✅ **個人化體驗**：
- 每個使用者都有獨特的客戶端名稱
- 便於識別不同裝置的連線狀態
- QR Code 文件路徑更有意義

✅ **維護便利**：
- 減少配置錯誤
- 便於多用戶環境管理
- 保持向後相容性

---

### 💻 步驟五：GitHub Variables 和 Secrets 配置

> 🎯 **執行位置**：🌐 GitHub 網頁界面操作

#### **5.1 前往 GitHub 專案設定**

1. **開啟 GitHub 專案頁面**：
   ```
   https://github.com/rich7420/QWV
   ```

2. **進入設定頁面**：
   ```
   點擊 "Settings" 選項卡（在專案頁面頂部）
   ```

3. **進入 Actions 配置**：
   ```
   左側選單 → "Secrets and variables" → "Actions"
   ```

---

## 🔐 GitHub Actions 配置對照表

### 📋 配置分類說明

| 配置類型 | 用途 | 安全性 | 儲存位置 |
|---------|------|--------|----------|
| **🔓 Variables** | 公開配置（域名等） | 非敏感 | GitHub Actions Variables |
| **🔒 Secrets** | 敏感信息（SSH金鑰、API權杖） | 加密儲存 | GitHub Actions Secrets |
| **📁 .env** | 伺服器本地環境變數 | 本地檔案 | GCP 伺服器 |

---

#### **5.2 🔓 配置 Variables（公開配置）**

> 🌐 **操作位置**：GitHub → Settings → Secrets and variables → Actions → **Variables 頁籤**

**單環境 Variables 配置**：

| Variable 名稱 | 值來源 | 範例值 | 說明 |
|--------------|--------|--------|------|
| `VPN_DOMAIN` | 步驟 2.5 | `vpn.917420.xyz` | VPN 服務的完整域名 |

**多環境 Variables 配置**：

| Variable 名稱 | 值來源 | 範例值 | 說明 |
|--------------|--------|--------|------|
| `VPN_DOMAIN_ASIA` | 步驟 2.5 | `vpn-asia.917420.xyz` | 亞洲區域 VPN 域名 |
| `VPN_DOMAIN_US` | 步驟 2.5 | `vpn-us.917420.xyz` | 美國區域 VPN 域名 |
| `VPN_DOMAIN_EU` | 步驟 2.5 | `vpn-eu.917420.xyz` | 歐洲區域 VPN 域名 |

---

#### **5.3 🔒 配置 Secrets（敏感信息）**

> 🌐 **操作位置**：GitHub → Settings → Secrets and variables → Actions → **Secrets 頁籤**

**單環境 Secrets 配置**：

| Secret 名稱 | 值來源 | 範例值 | 說明 | 🚨 注意事項 |
|------------|--------|--------|------|------------|
| `VPN_HOST` | 步驟 1.3 | `203.0.113.1` | GCP 伺服器的外部 IP 地址 | ⚠️ 使用真實 IP，不是內網 IP |
| `VPN_USER` | 步驟 1.3 | `ubuntu` | SSH 登入用戶名 | 🔑 通常是 ubuntu 或 您的用戶名 |
| `VPN_SSH_KEY` | 步驟 3.5 | `-----BEGIN OPENSSH...` | SSH 私鑰完整內容 | 🔒 必須包含 BEGIN/END 行 |
| `VPN_PORT` | 步驟 1.3 | `22` | SSH 連接埠 | ⚪ 可選，預設 22 |
| `CF_API_TOKEN` | 步驟 2.5 | `cf_xxxxxxxxxxxxx` | Cloudflare API 權杖 | 🌐 必須有 DNS:Edit 權限 |

**多環境 Secrets 配置**：

**🌏 亞洲環境**：
| Secret 名稱 | 值來源 | 範例值 | 說明 |
|------------|--------|--------|------|
| `VPN_HOST_ASIA` | 步驟 1.3 | `ASIA_SERVER_IP` | 亞洲伺服器 IP |
| `VPN_USER_ASIA` | 步驟 1.3 | `ubuntu` | 亞洲伺服器用戶名 |
| `VPN_SSH_KEY_ASIA` | 步驟 3.5 | `-----BEGIN OPENSSH...` | 亞洲伺服器 SSH 私鑰 |
| `VPN_PORT_ASIA` | 步驟 1.3 | `22` | 亞洲伺服器 SSH 埠 |
| `CF_API_TOKEN_ASIA` | 步驟 2.5 | `cf_xxxxxxxxxxxxx` | 亞洲環境 CF 權杖 |

**🇺🇸 美國環境**：
| Secret 名稱 | 值來源 | 範例值 | 說明 |
|------------|--------|--------|------|
| `VPN_HOST_US` | 步驟 1.3 | `US_SERVER_IP` | 美國伺服器 IP |
| `VPN_USER_US` | 步驟 1.3 | `ubuntu` | 美國伺服器用戶名 |
| `VPN_SSH_KEY_US` | 步驟 3.5 | `-----BEGIN OPENSSH...` | 美國伺服器 SSH 私鑰 |
| `VPN_PORT_US` | 步驟 1.3 | `22` | 美國伺服器 SSH 埠 |
| `CF_API_TOKEN_US` | 步驟 2.5 | `cf_xxxxxxxxxxxxx` | 美國環境 CF 權杖 |

**🇪🇺 歐洲環境**：
| Secret 名稱 | 值來源 | 範例值 | 說明 |
|------------|--------|--------|------|
| `VPN_HOST_EU` | 步驟 1.3 | `EU_SERVER_IP` | 歐洲伺服器 IP |
| `VPN_USER_EU` | 步驟 1.3 | `ubuntu` | 歐洲伺服器用戶名 |
| `VPN_SSH_KEY_EU` | 步驟 3.5 | `-----BEGIN OPENSSH...` | 歐洲伺服器 SSH 私鑰 |
| `VPN_PORT_EU` | 步驟 1.3 | `22` | 歐洲伺服器 SSH 埠 |
| `CF_API_TOKEN_EU` | 步驟 2.5 | `cf_xxxxxxxxxxxxx` | 歐洲環境 CF 權杖 |

#### **5.4 配置檢查清單**

**✅ 配置完成檢查**：

**Variables 檢查**：
- [ ] 單環境：VPN_DOMAIN 已設定
- [ ] 多環境：VPN_DOMAIN_ASIA, VPN_DOMAIN_US, VPN_DOMAIN_EU 已設定
- [ ] 域名格式正確（如：vpn.917420.xyz）

**Secrets 檢查**：
- [ ] 所有 VPN_HOST_* 使用正確的伺服器 IP 地址
- [ ] 所有 VPN_USER_* 使用正確的用戶名（通常是 ubuntu）
- [ ] 所有 VPN_SSH_KEY_* 包含完整的私鑰（含 BEGIN/END 行）
- [ ] 所有 CF_API_TOKEN_* 使用有效的 Cloudflare API 權杖
- [ ] 可選：VPN_PORT_* 設定正確的 SSH 連接埠

#### **5.5 配置驗證測試**

```bash
# 本地驗證所有 SSH 連線
# 單環境測試
ssh -i ~/.ssh/qwv_github_key ubuntu@YOUR_SERVER_IP "echo 'Single environment OK'"

# 多環境測試  
ssh -i ~/.ssh/qwv_github_key ubuntu@ASIA_SERVER_IP "echo 'Asia environment OK'"
ssh -i ~/.ssh/qwv_github_key ubuntu@US_SERVER_IP "echo 'US environment OK'"
ssh -i ~/.ssh/qwv_github_key ubuntu@EU_SERVER_IP "echo 'EU environment OK'"

# 驗證 Cloudflare API 權杖
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_CF_API_TOKEN" \
     -H "Content-Type: application/json"
```

---

## 🚀 部署測試

### 1️⃣ 觸發 GitHub Actions 部署

#### **步驟 1.1：推送代碼觸發自動部署**

```bash
# 確保在專案根目錄
cd QWV

# 提交小變更觸發部署
echo "# 部署測試 $(date)" >> README.md
git add README.md  
git commit -m "test: trigger GitHub Actions deployment"
git push origin main
```

#### **步驟 1.2：監控部署過程**

1. **前往 GitHub Actions 頁面**：
   ```
   https://github.com/rich7420/QWV/actions
   ```

2. **查看最新的工作流程執行**：
   - 點擊最新的 "Multi-Environment QWV VPN Deployment" 工作流程
   - 觀察每個步驟的執行狀態

3. **部署模式檢查**：
   - 查看 "Detect Deployment Mode" 步驟
   - 確認檢測到正確的部署模式（single 或 multi）

#### **步驟 1.3：手動選擇部署環境**

**如果您配置了多環境但想選擇性部署**：

1. **前往 Actions 頁面**
2. **點擊 "Multi-Environment QWV VPN Deployment"**
3. **點擊 "Run workflow" 按鈕**
4. **選擇部署目標**：
   - `auto`: 自動檢測（預設）
   - `single`: 強制單環境模式
   - `asia`: 只部署亞洲環境
   - `us`: 只部署美國環境
   - `eu`: 只部署歐洲環境
   - `all`: 部署所有多環境

---

### 2️⃣ 驗證部署結果

#### **步驟 2.1：檢查服務狀態**

```bash
# SSH 到伺服器檢查服務
ssh ubuntu@YOUR_SERVER_IP

# 進入專案目錄
cd QWV

# 檢查服務狀態
./scripts/manage.sh status

# 預期輸出：
# 🔍 服務狀態：
# ✅ wireguard: Up 2 minutes
# ✅ cloudflare-ddns: Up 2 minutes
```

#### **步驟 2.2：檢查 DNS 解析**

```bash
# 檢查 DNS 記錄更新
nslookup vpn.917420.xyz
# 預期輸出：應解析到伺服器 IP

# 多環境檢查
nslookup vpn-asia.917420.xyz
nslookup vpn-us.917420.xyz  
nslookup vpn-eu.917420.xyz

# 使用 dig 檢查 TTL
dig vpn.917420.xyz
```

#### **步驟 2.3：生成客戶端配置**

```bash
# 🤖 如果使用自動偵測，首先查看偵測到的客戶端名稱
./scripts/manage.sh setup
# 輸出：✅ 已設定客戶端: john-laptop,shared_tablet

# 或查看現有配置
cat .env | grep WIREGUARD_PEERS
# 輸出：WIREGUARD_PEERS=john-laptop,shared_tablet

# 生成自動偵測的客戶端 QR Code
./scripts/manage.sh qr john-laptop

# 📱 如果使用傳統命名，生成傳統客戶端配置
./scripts/manage.sh qr phone
./scripts/manage.sh qr laptop

# 檢查配置文件
ls -la config/
# 預期輸出：peer_john-laptop/ 或 peer_phone/, peer_laptop/

# 查看配置內容
cat config/peer_john-laptop/peer_john-laptop.conf  # 自動偵測的客戶端
# 或
cat config/peer_phone/peer_phone.conf  # 傳統命名的客戶端
```

---

## 📱 客戶端連線測試

### 3️⃣ 手機客戶端設定

#### **步驟 3.1：安裝 WireGuard 應用**

- **Android**: [Google Play Store](https://play.google.com/store/apps/details?id=com.wireguard.android)
- **iOS**: [App Store](https://apps.apple.com/app/wireguard/id1441195209)

#### **步驟 3.2：導入配置**

1. **開啟 WireGuard 應用**
2. **點擊 "+" 按鈕**
3. **選擇 "從 QR 碼建立"**
4. **掃描伺服器生成的 QR Code**
5. **為隧道命名**（如：917420 VPN - Asia）
6. **點擊 "建立隧道"**

#### **步驟 3.3：測試連線**

```bash
# 在手機上連線前，檢查原始 IP
# 使用瀏覽器訪問：https://ipinfo.io

# 啟動 VPN 連線

# 再次檢查 IP，應該顯示伺服器 IP
# 訪問：https://ipinfo.io
```

---

### 4️⃣ 桌面客戶端設定

#### **步驟 4.1：下載配置文件**

```bash
# 從伺服器下載配置文件
scp ubuntu@YOUR_SERVER_IP:~/QWV/config/peer_laptop/peer_laptop.conf ~/wireguard-917420.conf

# 檢查配置文件內容
cat ~/wireguard-917420.conf
```

#### **步驟 4.2：安裝 WireGuard 客戶端**

- **Windows**: [官方下載](https://www.wireguard.com/install/)
- **macOS**: [Mac App Store](https://apps.apple.com/app/wireguard/id1451685025) 或 Homebrew：`brew install wireguard-tools`
- **Linux**: `sudo apt install wireguard` (Ubuntu/Debian)

#### **步驟 4.3：導入配置並測試**

1. **開啟 WireGuard 客戶端**
2. **點擊 "Import tunnel(s) from file"**
3. **選擇下載的 .conf 文件**
4. **啟動隧道**

**驗證連線**：
```bash
# 檢查 IP 變化
curl https://ipinfo.io/ip

# 測試 DNS 解析
nslookup google.com

# 測試網路連通性
ping -c 4 8.8.8.8

# 測試速度（可選）
speedtest-cli
```

---

### 📊 預期結果

**成功連線後應該看到**:
- ✅ 公網 IP 變更為伺服器 IP
- ✅ DNS 解析正常工作
- ✅ 網路連通性良好
- ✅ 瀏覽網站正常

**多環境模式額外驗證**:
- 🌏 客戶端可選擇連接不同區域的伺服器
- 🚀 地理位置最佳化 (亞洲用戶連接 vpn-asia.917420.xyz)
- 🛡️ 單一區域故障不影響其他區域

---

### 🆘 快速故障排除

| 問題 | 可能原因 | 解決方案 |
|------|----------|----------|
| GitHub Actions 失敗 | Variables/Secrets 配置錯誤 | 檢查配置完整性 |
| 無法 SSH 連線 | SSH 金鑰或 IP 錯誤 | 驗證 VPN_HOST 和 VPN_SSH_KEY |
| VPN 無法握手 | 防火牆或連接埠問題 | 確認 UDP 51820 已開放 |
| DNS 無法解析 | Cloudflare 配置問題 | 檢查 CF_API_TOKEN 權限 |
| 🤖 自動偵測失敗 | .env 配置或權限問題 | 執行 `./scripts/manage.sh setup` |
| 🤖 客戶端名稱衝突 | 自動偵測與手動名稱重複 | 調整 AUTO_PEER_FORMAT 或使用純模式 |
| 🤖 setup 指令無效 | 環境變數語法錯誤 | 檢查 .env 檔案格式和權限 |

---

## 📋 完整測試流程

本文檔提供完整的測試流程，幫助您驗證 QWV VPN 專案的所有功能。包含自動化驗證、手動測試和故障排除。

## 📋 測試前檢查清單

### 🌍 部署架構選擇

在開始測試前，先選擇適合的部署架構：

#### 🔧 單環境部署（推薦新手）
- 部署一個 VPN 伺服器
- 適合個人或小團隊使用
- 成本較低，設定簡單

#### 🌍 多環境部署（企業級）
- 部署多個區域的 VPN 伺服器（Asia/US/EU）
- 提供地理分佈和冗餘
- 需要更多伺服器和 GitHub Secrets 設定

> 📖 **多環境詳細指南**: [MULTI-ENVIRONMENT.md](MULTI-ENVIRONMENT.md)

### 基本需求檢查

#### 單環境部署需求

- [ ] 擁有一台 Linux 伺服器（Ubuntu 20.04+ 或 Debian 11+）
- [ ] 伺服器具有公網 IP 位址或已設定 DDNS
- [ ] 擁有域名管理權限（建議使用 Cloudflare）
- [ ] 路由器管理權限（用於連接埠轉送）
- [ ] 測試用的客戶端裝置（手機、筆電等）

#### 多環境部署需求

- [ ] 多台 Linux 伺服器（分佈在不同地區）
- [ ] 每台伺服器具有公網 IP 位址
- [ ] 域名管理權限，支援多子域名（vpn-asia、vpn-us、vpn-eu）
- [ ] 每個環境的 SSH 金鑰和 Cloudflare API 權杖
- [ ] GitHub Actions 環境變數和 Secrets 配置

## 🚀 快速驗證（推薦起點）

### 自動化專案驗證

```bash
# 克隆專案後的第一步：執行完整驗證
cd QWV-QuickWireguardVpn
./scripts/validate.sh

# 或使用管理腳本
./scripts/manage.sh validate

# 或使用測試腳本
./test-commands.sh validate
```

**預期輸出**：
- ✅ 檔案結構驗證通過
- ✅ Docker Compose 語法正確
- ✅ 腳本語法正確
- ✅ 環境變數模板有效
- ✅ GitHub Actions 工作流程正確
- ✅ 文檔完整性檢查通過
- ✅ 安全性檢查通過

## 🔧 階段一：環境準備與初始檢查

### 1.1 檢查伺服器基本資訊

```bash
# 登入您的測試伺服器
ssh user@your-server-ip

# 檢查作業系統版本
lsb_release -a
# 預期輸出：Ubuntu 20.04+ 或 Debian 11+

# 檢查網路連接
ping -c 4 8.8.8.8
# 預期輸出：4 packets transmitted, 4 received

# 檢查可用磁碟空間
df -h
# 預期輸出：至少 2GB 可用空間

# 檢查記憶體
free -h
# 預期輸出：至少 512MB 可用記憶體
```

### 1.2 CGNAT 檢測（關鍵步驟）

```bash
# 檢查伺服器的公網 IP
curl -s https://ipinfo.io/ip
# 記錄此 IP 位址

# 同時登入路由器管理介面
# 記錄路由器的 WAN IP 位址
# 比較兩者是否相同

echo "伺服器檢測到的公網 IP: $(curl -s https://ipinfo.io/ip)"
echo "路由器 WAN IP: [請手動填入]"
```

**⚠️ 重要判斷點**：
- 如果兩個 IP 相同 ✅ → 繼續測試
- 如果兩個 IP 不同 ❌ → 您處於 CGNAT 環境，需要 VPS 反向代理方案

### 1.3 克隆專案到伺服器

```bash
# 安裝 Git（如果尚未安裝）
sudo apt update
sudo apt install -y git

# 克隆專案
git clone https://github.com/yourusername/QWV-QuickWireguardVpn.git
cd QWV-QuickWireguardVpn

# 檢查專案結構
tree -a -I '.git'
# 預期輸出：包含所有必要檔案的目錄結構

# 檢查腳本權限
ls -la scripts/
# 預期輸出：setup.sh 和 manage.sh 應該有執行權限
```

## 🚀 階段二：自動化環境設定

### 2.1 執行初始化腳本

```bash
# 執行自動化設定腳本
./scripts/setup.sh

# 預期輸出應包含：
# ✅ 系統套件更新完成
# ✅ Docker 安裝完成
# ✅ 防火牆設定完成
# ✅ IP 轉送啟用
# ✅ 目錄結構建立完成
```

### 2.2 驗證安裝結果

```bash
# 使用自動化系統檢查
./scripts/manage.sh check
# 預期輸出：
# 🔍 系統檢查：
# 📁 專案檔案：
# ✅ docker-compose.yml 存在
# ✅ .env 存在
# 🐳 Docker 狀態：
# ✅ Docker 已安裝 (version 24.0+)
# ✅ Docker 服務運行中
# ✅ Docker 權限正常

# 或手動檢查各個組件
# 檢查 Docker 安裝
docker --version
# 預期輸出：Docker version 24.0+

# 檢查 Docker Compose
docker compose version
# 預期輸出：Docker Compose version 2.20+

# 檢查防火牆狀態
sudo ufw status numbered
# 預期輸出：
# Status: active
# [1] 22/tcp                     ALLOW IN    Anywhere
# [2] 51820/udp                  ALLOW IN    Anywhere

# 檢查 IP 轉送
cat /proc/sys/net/ipv4/ip_forward
# 預期輸出：1

# 檢查 Docker 群組
groups $USER | grep docker
# 預期輸出：包含 docker
```

**⚠️ 如果 Docker 群組檢查失敗**：
```bash
# 登出並重新登入
exit
# 重新 SSH 連線
ssh user@your-server-ip
cd QWV-QuickWireguardVpn
```

### 2.3 執行完整專案驗證

```bash
# 執行綜合驗證腳本
./scripts/validate.sh

# 如果發現問題，查看詳細錯誤
echo $?  # 0 表示成功，1 表示有問題

# 使用測試腳本進行分階段驗證
./test-commands.sh 3-verify
```

## 🌐 階段三：Cloudflare 設定與驗證

### 3.1 建立 Cloudflare API 權杖

1. 登入 [Cloudflare 儀表板](https://dash.cloudflare.com)
2. 右上角頭像 → 「我的設定檔」 → 「API 權杖」
3. 「建立權杖」 → 「編輯區域 DNS」
4. 設定權限：
   ```
   權限：Zone:DNS:Edit
   區域資源：Include - Specific zone - yourdomain.com
   
   權限：Zone:Zone:Read  
   區域資源：Include - Specific zone - yourdomain.com
   ```
5. 複製權杖並記錄

### 3.2 測試 API 權杖

```bash
# 測試 API 權杖有效性
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_API_TOKEN_HERE" \
     -H "Content-Type:application/json"

# 預期輸出：
# {
#   "success": true,
#   "result": {
#     "id": "...",
#     "status": "active"
#   }
# }
```

### 3.3 設定環境變數

```bash
# 複製環境變數範本
cp env.example .env

# 編輯環境變數
nano .env

# 填入以下內容：
CF_API_TOKEN=your_actual_cloudflare_token
CF_ZONE=yourdomain.com
CF_SUBDOMAIN=vpn
```

### 3.4 驗證 Docker Compose 設定

```bash
# 檢查 Docker Compose 語法
docker compose config

# 預期輸出：應該顯示完整的服務配置，無語法錯誤
# 如果有環境變數警告，表示 .env 檔案設定正確
```

## 🔧 階段四：路由器連接埠轉送設定

### 4.1 設定連接埠轉送

1. 登入路由器管理介面（通常是 192.168.1.1 或 192.168.0.1）
2. 尋找「連接埠轉送」、「虛擬伺服器」或「Port Forwarding」
3. 新增規則：
   ```
   服務名稱: WireGuard
   協定: UDP
   外部連接埠: 51820
   內部 IP: [您的伺服器內網 IP，例如 192.168.1.100]
   內部連接埠: 51820
   狀態: 啟用
   ```

### 4.2 驗證內網 IP

```bash
# 在伺服器上檢查內網 IP
ip addr show | grep "inet " | grep -v "127.0.0.1"
# 記錄 192.168.x.x 或 10.x.x.x 的 IP 位址
```

## 🚀 階段五：VPN 服務部署與測試

### 5.1 啟動 VPN 服務

```bash
# 檢查管理腳本功能
./scripts/manage.sh
# 預期輸出：顯示所有可用指令

# 執行系統檢查
./scripts/manage.sh check
# 預期輸出：
# ✅ Docker 已安裝
# ✅ UFW 防火牆已安裝
# ✅ IP 轉送已啟用

# 啟動 VPN 服務
./scripts/manage.sh start
# 預期輸出：
# 🚀 啟動 VPN 服務...
# ✅ 服務已啟動
```

### 5.2 檢查服務狀態

```bash
# 查看服務狀態
./scripts/manage.sh status
# 預期輸出：所有容器都應該是 "Up" 狀態

# 查看詳細日誌
./scripts/manage.sh logs | head -50
# 預期輸出：
# - WireGuard 伺服器成功啟動
# - 為每個 PEER 生成了設定檔
# - DDNS 客戶端開始工作

# 檢查容器是否正在運行
docker ps
# 預期輸出：wireguard 和 cloudflare-ddns 容器都在運行
```

### 5.3 驗證 WireGuard 設定

```bash
# 檢查 WireGuard 介面
docker exec wireguard wg show
# 預期輸出：顯示 WireGuard 介面資訊

# 檢查生成的客戶端設定
ls -la config/
# 預期輸出：應該有 peer_laptop 和 peer_phone 目錄

# 檢查客戶端設定檔內容
cat config/peer_laptop/peer_laptop.conf
# 預期輸出：完整的 WireGuard 客戶端設定
```

### 5.4 驗證 DDNS 功能

```bash
# 檢查 DDNS 日誌
docker logs cloudflare-ddns
# 預期輸出：DNS 記錄更新成功的訊息

# 測試 DNS 解析
nslookup vpn.yourdomain.com
# 預期輸出：應該解析到您伺服器的公網 IP

# 測試 dig 查詢
dig vpn.yourdomain.com
# 預期輸出：A 記錄指向正確的 IP
```

## 📱 階段六：客戶端連接測試

### 6.1 手機客戶端測試

```bash
# 生成手機客戶端 QR Code
./scripts/manage.sh qr phone
# 預期輸出：顯示 QR Code 檔案位置

# 如果伺服器支援，直接顯示 QR Code
cat config/peer_phone/peer_phone.conf | qrencode -t ansiutf8
```

**手機設定步驟**：
1. 下載 WireGuard 應用程式（Android/iOS）
2. 點擊「+」→「從 QR code 建立」
3. 掃描 QR Code
4. 為隧道命名（例如：「Home VPN」）
5. 點擊「建立隧道」

### 6.2 桌面客戶端測試

```bash
# 查看筆電客戶端設定
./scripts/manage.sh qr laptop
# 記錄設定檔路徑

# 將設定檔複製到本機（在本機執行）
scp user@your-server:/path/to/config/peer_laptop/peer_laptop.conf ~/wireguard-home.conf
```

**桌面設定步驟**：
1. 下載 WireGuard 客戶端
2. 「從檔案匯入隧道」
3. 選擇下載的 .conf 檔案

### 6.3 連接測試

**在客戶端裝置上執行**：

```bash
# 連接 VPN 前檢查 IP
curl https://ipinfo.io/ip
# 記錄原始 IP

# 啟動 VPN 連接
# （在 WireGuard 應用中點擊開關）

# 等待 10 秒後檢查新 IP
curl https://ipinfo.io/ip
# 應該顯示伺服器的公網 IP

# 測試 DNS 解析
nslookup google.com
# 應該正常解析

# 測試網路連通性
ping -c 4 8.8.8.8
# 應該正常回應
```

## 🔍 階段七：詳細功能驗證

### 7.1 握手狀態檢查

```bash
# 在伺服器上檢查客戶端連接
./scripts/manage.sh peers
# 預期輸出：應該顯示已連接的客戶端和握手時間

# 詳細檢查
docker exec wireguard wg show all
# 預期輸出：
# interface: wg0
#   public key: ...
#   private key: (hidden)
#   listening port: 51820
#
# peer: [客戶端公鑰]
#   endpoint: [客戶端IP]:port
#   allowed ips: 10.13.13.x/32
#   latest handshake: X seconds ago
#   transfer: X.XX KiB received, X.XX KiB sent
```

### 7.2 網路流量測試

**在客戶端執行**：

```bash
# 測試下載速度
wget -O /dev/null https://speed.cloudflare.com/__down?bytes=100000000
# 記錄速度

# 測試延遲
ping -c 10 8.8.8.8
# 記錄平均延遲

# 測試不同網站的存取
curl -I https://www.google.com
curl -I https://www.github.com
curl -I https://www.youtube.com
# 應該都能正常返回 HTTP 200
```

### 7.3 內網存取測試（如果需要）

```bash
# 如果設定為存取內網，測試內網連接
ping 192.168.1.1  # 路由器 IP
ping 192.168.1.x  # 其他內網裝置

# 測試內網服務（如果有）
curl http://192.168.1.x:port
```

## 🛠️ 階段八：管理功能測試

### 8.1 測試備份功能

```bash
# 執行備份
./scripts/manage.sh backup
# 預期輸出：✅ 備份完成: backup/wireguard_backup_YYYYMMDD_HHMMSS.tar.gz

# 檢查備份檔案
ls -la backup/
# 應該看到新建立的備份檔案

# 驗證備份內容
tar -tzf backup/wireguard_backup_*.tar.gz | head -10
# 應該包含 config/ 目錄的內容
```

### 8.2 測試服務重啟

```bash
# 重啟服務
./scripts/manage.sh restart
# 預期輸出：
# 🛑 停止 VPN 服務...
# ✅ 服務已停止
# 🚀 啟動 VPN 服務...
# ✅ 服務已啟動

# 驗證客戶端重新連接
# 在客戶端應該能自動重新連接
```

### 8.3 測試更新功能

```bash
# 測試映像檔更新
./scripts/manage.sh update
# 預期輸出：
# 📦 更新服務映像檔...
# 🔄 重啟 VPN 服務...
# ✅ 更新完成
```

## 🆕 階段九：新增客戶端測試

### 9.1 新增客戶端（自動偵測模式）

```bash
# 🤖 方法一：使用混合模式在 .env 中添加新客戶端
nano .env

# 修改 WIREGUARD_PEERS 行，添加新的手動指定客戶端
WIREGUARD_PEERS=auto,tablet,work_computer,guest_phone

# 重新設定環境並重啟服務
./scripts/manage.sh setup
./scripts/manage.sh restart

# 檢查新客戶端設定
ls config/
# 應該看到：peer_john-laptop/ (自動偵測), peer_tablet/, peer_work_computer/, peer_guest_phone/

# 生成新客戶端 QR Code
./scripts/manage.sh qr tablet
./scripts/manage.sh qr work_computer
```

### 9.2 新增客戶端（傳統模式）

```bash
# 📝 方法二：傳統手動模式（不使用自動偵測）
nano .env

# 修改 WIREGUARD_PEERS 行
WIREGUARD_PEERS=laptop,phone,tablet,work_computer

# 重啟服務
./scripts/manage.sh restart

# 檢查新客戶端設定
ls config/
# 應該看到新的 peer_tablet 和 peer_work_computer 目錄

# 生成新客戶端 QR Code
./scripts/manage.sh qr tablet
```

### 9.2 驗證多客戶端同時連接

```bash
# 讓多個客戶端同時連接 VPN
# 然後檢查伺服器狀態
./scripts/manage.sh peers

# 預期輸出：應該顯示多個已連接的客戶端
# 每個客戶端都應該有最近的握手時間
```

## 🤖 階段十：GitHub Actions 自動部署測試

### 10.1 設定 GitHub Actions

```bash
# 1. 推送專案到 GitHub（如果尚未完成）
git remote add origin https://github.com/yourusername/QWV-QuickWireguardVpn.git
git push -u origin main
```

#### 10.1.1 配置 GitHub Variables 和 Secrets

**QWV 使用分離式配置管理**：
- **Variables (公開配置)**: 域名、區域等非敏感信息
- **Secrets (加密配置)**: SSH 金鑰、API Token 等敏感信息

**配置步驟**：
1. 前往您的 GitHub 專案頁面
2. 點擊 **Settings** 選項卡
3. 在左側選單中選擇 **Secrets and variables** → **Actions**

**單環境配置 (Legacy 相容)**：

**Variables 頁籤 (公開配置)**：
| Variable 名稱 | 說明 | 範例值 | 必要性 |
|--------------|------|--------|--------|
| `VPN_DOMAIN` | 完整 VPN 域名 | `vpn.917420.xyz` | ✅ 必要 |

**Secrets 頁籤 (敏感信息)**：
| Secret 名稱 | 說明 | 範例值 | 必要性 |
|------------|------|--------|--------|
| `VPN_HOST` | VPN 伺服器的 IP 地址 | `203.0.113.1` | ✅ 必要 |
| `VPN_USER` | 登入伺服器的用戶名 | `ubuntu` 或 `user` | ✅ 必要 |
| `VPN_SSH_KEY` | SSH 私鑰內容（完整文件） | `-----BEGIN OPENSSH PRIVATE KEY-----\n...` | ✅ 必要 |
| `VPN_PORT` | SSH 連接埠（如果不是預設的 22） | `2222` 或 `22` | ⚪ 可選 |
| `CF_API_TOKEN` | Cloudflare API 權杖 | `cf_token_here...` | ✅ 必要 |

**多環境配置 (DNS 服務路由)**：

**Variables 頁籤 (DNS 路由配置)**：
| Variable 名稱 | 說明 | 範例值 | 用途 |
|--------------|------|--------|------|
| `VPN_DOMAIN_ASIA` | 亞洲 VPN 服務域名 | `vpn-asia.917420.xyz` | 🌏 亞洲路由 |
| `VPN_DOMAIN_US` | 美國 VPN 服務域名 | `vpn-us.917420.xyz` | 🇺🇸 美國路由 |
| `VPN_DOMAIN_EU` | 歐洲 VPN 服務域名 | `vpn-eu.917420.xyz` | 🇪🇺 歐洲路由 |

#### 10.1.2 SSH 私鑰準備步驟

**在您的本機電腦上**：

```bash
# 1. 生成 SSH 金鑰對（如果尚未有）
ssh-keygen -t ed25519 -C "github-actions@yourdomain.com" -f ~/.ssh/github_actions_key

# 2. 複製私鑰內容（用於 GitHub Secret）
cat ~/.ssh/github_actions_key
# ⚠️ 複製完整輸出（包含 BEGIN 和 END 行）

# 3. 複製公鑰到伺服器
ssh-copy-id -i ~/.ssh/github_actions_key.pub user@your-server-ip

# 或手動添加公鑰
cat ~/.ssh/github_actions_key.pub
# 將輸出複製到伺服器的 ~/.ssh/authorized_keys
```

**在 VPN 伺服器上驗證**：

```bash
# 測試新金鑰是否可以登入
ssh -i ~/.ssh/github_actions_key user@your-server-ip

# 確認公鑰已正確安裝
cat ~/.ssh/authorized_keys | grep "github-actions"
# 應該看到您剛才添加的公鑰
```

#### 10.1.3 設定 Secrets 的詳細步驟

**VPN_HOST 設定**：
```
名稱: VPN_HOST
值: 203.0.113.1
（或您的伺服器域名，如 vpn.yourdomain.com）
```

**VPN_USER 設定**：
```
名稱: VPN_USER
值: ubuntu
（或您在伺服器上使用的用戶名）
```

**VPN_SSH_KEY 設定**：
```
名稱: VPN_SSH_KEY
值: -----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtz
c2gtZWQyNTUxOQAAACBQxXKp3gN+foooo3gN+foooo3gN+foooo3gN+foooo...
（完整的私鑰內容，包含所有換行符號）
-----END OPENSSH PRIVATE KEY-----
```

**VPN_PORT 設定**（如果 SSH 不是預設連接埠 22）：
```
名稱: VPN_PORT
值: 2222
（您的 SSH 連接埠號碼）
```

#### 10.1.4 安全性注意事項

⚠️ **重要安全提醒**：

1. **私鑰安全**：
   - 絕對不要將私鑰提交到程式碼庫
   - 使用專用的部署金鑰，不要使用個人 SSH 金鑰
   - 定期輪換 SSH 金鑰

2. **最小權限原則**：
   ```bash
   # 在伺服器上建立專用的部署用戶（建議）
   sudo adduser github-deploy
   sudo usermod -aG docker github-deploy
   
   # 設定 sudo 權限（僅允許必要的指令）
   echo "github-deploy ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart docker" | sudo tee /etc/sudoers.d/github-deploy
   ```

3. **金鑰權限設定**：
   ```bash
   # 在伺服器上確保正確的權限
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

#### 10.1.5 驗證 Secrets 設定

```bash
# 本地測試 SSH 連線（使用與 GitHub Actions 相同的金鑰）
ssh -i ~/.ssh/github_actions_key user@your-server-ip "docker --version"
# 預期輸出：Docker version 24.0+

# 測試 Docker 權限
ssh -i ~/.ssh/github_actions_key user@your-server-ip "docker ps"
# 預期輸出：容器列表（可能為空）

# 測試專案路徑存取
ssh -i ~/.ssh/github_actions_key user@your-server-ip "ls -la ~/QWV-QuickWireguardVpn/"
# 預期輸出：專案檔案列表
```

### 10.2 測試自動部署工作流程

```bash
# 1. 本地測試驗證腳本
./scripts/validate.sh
# 確保本地驗證通過

# 2. 提交小變更觸發部署
echo "# 測試部署 $(date)" >> README.md
git add README.md
git commit -m "test: 觸發 GitHub Actions 部署測試"
git push origin main

# 3. 監控 GitHub Actions 執行狀態
# 前往 GitHub → Actions 頁籤查看執行結果
```

### 10.3 驗證自動部署結果

```bash
# 在伺服器上檢查部署結果
./scripts/manage.sh status
# 預期輸出：服務應該正常運行

# 檢查最新的提交是否已部署
git log --oneline -5
# 應該顯示最新的提交

# 檢查服務更新時間
docker ps --format "table {{.Names}}\t{{.Status}}"
# 檢查容器的啟動時間
```

### 10.4 部署控制選項測試

#### 10.4.1 測試自動檢測功能

```bash
# 測試單環境檢測
# 只設定原始 Secrets (VPN_HOST, VPN_USER, etc.)
# 推送程式碼並檢查 GitHub Actions 日誌
# 預期：自動檢測為 "single" 模式

# 測試多環境檢測
# 添加至少一個多環境 Secret (如 VPN_HOST_ASIA)
# 推送程式碼並檢查 GitHub Actions 日誌
# 預期：自動檢測為 "multi" 模式
```

#### 10.4.2 測試手動選擇部署

```bash
# 透過 GitHub Actions UI 測試
# 1. 前往 GitHub → Actions → Multi-Environment QWV VPN Deployment
# 2. 點擊 "Run workflow"
# 3. 測試各種選項：

# auto: 自動檢測模式
# single: 強制單環境模式（即使有多環境 Secrets）
# asia: 只部署到亞洲環境
# us: 只部署到美國環境  
# eu: 只部署到歐洲環境
# all: 部署到所有多環境
```

#### 10.4.3 測試向後相容性

```bash
# 階段 1：測試原有用戶升級路徑
# 保持原有 Secrets 設定，確認仍可正常部署

# 階段 2：添加多環境 Secrets
# 逐步添加多環境 Secrets，測試自動切換

# 階段 3：測試強制單環境模式
# 即使有多環境 Secrets，仍可選擇 single 模式
```

### 10.5 GitHub Actions 故障排除

```bash
# 如果 GitHub Actions 失敗，檢查常見問題：

# 1. SSH 連線問題
ssh -i ~/.ssh/your_key user@host  # 測試本地連線

# 2. 權限問題
ls -la ~/.ssh/  # 檢查金鑰權限
groups $USER | grep docker  # 檢查 Docker 群組

# 3. 環境變數問題
cat .env  # 檢查環境變數設定

# 4. 服務狀態問題
./scripts/manage.sh check  # 檢查系統狀態

# 5. 部署模式檢測問題
# 檢查 GitHub Actions 日誌中的 "Detect Deployment Mode" 步驟
# 確認檢測結果是否符合預期
```

## 🔧 階段十一：故障測試與排除

### 11.1 模擬常見問題

#### 測試防火牆阻擋

```bash
# 臨時關閉 UFW 以模擬防火牆問題
sudo ufw disable

# 在客戶端嘗試連接（應該失敗）
# 預期結果：無法建立握手

# 重新啟用防火牆
sudo ufw enable

# 確認連接恢復正常
```

#### 測試 DNS 問題

```bash
# 修改客戶端設定中的 DNS
# 將 DNS 設為無效位址（如 192.168.999.999）
# 測試是否只能 ping IP 但無法解析域名
```

### 11.2 日誌分析測試

```bash
# 查看錯誤日誌
./scripts/manage.sh logs | grep -i error

# 查看 DDNS 相關日誌
docker logs cloudflare-ddns | tail -20

# 檢查系統資源使用
docker stats --no-stream
```

## 🧪 階段十二：效能與壓力測試

### 12.1 速度測試

```bash
# 在客戶端執行速度測試
# 記錄 VPN 連接前後的速度差異

# 不使用 VPN 的速度
speedtest-cli

# 使用 VPN 的速度
# （啟動 VPN 連接後）
speedtest-cli

# 計算速度損失百分比
```

### 12.2 延遲測試

```bash
# 測試到不同地區的延遲
ping -c 10 8.8.8.8          # Google DNS
ping -c 10 1.1.1.1          # Cloudflare DNS
ping -c 10 208.67.222.222   # OpenDNS

# 記錄 VPN 連接前後的延遲變化
```

### 12.3 長時間穩定性測試

```bash
# 啟動長時間 ping 測試
ping -i 30 8.8.8.8 > ping_test.log &

# 讓測試運行數小時，然後檢查結果
tail -f ping_test.log

# 檢查是否有連接中斷
grep "Destination Host Unreachable" ping_test.log
```

## 📊 測試結果記錄表

請在測試過程中填寫此表格：

### 🛠️ 配置獲取步驟驗證

#### **步驟一：伺服器信息收集**
- [ ] GCP 虛擬機創建：`[ ] 完成` `[ ] 跳過（已有）`
  - [ ] 外部 IP 獲取：`_________________`
  - [ ] 防火牆規則設定：`[ ] 完成` UDP 51820 開放：`[ ] 確認`
- [ ] SSH 連線測試：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 伺服器基本信息檢查：`[ ] 通過` 
  - [ ] OS 版本：`_________________`
  - [ ] 可用記憶體：`_________________`
  - [ ] 可用磁碟：`_________________`

#### **步驟二：Cloudflare API 權杖獲取**
- [ ] Cloudflare 帳號登入：`[ ] 完成`
- [ ] API 權杖創建：`[ ] 完成` 權杖名稱：`_________________`
- [ ] 權限配置：`[ ] 完成`
  - [ ] DNS:Edit 權限：`[ ] 設定` 
  - [ ] Zone:Read 權限：`[ ] 設定`
  - [ ] Zone Settings:Read 權限：`[ ] 設定` (可選)
- [ ] API 權杖測試：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] Zone ID 獲取：`[ ] 完成` Zone ID：`_________________`

#### **步驟三：SSH 金鑰生成與部署**
- [ ] SSH 金鑰生成：`[ ] 完成` 金鑰類型：`ed25519` `[ ] rsa`
- [ ] 私鑰內容獲取：`[ ] 完成` 格式檢查：`[ ] 包含 BEGIN/END 行`
- [ ] 公鑰部署到伺服器：`[ ] 完成` `[ ] 失敗` 錯誤：`_________`
  - [ ] 單環境部署：`[ ] 完成` IP：`_________________`
  - [ ] 多環境部署：
    - [ ] 亞洲伺服器：`[ ] 完成` IP：`_________________`
    - [ ] 美國伺服器：`[ ] 完成` IP：`_________________`
    - [ ] 歐洲伺服器：`[ ] 完成` IP：`_________________`
- [ ] SSH 金鑰驗證：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] Docker 權限測試：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

#### **步驟四：.env 環境變數配置**
- [ ] .env 文件創建：`[ ] 完成` 來源：`env.example`
- [ ] 配置值填寫：`[ ] 完成`
  - [ ] CF_API_TOKEN：`[ ] 填入` 格式：`cf_xxxxxxx...`
  - [ ] CF_ZONE：`[ ] 填入` 值：`_________________`
  - [ ] CF_SUBDOMAIN：`[ ] 填入` 值：`_________________`
  - [ ] SERVERURL：`[ ] 填入` 值：`_________________`
  - [ ] PEERS：`[ ] 填入` 值：`_________________`
- [ ] .env 配置驗證：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] Docker Compose 配置測試：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 文件權限設定：`[ ] 完成` 權限：`600` `[ ] 確認`
- [ ] Git 忽略檢查：`[ ] 確認` .env 不在 Git 追蹤中：`[ ] 是`

#### **步驟五：GitHub Variables 和 Secrets 配置**

**Variables 配置驗證**：
- [ ] GitHub 專案設定訪問：`[ ] 完成`
- [ ] Variables 頁籤配置：`[ ] 完成`
  - [ ] 單環境：VPN_DOMAIN：`[ ] 設定` 值：`_________________`
  - [ ] 多環境：
    - [ ] VPN_DOMAIN_ASIA：`[ ] 設定` 值：`_________________`
    - [ ] VPN_DOMAIN_US：`[ ] 設定` 值：`_________________`  
    - [ ] VPN_DOMAIN_EU：`[ ] 設定` 值：`_________________`

**Secrets 配置驗證**：
- [ ] Secrets 頁籤配置：`[ ] 完成`
- [ ] 單環境 Secrets：`[ ] 完成`
  - [ ] VPN_HOST：`[ ] 設定` 來源：`步驟 1.3`
  - [ ] VPN_USER：`[ ] 設定` 來源：`步驟 1.3`
  - [ ] VPN_SSH_KEY：`[ ] 設定` 來源：`步驟 3.5` 格式：`[ ] 完整私鑰`
  - [ ] VPN_PORT：`[ ] 設定` `[ ] 使用預設` 值：`_________`
  - [ ] CF_API_TOKEN：`[ ] 設定` 來源：`步驟 2.5`
- [ ] 多環境 Secrets：`[ ] 完成` `[ ] 跳過`
  - [ ] 亞洲環境 Secrets：`[ ] 完成` (VPN_HOST_ASIA, VPN_USER_ASIA, etc.)
  - [ ] 美國環境 Secrets：`[ ] 完成` (VPN_HOST_US, VPN_USER_US, etc.)  
  - [ ] 歐洲環境 Secrets：`[ ] 完成` (VPN_HOST_EU, VPN_USER_EU, etc.)

**配置驗證測試**：
- [ ] 本地 SSH 連線測試：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] Cloudflare API 權杖驗證：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

### 📋 環境資訊
- [ ] 伺服器作業系統：`_________________`
- [ ] 伺服器規格：`_________________`
- [ ] 網路環境：`[ ] 無 CGNAT` `[ ] 有 CGNAT`
- [ ] 測試時間：`_________________`
- [ ] Docker 版本：`_________________`
- [ ] Docker Compose 版本：`_________________`

### 專案驗證結果
- [ ] 專案完整驗證：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 檔案結構檢查：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] Docker Compose 語法：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 腳本語法檢查：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 安全性檢查：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

### 功能測試結果
- [ ] 環境設定：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 服務啟動：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] DDNS 功能：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 客戶端連接：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 流量路由：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] DNS 解析：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

### GitHub Actions 測試

#### 自動檢測和向後相容性測試
- [ ] 部署模式自動檢測：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
  - [ ] 單環境 Variables 檢測：`[ ] 正確檢測` 模式：`_________`
  - [ ] 多環境 Variables 檢測：`[ ] 正確檢測` 模式：`_________`
  - [ ] Legacy Secrets 處理：`[ ] 正確處理` 優先級：`_________`
  - [ ] 混合配置處理：`[ ] 正確處理` 檢測結果：`_________`

#### 單環境部署測試（Legacy 相容性）
- [ ] GitHub Variables 配置：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
  - [ ] VPN_DOMAIN 設定：`[ ] 完成` 值：`_________`
- [ ] GitHub Secrets 配置：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
  - [ ] VPN_HOST 設定：`[ ] 完成` 值：`_________`
  - [ ] VPN_USER 設定：`[ ] 完成` 值：`_________`
  - [ ] VPN_SSH_KEY 設定：`[ ] 完成` 格式：`[ ] 正確`
  - [ ] VPN_PORT 設定：`[ ] 完成` `[ ] 使用預設` 值：`_________`
  - [ ] VPN_DEPLOY_PATH 設定：`[ ] 完成` `[ ] 使用預設` 值：`_________`
  - [ ] CF_API_TOKEN 設定：`[ ] 完成` 格式：`[ ] 正確`
- [ ] Legacy Secrets 支援：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
  - [ ] CF_ZONE (棄用) 設定：`[ ] 檢測到` `[ ] 向下相容` 值：`_________`
  - [ ] CF_SUBDOMAIN (棄用) 設定：`[ ] 檢測到` `[ ] 向下相容` 值：`_________`
- [ ] SSH 金鑰驗證：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 工作流程觸發：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] SSH 連線測試：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 自動部署：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 服務健康檢查：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 向後相容性驗證：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

#### 多環境部署測試

**DNS 服務路由配置測試**
- [ ] 多環境 Variables 配置：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
  - [ ] VPN_DOMAIN_ASIA：`[ ] 完成` 值：`_________`
  - [ ] VPN_DOMAIN_US：`[ ] 完成` 值：`_________`
  - [ ] VPN_DOMAIN_EU：`[ ] 完成` 值：`_________`

**🌏 Asia 環境**
- [ ] 亞洲環境 Secrets 配置：`[ ] 通過` `[ ] 失敗`
  - [ ] VPN_HOST_ASIA：`[ ] 完成` 值：`_________`
  - [ ] VPN_USER_ASIA：`[ ] 完成` 值：`_________`
  - [ ] VPN_SSH_KEY_ASIA：`[ ] 完成` 格式：`[ ] 正確`
  - [ ] CF_API_TOKEN_ASIA：`[ ] 完成` 格式：`[ ] 正確`
  - [ ] VPN_DEPLOY_PATH_ASIA：`[ ] 完成` `[ ] 使用預設` 值：`_________`
- [ ] 亞洲 DNS 路由測試：`[ ] 通過` `[ ] 失敗` 域名：`_________`
- [ ] 亞洲伺服器部署：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 亞洲服務健康檢查：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

**🇺🇸 US 環境**
- [ ] 美國環境 Secrets 配置：`[ ] 通過` `[ ] 失敗`
  - [ ] VPN_HOST_US：`[ ] 完成` 值：`_________`
  - [ ] VPN_USER_US：`[ ] 完成` 值：`_________`
  - [ ] VPN_SSH_KEY_US：`[ ] 完成` 格式：`[ ] 正確`
  - [ ] CF_API_TOKEN_US：`[ ] 完成` 格式：`[ ] 正確`
  - [ ] VPN_DEPLOY_PATH_US：`[ ] 完成` `[ ] 使用預設` 值：`_________`
- [ ] 美國 DNS 路由測試：`[ ] 通過` `[ ] 失敗` 域名：`_________`
- [ ] 美國伺服器部署：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 美國服務健康檢查：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

**🇪🇺 EU 環境**
- [ ] 歐洲環境 Secrets 配置：`[ ] 通過` `[ ] 失敗`
  - [ ] VPN_HOST_EU：`[ ] 完成` 值：`_________`
  - [ ] VPN_USER_EU：`[ ] 完成` 值：`_________`
  - [ ] VPN_SSH_KEY_EU：`[ ] 完成` 格式：`[ ] 正確`
  - [ ] CF_API_TOKEN_EU：`[ ] 完成` 格式：`[ ] 正確`
  - [ ] VPN_DEPLOY_PATH_EU：`[ ] 完成` `[ ] 使用預設` 值：`_________`
- [ ] 歐洲 DNS 路由測試：`[ ] 通過` `[ ] 失敗` 域名：`_________`
- [ ] 歐洲伺服器部署：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 歐洲服務健康檢查：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

**多環境整合測試**
- [ ] 矩陣部署測試：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 選擇性部署測試：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 部署摘要生成：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 失敗恢復機制：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

**部署控制選項測試**
- [ ] `auto` 模式：`[ ] 通過` `[ ] 失敗` 檢測結果：`_________`
- [ ] `single` 強制模式：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] `asia` 單區域部署：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] `us` 單區域部署：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] `eu` 單區域部署：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] `all` 全區域部署：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

**向後相容性整合測試**
- [ ] 從單環境升級到多環境：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 混合 Secrets 環境處理：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] Legacy 用戶平滑升級：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

### 效能測試結果
- 不使用 VPN 速度：`下載 _____ Mbps，上傳 _____ Mbps`
- 使用 VPN 速度：`下載 _____ Mbps，上傳 _____ Mbps`
- 平均延遲增加：`_____ ms`
- 速度損失：`_____ %`

### 管理功能測試
- [ ] 驗證功能（validate）：`[ ] 通過` `[ ] 失敗`
- [ ] 系統檢查（check）：`[ ] 通過` `[ ] 失敗`
- [ ] 備份功能：`[ ] 通過` `[ ] 失敗`
- [ ] 重啟功能：`[ ] 通過` `[ ] 失敗`
- [ ] 新增客戶端：`[ ] 通過` `[ ] 失敗`
- [ ] 日誌查看：`[ ] 通過` `[ ] 失敗`
- [ ] 同儕檢視（peers）：`[ ] 通過` `[ ] 失敗`

## 🚨 常見測試問題與解決方案

### 🔧 配置獲取階段問題

#### 問題 1：GCP 伺服器 IP 獲取失敗
```bash
# 症狀：gcloud 指令無法獲取外部 IP
# 原因：未安裝 gcloud CLI 或未登入
# 解決：
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
tar -xf google-cloud-cli-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# 手動獲取 IP（替代方案）：
# 登入 GCP Console → Compute Engine → VM instances → External IP 欄位
```

#### 問題 2：Cloudflare API 權杖權限不足
```bash
# 症狀：API 權杖測試返回 "insufficient_scope" 錯誤
# 解決：重新創建權杖，確保包含所有必要權限
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json"

# 檢查權限是否包含：
# - Zone:DNS:Edit
# - Zone:Zone:Read
# - Zone:Zone Settings:Read (可選)
```

#### 問題 3：SSH 金鑰格式錯誤
```bash
# 症狀：GitHub Actions 中 SSH 連線失敗，顯示 "invalid format"
# 解決：確保私鑰格式正確
echo "檢查私鑰是否包含完整的 BEGIN 和 END 行："
cat ~/.ssh/qwv_github_key | head -1  # 應顯示 -----BEGIN OPENSSH PRIVATE KEY-----
cat ~/.ssh/qwv_github_key | tail -1  # 應顯示 -----END OPENSSH PRIVATE KEY-----

# 重新生成金鑰（如果格式有問題）：
ssh-keygen -t ed25519 -C "github-actions@917420.xyz" -f ~/.ssh/qwv_github_key_new
```

#### 問題 4：SSH 公鑰部署失敗
```bash
# 症狀：ssh-copy-id 失敗或 SSH 連線被拒絕
# 解決步驟：

# 1. 確認伺服器 SSH 服務運行
ssh ubuntu@YOUR_SERVER_IP "sudo systemctl status ssh"

# 2. 手動添加公鑰
cat ~/.ssh/qwv_github_key.pub
# 複製輸出，然後在伺服器上執行：
ssh ubuntu@YOUR_SERVER_IP
mkdir -p ~/.ssh
echo "PASTE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 3. 測試連線
ssh -i ~/.ssh/qwv_github_key ubuntu@YOUR_SERVER_IP "echo 'Test successful'"
```

#### 問題 5：.env 文件配置錯誤
```bash
# 症狀：Docker Compose 啟動失敗或 DDNS 不工作
# 解決：逐項檢查環境變數

# 檢查 .env 文件語法
cat .env | grep -v '^#' | grep -v '^$'  # 顯示所有非註釋行

# 常見錯誤：
# - CF_API_TOKEN 格式錯誤（應以 cf_ 開頭）
# - CF_ZONE 包含不正確的域名
# - SERVERURL 與實際域名不符
# - PEERS 列表格式錯誤（應用逗號分隔）

# 驗證 Cloudflare 連線：
source .env
curl -X GET "https://api.cloudflare.com/client/v4/zones?name=$CF_ZONE" \
     -H "Authorization: Bearer $CF_API_TOKEN" \
     -H "Content-Type: application/json"
```

#### 問題 6：GitHub Secrets 配置檢測失敗
```bash
# 症狀：GitHub Actions 無法檢測到正確的部署模式
# 解決：

# 1. 檢查 Variables 和 Secrets 的命名是否正確
# Variables 應為：VPN_DOMAIN, VPN_DOMAIN_ASIA, VPN_DOMAIN_US, VPN_DOMAIN_EU
# Secrets 應為：VPN_HOST, VPN_USER, VPN_SSH_KEY, CF_API_TOKEN (單環境)
#             VPN_HOST_ASIA, VPN_USER_ASIA, VPN_SSH_KEY_ASIA, CF_API_TOKEN_ASIA (多環境)

# 2. 確認 VPN_SSH_KEY 包含完整私鑰內容
# 正確格式：
# -----BEGIN OPENSSH PRIVATE KEY-----
# [私鑰內容]
# -----END OPENSSH PRIVATE KEY-----

# 3. 測試 GitHub Actions 手動觸發
# 前往 GitHub → Actions → Run workflow → 選擇 "auto" 模式
```

#### 問題 7：配置分離搞混
```bash
# 症狀：不確定某個配置要放在哪裡
# 解決方案：

# 🔐 GitHub Secrets (敏感信息，用於自動部署)
VPN_HOST=203.0.113.1          # 伺服器 IP，GitHub Actions 用來 SSH 連線
VPN_USER=ubuntu               # SSH 用戶名，GitHub Actions 用來登入
VPN_SSH_KEY=-----BEGIN...     # SSH 私鑰，GitHub Actions 用來認證
CF_API_TOKEN=cf_xxxx          # Cloudflare API，GitHub Actions 用來更新 DNS

# 🔓 GitHub Variables (公開配置，用於自動部署)
VPN_DOMAIN=vpn.917420.xyz     # VPN 域名，GitHub Actions 知道要部署的域名

# 📁 .env 檔案 (伺服器本地，用於 Docker 容器)
CF_API_TOKEN=cf_xxxx          # 同一個 API 權杖，Docker 容器用來 DDNS 更新
CF_ZONE=917420.xyz            # 域名，Docker 容器知道要更新哪個域名
CF_SUBDOMAIN=vpn              # 子域名，Docker 容器知道要更新哪個子域名
SERVERURL=vpn.917420.xyz      # VPN 服務域名，WireGuard 配置用
PEERS=laptop,phone            # 客戶端列表，WireGuard 生成配置用

# 📝 記憶口訣：
# - GitHub = 自動部署用
# - .env = 服務運行用
# - 敏感信息 → Secrets
# - 域名配置 → Variables
```

#### 問題 8：多環境配置重複
```bash
# 症狀：多環境配置很多重複的值
# 解決方案：

# ✅ 推薦：共用相同的 API 權杖
CF_API_TOKEN=cf_xxxx          # 三個環境都使用相同權杖

# ❌ 不建議：為每個環境創建不同權杖
CF_API_TOKEN_ASIA=cf_xxxx1    # 除非有特殊安全需求
CF_API_TOKEN_US=cf_xxxx2
CF_API_TOKEN_EU=cf_xxxx3

# 🔑 SSH 金鑰建議：
# ✅ 簡單方式：共用同一個金鑰
VPN_SSH_KEY=same_key_content

# ✅ 安全方式：每環境獨立金鑰
VPN_SSH_KEY_ASIA=asia_key_content
VPN_SSH_KEY_US=us_key_content  
VPN_SSH_KEY_EU=eu_key_content
```

---

### 🐛 部署階段問題

#### 問題 7：專案驗證失敗
```bash
# 症狀：./scripts/validate.sh 回報錯誤
# 解決步驟：
./scripts/validate.sh  # 查看詳細錯誤
# 常見問題：
# - 缺少 .env 檔案：cp env.example .env
# - 權限問題：chmod +x scripts/*.sh
# - shellcheck 未安裝：sudo apt install shellcheck
```

### 問題 2：Docker 權限問題
```bash
# 症狀：Got permission denied while trying to connect to the Docker daemon
# 解決：
sudo usermod -aG docker $USER
# 然後登出重新登入
# 使用系統檢查確認：
./scripts/manage.sh check
```

### 問題 3：無法建立握手
```bash
# 使用系統檢查診斷問題
./scripts/manage.sh check
# 檢查防火牆狀態
sudo ufw status
# 檢查連接埠轉送設定
# 檢查 CGNAT 狀態
```

### 問題 4：DNS 無法解析
```bash
# 檢查客戶端 DNS 設定
# 測試直接 IP 連接
ping 8.8.8.8
# 使用驗證腳本檢查組態
./scripts/validate.sh
```

### 問題 5：DDNS 更新失敗
```bash
# 檢查 API 權杖有效性
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_TOKEN"
# 檢查環境變數設定
./scripts/validate.sh
# 檢查網路連接
```

### 問題 6：GitHub Actions 部署失敗

#### 6.1 部署模式檢測問題
```bash
# 症狀：部署模式檢測不正確
# 解決步驟：

# 檢查 Secrets 設定
# 前往 GitHub → Settings → Secrets and variables → Actions
# 確認以下設定：

# 單環境模式：只應有 VPN_HOST, VPN_USER, VPN_SSH_KEY 等基本 Secrets
# 多環境模式：應有 VPN_HOST_ASIA, VPN_HOST_US, VPN_HOST_EU 等多環境 Secrets

# 檢查 GitHub Actions 日誌
# 查看 "Detect Deployment Mode" 步驟的輸出
# 確認檢測邏輯是否正確執行
```

#### 6.2 環境矩陣部署問題
```bash
# 症狀：某些環境部署失敗，其他成功
# 解決步驟：

# 檢查失敗環境的特定 Secrets
# 每個環境都需要獨立的 Secrets 設定

# 測試特定環境的 SSH 連線
ssh -i ~/.ssh/specific_env_key user@specific_host "echo 'Test connection'"

# 檢查 fail-fast 設定
# 確保矩陣策略中 fail-fast: false 正確設定
```

#### 6.3 GitHub Secrets 配置問題
```bash
# 檢查 Secrets 是否正確設定
# 常見錯誤和解決方案：

# 錯誤 1：VPN_SSH_KEY 格式不正確
# 症狀：SSH 連線失敗，顯示 "invalid format" 或 "bad permissions"
# 解決：確保私鑰包含完整的 BEGIN 和 END 行
cat ~/.ssh/github_actions_key | pbcopy  # macOS
cat ~/.ssh/github_actions_key | xclip -selection clipboard  # Linux

# 錯誤 2：VPN_HOST 無法連接
# 症狀：連線超時或主機無法到達
# 解決：確認伺服器 IP 或域名正確
ping $VPN_HOST  # 本地測試連通性
nslookup $VPN_HOST  # 如果使用域名

# 錯誤 3：VPN_USER 權限不足
# 症狀：SSH 連線成功但 Docker 指令失敗
# 解決：確認用戶在 docker 群組中
ssh user@host "groups \$USER | grep docker"

# 錯誤 4：VPN_PORT 設定錯誤
# 症狀：SSH 連線被拒絕
# 解決：確認 SSH 連接埠設定
ssh -p $VPN_PORT user@host "echo 'Connection successful'"

# 錯誤 5：多環境配置不完整
# 症狀：某些環境檢測到但無法部署
# 解決：確保每個環境都有完整的配置
# Variables: VPN_DOMAIN_* (asia/us/eu)
# Secrets: VPN_HOST_*, VPN_USER_*, VPN_SSH_KEY_*, CF_API_TOKEN_*

# 錯誤 6：Variables 和 Secrets 分離問題
# 症狀：配置檢測失敗或域名解析問題
# 解決：檢查 Variables 和 Secrets 的正確分離
# Variables 頁籤：VPN_DOMAIN 相關配置
# Secrets 頁籤：敏感信息（SSH key, API token 等）
```

#### 6.2 SSH 金鑰問題診斷
```bash
# 本地測試 SSH 連線（模擬 GitHub Actions 環境）
ssh -i ~/.ssh/github_actions_key -o StrictHostKeyChecking=no user@your-server-ip

# 檢查伺服器端的 SSH 設定
ssh user@host "cat ~/.ssh/authorized_keys | grep github-actions"

# 檢查金鑰權限
ssh user@host "ls -la ~/.ssh/"
# 預期：drwx------ .ssh/ 和 -rw------- authorized_keys

# 測試 Docker 權限
ssh -i ~/.ssh/github_actions_key user@host "docker ps"
# 預期：能夠執行 Docker 指令
```

#### 6.3 其他部署問題
```bash
# 檢查 GitHub Actions 狀態
# 在 GitHub Actions 頁面檢查錯誤日誌

# 本地測試部署腳本
./scripts/validate.sh

# 檢查伺服器的防火牆狀態
ssh user@host "sudo ufw status"

# 檢查磁碟空間
ssh user@host "df -h"
```

## ✅ 測試完成檢查

當所有測試階段完成後，確認以下項目：

- [ ] 所有服務容器正常運行
- [ ] 至少一個客戶端能成功連接
- [ ] 網路流量正確路由通過 VPN
- [ ] DNS 解析正常工作
- [ ] DDNS 自動更新功能正常
- [ ] 管理腳本所有功能正常
- [ ] 備份功能可以正常執行
- [ ] 效能損失在可接受範圍內（通常 <20%）

## 🎉 測試成功！

如果所有測試都通過，恭喜您已經成功部署了一個功能完整的個人 VPN 服務！

您現在可以：
- 安全地在公共 Wi-Fi 上瀏覽網路
- 遠端存取家庭網路資源
- 保護您的網路隱私和安全

## 📝 測試後續步驟

1. **定期維護**：每月執行一次完整測試
2. **監控服務**：設定監控告警
3. **更新管理**：定期更新 Docker 映像檔
4. **備份策略**：建立自動備份計畫
5. **安全審查**：定期檢查安全設定

---

**🔍 需要協助？**
如果在測試過程中遇到問題，請檢查：
1. 本文檔的故障排除章節
2. README.md 的故障排除指南
3. 規劃書.md 的詳細技術分析
4. 或提交 GitHub Issue 尋求協助

---

## 📊 最終配置總覽表

### 🔐 GitHub Actions Secrets（敏感信息）

| Secret 名稱 | 範例值 | 來源步驟 | 必要性 | 說明 |
|------------|--------|----------|--------|------|
| `VPN_HOST` | `203.0.113.1` | 步驟 1.3 | ✅ 必要 | GCP 伺服器外部 IP |
| `VPN_USER` | `ubuntu` | 步驟 1.3 | ✅ 必要 | SSH 登入用戶名 |
| `VPN_SSH_KEY` | `-----BEGIN OPENSSH...` | 步驟 3.5 | ✅ 必要 | SSH 私鑰完整內容 |
| `VPN_PORT` | `22` | 步驟 1.3 | ⚪ 可選 | SSH 連接埠（預設 22）|
| `CF_API_TOKEN` | `cf_xxxxxxxxxx` | 步驟 2.5 | ✅ 必要 | Cloudflare API 權杖 |

### 🔓 GitHub Actions Variables（公開配置）

| Variable 名稱 | 範例值 | 來源步驟 | 必要性 | 說明 |
|--------------|--------|----------|--------|------|
| `VPN_DOMAIN` | `vpn.917420.xyz` | 步驟 2.5 | ✅ 必要 | VPN 服務完整域名 |

### 📁 .env 檔案（伺服器本地）

| 環境變數 | 範例值 | 來源步驟 | 必要性 | 說明 |
|---------|--------|----------|--------|------|
| `CF_API_TOKEN` | `cf_xxxxxxxxxx` | 步驟 2.5 | ✅ 必要 | Cloudflare API 權杖 |
| `CF_ZONE` | `917420.xyz` | 步驟 2.5 | ✅ 必要 | Cloudflare 域名 |
| `CF_SUBDOMAIN` | `vpn` | 步驟 2.5 | ✅ 必要 | VPN 子域名 |
| `SERVERURL` | `vpn.917420.xyz` | 步驟 2.5 | ✅ 必要 | WireGuard 伺服器域名 |
| `PEERS` | `laptop,phone,tablet` | 用戶定義 | ✅ 必要 | WireGuard 客戶端列表 |
| `SERVERPORT` | `51820` | 預設值 | ✅ 必要 | WireGuard 連接埠 |
| `INTERNAL_SUBNET` | `10.13.13.0` | 預設值 | ✅ 必要 | VPN 內網網段 |

### 💡 配置提醒

⚠️ **相同值但不同用途**：
- `CF_API_TOKEN` 同時存在於 GitHub Secrets 和 .env 檔案
- `SERVERURL` 和 `VPN_DOMAIN` 通常是相同的域名
- GitHub 配置用於自動部署，.env 配置用於服務運行

🔄 **配置同步**：
- 修改域名時，需要同時更新 GitHub Variables 和 .env 檔案
- 更換 API 權杖時，需要同時更新 GitHub Secrets 和 .env 檔案