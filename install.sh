#!/bin/bash

# OpenClaw 安全安装脚本
# 版本: 3.0
# 使用方法: curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash
# 下载: curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh -o install.sh

set -euo pipefail

# ==================== 安全强化 ====================
# 设置安全的文件权限
umask 077

# ==================== 配置 ====================
readonly SCRIPT_VERSION="3.0"
readonly SCRIPT_URL="https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh"
readonly SCRIPT_SHA256_URL="${SCRIPT_URL}.sha256"

# 颜色定义
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# 全局配置（支持环境变量和配置文件）
readonly DEBUG="${DEBUG:-0}"
readonly AUTO_ACCEPT="${AUTO_ACCEPT:-0}"
readonly SKIP_TAILSCALE="${SKIP_TAILSCALE:-0}"
readonly SKIP_DOCKER="${SKIP_DOCKER:-0}"
readonly LLM_PROVIDER="${LLM_PROVIDER:-minimax}"
readonly INSTALL_DIR="${INSTALL_DIR:-$HOME/.openclaw}"
readonly VERBOSE="${VERBOSE:-0}"
readonly DRY_RUN="${DRY_RUN:-0}"
INSTALL_MODE="${INSTALL_MODE:-native}"  # native | docker

# 配置文件路径
readonly CONFIG_FILE="${CONFIG_FILE:-$HOME/.openclaw/install.conf}"

# ==================== 日志函数 ====================
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 详细模式下显示更多调试信息
    if [[ "${VERBOSE}" == "1" ]] && [[ "$level" == "DEBUG" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $message"
    fi
    
    case "$level" in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "SUCCESS")
            echo -e "${GREEN}[OK]${NC} $message"
            ;;
    esac
    
    # 写入日志文件
    local log_dir="${INSTALL_DIR}/logs"
    mkdir -p "$log_dir"
    local log_file="$log_dir/install_$(date +%Y%m%d).log"
    echo "[$timestamp] [$level] $message" >> "$log_file" 2>/dev/null || true
}

# 错误处理函数
error_exit() {
    log "ERROR" "$1"
    log "ERROR" "安装失败，请查看文档: https://openclaw.ai/docs"
    exit "${2:-1}"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" &> /dev/null
}

# ==================== 参数解析 ====================
show_help() {
    cat << EOF
OpenClaw 安全安装脚本 v${SCRIPT_VERSION}

用法: 
  curl -fsSL $SCRIPT_URL | bash [选项]
  curl -fsSL $SCRIPT_URL -o install.sh && bash install.sh [选项]

选项:
  -h, --help              显示帮助信息
  -v, --verbose           详细输出模式
  -n, --dry-run           模拟运行（不执行实际操作）
  --mode MODE             安装模式: native | docker (默认: native)
  --config FILE           配置文件路径
  --uninstall             卸载 OpenClaw

环境变量:
  DEBUG=1                 启用调试模式
  AUTO_ACCEPT=1           自动确认所有提示
  VERBOSE=1               详细输出
  DRY_RUN=1               模拟运行
  SKIP_TAILSCALE=1        跳过 Tailscale 安装
  SKIP_DOCKER=1           跳过 Docker 模式选项
  LLM_PROVIDER=<name>     LLM提供商 (minimax/claude/gpt/ollama)
  INSTALL_DIR=<path>      安装目录

配置文件格式 (${CONFIG_FILE}):
  LLM_PROVIDER=minimax
  AUTO_ACCEPT=1
  SKIP_TAILSCALE=1

示例:
  # 标准安装
  curl -fsSL $SCRIPT_URL | bash

  # Docker 模式安装
  curl -fsSL $SCRIPT_URL | bash -- --mode docker

  # 模拟运行检查
  DRY_RUN=1 curl -fsSL $SCRIPT_URL | bash

  # 使用配置文件
  curl -fsSL $SCRIPT_URL | bash -- --config /path/to/config
EOF
    exit 0
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                ;;
            -v|--verbose)
                export VERBOSE=1
                shift
                ;;
            -n|--dry-run)
                export DRY_RUN=1
                log "INFO" "🚧 模拟运行模式 - 不会执行实际操作"
                shift
                ;;
            --mode)
                export INSTALL_MODE="$2"
                shift 2
                ;;
            --config)
                export CONFIG_FILE="$2"
                shift 2
                ;;
            --uninstall)
                uninstall_openclaw
                exit 0
                ;;
            *)
                log "WARN" "未知参数: $1"
                shift
                ;;
        esac
    done
}

