# OpenClaw Docker 部署

使用 Docker 部署 OpenClaw，获得更好的隔离性和安全性。

## 快速开始

```bash
# 方式1: 使用安装脚本（推荐）
curl -fsSL https://raw.githubusercontent.com/Espl0it/OpenClawInstall/main/install.sh | bash -s -- --mode docker

# 方式2: 手动部署 (Linux)
docker pull alpine/openclaw:latest
docker run -d \
  --name openclaw \
  --restart unless-stopped \
  -p 18789:18789 \
  -v ~/.openclaw:/home/node/.openclaw \
  alpine/openclaw:latest
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `OPENCLAW_TOKEN` | 自动生成 | 网关 Token |
| `OPENCLAW_LLM_PROVIDER` | minimax | LLM 提供商 |
| `OPENCLAW_LLM_KEY` | - | API Key |

## 持久化配置

```bash
# 创建配置目录
mkdir -p ~/.openclaw

# 启动容器（配置持久化）
docker run -d \
  --name openclaw \
  --restart unless-stopped \
  -p 18789:18789 \
  -v ~/.openclaw:/home/node/.openclaw \
  -e OPENCLAW_LLM_PROVIDER=minimax \
  -e OPENCLAW_LLM_KEY=your-api-key \
  alpine/openclaw:latest
```

## 数据存储

- 配置: `~/.openclaw/`
- 工作区: `~/.openclaw/workspace/`
- 日志: `~/.openclaw/logs/`

## 常用命令

```bash
# 启动
docker start openclaw

# 停止
docker stop openclaw

# 重启
docker restart openclaw

# 查看日志
docker logs -f openclaw

# 进入容器
docker exec -it openclaw sh

# 获取 Token
docker exec openclaw openclaw token
```

## Docker Compose

```yaml
version: '3.8'

services:
  openclaw:
    image: alpine/openclaw:latest
    container_name: openclaw
    restart: unless-stopped
    ports:
      - "18789:18789"
    volumes:
      - ~/.openclaw:/home/node/.openclaw
    environment:
      - OPENCLAW_LLM_PROVIDER=minimax
      # - OPENCLAW_LLM_KEY=your-key
```

## 安全建议

1. **定期更新镜像**: `docker pull alpine/openclaw:latest`
2. **限制网络访问**: 使用防火墙规则
3. **敏感数据**: 使用 Docker secrets 或环境变量
4. **定期备份**: 备份 `~/.openclaw` 目录
