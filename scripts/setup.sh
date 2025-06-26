#!/bin/bash

# QWV (QuickWireguardVpn) 伺服器初始設定腳本
# 根據規劃書第2部分的前置作業要求

set -e

echo "🚀 QWV - WireGuard VPN 伺服器設定腳本"
echo "========================================"

# 檢查是否為 root 用戶
if [[ $EUID -eq 0 ]]; then
   echo "❌ 請勿以 root 用戶執行此腳本，請使用一般用戶" 
   exit 1
fi

# 更新系統
echo "📦 更新系統套件..."
sudo apt update && sudo apt upgrade -y

# 安裝必要套件
echo "🔧 安裝必要套件..."
# 安裝 Docker 官方最新版本（包含 Compose V2）
echo "📦 安裝 Docker 官方版本..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# 安裝其他必要套件
echo "📦 安裝系統套件..."
sudo apt install -y curl wget ufw git

# 將當前用戶加入 docker 群組
echo "👤 設定 Docker 權限..."
sudo usermod -aG docker $USER

# 設定 UFW 防火牆
echo "🔥 設定防火牆..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 51820/udp
sudo ufw --force enable

# 啟用 IP 轉送
echo "🌐 啟用 IP 轉送..."
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 啟動並啟用 Docker 服務
echo "🐳 啟動 Docker 服務..."
sudo systemctl enable docker
sudo systemctl start docker

# 檢查 CGNAT
echo "🔍 檢查網路環境..."
echo "請手動檢查是否處於 CGNAT 環境："
echo "1. 登入路由器查看 WAN IP"
echo "2. 訪問 https://whatismyipaddress.com 查看公網 IP"
echo "3. 比較兩者是否相同"

# 建立專案目錄結構
echo "📁 建立專案目錄..."
mkdir -p config logs backup

echo "✅ 伺服器初始設定完成！"
echo ""
echo "接下來的步驟："
echo "1. 複製 env.example 為 .env 並填入您的設定"
echo "2. 確認沒有 CGNAT 問題"
echo "3. 設定路由器連接埠轉送（UDP 51820）"
echo "4. 執行 docker compose up -d 啟動服務"
echo ""
echo "⚠️  重要：請登出並重新登入以使 Docker 群組生效！" 