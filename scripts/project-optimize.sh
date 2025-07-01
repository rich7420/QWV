#!/bin/bash

# QWV 專案優化腳本
# 用於整理專案結構、檢查配置、優化效能

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/logs/project-optimize.log"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日誌函數
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🔧 QWV 專案優化工具${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_section() {
    echo -e "${BLUE}📋 $1${NC}"
    echo -e "${BLUE}$( printf '─%.0s' {1..50} )${NC}"
}

# 檢查專案結構
check_project_structure() {
    print_section "檢查專案結構"
    
    local required_dirs=("config" "logs" "backup" "scripts" "docs")
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$PROJECT_DIR/$dir" ]; then
            missing_dirs+=("$dir")
            mkdir -p "$PROJECT_DIR/$dir"
            echo -e "${YELLOW}📁 已創建目錄: $dir${NC}"
            log "Created missing directory: $dir"
        else
            echo -e "${GREEN}✅ 目錄存在: $dir${NC}"
        fi
    done
    
    if [ ${#missing_dirs[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ 專案結構完整${NC}"
    else
        echo -e "${YELLOW}⚠️  已修復 ${#missing_dirs[@]} 個缺失目錄${NC}"
    fi
    echo ""
}

# 檢查檔案權限
check_file_permissions() {
    print_section "檢查檔案權限"
    
    # 檢查 .env 檔案權限
    if [ -f "$PROJECT_DIR/.env" ]; then
        current_perm=$(stat -c "%a" "$PROJECT_DIR/.env" 2>/dev/null || stat -f "%OLp" "$PROJECT_DIR/.env" 2>/dev/null)
        if [ "$current_perm" != "600" ]; then
            chmod 600 "$PROJECT_DIR/.env"
            echo -e "${YELLOW}🔒 已修正 .env 檔案權限: 644 → 600${NC}"
            log "Fixed .env file permissions: $current_perm -> 600"
        else
            echo -e "${GREEN}✅ .env 檔案權限正確: 600${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  .env 檔案不存在${NC}"
    fi
    
    # 檢查腳本執行權限
    local scripts=("scripts/manage.sh" "scripts/setup.sh" "scripts/validate.sh" "scripts/qr-cleanup.sh" "scripts/setup-cron.sh")
    for script in "${scripts[@]}"; do
        if [ -f "$PROJECT_DIR/$script" ]; then
            if [ ! -x "$PROJECT_DIR/$script" ]; then
                chmod +x "$PROJECT_DIR/$script"
                echo -e "${YELLOW}🔧 已添加執行權限: $script${NC}"
                log "Added execute permission: $script"
            else
                echo -e "${GREEN}✅ 腳本權限正確: $script${NC}"
            fi
        fi
    done
    echo ""
}

# 清理過期的 QR Code
cleanup_expired_qr() {
    print_section "清理過期 QR Code"
    
    if [ -x "$SCRIPT_DIR/qr-cleanup.sh" ]; then
        echo -e "${BLUE}🧹 執行 QR Code 清理...${NC}"
        "$SCRIPT_DIR/qr-cleanup.sh"
        echo -e "${GREEN}✅ QR Code 清理完成${NC}"
    else
        echo -e "${YELLOW}⚠️  QR Code 清理腳本不存在或無執行權限${NC}"
    fi
    echo ""
}

# 優化日誌檔案
optimize_logs() {
    print_section "優化日誌檔案"
    
    local log_dir="$PROJECT_DIR/logs"
    local rotated_count=0
    
    # 輪轉大於 10MB 的日誌檔案
    find "$log_dir" -name "*.log" -size +10M 2>/dev/null | while read -r logfile; do
        if [ -f "$logfile" ]; then
            local timestamp=$(date +%Y%m%d_%H%M%S)
            local backup_name="${logfile}.${timestamp}"
            mv "$logfile" "$backup_name"
            touch "$logfile"
            echo -e "${YELLOW}📄 已輪轉大日誌檔案: $(basename "$logfile")${NC}"
            log "Rotated large log file: $logfile"
            ((rotated_count++))
        fi
    done
    
    # 清理超過 30 天的舊日誌
    local old_logs=$(find "$log_dir" -name "*.log.*" -mtime +30 2>/dev/null | wc -l)
    if [ "$old_logs" -gt 0 ]; then
        find "$log_dir" -name "*.log.*" -mtime +30 -delete 2>/dev/null
        echo -e "${YELLOW}🗑️  已清理 $old_logs 個超過30天的舊日誌${NC}"
        log "Cleaned up $old_logs old log files"
    fi
    
    echo -e "${GREEN}✅ 日誌優化完成${NC}"
    echo ""
}

# 檢查 Docker 配置
check_docker_config() {
    print_section "檢查 Docker 配置"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker 未安裝${NC}"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker 服務未運行或權限不足${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Docker 配置正常${NC}"
    
    # 檢查 docker-compose.yml
    if [ -f "$PROJECT_DIR/docker-compose.yml" ]; then
        if docker-compose -f "$PROJECT_DIR/docker-compose.yml" config &> /dev/null; then
            echo -e "${GREEN}✅ docker-compose.yml 語法正確${NC}"
        else
            echo -e "${RED}❌ docker-compose.yml 語法錯誤${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ docker-compose.yml 檔案不存在${NC}"
        return 1
    fi
    echo ""
}

# 驗證環境配置
validate_environment() {
    print_section "驗證環境配置"
    
    if [ ! -f "$PROJECT_DIR/.env" ]; then
        echo -e "${YELLOW}⚠️  .env 檔案不存在，建議從 env.example 複製${NC}"
        return 1
    fi
    
    # 檢查必要的環境變數
    local required_vars=("CLOUDFLARE_API_TOKEN" "CLOUDFLARE_ZONE_ID" "DOMAIN_NAME")
    local missing_vars=()
    
    source "$PROJECT_DIR/.env"
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ 環境配置完整${NC}"
    else
        echo -e "${YELLOW}⚠️  缺少環境變數: ${missing_vars[*]}${NC}"
    fi
    echo ""
}

# 生成優化報告
generate_report() {
    print_section "生成優化報告"
    
    local report_file="$PROJECT_DIR/logs/optimization-report-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "QWV 專案優化報告"
        echo "生成時間: $(date)"
        echo "專案路徑: $PROJECT_DIR"
        echo ""
        echo "=== 專案狀態 ==="
        echo "Docker 狀態: $(docker info &> /dev/null && echo "正常" || echo "異常")"
        echo ".env 檔案: $([ -f "$PROJECT_DIR/.env" ] && echo "存在" || echo "不存在")"
        echo "腳本權限: $([ -x "$SCRIPT_DIR/manage.sh" ] && echo "正常" || echo "異常")"
        echo ""
        echo "=== 目錄結構 ==="
        find "$PROJECT_DIR" -maxdepth 2 -type d | sort
        echo ""
        echo "=== QR Code 狀態 ==="
        if [ -d "$PROJECT_DIR/config" ]; then
            find "$PROJECT_DIR/config" -name ".qr_expiry" | wc -l | xargs echo "活躍 QR Code 數量:"
        fi
        echo ""
        echo "=== 日誌檔案 ==="
        find "$PROJECT_DIR/logs" -name "*.log" -exec ls -lh {} \; 2>/dev/null || echo "無日誌檔案"
    } > "$report_file"
    
    echo -e "${GREEN}📄 優化報告已保存: $report_file${NC}"
    echo ""
}

# 主函數
main() {
    # 確保日誌目錄存在
    mkdir -p "$(dirname "$LOG_FILE")"
    
    print_header
    log "Starting project optimization"
    
    echo -e "${PURPLE}🔍 開始專案優化檢查...${NC}"
    echo ""
    
    # 執行各項檢查
    check_project_structure
    check_file_permissions
    cleanup_expired_qr
    optimize_logs
    check_docker_config
    validate_environment
    generate_report
    
    echo -e "${GREEN}🎉 專案優化完成！${NC}"
    echo -e "${CYAN}📋 完整報告請查看日誌: $LOG_FILE${NC}"
    echo -e "${CYAN}🔧 如需更多幫助，請運行: ./scripts/manage.sh --help${NC}"
    echo ""
    
    log "Project optimization completed successfully"
}

# 執行主函數
main "$@" 