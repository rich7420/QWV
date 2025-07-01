#!/bin/bash

# QWV QR Code 自動清理 Cron 設定腳本
# 設定每小時清理過期的 QR Code

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLEANUP_SCRIPT="$SCRIPT_DIR/qr-cleanup.sh"

echo "🕒 設定 QWV QR Code 自動清理 Cron 任務"
echo ""

# 檢查清理腳本是否存在
if [ ! -f "$CLEANUP_SCRIPT" ]; then
    echo "❌ 清理腳本不存在: $CLEANUP_SCRIPT"
    exit 1
fi

# 確保腳本有執行權限
chmod +x "$CLEANUP_SCRIPT"

# 檢查當前的 cron 任務
echo "📋 當前的 QWV 相關 cron 任務："
crontab -l 2>/dev/null | grep -E "(qr-cleanup|QWV)" || echo "   無"
echo ""

# Cron 任務設定
CRON_ENTRY="0 * * * * $CLEANUP_SCRIPT >/dev/null 2>&1"

# 檢查是否已經設定
if crontab -l 2>/dev/null | grep -F "$CLEANUP_SCRIPT" >/dev/null; then
    echo "✅ QWV QR Code 清理任務已經存在"
    echo "📝 如需更新，請選擇覆蓋設定"
    echo ""
    read -p "是否要重新設定 cron 任務？(y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "⏭️ 跳過設定"
        exit 0
    fi
fi

echo "⚙️ 設定 cron 任務選項："
echo "1. 🕐 每5分鐘清理一次（推薦，配合3分鐘過期）"
echo "2. 🕕 每15分鐘清理一次"
echo "3. 🕛 每小時清理一次"
echo "4. 🚫 移除 cron 任務"
echo "5. 📝 自訂時間間隔"
echo ""

read -p "請選擇選項 (1-5): " -n 1 -r choice
echo ""

case $choice in
    1)
        CRON_ENTRY="*/5 * * * * $CLEANUP_SCRIPT >/dev/null 2>&1"
        DESCRIPTION="每5分鐘"
        ;;
    2)
        CRON_ENTRY="*/15 * * * * $CLEANUP_SCRIPT >/dev/null 2>&1"
        DESCRIPTION="每15分鐘"
        ;;
    3)
        CRON_ENTRY="0 * * * * $CLEANUP_SCRIPT >/dev/null 2>&1"
        DESCRIPTION="每小時"
        ;;
    4)
        echo "🗑️ 移除 QWV QR Code 清理任務..."
        # 移除包含清理腳本路徑的所有 cron 任務
        crontab -l 2>/dev/null | grep -v "$CLEANUP_SCRIPT" | crontab -
        echo "✅ 已移除 cron 任務"
        exit 0
        ;;
    5)
        echo "📝 自訂 cron 時間格式說明："
        echo "   格式: minute hour day month weekday"
        echo "   範例: '0 */2 * * *' = 每2小時"
        echo "         '30 1 * * 0' = 每週日凌晨1:30"
        echo ""
        read -p "請輸入 cron 時間格式: " custom_time
        if [ -z "$custom_time" ]; then
            echo "❌ 無效的輸入"
            exit 1
        fi
        CRON_ENTRY="$custom_time $CLEANUP_SCRIPT >/dev/null 2>&1"
        DESCRIPTION="自訂時間 ($custom_time)"
        ;;
    *)
        echo "❌ 無效的選項"
        exit 1
        ;;
esac

echo "⚙️ 設定 cron 任務: $DESCRIPTION"

# 備份現有的 cron 任務
echo "📋 備份現有 cron 任務..."
crontab -l 2>/dev/null > "/tmp/crontab_backup_$(date +%Y%m%d_%H%M%S)"

# 移除舊的 QWV 相關任務並添加新任務
{
    crontab -l 2>/dev/null | grep -v "$CLEANUP_SCRIPT"
    echo "$CRON_ENTRY"
} | crontab -

if [ $? -eq 0 ]; then
    echo "✅ Cron 任務設定成功"
    echo ""
    echo "📋 當前的 cron 任務："
    crontab -l | grep "$CLEANUP_SCRIPT"
    echo ""
    echo "📁 清理日誌位置: $PROJECT_DIR/logs/qr-cleanup.log"
    echo "🔍 查看日誌: tail -f $PROJECT_DIR/logs/qr-cleanup.log"
    echo ""
    echo "💡 手動執行清理: $PROJECT_DIR/scripts/manage.sh cleanup-qr"
else
    echo "❌ Cron 任務設定失敗"
    exit 1
fi

# 測試清理腳本
echo "🧪 測試清理腳本..."
if "$CLEANUP_SCRIPT"; then
    echo "✅ 清理腳本測試成功"
else
    echo "⚠️ 清理腳本測試失敗，請檢查腳本權限和路徑"
fi

echo ""
echo "🎉 QWV QR Code 自動清理設定完成！"
echo ""
echo "💡 小提醒："
echo "• 自動清理只會處理已過期的 QR Code"
echo "• 清理日誌會自動輪轉，保留30天"
echo "• 如需立即撤銷 QR Code，請使用: $PROJECT_DIR/scripts/manage.sh revoke-qr <客戶端名稱>" 