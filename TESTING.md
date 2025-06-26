# 🧪 QWV VPN 詳細測試步驟

本文檔提供完整的測試流程，幫助您驗證 QWV VPN 專案的所有功能。

## 📋 測試前檢查清單

在開始測試前，請確認以下項目：

- [ ] 擁有一台 Linux 伺服器（Ubuntu 20.04+ 或 Debian 11+）
- [ ] 伺服器具有公網 IP 位址或已設定 DDNS
- [ ] 擁有域名管理權限（建議使用 Cloudflare）
- [ ] 路由器管理權限（用於連接埠轉送）
- [ ] 測試用的客戶端裝置（手機、筆電等）

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
# 檢查 Docker 安裝
docker --version
# 預期輸出：Docker version 20.10+

# 檢查 Docker Compose
docker compose version
# 預期輸出：Docker Compose version 2.0+

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

### 9.1 新增客戶端

```bash
# 編輯 docker-compose.yml
nano docker-compose.yml

# 修改 PEERS 行
- PEERS=laptop,phone,tablet,work_computer

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

## 🔧 階段十：故障測試與排除

### 10.1 模擬常見問題

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

### 10.2 日誌分析測試

```bash
# 查看錯誤日誌
./scripts/manage.sh logs | grep -i error

# 查看 DDNS 相關日誌
docker logs cloudflare-ddns | tail -20

# 檢查系統資源使用
docker stats --no-stream
```

## 🧪 階段十一：效能與壓力測試

### 11.1 速度測試

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

### 11.2 延遲測試

```bash
# 測試到不同地區的延遲
ping -c 10 8.8.8.8          # Google DNS
ping -c 10 1.1.1.1          # Cloudflare DNS
ping -c 10 208.67.222.222   # OpenDNS

# 記錄 VPN 連接前後的延遲變化
```

### 11.3 長時間穩定性測試

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

### 環境資訊
- [ ] 伺服器作業系統：`_________________`
- [ ] 伺服器規格：`_________________`
- [ ] 網路環境：`[ ] 無 CGNAT` `[ ] 有 CGNAT`
- [ ] 測試時間：`_________________`

### 功能測試結果
- [ ] 環境設定：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 服務啟動：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] DDNS 功能：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 客戶端連接：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] 流量路由：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`
- [ ] DNS 解析：`[ ] 通過` `[ ] 失敗` 錯誤：`_________`

### 效能測試結果
- 不使用 VPN 速度：`下載 _____ Mbps，上傳 _____ Mbps`
- 使用 VPN 速度：`下載 _____ Mbps，上傳 _____ Mbps`
- 平均延遲增加：`_____ ms`
- 速度損失：`_____ %`

### 管理功能測試
- [ ] 備份功能：`[ ] 通過` `[ ] 失敗`
- [ ] 重啟功能：`[ ] 通過` `[ ] 失敗`
- [ ] 新增客戶端：`[ ] 通過` `[ ] 失敗`
- [ ] 日誌查看：`[ ] 通過` `[ ] 失敗`

## 🚨 常見測試問題與解決方案

### 問題 1：Docker 權限問題
```bash
# 症狀：Got permission denied while trying to connect to the Docker daemon
# 解決：
sudo usermod -aG docker $USER
# 然後登出重新登入
```

### 問題 2：無法建立握手
```bash
# 檢查防火牆
sudo ufw status
# 檢查連接埠轉送
# 檢查 CGNAT 狀態
```

### 問題 3：DNS 無法解析
```bash
# 檢查客戶端 DNS 設定
# 測試直接 IP 連接
ping 8.8.8.8
```

### 問題 4：DDNS 更新失敗
```bash
# 檢查 API 權杖
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer YOUR_TOKEN"
# 檢查網路連接
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