# 加载配置文件
load_config() {
    if [[ -f "${CONFIG_FILE}" ]]; then
        log "INFO" "加载配置文件: ${CONFIG_FILE}"
        # shellcheck source=/dev/null
        source "${CONFIG_FILE}"
    fi
}

# ==================== 安全检查 ====================
check_security() {
    log "INFO" "🔒 执行安全检查..."
    
    # 检查 Bash 版本 (Shellshock 漏洞)
    local bash_version
    bash_version=$(bash --version | head -1 | grep -oP '\d+\.\d+')
    local major minor
    major=$(echo "$bash_version" | cut -d. -f1)
    minor=$(echo "$bash_version" | cut -d. -f2)
    
    if [[ "$major" -lt 4 ]]; then
        error_exit "Bash 版本过低 ($bash_version)，存在安全风险"
    elif [[ "$major" -eq 4 ]] && [[ "$minor" -lt 1 ]]; then
        log "WARN" "Bash 4.1 以下版本存在 Shellshock 漏洞风险"
    else
        log "SUCCESS" "Bash 版本检查通过: $bash_version"
    fi
    
    # 检查是否为 root 用户（不推荐生产环境使用 root）
    if [[ "$EUID" -eq 0 ]]; then
        log "WARN" "检测到 root 用户运行，生产环境建议使用非 root 用户"
    fi
    
    # 检查脚本来源
    if [[ -z "${CURL_EXECUTION:-}" ]]; then
        log "WARN" "建议通过 curl 执行: curl -fsSL $SCRIPT_URL | bash"
    fi
    
    log "SUCCESS" "安全检查完成"
}

# 验证脚本完整性
verify_script() {
    log "INFO" "🔐 验证脚本完整性..."
    
    # 尝试下载 SHA256 校验和
    if curl -fsSL "${SCRIPT_SHA256_URL}" -o /tmp/install.sh.sha256 2>/dev/null; then
        if command_exists sha256sum; then
            if echo "$(cat /tmp/install.sh.sha256)" | sha256sum -c - > /dev/null 2>&1; then
                log "SUCCESS" "脚本完整性验证通过"
            else
                log "WARN" "脚本完整性验证失败（校验和不匹配）"
            fi
        elif command_exists shasum; then
            if shasum -a 256 -c /tmp/install.sh.sha256 > /dev/null 2>&1; then
                log "SUCCESS" "脚本完整性验证通过"
            else
                log "WARN" "脚本完整性验证失败"
            fi
        fi
        rm -f /tmp/install.sh.sha256
    else
        log "WARN" "无法下载校验和文件，跳过完整性验证"
    fi
}

# 确认对话框
confirm() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "${DRY_RUN}" == "1" ]]; then
        log "INFO" "[模拟] 确认: $message"
        return 0
    fi
    
    if [[ "${AUTO_ACCEPT}" == "1" ]]; then
        log "INFO" "自动确认: $message"
        return 0
    fi
    
    local response
    if [[ "$default" == "y" ]]; then
        read -p "$message [Y/n]: " -r response
        response="${response:-y}"
    else
        read -p "$message [y/N]: " -r response
        response="${response:-n}"
    fi
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# 等待用户按键
wait_for_key() {
    if [[ "${DRY_RUN}" == "1" ]] || [[ "${AUTO_ACCEPT}" == "1" ]]; then
        return
    fi
    
    if [[ -t 0 ]]; then
        log "INFO" "按任意键继续（Ctrl+C退出）..."
        read -n 1 -s -r
        echo
    else
        log "INFO" "非交互式环境，自动继续..."
    fi
}

# ==================== 显示函数 ====================
show_banner() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${PURPLE}  OpenClaw 安全安装 v${SCRIPT_VERSION}${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo -e "${CYAN}🚀 AI 助手 | 🔒 安全部署 | 🌐 跨平台支持${NC}"
    echo
    echo -e "${YELLOW}⚡ 支持模式: ${INSTALL_MODE^^} ${NC}"
    echo -e "${YELLOW}⚡ LLM 提供商: ${LLM_PROVIDER} ${NC}"
    echo -e "${YELLOW}🔧 系统支持: Ubuntu 20.04+ | Debian 11+${NC}"
    echo
}

