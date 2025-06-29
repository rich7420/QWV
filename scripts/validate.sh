#!/bin/bash

# QWV VPN 專案驗證腳本
# 用於 GitHub Actions 和本地部署前的完整檢查

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}QWV VPN 專案驗證工具${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_section() {
    echo -e "${BLUE}📋 $1${NC}"
    echo "----------------------------"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

validate_files() {
    print_section "檔案結構驗證"
    
    local required_files=(
        "docker-compose.yml"
        "env.example"
        "scripts/setup.sh"
        "scripts/manage.sh"
        "README.md"
        "docs/TESTING.md"
        "docs/MULTI-ENVIRONMENT.md"
        ".gitignore"
        ".github/workflows/deploy.yml"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "$file 存在"
        else
            print_error "$file 缺失"
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        print_success "所有必要檔案都存在"
    else
        print_error "缺少 ${#missing_files[@]} 個必要檔案"
        return 1
    fi
    echo ""
}

validate_docker_compose() {
    print_section "Docker Compose 語法驗證"
    
    if command -v docker >/dev/null 2>&1; then
        if docker compose config >/dev/null 2>&1; then
            print_success "docker-compose.yml 語法正確"
        else
            print_error "docker-compose.yml 語法錯誤"
            docker compose config
            return 1
        fi
    else
        print_warning "Docker 未安裝，跳過語法檢查"
    fi
    echo ""
}

validate_scripts() {
    print_section "腳本語法驗證"
    
    local scripts=(
        "scripts/setup.sh"
        "scripts/manage.sh"
        "scripts/validate.sh"
    )
    
    if command -v shellcheck >/dev/null 2>&1; then
        for script in "${scripts[@]}"; do
            if [ -f "$script" ]; then
                if shellcheck "$script" >/dev/null 2>&1; then
                    print_success "$script 語法正確"
                else
                    print_error "$script 語法錯誤"
                    shellcheck "$script"
                    return 1
                fi
            fi
        done
    else
        print_warning "shellcheck 未安裝，跳過腳本語法檢查"
        # 基本語法檢查
        for script in "${scripts[@]}"; do
            if [ -f "$script" ]; then
                if bash -n "$script" 2>/dev/null; then
                    print_success "$script 基本語法正確"
                else
                    print_error "$script 語法錯誤"
                    bash -n "$script"
                    return 1
                fi
            fi
        done
    fi
    echo ""
}

validate_env_template() {
    print_section "環境變數模板驗證"
    
    if [ -f "env.example" ]; then
        print_success "env.example 存在"
        
        # 檢查必要變數
        local required_vars=(
            "CF_API_TOKEN"
            "CF_ZONE"
            "CF_SUBDOMAIN"
        )
        
        for var in "${required_vars[@]}"; do
            if grep -q "^${var}=" env.example; then
                print_success "$var 變數已定義"
            else
                print_error "$var 變數缺失"
                return 1
            fi
        done
    else
        print_error "env.example 檔案不存在"
        return 1
    fi
    echo ""
}

validate_github_workflow() {
    print_section "GitHub Actions 工作流程驗證"
    
    local workflow_file=".github/workflows/deploy.yml"
    
    if [ -f "$workflow_file" ]; then
        print_success "GitHub Actions 工作流程檔案存在"
        
        # 檢查必要的 secrets 引用
        local required_secrets=(
            "VPN_HOST"
            "VPN_USER"
            "VPN_SSH_KEY"
            "VPN_DEPLOY_PATH"
            "CF_API_TOKEN"
            "CF_ZONE"
            "CF_SUBDOMAIN"
        )
        
        for secret in "${required_secrets[@]}"; do
            if grep -q "secrets\.$secret" "$workflow_file"; then
                print_success "$secret secret 已引用"
            else
                print_warning "$secret secret 未被引用（可能為可選項目）"
            fi
        done
        
        # 檢查 YAML 語法（如果有 yq 工具）
        if command -v yq >/dev/null 2>&1; then
            if yq eval '.' "$workflow_file" >/dev/null 2>&1; then
                print_success "GitHub Actions YAML 語法正確"
            else
                print_error "GitHub Actions YAML 語法錯誤"
                return 1
            fi
        fi
    else
        print_error "GitHub Actions 工作流程檔案不存在"
        return 1
    fi
    echo ""
}

validate_documentation() {
    print_section "文檔完整性檢查"
    
    # 檢查 README.md
    if [ -f "README.md" ]; then
        print_success "README.md 存在"
        
        # 檢查關鍵章節
        local required_sections=(
            "快速開始"
            "安裝指南"
            "設定說明"
            "故障排除"
        )
        
        for section in "${required_sections[@]}"; do
            if grep -q "$section" README.md; then
                print_success "README.md 包含「$section」章節"
            else
                print_warning "README.md 缺少「$section」章節"
            fi
        done
    else
        print_error "README.md 不存在"
        return 1
    fi
    
    # 檢查測試文檔
    if [ -f "docs/TESTING.md" ]; then
        print_success "TESTING.md 存在於 docs/ 目錄"
    else
        print_warning "TESTING.md 不存在於 docs/ 目錄"
    fi
    echo ""
}

validate_security() {
    print_section "安全性檢查"
    
    # 檢查 .gitignore
    if [ -f ".gitignore" ]; then
        print_success ".gitignore 存在"
        
        # 檢查是否忽略敏感檔案
        local sensitive_patterns=(
            ".env"
            "config/"
            "backup/"
            "logs/"
            "*.key"
            "*.pem"
        )
        
        for pattern in "${sensitive_patterns[@]}"; do
            if grep -q "$pattern" .gitignore; then
                print_success "已忽略敏感檔案模式: $pattern"
            else
                print_warning "未忽略敏感檔案模式: $pattern"
            fi
        done
    else
        print_error ".gitignore 檔案不存在"
        return 1
    fi
    
    # 檢查是否意外提交了敏感檔案
    if [ -f ".env" ]; then
        print_warning ".env 檔案存在（確保未提交到 Git）"
    fi
    
    if [ -d "config" ]; then
        print_warning "config 目錄存在（確保未提交到 Git）"
    fi
    echo ""
}

generate_report() {
    print_section "驗證報告"
    
    echo "專案驗證完成！"
    echo ""
    echo "下一步建議："
    echo "1. 如果這是首次部署，請執行: ./scripts/setup.sh"
    echo "2. 複製 env.example 為 .env 並填入您的設定"
    echo "3. 設定 GitHub Secrets 以啟用自動部署"
    echo "4. 執行: ./scripts/manage.sh start"
    echo ""
}

main() {
    print_header
    
    local exit_code=0
    
    validate_files || exit_code=1
    validate_docker_compose || exit_code=1
    validate_scripts || exit_code=1
    validate_env_template || exit_code=1
    validate_github_workflow || exit_code=1
    validate_documentation || exit_code=1
    validate_security || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        generate_report
        print_success "所有驗證通過！專案已準備就緒"
    else
        print_error "驗證過程中發現問題，請修正後重新執行"
    fi
    
    exit $exit_code
}

# 如果直接執行此腳本
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi 