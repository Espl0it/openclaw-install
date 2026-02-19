# 安装指南

本文档说明 OpenClaw 的系统要求、安装方式与安装流程。

[← 返回 README](../README.md)

## 🚀 安全安装（推荐）

### 基础安装（原生模式）

```bash
curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash
```

### Docker 模式安装

```bash
# 方式1: 安装脚本（推荐）
curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash -s -- --mode docker

# 方式2: 手动部署
docker pull alpine/openclaw:latest
docker run -d --name openclaw -p 18789:18789 -v ~/.openclaw:/home/node/.openclaw alpine/openclaw:latest
```

详见 [Docker 部署指南](./docker.md)

### 高级安装选项

```bash
# 自动安装（无交互）
AUTO_ACCEPT=1 curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash

# 模拟运行（检查环境）
DRY_RUN=1 curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash

# 详细输出模式
VERBOSE=1 curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash

# 选择 LLM 提供商
LLM_PROVIDER=claude curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash

# 跳过 Tailscale 安装
SKIP_TAILSCALE=1 curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash

# 使用配置文件
curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash -s -- --config /path/to/config

# 组合选项
AUTO_ACCEPT=1 LLM_PROVIDER=minimax VERBOSE=1 curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash
```

### 卸载 OpenClaw

```bash
# 使用安装脚本卸载
curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash -s -- --uninstall
```

### 支持的 LLM 提供商

| 提供商 | 命令 | 优势 |
|--------|------|------|
| **MiniMax** (默认) | `LLM_PROVIDER=minimax` | 性价比高，中文支持优秀 |
| **Claude** | `LLM_PROVIDER=claude` | 推理能力强，安全性高 |
| **GPT** | `LLM_PROVIDER=gpt` | 生态完善，功能丰富 |
| **Ollama** | `LLM_PROVIDER=ollama` | 本地部署，保护隐私 |

### 本地安装

```bash
# 克隆仓库
git clone https://github.com/Espl0it/OpenClawInstall.git
cd OpenClawInstall
chmod +x install.sh

# 运行安装脚本
./install.sh

# 查看帮助
./install.sh --help
```

## 📋 系统要求

### 支持的操作系统

- **Ubuntu**: 20.04 LTS 及以上版本
- **Debian**: 11+ (实验性支持)
- **Docker**: Linux (Docker Desktop)

### 前置条件

#### 基础要求

1. **网络连接**: 稳定的互联网连接用于下载依赖
2. **磁盘空间**: 至少 2GB 可用空间
3. **管理员权限**: 用于安装系统服务和配置防火墙

#### LLM 提供商账户（选择其一）

| 提供商 | 注册地址 | 需要准备 | 适用场景 |
|--------|----------|----------|----------|
| **MiniMax** (默认) | https://api.minimax.chat/ | Group ID + API Key | 个人开发者，中小企业 |
| **Claude** | https://console.anthropic.com/ | API Key | 企业用户，注重安全 |
| **GPT** | https://platform.openai.com/ | API Key | 技术团队，集成开发 |
| **Ollama** | https://ollama.ai | 本地运行 | 隐私敏感，无需 API 费用 |

## 📦 安装流程

### 安装步骤概览

1. **安全检查** - 验证 Bash 版本，检查 Shellshock 漏洞
2. **脚本验证** - SHA256 校验和验证（可选）
3. **系统检测** - 检测操作系统版本和配置
4. **前置检查** - 网络连接、磁盘空间检查
5. **依赖安装** - 安装 curl、wget、git 等基础工具
6. **网络安全** - 安装和配置 Tailscale（可选）
7. **Node.js** - 安装 Node.js 24 运行环境
8. **OpenClaw** - 安装 OpenClaw CLI 工具
9. **初始化** - 配置 LLM 提供商
10. **插件安装** - 安装 Matrix 插件和安全组件
11. **服务配置** - 创建系统服务，支持开机自启动
12. **安全加固** - 设置文件权限和防护机制
13. **健康检查** - 验证安装结果

### 环境变量配置

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `DEBUG` | 0 | 启用调试模式，显示详细日志 |
| `VERBOSE` | 0 | 详细输出模式 |
| `DRY_RUN` | 0 | 模拟运行，不执行实际操作 |
| `AUTO_ACCEPT` | 0 | 自动确认所有提示，无需用户交互 |
| `SKIP_TAILSCALE` | 0 | 跳过 Tailscale 安装和配置 |
| `SKIP_DOCKER` | 0 | 跳过 Docker 模式选项 |
| `LLM_PROVIDER` | minimax | LLM 提供商：minimax / claude / gpt / ollama |
| `INSTALL_DIR` | ~/.openclaw | OpenClaw 安装目录 |
| `INSTALL_MODE` | native | 安装模式：native / docker |

### 配置文件

支持使用配置文件进行安装配置：

```bash
# 创建配置文件
cat > ~/.openclaw/install.conf << 'EOF'
LLM_PROVIDER=minimax
AUTO_ACCEPT=1
SKIP_TAILSCALE=1
VERBOSE=1
EOF

# 使用配置文件安装
curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash -s -- --config ~/.openclaw/install.conf
```

## 🔐 安全特性

### 安装过程安全

- **umask 077**: 敏感文件权限保护
- **Bash 版本检查**: 防止 Shellshock 漏洞
- **SHA256 校验**: 脚本完整性验证
- **非 root 警告**: 提醒生产环境使用非 root 用户

### 部署后安全

详见 [安全特性](./security.md)

## 🆘 故障排除

详见 [故障排除](./troubleshooting.md)
