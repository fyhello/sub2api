#!/bin/bash
set -e

echo "=========================================="
echo "Sub2API 部署脚本 (Zima 专用)"
echo "=========================================="
echo ""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 root 权限运行此脚本：sudo $0"
    exit 1
fi

# 1. 安装 Docker 和 Docker Compose
echo "[1/6] 检查并安装 Docker..."
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，正在安装..."
    
    # 检测系统类型并安装 Docker
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu 系统
        apt-get update
        apt-get install -y ca-certificates curl gnupg lsb-release
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    elif [ -f /etc/redhat-release ]; then
        # RHEL/CentOS/Fedora 系统
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl start docker
        systemctl enable docker
    else
        # 使用通用安装脚本
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
    fi
    
    echo "Docker 安装完成！"
else
    echo "Docker 已安装，版本：$(docker --version)"
fi

# 检查 Docker Compose
echo ""
echo "[2/6] 检查 Docker Compose..."
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Docker Compose 未找到，正在安装..."
    # 尝试安装 Docker Compose 插件
    apt-get install -y docker-compose-plugin 2>/dev/null || yum install -y docker-compose-plugin 2>/dev/null || true
fi
echo "Docker Compose 检查完成"

# 2. 创建部署目录
echo ""
echo "[3/6] 创建部署目录..."
mkdir -p /opt/sub2api-deploy
cd /opt/sub2api-deploy

# 3. 下载部署文件
echo ""
echo "[4/6] 下载部署配置文件..."
curl -sSL https://raw.githubusercontent.com/Wei-Shaw/sub2api/main/deploy/docker-deploy.sh -o docker-deploy.sh
chmod +x docker-deploy.sh

# 运行部署准备脚本
echo ""
echo "[5/6] 准备部署配置..."
./docker-deploy.sh

# 4. 启动服务
echo ""
echo "[6/6] 启动 Sub2API 服务..."
docker compose up -d

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "请等待 1-2 分钟让服务完全启动，然后访问："
echo "http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "有用的命令："
echo "  查看日志：    docker compose -f /opt/sub2api-deploy/docker-compose.yml logs -f sub2api"
echo "  重启服务：    docker compose -f /opt/sub2api-deploy/docker-compose.yml restart"
echo "  停止服务：    docker compose -f /opt/sub2api-deploy/docker-compose.yml down"
echo ""
echo "如果管理员密码是自动生成的，可以通过以下命令查看："
echo "  docker compose -f /opt/sub2api-deploy/docker-compose.yml logs sub2api | grep \"admin password\""
echo ""
