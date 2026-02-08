# OpenClaw 安全部署脚本

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Ubuntu-blue.svg)](https://github.com/zhengweiyu/openclaw)

## 📋 概述

OpenClaw 跨平台安全部署脚本是一个自动化安装和配置 OpenClaw AI 助手的 Bash 脚本，专为生产环境的安全部署而设计。脚本支持 **在线一键安装** 和本地安装两种方式，兼容 macOS 和 Ubuntu 20.04+ 系统，提供完整的安全加固措施和最佳实践配置。

### 🌟 核心特性

- **🚀 在线一键安装**: 单条命令完成所有配置
- **🔧 多LLM支持**: MiniMax、Claude、GPT 自由选择
- **🛡️ 企业级安全**: Tailscale VPN + 防火墙 + 权限控制
- **📱 智能防护**: 提示词注入防护 + 技能审计 + 认知免疫
- **🔄 自动化运维**: 系统服务 + 开机自启 + 日志监控

## 🚀 快速开始

```bash
# 一键安装（推荐）
curl -fsSL https://raw.githubusercontent.com/zhengweiyu/openclaw/main/openclaw_secure_install.sh | bash
```

更多安装方式与选项见 **[安装指南](docs/installation.md)**。

## 📚 文档索引

| 文档 | 说明 |
|------|------|
| [安装指南](docs/installation.md) | 系统要求、安装步骤、环境变量、LLM 提供商 |
| [项目工具](docs/tools.md) | Git 提交工具、安全安装脚本、Gateway 修复脚本 |
| [安全特性](docs/security.md) | 网络安全、应用安全、系统安全 |
| [部署与运维](docs/operations.md) | 启动服务、访问控制台、日志与监控 |
| [故障排除](docs/troubleshooting.md) | 常见问题、Gateway 修复、重新安装 |
| [维护与更新](docs/maintenance.md) | 定期维护、备份策略、API 密钥轮换 |
| [贡献指南](docs/contributing.md) | 开发环境、代码规范、提交流程 |
| [支持与帮助](docs/support.md) | 官方资源、获取帮助、版本历史 |

## 📄 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE)。

---

**⚠️ 免责声明**: 本脚本用于生产环境部署，请在测试环境中充分验证后再用于生产系统。作者不对因使用本脚本造成的任何损失承担责任。

**🔄 自动更新**: 建议定期检查脚本更新以获取最新安全补丁和功能改进。