# ==================== 系统检测 ====================
detect_system() {
    local uname_s
    uname_s="$(uname -s)"
    local os="unknown"
    
    case "$uname_s" in
        "Linux")
            if [[ -f "/etc/lsb-release" ]]; then
                local ubuntu_version
                ubuntu_version=$(grep "DISTRIB_RELEASE" /etc/lsb-release | cut -d'=' -f2)
                if [[ $(echo "$ubuntu_version" | cut -d'.' -f1) -lt 20 ]]; then
                    error_exit "不支持的 Ubuntu 版本：$ubuntu_version（需要 20.04+）"
                fi
                os="ubuntu"
                log "INFO" "检测到系统: Ubuntu $ubuntu_version"
            else
                # 检查其他 Linux 发行版
                if [[ -f "/etc/os-release" ]]; then
                    local os_id
                    os_id=$(grep "^ID=" /etc/os-release | cut -d'"' -f2)
                    case "$os_id" in
                        debian|fedora|centos|arch)
                            os="$os_id"
                            log "INFO" "检测到系统: $os_id (实验性支持)"
                            ;;
                        *)
                            error_exit "不支持的 Linux 发行版"
                            ;;
                    esac
                else
                    error_exit "不支持的 Linux 发行版"
                fi
            fi
            ;;
        *)
            error_exit "不支持的系统：$uname_s"
            ;;
    esac
    
    echo "$os"
}

# ==================== 前置条件检查 ====================
check_prerequisites() {
    log "INFO" "检查前置条件..."
    
    # 检查网络连接
    log "INFO" "检查网络连接..."
    if ! curl -s --connect-timeout 5 https://api.minimax.chat &> /dev/null; then
        log "WARN" "网络连接异常"
    else
        log "SUCCESS" "网络连接正常"
    fi
    
    # 检查磁盘空间（至少需要 2GB）
    local available_space
    available_space=$(df . | awk 'NR==2 {print $4}')
    local required_space=2097152
    
    if [[ $available_space -lt $required_space ]]; then
        error_exit "磁盘空间不足，至少需要 2GB"
    fi
    
    log "SUCCESS" "前置条件检查通过"
    log "INFO" "可用磁盘空间: $((available_space / 1024 / 1024)) GB"
}

# ==================== Docker 模式 ====================
check_docker() {
    if ! command_exists docker; then
        return 1
    fi
    
    if ! docker ps &> /dev/null; then
        return 1
    fi
    
    return 0
}

install_docker() {
    log "INFO" "安装 Docker..."
    
    local os="$1"
    
    case "$os" in
        "ubuntu"|"debian")
            curl -fsSL https://get.docker.com | sh
            sudo usermod -aG docker "$USER"
            log "SUCCESS" "Docker 安装完成，请重新登录以应用用户组"
            ;;
    esac
}

run_docker_install() {
    log "INFO" "🚀 开始 Docker 模式安装..."
    
    if ! check_docker; then
        if confirm "Docker 未安装或未运行，是否安装 Docker？" "y"; then
            install_docker "ubuntu"
        else
            error_exit "Docker 是必需的"
        fi
    fi
    
    # 拉取官方镜像
    log "INFO" "拉取 OpenClaw 官方镜像..."
    if [[ "${DRY_RUN}" != "1" ]]; then
        docker pull alpine/openclaw:latest
    fi
    
    # 创建配置目录
    mkdir -p "$HOME/.openclaw"
    
    # 启动容器
    log "INFO" "启动 OpenClaw 容器..."
    if [[ "${DRY_RUN}" != "1" ]]; then
        docker run -d \
            --name openclaw \
            --restart unless-stopped \
            -p 18789:18789 \
            -v "$HOME/.openclaw:/home/node/.openclaw" \
            alpine/openclaw:latest
    fi
    
    log "SUCCESS" "Docker 模式安装完成"
    show_docker_guide
}

show_docker_guide() {
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}        🎉 Docker 安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${CYAN}📋 后续步骤:${NC}"
    echo "1. 启动容器: docker start openclaw"
    echo "2. 查看日志: docker logs -f openclaw"
    echo "3. 访问控制台: http://localhost:18789"
    echo "4. 获取 Token: docker exec openclaw openclaw token"
    echo
    echo -e "${CYAN}🔧 常用命令:${NC}"
    echo "  docker start openclaw    # 启动"
    echo "  docker stop openclaw     # 停止"
    echo "  docker restart openclaw  # 重启"
    echo "  docker logs -f openclaw # 查看日志"
    echo
}

