#!/bin/bash

# QWV - QuickWireguardVpn 管理腳本
# 提供 VPN 服務的啟動、停止、狀態檢查等功能

set -e  # 遇到錯誤時退出

# 自動偵測裝置信息並生成客戶端名稱
generate_auto_peer() {
    local format="${AUTO_PEER_FORMAT:-username-hostname}"
    local username=$(whoami)
    local hostname=$(hostname | cut -d'.' -f1)  # 只取第一部分，避免 FQDN
    
    case "$format" in
        "username")
            echo "$username"
            ;;
        "hostname")
            echo "$hostname"
            ;;
        "username-hostname")
            echo "${username}-${hostname}"
            ;;
        "hostname-username")
            echo "${hostname}-${username}"
            ;;
        *)
            echo "${username}-${hostname}"  # 預設格式
            ;;
    esac
}

# 處理 PEERS 配置，支援自動偵測
process_peers_config() {
    local peers_config="${WIREGUARD_PEERS:-auto}"
    local processed_peers=""
    
    # 載入環境變數
    if [ -f .env ]; then
        set -a  # 自動匯出所有變數
        source .env
        set +a
    fi
    
    # 分割逗號分隔的 peers
    IFS=',' read -ra PEER_ARRAY <<< "$peers_config"
    
    for peer in "${PEER_ARRAY[@]}"; do
        # 移除前後空格
        peer=$(echo "$peer" | xargs)
        
        if [ "$peer" = "auto" ]; then
            # 自動偵測當前裝置
            auto_peer=$(generate_auto_peer)
            if [ -n "$processed_peers" ]; then
                processed_peers="${processed_peers},${auto_peer}"
            else
                processed_peers="$auto_peer"
            fi
        else
            # 手動指定的名稱
            if [ -n "$processed_peers" ]; then
                processed_peers="${processed_peers},${peer}"
            else
                processed_peers="$peer"
            fi
        fi
    done
    
    echo "$processed_peers"
}

