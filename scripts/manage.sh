#!/bin/bash

# QWV VPN 服務管理腳本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

usage() {
    echo "QWV VPN 服務管理工具"
    echo ""
    echo "使用方法: $0 <command>"
    echo ""
    echo "可用指令:"
    echo "  start      啟動 VPN 服務"
    echo "  stop       停止 VPN 服務"
    echo "  restart    重啟 VPN 服務"
    echo "  status     查看服務狀態"
    echo "  logs       查看服務日誌"
    echo "  peers      顯示連線的客戶端"
    echo "  update     更新服務映像檔"
    echo "  backup     備份設定檔"
    echo "  qr <peer>  顯示客戶端 QR Code"
    echo "  check      檢查系統狀態"
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
    docker compose ps
    echo ""
    echo "🌐 系統資源:"
    docker stats --no-stream
}

show_logs() {
    echo "📋 服務日誌:"
    docker compose logs --tail=50 -f
}

show_peers() {
    echo "👥 已連線的客戶端:"
    docker exec wireguard wg show 2>/dev/null || echo "WireGuard 服務未運行或無客戶端連線"
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
            cat "config/peer_${peer_name}/peer_${peer_name}.conf" | qrencode -t ansiutf8
        fi
    else
        echo "❌ 找不到客戶端 ${peer_name} 的 QR Code"
        echo "可用的客戶端:"
        ls config/ | grep "peer_" | sed 's/peer_/  - /'
    fi
}

check_system() {
    echo "🔍 系統檢查:"
    echo ""
    
    # 檢查 Docker
    if command -v docker >/dev/null 2>&1; then
        echo "✅ Docker 已安裝 ($(docker --version))"
    else
        echo "❌ Docker 未安裝"
    fi
    
    # 檢查防火牆
    if command -v ufw >/dev/null 2>&1; then
        echo "✅ UFW 防火牆已安裝"
        ufw_status=$(sudo ufw status | head -1)
        echo "   狀態: $ufw_status"
    else
        echo "❌ UFW 防火牆未安裝"
    fi
    
    # 檢查 IP 轉送
    ip_forward=$(cat /proc/sys/net/ipv4/ip_forward)
    if [ "$ip_forward" = "1" ]; then
        echo "✅ IP 轉送已啟用"
    else
        echo "❌ IP 轉送未啟用"
    fi
    
    # 檢查連接埠
    echo ""
    echo "📡 網路檢查:"
    netstat -uln | grep :51820 && echo "✅ WireGuard 連接埠 51820 正在監聽" || echo "❌ WireGuard 連接埠 51820 未監聽"
}

case "${1:-}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
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
    *)
        usage
        exit 1
        ;;
esac 