# ==================== 原生模式安装 ====================
install_dependencies() {
    local os="$1"
    log "INFO" "安装系统依赖..."
    
    case "$os" in
        "ubuntu"|"debian")
            log "INFO" "更新系统包..."
            sudo apt update && sudo apt upgrade -y
            
            log "INFO" "安装基础工具..."
            sudo apt install -y curl wget git ufw unattended-upgrades
            
            # 配置自动安全更新
            echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true' | sudo debconf-set-selections
            sudo dpkg-reconfigure -f noninteractive unattended-upgrades
            ;;
        "fedora"|"centos")
            sudo dnf install -y curl wget git ufw
            ;;
    esac
    
    log "SUCCESS" "系统依赖安装完成"
}

configure_network_security() {
    local os="$1"
    
    if [[ "${SKIP_TAILSCALE}" == "1" ]]; then
        log "INFO" "跳过 Tailscale 配置"
        return
    fi
    
    log "INFO" "配置网络安全..."
    
    # 安装 Tailscale
    if ! command_exists tailscale; then
        log "INFO" "安装 Tailscale..."
        if ! curl -fsSL https://tailscale.com/install.sh | sh; then
            log "WARN" "Tailscale 安装失败"
        else
            log "SUCCESS" "Tailscale 安装完成"
            echo "请运行: sudo tailscale up"
        fi
    fi
    
    configure_firewall "$os"
}

configure_firewall() {
    local os="$1"
    log "INFO" "配置防火墙..."
    
    case "$os" in
        "ubuntu"|"debian")
            sudo ufw --force reset
            sudo ufw default deny incoming
            sudo ufw default allow outgoing
            
            if command_exists tailscale && ip link show tailscale0 &> /dev/null; then
                sudo ufw allow in on tailscale0 to any port 22
            fi
            
            sudo ufw --force enable
            sudo ufw --force status
            ;;
    esac
    
    log "SUCCESS" "防火墙配置完成"
}

install_nodejs() {
    log "INFO" "安装 Node.js 24..."
    
    # 安装 nvm
    if ! command_exists nvm; then
        log "INFO" "安装 nvm..."
        export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.nvm}"
        if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash; then
            error_exit "nvm 安装失败"
        fi
        
        # 加载 nvm
        # shellcheck source=/dev/null
        source "$NVM_DIR/nvm.sh" 2>/dev/null || true
    fi
    
    # 安装 Node.js
    export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.nvm}"
    # shellcheck source=/dev/null
    source "$NVM_DIR/nvm.sh" 2>/dev/null || true
    
    if command_exists nvm; then
        nvm install 24 || error_exit "Node.js 安装失败"
        nvm use 24
        nvm alias default 24
        
        local node_version
        node_version=$(node --version)
        log "SUCCESS" "Node.js 安装成功: $node_version"
    else
        error_exit "nvm 不可用"
    fi
}

install_openclaw() {
    log "INFO" "安装 OpenClaw..."
    
    if command_exists openclaw; then
        log "INFO" "OpenClaw 已安装: $(openclaw --version 2>/dev/null || echo "unknown")"
        return
    fi
    
    # 从 npm 安装
    if npm install -g @openclaw/cli 2>/dev/null; then
        log "SUCCESS" "从 npm 安装成功"
    elif [[ "${DRY_RUN}" != "1" ]]; then
        error_exit "OpenClaw 安装失败"
    fi
    
    # 验证安装
    if command_exists openclaw; then
        local version
        version=$(openclaw --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "OpenClaw 安装成功: $version"
    elif [[ "${DRY_RUN}" != "1" ]]; then
        error_exit "OpenClaw 验证失败"
    fi
}

initialize_openclaw() {
    log "INFO" "初始化 OpenClaw..."
    
    echo
    log "INFO" "LLM 提供商: ${LLM_PROVIDER}"
    
    case "${LLM_PROVIDER}" in
        "minimax")
            echo "📝 MiniMax: https://api.minimax.chat/"
            ;;
        "claude")
            echo "📝 Claude: https://console.anthropic.com/"
            ;;
        "gpt")
            echo "📝 OpenAI: https://platform.openai.com/"
            ;;
        "ollama")
            echo "📝 Ollama: 本地模型 (http://localhost:11434)"
            ;;
    esac
    echo
    
    if [[ "${AUTO_ACCEPT}" == "1" ]] || [[ "${DRY_RUN}" == "1" ]]; then
        log "INFO" "跳过交互式初始化"
        return
    fi
    
    if confirm "是否现在配置 LLM 提供商？" "y"; then
        if openclaw onboard; then
            log "SUCCESS" "OpenClaw 初始化完成"
        else
            log "WARN" "初始化失败，可稍后执行: openclaw onboard"
        fi
    fi
}

