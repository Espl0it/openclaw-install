# OpenClaw 安全部署脚本

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian%20%7C%20Docker-blue.svg)](https://github.com/Espl0it/OpenClawInstall)
[![Version](https://img.shields.io/badge/Version-3.0-blue.svg)](https://github.com/Espl0it/OpenClawInstall)

## 📋 概述

OpenClaw 跨平台安全部署脚本是一个自动化安装和配置 OpenClaw AI 助手的 Bash 脚本，专为生产环境的安全部署而设计。脚本支持 **在线一键安装** 和本地安装两种方式，兼容 Ubuntu、Debian 系统，提供完整的安全加固措施和最佳实践配置。

### 🌟 核心特性

- **🚀 多种安装模式**: 原生安装 (native) / Docker 容器化部署
- **🔒 企业级安全**: Tailscale VPN + 防火墙 + 权限控制 + 安全检查
- **🛡️ 安全强化**: umask 077、Bash 版本检查、脚本完整性校验
- **⚡ 可靠性**: 模拟运行 (dry-run)、断点安装、详细日志
- **📱 灵活配置**: 环境变量 / 配置文件 / 命令行选项
- **🔧 完整工具链**: Git 提交工具、Gateway 修复、健康检查

## 🚀 快速开始

### 原生模式（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash
```

### Docker 模式

```bash
curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash -s -- --mode docker
```

### 模拟运行（检查环境）

```bash
DRY_RUN=1 curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash
```

## 📚 文档索引

| 文档 | 说明 |
|------|------|
| [安装指南](docs/installation.md) | 系统要求、安装步骤、环境变量、LLM 提供商 |
| [Docker 部署](docs/docker.md) | Docker 模式安装、Compose 配置 |
| [项目工具](docs/tools.md) | Git 提交工具、安装脚本、Gateway 修复 |
| [安全特性](docs/security.md) | 网络安全、应用安全、系统安全 |
| [部署与运维](docs/operations.md) | 启动服务、访问控制台、日志与监控 |
| [故障排除](docs/troubleshooting.md) | 常见问题、Gateway 修复、重新安装 |
| [维护与更新](docs/maintenance.md) | 定期维护、备份策略、API 密钥轮换 |
| [贡献指南](docs/contributing.md) | 开发环境、代码规范、提交流程 |
| [支持与帮助](docs/support.md) | 官方资源、获取帮助、版本历史 |

## ⚡ 功能对比

| 功能 | v2.x | v3.0 |
|------|------|------|
| 原生安装 | ✅ | ✅ |
| Docker 支持 | ❌ | ✅ |
| 模拟运行 (dry-run) | ❌ | ✅ |
| 配置文件 | ❌ | ✅ |
| 安全校验 (SHA256) | ❌ | ✅ |
| Bash 版本检查 | ❌ | ✅ |
| 卸载功能 | ❌ | ✅ |
| 健康检查 | ❌ | ✅ |
| Ollama 支持 | ❌ | ✅ |
| 详细输出 (verbose) | ❌ | ✅ |

## 📦 支持的 LLM 提供商

| 提供商 | 命令 | 特点 |
|--------|------|------|
| MiniMax | `LLM_PROVIDER=minimax` | 性价比高，中文优化 |
| Claude | `LLM_PROVIDER=claude` | 推理能力强 |
| GPT | `LLM_PROVIDER=gpt` | 生态完善 |
| Ollama | `LLM_PROVIDER=ollama` | 本地部署 |

## 🔧 常用命令

```bash
# 标准安装
curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash

# 自动安装
AUTO_ACCEPT=1 curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash

# 使用配置文件
curl -fsSL ... | bash -s -- --config /path/to/config

# 卸载
curl -fsSL ... | bash -s -- --uninstall
```

## 📄 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE)。

---

**⚠️ 免责声明**: 本脚本用于生产环境部署，请在测试环境中充分验证后再用于生产系统。作者不对因使用本脚本造成的任何损失承担责任。

**🔄 自动更新**: 建议定期检查脚本更新以获取最新安全补丁和功能改进。
