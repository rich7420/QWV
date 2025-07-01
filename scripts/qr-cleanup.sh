#!/bin/bash

# QWV QR Code 自動清理腳本
# 用於 cron 任務，自動清理過期的 QR Code
# 建議設定：每小時執行一次

# 設定工作目錄
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 切換到專案目錄
cd "$PROJECT_DIR" || {
    echo "❌ 無法進入專案目錄: $PROJECT_DIR"
    exit 1
}

# 檢查是否為 QWV 專案目錄
if [ ! -f "docker-compose.yml" ] || [ ! -f ".env" ]; then
    echo "❌ 不在有效的 QWV 專案目錄中"
    exit 1
fi

# 記錄日誌
log_file="logs/qr-cleanup.log"
mkdir -p logs
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$timestamp] 開始 QR Code 清理作業" >> "$log_file"

# 執行清理
current_time=$(date +%s)
cleaned_count=0

for expiry_file in config/peer_*/.qr_expiry; do
    if [ -f "$expiry_file" ]; then
        expiry_time=$(cat "$expiry_file" 2>/dev/null || echo "0")
        if [ "$current_time" -gt "$expiry_time" ]; then
            peer_dir=$(dirname "$expiry_file")
            peer_name=$(basename "$peer_dir" | sed 's/peer_//')
            
            echo "[$timestamp] 清理過期的客戶端: $peer_name (過期時間: $(date -d "@$expiry_time" 2>/dev/null || echo "Unknown"))" >> "$log_file"
            
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
    echo "[$timestamp] 已清理 $cleaned_count 個過期的 QR Code，重新啟動 WireGuard 服務" >> "$log_file"
    docker restart wireguard >> "$log_file" 2>&1
else
    echo "[$timestamp] 沒有過期的 QR Code 需要清理" >> "$log_file"
fi

# 清理舊的日誌（保留 30 天）
find logs -name "qr-cleanup.log.*" -mtime +30 -delete 2>/dev/null

# 輪轉日誌檔案（如果超過 1MB）
if [ -f "$log_file" ] && [ $(stat -c%s "$log_file" 2>/dev/null || stat -f%z "$log_file" 2>/dev/null || echo 0) -gt 1048576 ]; then
    mv "$log_file" "${log_file}.$(date +%Y%m%d-%H%M%S)"
    echo "[$timestamp] 已輪轉日誌檔案" > "$log_file"
fi

echo "[$timestamp] QR Code 清理作業完成" >> "$log_file" 