install_plugins_security() {
    log "INFO" "安装插件和安全配置..."
    
    if ! command_exists openclaw; then
        log "WARN" "OpenClaw 未安装，跳过插件安装"
        return
    fi
    
    # 安装安全技能
    log "INFO" "安装安全防护技能..."
    for skill in "skillguard" "prompt-guard"; do
        if npx clawhub install "$skill" 2>/dev/null; then
            log "SUCCESS" "安全技能 $skill 安装成功"
        else
            log "WARN" "安全技能 $skill 安装失败"
        fi
    done
    
    # 设置文件权限
    if [[ -d "$HOME/.openclaw" ]]; then
        chmod 700 "$HOME/.openclaw"
        find "$HOME/.openclaw" -name "*.json" -type f -exec chmod 600 {} \; 2>/dev/null || true
        find "$HOME/.openclaw" -name "*.key" -type f -exec chmod 600 {} \; 2>/dev/null || true
        log "SUCCESS" "文件权限设置完成"
    fi
    
    # 禁用 mDNS
    local shell_config="$HOME/.zshrc"
    [[ -f "$HOME/.bashrc" ]] && shell_config="$HOME/.bashrc"
    
    if ! grep -q "OPENCLAW_DISABLE_BONJOUR" "$shell_config" 2>/dev/null; then
        echo 'export OPENCLAW_DISABLE_BONJOUR=1' >> "$shell_config"
    fi
    
    export OPENCLAW_DISABLE_BONJOUR=1
    log "SUCCESS" "安全配置完成"
}

# ==================== 系统服务 ====================
create_service() {
    local os="$1"
    log "INFO" "创建系统服务..."
    
    local openclaw_path
    openclaw_path=$(which openclaw 2>/dev/null || echo "$HOME/.nvm/versions/node/v*/bin/openclaw")
    local log_dir="$HOME/.openclaw/logs"
    
    mkdir -p "$log_dir"
    
    case "$os" in
        "ubuntu"|"debian")
            local service_file="/etc/systemd/system/openclaw.service"
            
            sudo tee "$service_file" > /dev/null << EOF
[Unit]
Description=OpenClaw AI Assistant
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$HOME
ExecStart=$openclaw_path start
Restart=on-failure
RestartSec=10
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$HOME/.openclaw
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
            
            sudo systemctl daemon-reload 2>/dev/null || log "WARN" "服务重载失败"
            sudo systemctl enable openclaw 2>/dev/null || log "WARN" "服务启用失败"
            ;;
    esac
    
    log "SUCCESS" "系统服务配置完成"
}

# ==================== 卸载功能 ====================
uninstall_openclaw() {
    echo -e "${RED}⚠️  确认卸载 OpenClaw？${NC}"
    
    if ! confirm "此操作将删除所有配置和数据，是否继续？" "n"; then
        log "INFO" "取消卸载"
        exit 0
    fi
    
    log "INFO" "开始卸载 OpenClaw..."
    
    # 停止服务
    if command_exists openclaw; then
        openclaw stop 2>/dev/null || true
    fi
    
    # 删除服务
    case "$(detect_system)" in
        "ubuntu"|"debian")
            sudo systemctl stop openclaw 2>/dev/null || true
            sudo systemctl disable openclaw 2>/dev/null || true
            sudo rm -f /etc/systemd/system/openclaw.service
            ;;
    esac
    
    # 删除文件
    rm -rf "$HOME/.openclaw"
    rm -rf "$HOME/.nvm/versions/node" # 可选
    
    # 删除 npm 全局包
    npm uninstall -g @openclaw/cli 2>/dev/null || true
    
    log "SUCCESS" "OpenClaw 卸载完成"
}

# ==================== 健康检查 ====================
run_healthcheck() {
    log "INFO" "🔍 运行健康检查..."
    
    local issues=0
    
    # 检查服务状态
    if command_exists openclaw; then
        if openclaw status &> /dev/null; then
            log "SUCCESS" "OpenClaw 服务运行中"
        else
            log "WARN" "OpenClaw 服务未运行"
            ((issues++))
        fi
    else
        log "WARN" "OpenClaw 未安装"
        ((issues++))
    fi
    
    # 检查网络
    if curl -s --connect-timeout 3 https://api.minimax.chat &> /dev/null; then
        log "SUCCESS" "网络连接正常"
    else
        log "WARN" "网络连接异常"
        ((issues++))
    fi
    
    if [[ $issues -eq 0 ]]; then
        log "SUCCESS" "健康检查通过"
    else
        log "WARN" "发现 $issues 个问题"
    fi
}