# 設定環境變數，包含自動偵測的 PEERS
setup_environment() {
    echo "🔧 設定環境變數..."
    
    # 檢查 .env 檔案
    if [ ! -f .env ]; then
        echo "❌ .env 檔案不存在，請先複製 env.example 並設定"
        echo "   cp env.example .env"
        echo "   nano .env"
        return 1
    fi
    
    # 處理 PEERS 配置
    processed_peers=$(process_peers_config)
    
    # 更新 .env 檔案中的 WIREGUARD_PEERS
    if [ -n "$processed_peers" ]; then
        # 備份原始 .env
        cp .env .env.backup
        
        # 更新或添加 WIREGUARD_PEERS
        if grep -q "^WIREGUARD_PEERS=" .env; then
            sed -i "s/^WIREGUARD_PEERS=.*/WIREGUARD_PEERS=$processed_peers/" .env
        else
            echo "WIREGUARD_PEERS=$processed_peers" >> .env
        fi
        
        echo "✅ 已設定客戶端: $processed_peers"
        
        # 如果包含自動偵測，顯示偵測結果
        if echo "$WIREGUARD_PEERS" | grep -q "auto"; then
            auto_peer=$(generate_auto_peer)
            echo "🤖 自動偵測裝置: $auto_peer"
            echo "   - 使用者: $(whoami)"
            echo "   - 主機名: $(hostname | cut -d'.' -f1)"
            echo "   - 格式: ${AUTO_PEER_FORMAT:-username-hostname}"
        fi
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

usage() {
    echo "🚀 QWV VPN 服務管理工具"
    echo ""
    echo "使用方法: $0 <command>"
    echo ""
    echo "可用指令:"
    echo "  setup        設定環境變數（支援自動偵測裝置名稱）"
    echo "  start        啟動 VPN 服務"
    echo "  stop         停止 VPN 服務"
    echo "  restart      重啟 VPN 服務"
    echo "  status       查看服務狀態"
    echo "  logs         查看服務日誌"
    echo "  peers        顯示連線的客戶端"
    echo "  update       更新服務映像檔"
    echo "  backup       備份設定檔"
    echo "  qr <peer>    顯示客戶端 QR Code"
    echo "  check        檢查系統狀態"
    echo "  validate     執行專案完整驗證"
    echo ""
    echo "🤖 自動偵測功能:"
    echo "  在 .env 中設定 WIREGUARD_PEERS=auto 可自動偵測當前裝置"
    echo "  支援格式: username, hostname, username-hostname, hostname-username"
    echo "  混合模式: WIREGUARD_PEERS=auto,work_laptop,family_tablet"
    echo ""
    echo "範例:"
    echo "  $0 setup           # 設定環境變數並自動偵測裝置"
    echo "  $0 start           # 啟動 VPN 服務"
    echo "  $0 qr john-laptop  # 顯示自動偵測的客戶端 QR Code"
    echo ""
}

check_env() {
    if [ ! -f ".env" ]; then
        echo "❌ 找不到 .env 檔案"
        echo "請複製 env.example 為 .env 並填入您的設定"
        exit 1
    fi
}

start_services() {
    echo "🚀 啟動 VPN 服務..."
    check_env
    docker compose up -d
    echo "✅ 服務已啟動"
}

stop_services() {
    echo "🛑 停止 VPN 服務..."
    docker compose down
    echo "✅ 服務已停止"
}

restart_services() {
    echo "🔄 重啟 VPN 服務..."
    stop_services
    start_services
}

show_status() {
    echo "📊 服務狀態:"
    if docker compose ps >/dev/null 2>&1; then
        docker compose ps
    else
        echo "❌ 無法取得 Docker Compose 狀態"
        exit 1
    fi
    
    echo ""
    echo "🌐 系統資源:"
    if docker stats --no-stream >/dev/null 2>&1; then
        docker stats --no-stream
    else
        echo "⚠️ 無法取得容器資源使用情況"
    fi
    
    echo ""
    echo "🔗 WireGuard 介面狀態:"
    if docker exec wireguard wg show >/dev/null 2>&1; then
        docker exec wireguard wg show
    else
        echo "⚠️ WireGuard 介面未啟動或無法存取"
    fi
}

show_logs() {
    echo "📋 服務日誌:"
    docker compose logs --tail=50 -f
}

show_peers() {
    echo "👥 已連線的客戶端:"
    
    # 檢查容器是否運行
    if ! docker compose ps wireguard | grep -q "Up"; then
        echo "❌ WireGuard 容器未運行"
        return 1
    fi
    
    # 檢查 WireGuard 介面
    peer_info=$(docker exec wireguard wg show 2>/dev/null || true)
    if [ -n "$peer_info" ]; then
        echo "$peer_info"
        
        # 統計連線數
        peer_count=$(echo "$peer_info" | grep -c "peer:" || echo "0")
        echo ""
        echo "📊 連線統計: $peer_count 個客戶端"
    else
        echo "⚠️ WireGuard 介面未啟動或無客戶端連線"
        echo ""
        echo "📋 可用的客戶端設定:"
        if [ -d "config" ]; then
            # 使用 glob 模式替代 ls | grep
            peer_found=false
            for dir in config/peer_*; do
                if [ -d "$dir" ]; then
                    peer_name=$(basename "$dir" | sed 's/peer_//')
                    echo "  - $peer_name"
                    peer_found=true
                fi
            done
            if [ "$peer_found" = false ]; then
                echo "  (無)"
            fi
        else
            echo "  (config 目錄不存在)"
        fi
    fi
}

update_services() {
    echo "📦 更新服務映像檔..."
    docker compose pull
    restart_services
    echo "✅ 更新完成"
}

backup_config() {
    timestamp=$(date +"%Y%m%d_%H%M%S")
    backup_file="backup/wireguard_backup_${timestamp}.tar.gz"
    
    echo "💾 備份設定檔..."
    mkdir -p backup
    tar -czf "$backup_file" config/
    echo "✅ 備份完成: $backup_file"
}

show_qr() {
    peer_name="$1"
    if [ -z "$peer_name" ]; then
        echo "❌ 請指定客戶端名稱"
        echo "例如: $0 qr laptop"
        return 1
    fi
    
    qr_file="config/peer_${peer_name}/peer_${peer_name}.png"
    if [ -f "$qr_file" ]; then
        echo "📱 客戶端 ${peer_name} 的 QR Code:"
        echo "檔案位置: $qr_file"
        # 如果系統支援，可以直接顯示 QR code
        if command -v qrencode >/dev/null 2>&1; then
            qrencode -t ansiutf8 < "config/peer_${peer_name}/peer_${peer_name}.conf"
        fi
    else
        echo "❌ 找不到客戶端 ${peer_name} 的 QR Code"
        echo "可用的客戶端:"
        # 使用 glob 模式替代 ls | grep
        for dir in config/peer_*; do
            if [ -d "$dir" ]; then
                peer_name_available=$(basename "$dir" | sed 's/peer_//')
                echo "  - $peer_name_available"
            fi
        done
    fi
}

check_system() {
    echo "🔍 系統檢查："
    echo ""
    
    # 檢查必要檔案
    echo "📁 專案檔案："
    for file in docker-compose.yml .env; do
        if [ -f "$file" ]; then
            echo "✅ $file 存在"
        else
            echo "❌ $file 不存在"
        fi
    done
    echo ""
    
    # 檢查 Docker
    echo "🐳 Docker 狀態："
    if command -v docker >/dev/null 2>&1; then
        echo "✅ Docker 已安裝 ($(docker --version | cut -d' ' -f3 | tr -d ','))"
        
        # 檢查 Docker 服務
        if docker info >/dev/null 2>&1; then
            echo "✅ Docker 服務運行中"
        else
            echo "❌ Docker 服務未運行"
        fi
        
        # 檢查使用者權限
        if docker ps >/dev/null 2>&1; then
            echo "✅ Docker 權限正常"
        else
            echo "❌ Docker 權限不足（請將使用者加入 docker 群組）"
        fi
    else
        echo "❌ Docker 未安裝"
    fi
    echo ""
    
    # 檢查防火牆
    echo "🔥 防火牆狀態："
    if command -v ufw >/dev/null 2>&1; then
        echo "✅ UFW 防火牆已安裝"
        ufw_status=$(sudo ufw status 2>/dev/null | head -1 || echo "無法取得狀態")
        echo "   狀態: $ufw_status"
        
        # 檢查 WireGuard 連接埠規則
        if sudo ufw status | grep -q "51820/udp"; then
            echo "✅ WireGuard 連接埠 51820/UDP 已開放"
        else
            echo "⚠️ WireGuard 連接埠 51820/UDP 未在防火牆中開放"
        fi
    else
        echo "❌ UFW 防火牆未安裝"
    fi
    echo ""
    
    # 檢查網路設定
    echo "🌐 網路設定："
    
    # 檢查 IP 轉送
    if [ -r /proc/sys/net/ipv4/ip_forward ]; then
        ip_forward=$(cat /proc/sys/net/ipv4/ip_forward)
        if [ "$ip_forward" = "1" ]; then
            echo "✅ IP 轉送已啟用"
        else
            echo "❌ IP 轉送未啟用"
        fi
    else
        echo "⚠️ 無法檢查 IP 轉送狀態"
    fi
    
    # 檢查連接埠監聽
    if command -v ss >/dev/null 2>&1; then
        if ss -uln | grep -q :51820; then
            echo "✅ WireGuard 連接埠 51820 正在監聽"
        else
            echo "⚠️ WireGuard 連接埠 51820 未監聽（服務可能未啟動）"
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -uln | grep -q :51820; then
            echo "✅ WireGuard 連接埠 51820 正在監聽"
        else
            echo "⚠️ WireGuard 連接埠 51820 未監聽（服務可能未啟動）"
        fi
    else
        echo "⚠️ 無法檢查連接埠狀態（缺少 ss 或 netstat）"
    fi
    echo ""
    
    # 檢查 Docker Compose 服務
    echo "📊 服務狀態："
    if [ -f docker-compose.yml ]; then
        if docker compose ps >/dev/null 2>&1; then
            docker compose ps
        else
            echo "⚠️ 無法取得 Docker Compose 服務狀態"
        fi
    else
        echo "❌ docker-compose.yml 檔案不存在"
    fi
    echo ""
    
    # 檢查磁碟空間
    echo "💽 系統資源："
    df -h / | head -2
    echo ""
    free -h | head -2
}

case "${1:-}" in
    setup)
        setup_environment
        ;;
    start)
        setup_environment  # 自動設定環境變數
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        setup_environment  # 自動設定環境變數
        restart_services
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    peers)
        show_peers
        ;;
    update)
        update_services
        ;;
    backup)
        backup_config
        ;;
    qr)
        show_qr "$2"
        ;;
    check)
        check_system
        ;;
    validate)
        if [ -f "scripts/validate.sh" ]; then
            echo "🔍 執行專案完整驗證..."
            bash scripts/validate.sh
        else
            echo "❌ 找不到驗證腳本: scripts/validate.sh"
            exit 1
        fi
        ;;
    *)
        usage
        exit 1
        ;;
esac 