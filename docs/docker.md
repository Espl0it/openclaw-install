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

# 进入容器 (交互式)
docker exec -it openclaw /bin/bash

# 使用 docker compose
docker compose exec openclaw bash

# 获取 Token
docker exec openclaw openclaw token
```

### 容器内使用 OpenClaw

在 Docker 容器中，OpenClaw 通过 `npx` 运行：

```bash
# 进入容器
docker exec -it openclaw /bin/bash

# 查看状态
npx openclaw status

# 启动 Gateway
npx openclaw gateway start

# 停止 Gateway
npx openclaw gateway stop

# 查看帮助
npx openclaw --help

# 可选：全局安装
npm install -g openclaw
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

---

## 容器内更新持久化

在容器内执行 `npm install -g openclaw` 更新后，重启容器更新会丢失（因为在镜像内）。

### 解决方案：使用卷挂载

```bash
# 挂载宿主机目录到容器
docker run -d \
  --name openclaw \
  --restart unless-stopped \
  -p 18789:18789 \
  -v ~/.openclaw:/home/node/.openclaw \
  -v ~/.openclaw/workspace:/home/node/.openclaw/workspace \
  openclaw:latest
```

### 持久化关键目录

| 目录 | 说明 |
|------|------|
| `~/.openclaw` | 配置目录 |
| `~/.openclaw/workspace` | 工作区 |

### 检查挂载

```bash
docker inspect openclaw | grep -A 20 "Mounts"
```

### 备份

```bash
# 备份配置
docker cp openclaw:/home/node/.openclaw ./backup

# 恢复
docker cp ./backup/. openclaw:/home/node/.openclaw/
```

---

## 容器权限问题

### 问题原因

容器内用户 `node` 没有权限写入挂载的宿主机目录。

### 解决方案

在 **宿主机** 执行：

```bash
# 修复权限（宿主机）
sudo chown -R 1000:1000 ~/.openclaw
chmod -R 755 ~/.openclaw
```

### Docker Compose 配置

```yaml
services:
  openclaw:
    image: openclaw:latest
    user: "1000:1000"  # 使用宿主机用户
    volumes:
      - ~/.openclaw:/home/node/.openclaw
```

### 启动时指定用户

```bash
docker run -d \
  --name openclaw \
  --user $(id -u):$(id -g) \
  -v ~/.openclaw:/home/node/.openclaw \
  ...
```

### 恢复备份

如果遇到权限错误，配置文件可能有 `.bak` 备份：

```bash
cp ~/.openclaw/openclaw.json.bak ~/.openclaw/openclaw.json
```