# ==================== 辅助工具安装 ====================
install_clawdock() {
    log "INFO" "安装 ClawDock 辅助工具..."
    
    mkdir -p "$HOME/.clawdock"
    
    if curl -fsSL https://raw.githubusercontent.com/openclaw/openclaw/main/scripts/shell-helpers/clawdock-helpers.sh \
        -o "$HOME/.clawdock/clawdock-helpers.sh"; then
        
        local shell_config="$HOME/.zshrc"
        [[ -f "$HOME/.bashrc" ]] && shell_config="$HOME/.bashrc"
        
        if ! grep -q "clawdock-helpers.sh" "$shell_config"; then
            echo "source $HOME/.clawdock/clawdock-helpers.sh" >> "$shell_config"
        fi
        
        log "SUCCESS" "ClawDock 安装完成"
    else
        log "WARN" "ClawDock 安装失败"
    fi
}

# ==================== 完成指南 ====================
show_completion_guide() {
    local os="$1"
    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}        🎉 OpenClaw 安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${CYAN}🚀 快速开始:${NC}"
    echo "  openclaw gateway          # 启动网关"
    echo "  openclaw status          # 查看状态"
    echo "  openclaw onboard         # 配置 LLM"
    echo "  openclaw doctor          # 健康检查"
    echo
    echo -e "${CYAN}🔧 服务管理:${NC}"
    echo "  sudo systemctl start openclaw"
    echo "  sudo systemctl stop openclaw"
    echo
    echo -e "${CYAN}📚 文档:${NC}"
    echo "  https://openclaw.ai/docs"
    echo
    echo -e "${GREEN}✨ 感谢使用 OpenClaw！${NC}"
    echo
}

# ==================== 主函数 ====================
main() {
    # 解析参数
    parse_args "$@"
    
    # 加载配置
    load_config
    
    # 显示横幅
    show_banner
    
    # 安全检查
    check_security
    
    # 脚本验证
    verify_script
    
    # 显示配置信息
    if [[ "${DEBUG}" == "1" ]]; then
        log "INFO" "安装模式: ${INSTALL_MODE}"
        log "INFO" "LLM 提供商: ${LLM_PROVIDER}"
        log "INFO" "安装目录: ${INSTALL_DIR}"
    fi
    
    # 选择安装模式
    if [[ "${INSTALL_MODE}" == "docker" ]]; then
        if [[ "${SKIP_DOCKER}" != "1" ]]; then
            if confirm "是否使用 Docker 模式安装？" "y"; then
                run_docker_install
                return
            fi
        fi
    fi
    
    # 检测系统
    local os
    os=$(detect_system)
    
    # 检查前置条件
    check_prerequisites
    
    # 显示注意事项
    echo
    echo -e "${YELLOW}⚠️  安装前准备:${NC}"
    echo "  • 确保有稳定的网络连接"
    echo "  • 准备 LLM 提供商的 API 密钥"
    echo "  • 确保有管理员权限"
    echo
    
    wait_for_key
    
    # 执行安装步骤
    if [[ "${DRY_RUN}" != "1" ]]; then
        install_dependencies "$os"
        configure_network_security "$os"
        install_nodejs
        install_openclaw
        initialize_openclaw
        install_plugins_security
        create_service "$os"
        install_clawdock
    else
        log "INFO" "[模拟] install_dependencies $os"
        log "INFO" "[模拟] configure_network_security $os"
        log "INFO" "[模拟] install_nodejs"
        log "INFO" "[模拟] install_openclaw"
        log "INFO" "[模拟] initialize_openclaw"
        log "INFO" "[模拟] install_plugins_security"
        log "INFO" "[模拟] create_service $os"
        log "INFO" "[模拟] install_clawdock"
    fi
    
    # 显示完成指南
    show_completion_guide "$os"
    
    # 运行健康检查
    run_healthcheck
}

# ==================== 脚本入口 ====================
if [[ -n "${CURL_EXECUTION:-}" ]] || [[ "$(basename "$0")" == "bash" ]]; then
    export CURL_EXECUTION=1
    main "$@"
else
    log "ERROR" "请通过 curl 执行: curl -fsSL $SCRIPT_URL | bash"
    exit 1
fi
