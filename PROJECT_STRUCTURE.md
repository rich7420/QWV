# 📁 QWV 專案結構說明

## 🗂️ 目錄結構

```
QWV/
├── 📁 backup/                  # 備份目錄
├── 📁 config/                  # WireGuard 配置檔案目錄（自動生成）
│   └── peer_**/               # 各客戶端配置目錄
│       ├── *.conf             # WireGuard 配置檔案
│       ├── *.png              # QR Code 圖片
│       └── .qr_expiry         # QR Code 過期時間戳
├── 📁 docs/                   # 說明文檔
│   ├── MULTI-ENVIRONMENT.md  # 多環境部署指南
│   └── TESTING.md            # 詳細測試指南
├── 📁 logs/                   # 日誌目錄
│   └── qr-cleanup.log        # QR Code 清理日誌
├── 📁 scripts/               # 管理腳本
│   ├── manage.sh             # 主要管理腳本
│   ├── setup.sh              # 環境設定腳本
│   ├── validate.sh           # 驗證腳本
│   ├── qr-cleanup.sh         # QR Code 自動清理腳本
│   └── setup-cron.sh         # Cron 任務設定腳本
├── 📁 tools/                 # 測試工具
│   └── test-commands.sh      # 測試指令腳本
├── 📄 docker-compose.yml     # Docker 服務編排檔案
├── 📄 .env                   # 環境變數檔案（不提交到 Git）
├── 📄 env.example            # 環境變數範本
├── 📄 README.md              # 主要說明文檔
├── 📄 PROJECT_STRUCTURE.md   # 專案結構說明（本檔案）
└── 📄 LICENSE                # 授權條款
```

## 🔧 核心檔案說明

### 📄 docker-compose.yml
- **用途**：定義 WireGuard 和 Cloudflare DDNS 服務
- **關鍵功能**：
  - 自動檢測用戶 ID (PUID/PGID) 解決檔案權限問題
  - 支援健康檢查
  - 網路和安全設定

### 📄 .env
- **用途**：存放敏感的環境變數
- **關鍵設定**：
  - Cloudflare API 權杖和域名設定
  - WireGuard 客戶端列表（支援自動偵測）
  - 系統配置（PUID/PGID 自動設定）

### 📄 scripts/manage.sh
- **用途**：專案主要管理介面
- **核心功能**：
  ```bash
  # 基本服務管理
  ./scripts/manage.sh start     # 啟動服務
  ./scripts/manage.sh status    # 查看狀態
  ./scripts/manage.sh logs      # 查看日誌
  
  # QR Code 時效性管理（預設3分鐘過期）
  ./scripts/manage.sh qr phone 5        # 生成5分鐘有效的 QR Code
  ./scripts/manage.sh qr-status         # 查看所有 QR Code 狀態
  ./scripts/manage.sh revoke-qr phone   # 立即撤銷 QR Code
  ./scripts/manage.sh cleanup-qr        # 清理過期 QR Code
  
  # 安全功能
  ./scripts/manage.sh web-qr phone 8080 # 啟動安全 Web QR Code 服務
  ./scripts/manage.sh security          # 安全性檢查
  ```

## 🔒 安全特性

### 📱 QR Code 時效性管理
- **預設過期時間**：3分鐘（提升安全性）
- **自動清理**：過期後自動移除配置檔案
- **狀態追蹤**：即時查看所有 QR Code 狀態
- **立即撤銷**：緊急情況下立即失效

### 🛡️ 檔案權限管理
- **自動檢測**：自動設定正確的 PUID/PGID
- **權限檢查**：`.env` 檔案自動設為 600 權限
- **安全掃描**：定期檢查敏感檔案權限

### 🌐 Web QR Code 安全服務
- **隨機 Token**：每次啟動生成隨機安全 Token
- **內網限制**：僅限內網訪問
- **臨時檔案**：服務關閉後自動清理

## 🤖 自動化功能

### 🕐 自動偵測裝置名稱
```bash
# .env 檔案中設定
WIREGUARD_PEERS=auto                    # 純自動模式
WIREGUARD_PEERS=auto,work_laptop        # 混合模式
AUTO_PEER_FORMAT=username-hostname      # 命名格式
```

### ⏰ 自動清理任務
```bash
# 設定自動清理 Cron 任務
./scripts/setup-cron.sh

# 選項：
# 1. 每5分鐘清理（推薦）
# 2. 每15分鐘清理  
# 3. 每小時清理
```

## 📊 監控和日誌

### 📝 日誌位置
```bash
logs/qr-cleanup.log          # QR Code 清理日誌
docker logs wireguard        # WireGuard 服務日誌
docker logs cloudflare-ddns  # DDNS 更新日誌
```

### 🔍 健康檢查
```bash
./scripts/manage.sh check     # 系統狀態檢查
./scripts/manage.sh security  # 安全性檢查
./scripts/manage.sh validate  # 完整專案驗證
```

## 🚀 快速開始

### 1️⃣ 初始設定
```bash
# 複製環境變數範本
cp env.example .env

# 編輯環境變數
nano .env

# 自動設定環境（包含 PUID/PGID 檢測）
./scripts/manage.sh setup
```

### 2️⃣ 啟動服務
```bash
# 啟動 VPN 服務
./scripts/manage.sh start

# 檢查服務狀態
./scripts/manage.sh status
```

### 3️⃣ 生成客戶端配置
```bash
# 生成3分鐘有效期的 QR Code（預設）
./scripts/manage.sh qr phone

# 生成10分鐘有效期的 QR Code
./scripts/manage.sh qr laptop 10

# 啟動安全 Web QR Code 服務
./scripts/manage.sh web-qr phone 8080
```

### 4️⃣ 設定自動清理
```bash
# 設定自動清理任務
./scripts/setup-cron.sh

# 選擇每5分鐘清理一次（推薦）
```

## 💡 最佳實踐

### 🔒 安全建議
1. **QR Code 時效性**：使用預設3分鐘過期時間
2. **立即撤銷**：掃描後立即撤銷不再需要的 QR Code
3. **定期檢查**：使用 `qr-status` 監控所有 QR Code 狀態
4. **自動清理**：設定 Cron 任務自動清理過期配置

### 📱 使用流程
1. **生成**：`./scripts/manage.sh qr device_name`
2. **分享**：`./scripts/manage.sh web-qr device_name`
3. **掃描**：客戶端掃描 QR Code
4. **撤銷**：`./scripts/manage.sh revoke-qr device_name`

### 🔧 維護流程
1. **定期備份**：`./scripts/manage.sh backup`
2. **安全檢查**：`./scripts/manage.sh security`
3. **系統更新**：`./scripts/manage.sh update`
4. **日誌清理**：自動輪轉，保留30天

## 🆘 故障排除

### 常見問題
1. **檔案權限問題**：腳本會自動檢測並設定正確的 PUID/PGID
2. **QR Code 過期**：使用 `qr-status` 檢查狀態，`cleanup-qr` 清理過期配置
3. **服務異常**：使用 `check` 指令診斷問題

### 完整驗證
```bash
./scripts/validate.sh        # 執行完整專案驗證
./scripts/manage.sh check    # 檢查系統狀態
./scripts/manage.sh security # 檢查安全設定
``` 