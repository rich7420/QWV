#!/bin/bash

# QWV VPN 快速測試指令腳本
# 此腳本包含 TESTING.md 中的所有關鍵測試指令

echo "🧪 QWV VPN 快速測試指令"
echo "========================"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

test_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# 檢查是否有參數
if [ $# -eq 0 ]; then
    echo "使用方法："
    echo "  $0 <test_stage>"
    echo ""
    echo "可用的測試階段："
    echo "  1-env       - 環境檢查"
    echo "  2-setup     - 自動化設定"
    echo "  3-verify    - 驗證安裝"
    echo "  4-cloudflare - Cloudflare 測試"
    echo "  5-deploy    - 部署 VPN 服務"
    echo "  6-client    - 客戶端測試"
    echo "  7-function  - 功能驗證"
    echo "  8-manage    - 管理功能測試"
    echo "  9-github    - GitHub Actions 測試"
    echo "  10-troubleshoot - 故障排除"
    echo "  validate    - 執行專案完整驗證"
    echo "  all         - 執行所有自動化測試"
    echo ""
    exit 1
fi

case "$1" in
    "1-env")
        test_step "階段一：環境檢查"
        echo ""
        echo "1.1 檢查系統資訊："
        echo "lsb_release -a"
        echo "free -h"
        echo "df -h"
        echo ""
        echo "1.2 檢查網路："
        echo "ping -c 4 8.8.8.8"
        echo ""
        echo "1.3 CGNAT 檢測："
        echo "curl -s https://ipinfo.io/ip"
        echo "# 請同時檢查路由器 WAN IP 並比較"
        ;;
        
    "2-setup")
        test_step "階段二：執行自動化設定"
        echo ""
        echo "執行設定腳本："
        echo "./scripts/setup.sh"
        echo ""
        warning "設定完成後請登出並重新登入以使 Docker 群組生效！"
        ;;
        
    "3-verify")
        test_step "階段三：驗證安裝結果"
        echo ""
        echo "🔍 使用自動化系統檢查："
        ./scripts/manage.sh check
        echo ""
        echo "📋 或手動檢查各組件："
        echo "檢查 Docker："
        docker --version
        echo ""
        echo "檢查 Docker Compose："
        docker compose version
        echo ""
        echo "檢查防火牆："
        sudo ufw status numbered
        echo ""
        echo "檢查 IP 轉送："
        cat /proc/sys/net/ipv4/ip_forward
        echo ""
        echo "檢查 Docker 群組："
        groups $USER | grep docker && success "Docker 群組正常" || error "Docker 群組未設定，請重新登入"
        echo ""
        echo "🧪 執行完整專案驗證："
        ./scripts/validate.sh
        ;;
        
    "4-cloudflare")
        test_step "階段四：Cloudflare 設定測試"
        echo ""
        echo "1. 請先在 Cloudflare 建立 API 權杖"
        echo "2. 複製環境變數範本："
        echo "cp env.example .env"
        echo ""
        echo "3. 編輯 .env 檔案："
        echo "nano .env"
        echo ""
        echo "4. 測試 API 權杖（請替換 YOUR_TOKEN）："
        echo 'curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \'
        echo '     -H "Authorization: Bearer YOUR_TOKEN" \'
        echo '     -H "Content-Type:application/json"'
        echo ""
        echo "5. 驗證 Docker Compose 設定："
        echo "docker compose config"
        ;;
        
    "5-deploy")
        test_step "階段五：部署 VPN 服務"
        echo ""
        echo "系統檢查："
        ./scripts/manage.sh check
        echo ""
        echo "啟動服務："
        ./scripts/manage.sh start
        echo ""
        echo "檢查狀態："
        ./scripts/manage.sh status
        echo ""
        echo "查看日誌："
        echo "./scripts/manage.sh logs"
        ;;
        
    "6-client")
        test_step "階段六：客戶端設定"
        echo ""
        echo "生成手機 QR Code："
        ./scripts/manage.sh qr phone
        echo ""
        echo "生成筆電 QR Code："
        ./scripts/manage.sh qr laptop
        echo ""
        echo "客戶端連接測試指令："
        echo "# VPN 連接前："
        echo "curl https://ipinfo.io/ip"
        echo ""
        echo "# 啟動 VPN 連接後："
        echo "curl https://ipinfo.io/ip  # 應該顯示伺服器 IP"
        echo "nslookup google.com       # 測試 DNS"
        echo "ping -c 4 8.8.8.8        # 測試連通性"
        ;;
        
    "7-function")
        test_step "階段七：功能驗證"
        echo ""
        echo "檢查 WireGuard 連接："
        ./scripts/manage.sh peers
        echo ""
        echo "詳細連接狀態："
        docker exec wireguard wg show 2>/dev/null || echo "WireGuard 服務未運行"
        echo ""
        echo "檢查 DDNS 狀態："
        docker logs cloudflare-ddns --tail 10
        echo ""
        echo "測試 DNS 解析："
        if [ -f .env ]; then
            source .env
            echo "nslookup ${CF_SUBDOMAIN}.${CF_ZONE}"
        else
            echo "請先設定 .env 檔案"
        fi
        ;;
        
    "8-manage")
        test_step "階段八：管理功能測試"
        echo ""
        echo "🔧 驗證功能測試："
        ./scripts/manage.sh validate
        echo ""
        echo "📊 系統檢查測試："
        ./scripts/manage.sh check
        echo ""
        echo "💾 備份功能測試："
        ./scripts/manage.sh backup
        echo ""
        echo "檢查備份檔案："
        ls -la backup/
        echo ""
        echo "👥 同儕檢視測試："
        ./scripts/manage.sh peers
        echo ""
        echo "🔄 服務重啟測試："
        echo "./scripts/manage.sh restart"
        echo ""
        echo "📦 更新測試："
        echo "./scripts/manage.sh update"
        ;;
        
    "9-github")
        test_step "階段九：GitHub Actions 自動部署測試"
        echo ""
        echo "🧪 本地驗證測試："
        ./scripts/validate.sh
        echo ""
        echo "📋 GitHub Actions 設定指南："
        echo "1. 確保專案已推送到 GitHub"
        echo "2. 設定 GitHub Secrets (Settings → Secrets and variables → Actions)："
        echo "   - VPN_HOST: 伺服器 IP 或域名"
        echo "   - VPN_USER: SSH 使用者名稱"
        echo "   - VPN_SSH_KEY: SSH 私鑰內容"
        echo "   - VPN_PORT: SSH 連接埠 (可選，預設 22)"
        echo ""
        echo "3. 觸發部署測試："
        echo 'echo "# 測試部署 $(date)" >> README.md'
        echo "git add README.md"
        echo 'git commit -m "test: 觸發 GitHub Actions 部署測試"'
        echo "git push origin main"
        echo ""
        echo "4. 監控執行狀態："
        echo "前往 GitHub → Actions 頁籤查看執行結果"
        echo ""
        echo "5. 驗證部署結果："
        echo "部署完成後，在伺服器上執行："
        echo "./scripts/manage.sh status"
        ;;
        
    "10-troubleshoot")
        test_step "階段十：故障排除"
        echo ""
        echo "檢查容器狀態："
        docker ps
        echo ""
        echo "檢查錯誤日誌："
        ./scripts/manage.sh logs | grep -i error | tail -10
        echo ""
        echo "檢查網路連通性："
        echo "nc -u -v localhost 51820 </dev/null"
        echo ""
        echo "檢查防火牆規則："
        sudo ufw status numbered
        ;;
        
    "all")
        test_step "執行自動化測試"
        echo ""
        
        # 執行完整專案驗證
        echo "🧪 執行完整專案驗證..."
        if [ -f "scripts/validate.sh" ]; then
            chmod +x scripts/validate.sh
            ./scripts/validate.sh
            validation_result=$?
            if [ $validation_result -eq 0 ]; then
                success "專案驗證通過"
            else
                error "專案驗證失敗，請檢查錯誤訊息"
                echo "詳細檢查請執行: ./scripts/validate.sh"
            fi
        else
            warning "找不到 scripts/validate.sh，執行基本檢查..."
        fi
        
        echo ""
        
        # 檢查基本環境
        echo "🔍 檢查基本環境..."
        docker --version >/dev/null 2>&1 && success "Docker 已安裝" || error "Docker 未安裝"
        groups $USER | grep docker >/dev/null && success "Docker 群組設定正確" || error "Docker 群組未設定"
        
        # 檢查專案檔案
        echo ""
        echo "📁 檢查專案檔案..."
        [ -f docker-compose.yml ] && success "docker-compose.yml 存在" || error "docker-compose.yml 不存在"
        [ -f .env ] && success ".env 設定檔存在" || warning ".env 設定檔不存在，請設定環境變數"
        [ -x scripts/setup.sh ] && success "setup.sh 可執行" || error "setup.sh 無執行權限"
        [ -x scripts/manage.sh ] && success "manage.sh 可執行" || error "manage.sh 無執行權限"
        [ -x scripts/validate.sh ] && success "validate.sh 可執行" || error "validate.sh 無執行權限"
        
                 # 檢查 Docker Compose 語法
         echo ""
         echo "🔧 檢查 Docker Compose 語法..."
         docker compose config >/dev/null 2>&1 && success "Docker Compose V2 語法正確" || error "Docker Compose 語法錯誤"
        
        # 檢查服務狀態
        echo ""
        echo "🚀 檢查服務狀態..."
        if docker ps | grep -q wireguard; then
            success "WireGuard 服務運行中"
            ./scripts/manage.sh peers
        else
            warning "WireGuard 服務未運行"
            echo "啟動服務請執行: ./scripts/manage.sh start"
        fi
        
        # 檢查網路設定
        echo ""
        echo "🌐 檢查網路設定..."
        ip_forward=$(cat /proc/sys/net/ipv4/ip_forward)
        [ "$ip_forward" = "1" ] && success "IP 轉送已啟用" || error "IP 轉送未啟用"
        
        # 檢查防火牆
        echo ""
        echo "🔥 檢查防火牆設定..."
        if sudo ufw status | grep -q "51820/udp"; then
            success "WireGuard 連接埠已開放"
        else
            error "WireGuard 連接埠未開放"
        fi
        
        echo ""
        success "自動化測試完成！"
        echo ""
        echo "📋 後續手動測試項目："
        echo "1. 設定 Cloudflare API 權杖 (./test-commands.sh 4-cloudflare)"
        echo "2. 設定路由器連接埠轉送"
        echo "3. 部署 VPN 服務 (./test-commands.sh 5-deploy)"
        echo "4. 測試客戶端連接 (./test-commands.sh 6-client)"
        echo "5. 驗證功能正常 (./test-commands.sh 7-function)"
        echo "6. 測試管理功能 (./test-commands.sh 8-manage)"
        echo "7. 設定 GitHub Actions 自動部署 (./test-commands.sh 9-github)"
        echo ""
        echo "📚 詳細測試步驟請參考 TESTING.md"
        ;;
        
    "validate")
        test_step "執行專案完整驗證"
        echo ""
        if [ -f "scripts/validate.sh" ]; then
            echo "🔍 執行專案驗證腳本..."
            chmod +x scripts/validate.sh
            ./scripts/validate.sh
        else
            error "找不到驗證腳本: scripts/validate.sh"
            echo "請確保所有腳本檔案都存在"
        fi
        ;;
        
    *)
        error "未知的測試階段: $1"
        echo "請使用 $0 查看可用選項"
        exit 1
        ;;
esac

# 顯示測試完成狀態
if [ "$1" != "all" ] && [ "$1" != "validate" ]; then
    echo ""
    echo "📋 測試進度追蹤："
    echo "✅ 已完成：$1"
    echo "📚 完整測試流程請參考 TESTING.md"
    echo "🚀 或使用：./test-commands.sh all （執行自動化測試）"
fi

echo ""
echo "📖 詳細測試步驟請參考 TESTING.md" 