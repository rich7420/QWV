#!/bin/bash

# QWV - QuickWireguardVpn 管理腳本
# 提供 VPN 服務的啟動、停止、狀態檢查等功能

set -e  # 遇到錯誤時退出

# 自動偵測裝置信息並生成客戶端名稱
generate_auto_peer() {
    local format="${AUTO_PEER_FORMAT:-username-hostname}"
    local username
    local hostname
    username=$(whoami)
    hostname=$(hostname | cut -d'.' -f1)  # 只取第一部分，避免 FQDN
    
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
    # 載入環境變數
    if [ -f .env ]; then
        set -a  # 自動匯出所有變數
        # shellcheck disable=SC1091
        source .env
        set +a
    fi
    
    local peers_config="${WIREGUARD_PEERS:-auto}"
    local processed_peers=""
    
    # 檢查是否包含 auto 關鍵字
    if echo "$peers_config" | grep -q "auto"; then
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
    else
        # 沒有 auto 關鍵字，直接使用原始配置
        processed_peers="$peers_config"
    fi
    
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
    
    # 載入現有環境變數
    if [ -f .env ]; then
        set -a
        # shellcheck disable=SC1091
        source .env
        set +a
    fi
    
    # 自動檢測並設置正確的 PUID/PGID（如果未設置）
    current_uid=$(id -u)
    current_gid=$(id -g)
    
    if ! grep -q "^PUID=" .env 2>/dev/null; then
        echo "PUID=$current_uid" >> .env
    fi
    
    if ! grep -q "^PGID=" .env 2>/dev/null; then
        echo "PGID=$current_gid" >> .env
    fi
    
    # 確保 PUID/PGID 與當前用戶匹配
    if [ -f .env ]; then
        if grep -q "^PUID=" .env; then
            sed -i "s/^PUID=.*/PUID=$current_uid/" .env
        fi
        if grep -q "^PGID=" .env; then
            sed -i "s/^PGID=.*/PGID=$current_gid/" .env
        fi
    fi
    
    # 檢查是否需要處理自動偵測
    if echo "${WIREGUARD_PEERS:-auto}" | grep -q "auto"; then
        # 處理 PEERS 配置（僅在包含 auto 時）
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
            
            # 顯示自動偵測結果
            auto_peer=$(generate_auto_peer)
            echo "🤖 自動偵測裝置: $auto_peer"
            echo "   - 使用者: $(whoami)"
            echo "   - 主機名: $(hostname | cut -d'.' -f1)"
            echo "   - 格式: ${AUTO_PEER_FORMAT:-username-hostname}"
        fi
    else
        # 手動設定模式，保持現有配置
        echo "✅ 已設定客戶端: ${WIREGUARD_PEERS}"
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
    echo "📋 基本服務管理:"
    echo "  setup        設定環境變數（支援自動偵測裝置名稱）"
    echo "  start        啟動 VPN 服務"
    echo "  stop         停止 VPN 服務"
    echo "  restart      重啟 VPN 服務"
    echo "  status       查看服務狀態"
    echo "  logs         查看服務日誌"
    echo "  peers        顯示連線的客戶端"
    echo "  update       更新服務映像檔"
    echo "  backup       備份設定檔"
    echo ""
    echo "📱 QR Code 時效性管理:"
    echo "  qr <peer> [minutes]         生成時效性 QR Code（預設3分鐘）"
    echo "  web-qr <peer> [port]        啟動安全 Web QR Code 服務"
    echo "  qr-status                   查看所有 QR Code 狀態"
    echo "  revoke-qr <peer>            立即撤銷 QR Code"
    echo "  cleanup-qr                  清理過期的 QR Code"
    echo ""
    echo "🔍 系統檢查:"
    echo "  check        檢查系統狀態"
    echo "  security     檢查專案安全性設定"
    echo "  validate     執行專案完整驗證"
    echo ""
    echo "🤖 自動偵測功能:"
    echo "  在 .env 中設定 WIREGUARD_PEERS=auto 可自動偵測當前裝置"
    echo "  支援格式: username, hostname, username-hostname, hostname-username"
    echo "  混合模式: WIREGUARD_PEERS=auto,work_laptop,family_tablet"
    echo ""
    echo "📋 QR Code 時效性範例:"
    echo "  $0 qr phone             # 生成3分鐘有效期的 QR Code（預設）"
    echo "  $0 qr laptop 5          # 生成5分鐘有效期的 QR Code"
    echo "  $0 qr tablet 60         # 生成1小時（60分鐘）有效期的 QR Code"
    echo "  $0 qr-status            # 查看所有 QR Code 狀態"
    echo "  $0 revoke-qr phone      # 立即撤銷手機的 QR Code"
    echo ""
    echo "🌐 Web QR Code 範例:"
    echo "  $0 web-qr laptop 8080   # 啟動Web服務分享QR Code（含安全token）"
    echo ""
    echo "🔧 系統管理範例:"
    echo "  $0 setup                # 設定環境變數並自動偵測裝置"
    echo "  $0 security             # 檢查專案安全性設定"
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
    ttl_minutes="${2:-3}"  # 預設3分鐘過期
    
    if [ -z "$peer_name" ]; then
        echo "❌ 請指定客戶端名稱"
        echo "例如: $0 qr laptop [過期時間分鐘]"
        echo "      $0 qr laptop 5     # 5分鐘後過期"
        echo "      $0 qr laptop 60    # 60分鐘後過期"
        echo "      $0 qr laptop 3     # 3分鐘後過期（預設）"
        return 1
    fi
    
    # 檢查 TTL 參數是否為數字
    if ! echo "$ttl_minutes" | grep -E '^[0-9]+$' >/dev/null; then
        echo "❌ 過期時間必須為數字（分鐘）"
        return 1
    fi
    
    qr_file="config/peer_${peer_name}/peer_${peer_name}.png"
    conf_file="config/peer_${peer_name}/peer_${peer_name}.conf"
    expiry_file="config/peer_${peer_name}/.qr_expiry"
    
    if [ ! -f "$qr_file" ] || [ ! -f "$conf_file" ]; then
        echo "❌ 找不到客戶端 ${peer_name} 的配置"
        echo "可用的客戶端:"
        # 使用 glob 模式替代 ls | grep
        for dir in config/peer_*; do
            if [ -d "$dir" ]; then
                peer_name_available=$(basename "$dir" | sed 's/peer_//')
                echo "  - $peer_name_available"
            fi
        done
        return 1
    fi
    
    # 檢查是否已過期
    current_time=$(date +%s)
    if [ -f "$expiry_file" ]; then
        expiry_time=$(cat "$expiry_file" 2>/dev/null || echo "0")
        if [ "$current_time" -gt "$expiry_time" ]; then
            echo "⏰ QR Code 已過期，正在重新生成..."
            # 移除過期的檔案
            rm -f "$expiry_file"
            # 觸發 WireGuard 重新生成配置
            echo "🔄 重新啟動 WireGuard 服務以生成新配置..."
            docker restart wireguard >/dev/null 2>&1
            sleep 5  # 等待服務重啟
        else
            # 計算剩餘時間
            remaining_seconds=$((expiry_time - current_time))
            remaining_minutes=$((remaining_seconds / 60))
            remaining_secs=$((remaining_seconds % 60))
            echo "⏰ QR Code 剩餘有效時間: ${remaining_minutes}分${remaining_secs}秒"
        fi
    fi
    
    # 設定新的過期時間（轉換分鐘為秒）
    expiry_time=$((current_time + ttl_minutes * 60))
    echo "$expiry_time" > "$expiry_file"
    expiry_date=$(date -d "@$expiry_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r "$expiry_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")
    
    echo "📱 客戶端 ${peer_name} 的時效性 QR Code:"
    echo "⏰ 有效期限: $expiry_date (${ttl_minutes}分鐘)"
    echo "📁 檔案位置: $qr_file"
    echo ""
    
    # 偵測伺服器IP（支援多種系統）
    server_ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}' || hostname -I 2>/dev/null | awk '{print $1}' || ifconfig 2>/dev/null | grep -E 'inet.*192\.168\.|inet.*10\.|inet.*172\.' | head -1 | awk '{print $2}' | cut -d: -f2)
    
    echo "💡 獲取QR Code的方法："
    echo "1. 📥 下載PNG圖片："
    echo "   scp $(whoami)@${server_ip}:$(pwd)/$qr_file ~/qr-${peer_name}.png"
    echo "2. 📋 複製配置文件："
    echo "   scp $(whoami)@${server_ip}:$(pwd)/$conf_file ~/wireguard-${peer_name}.conf"
    echo "3. 🌐 啟動安全Web服務："
    echo "   $0 web-qr ${peer_name}"
    echo ""
    
    # 如果系統支援，可以直接顯示 QR code
    if command -v qrencode >/dev/null 2>&1; then
        echo "4. 📱 終端機QR Code："
        qrencode -t ansiutf8 < "$conf_file"
    else
        echo "4. ⚠️  終端機QR Code（需要安裝qrencode）："
        echo "   sudo apt install qrencode  # Ubuntu/Debian"
        echo "   brew install qrencode      # macOS"
    fi
    
    # 設定自動清理任務
    echo ""
    echo "🗑️  過期後將自動清理配置檔案"
    echo "💡 延長有效期: $0 qr ${peer_name} ${ttl_minutes}"
    echo "🔒 立即撤銷: $0 revoke-qr ${peer_name}"
}

revoke_qr() {
    peer_name="$1"
    
    if [ -z "$peer_name" ]; then
        echo "❌ 請指定要撤銷的客戶端名稱"
        echo "例如: $0 revoke-qr laptop"
        return 1
    fi
    
    expiry_file="config/peer_${peer_name}/.qr_expiry"
    qr_file="config/peer_${peer_name}/peer_${peer_name}.png"
    conf_file="config/peer_${peer_name}/peer_${peer_name}.conf"
    
    if [ ! -d "config/peer_${peer_name}" ]; then
        echo "❌ 客戶端 ${peer_name} 不存在"
        return 1
    fi
    
    echo "🔒 撤銷客戶端 ${peer_name} 的 QR Code..."
    
    # 設定過期時間為過去（立即過期）
    past_time=$(($(date +%s) - 1))
    echo "$past_time" > "$expiry_file"
    
    # 移除敏感檔案
    if [ -f "$qr_file" ]; then
        rm -f "$qr_file"
        echo "✅ 已移除 QR Code 圖片"
    fi
    
    if [ -f "$conf_file" ]; then
        # 備份原始配置
        backup_file="config/peer_${peer_name}/peer_${peer_name}.conf.revoked.$(date +%s)"
        mv "$conf_file" "$backup_file"
        echo "✅ 已撤銷配置檔案（備份為 $(basename "$backup_file")）"
    fi
    
    echo "🔄 重新啟動 WireGuard 服務..."
    docker restart wireguard >/dev/null 2>&1
    
    echo "✅ QR Code 已成功撤銷"
    echo "💡 如需重新啟用，請使用: $0 qr ${peer_name}"
}

cleanup_expired_qr() {
    echo "🧹 清理過期的 QR Code..."
    
    current_time=$(date +%s)
    cleaned_count=0
    
    for expiry_file in config/peer_*/.qr_expiry; do
        if [ -f "$expiry_file" ]; then
            expiry_time=$(cat "$expiry_file" 2>/dev/null || echo "0")
            if [ "$current_time" -gt "$expiry_time" ]; then
                peer_dir=$(dirname "$expiry_file")
                peer_name=$(basename "$peer_dir" | sed 's/peer_//')
                
                echo "⏰ 清理過期的客戶端: $peer_name"
                
                # 移除過期的 QR Code 和配置
                rm -f "$peer_dir"/*.png
                rm -f "$expiry_file"
                
                # 將配置檔案標記為過期
                if [ -f "$peer_dir/peer_${peer_name}.conf" ]; then
                    mv "$peer_dir/peer_${peer_name}.conf" "$peer_dir/peer_${peer_name}.conf.expired.$(date +%s)"
                fi
                
                cleaned_count=$((cleaned_count + 1))
            fi
        fi
    done
    
    if [ "$cleaned_count" -gt 0 ]; then
        echo "✅ 已清理 $cleaned_count 個過期的 QR Code"
        echo "🔄 重新啟動 WireGuard 服務..."
        docker restart wireguard >/dev/null 2>&1
    else
        echo "✅ 沒有過期的 QR Code 需要清理"
    fi
}

list_qr_status() {
    echo "📋 QR Code 狀態總覽:"
    echo ""
    
    current_time=$(date +%s)
    
    for peer_dir in config/peer_*; do
        if [ -d "$peer_dir" ]; then
            peer_name=$(basename "$peer_dir" | sed 's/peer_//')
            expiry_file="$peer_dir/.qr_expiry"
            conf_file="$peer_dir/peer_${peer_name}.conf"
            qr_file="$peer_dir/peer_${peer_name}.png"
            
            echo "👤 客戶端: $peer_name"
            
            if [ -f "$expiry_file" ]; then
                expiry_time=$(cat "$expiry_file" 2>/dev/null || echo "0")
                expiry_date=$(date -d "@$expiry_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r "$expiry_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")
                
                if [ "$current_time" -gt "$expiry_time" ]; then
                    echo "   ⏰ 狀態: ❌ 已過期 ($expiry_date)"
                else
                    remaining_seconds=$((expiry_time - current_time))
                    remaining_minutes=$((remaining_seconds / 60))
                    remaining_secs=$((remaining_seconds % 60))
                    echo "   ⏰ 狀態: ✅ 有效 (剩餘 ${remaining_minutes}分${remaining_secs}秒)"
                    echo "   📅 過期時間: $expiry_date"
                fi
            else
                echo "   ⏰ 狀態: ⚪ 無時效限制（舊版本）"
            fi
            
            echo "   📁 配置檔案: $([ -f "$conf_file" ] && echo "✅ 存在" || echo "❌ 不存在")"
            echo "   📱 QR Code: $([ -f "$qr_file" ] && echo "✅ 存在" || echo "❌ 不存在")"
            echo ""
        fi
    done
}

show_web_qr() {
    peer_name="$1"
    port="${2:-8080}"
    
    if [ -z "$peer_name" ]; then
        echo "❌ 請指定客戶端名稱"
        echo "例如: $0 web-qr laptop [port]"
        return 1
    fi
    
    qr_file="config/peer_${peer_name}/peer_${peer_name}.png"
    expiry_file="config/peer_${peer_name}/.qr_expiry"
    
    # 檢查客戶端是否存在
    if [ ! -f "$qr_file" ]; then
        echo "❌ 找不到客戶端 ${peer_name} 的 QR Code"
        echo "請先生成 QR Code: $0 qr ${peer_name}"
        return 1
    fi
    
    # 檢查是否已過期
    current_time=$(date +%s)
    if [ -f "$expiry_file" ]; then
        expiry_time=$(cat "$expiry_file" 2>/dev/null || echo "0")
        if [ "$current_time" -gt "$expiry_time" ]; then
            echo "❌ QR Code 已過期"
            echo "請重新生成: $0 qr ${peer_name}"
            return 1
                 else
            remaining_seconds=$((expiry_time - current_time))
            remaining_minutes=$((remaining_seconds / 60))
            remaining_secs=$((remaining_seconds % 60))
            echo "⏰ QR Code 剩餘有效時間: ${remaining_minutes}分${remaining_secs}秒"
        fi
    fi
    
    # 偵測伺服器IP
    server_ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}' || hostname -I 2>/dev/null | awk '{print $1}' || ifconfig 2>/dev/null | grep -E 'inet.*192\.168\.|inet.*10\.|inet.*172\.' | head -1 | awk '{print $2}' | cut -d: -f2)
    
    # 生成隨機安全token
    security_token=$(openssl rand -hex 16 2>/dev/null || date +%s | sha256sum | head -c 32)
    
    echo "🌐 啟動安全Web QR Code分享服務..."
    echo "📱 QR Code網址: http://${server_ip}:${port}/?token=${security_token}"
    echo "🔒 安全提醒: 僅限內網存取，含隨機token驗證"
    echo "⚠️  按 Ctrl+C 停止服務"
    echo ""
    
    # 建立臨時目錄和檔案
    temp_dir=$(mktemp -d)
    
    # 設定trap確保清理
    trap 'echo "🧹 清理臨時檔案..."; rm -rf "$temp_dir"; exit 0' INT TERM EXIT
    
    cp "$qr_file" "$temp_dir/qr.png"
    
    # 建立安全的HTML頁面
    cat > "$temp_dir/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>QWV - ${peer_name} QR Code</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 20px; background: #f0f0f0; }
        .container { max-width: 500px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .qr-code { max-width: 100%; height: auto; border: 2px solid #ddd; border-radius: 8px; }
        .title { color: #333; margin-bottom: 20px; }
        .instructions { color: #666; margin-top: 20px; text-align: left; }
        .step { margin: 10px 0; padding: 10px; background: #f8f9fa; border-radius: 5px; }
        .security-warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }
    </style>
    <script>
        // 簡單的token驗證
        const urlParams = new URLSearchParams(window.location.search);
        const token = urlParams.get('token');
        if (!token || token !== '${security_token}') {
            document.body.innerHTML = '<div style="text-align:center;padding:50px;"><h1>🔒 存取被拒絕</h1><p>無效的安全token</p></div>';
        }
    </script>
</head>
<body>
    <div class="container">
        <h1 class="title">🔐 WireGuard VPN - ${peer_name}</h1>
        <div class="security-warning">
            <strong>🔒 安全提醒：</strong>此QR碼包含您的私密VPN設定，請勿截圖分享或外洩
        </div>
        <img src="qr.png" alt="QR Code" class="qr-code">
        <div class="instructions">
            <h3>📱 設定步驟：</h3>
            <div class="step">1. 下載 WireGuard 應用程式</div>
            <div class="step">2. 點擊 "+" → "從QR碼建立"</div>
            <div class="step">3. 掃描上方QR碼</div>
            <div class="step">4. 為隧道命名並建立</div>
        </div>
        <p style="color: #999; font-size: 12px; margin-top: 30px;">
            QWV - QuickWireguardVpn<br>
            此服務將在掃描後自動關閉
        </p>
    </div>
</body>
</html>
EOF
    
    # 啟動HTTP服務（綁定到內網IP）
    echo "🚀 啟動中..."
    cd "$temp_dir"
    if command -v python3 >/dev/null 2>&1; then
        python3 -m http.server "$port" --bind "$server_ip" 2>/dev/null &
        server_pid=$!
    elif command -v python >/dev/null 2>&1; then
        python -m SimpleHTTPServer "$port" 2>/dev/null &
        server_pid=$!
    else
        echo "❌ 需要安裝 Python 來啟動 Web 服務"
        echo "或者使用其他方法獲取 QR Code"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 等待服務啟動
    sleep 2
    echo "✅ 服務已啟動，請在瀏覽器開啟上方網址"
    
    # 等待用戶中斷
    wait "$server_pid" 2>/dev/null
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

security_check() {
    echo "🔒 QWV 安全性檢查"
    echo ""
    
    # 檢查檔案權限
    echo "📂 檔案權限檢查："
    if [ -f ".env" ]; then
        env_perms=$(stat -c "%a" .env 2>/dev/null || stat -f "%A" .env 2>/dev/null)
        if [ "$env_perms" = "600" ] || [ "$env_perms" = "0600" ]; then
            echo "✅ .env 檔案權限安全 ($env_perms)"
        else
            echo "⚠️ .env 檔案權限不安全 ($env_perms)，建議設為 600"
            echo "   修正指令: chmod 600 .env"
        fi
    else
        echo "❌ .env 檔案不存在"
    fi
    
    if [ -d "config" ]; then
        config_perms=$(stat -c "%a" config 2>/dev/null || stat -f "%A" config 2>/dev/null)
        echo "✅ config 目錄權限: $config_perms"
        
        # 檢查是否有私鑰檔案的權限
        find config -name "*.conf" -exec ls -la {} \; 2>/dev/null | head -3
    else
        echo "❌ config 目錄不存在"
    fi
    echo ""
    
    # 檢查 .env 檔案內容安全性
    echo "🔑 設定檔安全性："
    if [ -f ".env" ]; then
        if grep -q "your_cloudflare_api_token_here" .env; then
            echo "❌ 預設 API token 未更改"
        else
            echo "✅ Cloudflare API token 已設定"
        fi
        
        if grep -q "yourdomain.com" .env; then
            echo "❌ 預設域名未更改"
        else
            echo "✅ 域名設定已更新"
        fi
        
        # 檢查是否有敏感資料意外暴露
        if [ -d ".git" ]; then
            if git status --porcelain | grep -q ".env"; then
                echo "⚠️ .env 檔案尚未commit（正常）"
            else
                if git log --name-only --pretty=format: | grep -q ".env"; then
                    echo "❌ 危險！.env 檔案曾被commit到Git"
                    echo "   請立即更換 API token 並從 Git 歷史移除"
                else
                    echo "✅ .env 檔案未被commit到Git"
                fi
            fi
        fi
    fi
    echo ""
    
    # 檢查網路安全性
    echo "🌐 網路安全性："
    
    # 檢查是否有不安全的連接埠開放
    if command -v ss >/dev/null 2>&1; then
        open_ports=$(ss -tuln | grep -E ":80|:8080|:3000|:5000" | grep -v ":51820")
        if [ -n "$open_ports" ]; then
            echo "⚠️ 偵測到其他開放的連接埠："
            echo "$open_ports"
            echo "   請確認這些服務是否必要"
        else
            echo "✅ 無偵測到非必要的開放連接埠"
        fi
    fi
    
    # 檢查SSH設定（如果存在）
    if [ -f "/etc/ssh/sshd_config" ]; then
        if sudo grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config 2>/dev/null; then
            echo "⚠️ SSH 密碼驗證仍啟用，建議使用金鑰驗證"
        else
            echo "✅ SSH 安全設定良好"
        fi
    fi
    echo ""
    
    # 檢查Docker安全性
    echo "🐳 Docker 安全性："
    if command -v docker >/dev/null 2>&1; then
        # 檢查是否以root身份運行Docker
        if [ "$EUID" -eq 0 ]; then
            echo "⚠️ 正以root身份運行，建議使用一般使用者帳號"
        else
            echo "✅ 使用一般使用者帳號運行Docker"
        fi
        
        # 檢查Docker映像檔版本
        latest_check=$(docker compose config 2>/dev/null | grep -c "latest")
        if [ "$latest_check" -gt 0 ]; then
            echo "⚠️ 使用 latest 標籤，建議固定版本號"
        else
            echo "✅ 使用固定版本標籤"
        fi
    fi
    echo ""
    
    # 安全建議
    echo "💡 安全建議："
    echo "1. 🔑 定期更換 Cloudflare API token"
    echo "2. 📝 定期備份設定檔到安全位置"
    echo "3. 🔄 定期更新 Docker 映像檔版本"
    echo "4. 🚫 切勿將 .env 檔案上傳到公開儲存庫"
    echo "5. 📱 QR Code 使用後立即關閉分享服務"
    echo "6. 🔍 定期檢查連線日誌是否有異常"
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
        show_qr "$2" "$3"
        ;;
    web-qr)
        show_web_qr "$2" "$3"
        ;;
    qr-status)
        list_qr_status
        ;;
    revoke-qr)
        revoke_qr "$2"
        ;;
    cleanup-qr)
        cleanup_expired_qr
        ;;
    check)
        check_system
        ;;
    security)
        security_check
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