# PinchTab OpenClaw Kit

[English](README.md) | [中文](README.zh-CN.md)

给 OpenClaw 的浏览器能力套件：支持截图、输入、点击、文本提取、元素识别、表单填写、VNC / noVNC 登录接管、登录态复用，以及可直接落地的容器化部署方案。

## 能力一览

这个仓库不是单纯的安装说明，而是一套让 OpenClaw 真正拥有浏览器执行能力的工程化组合：

- **截图与可视化留痕**：打开页面、截取当前视图，适合结果核对、留痕和回传给用户确认
- **输入、点击、键盘操作**：可执行常见 UI 流程，适用于后台操作、管理面板和流程推进
- **文本提取**：从页面中提取可读文本，适合摘要、采集、审查和后续结构化处理
- **元素识别**：在真实页面里定位按钮、输入框、链接等可操作元素
- **表单填写**：适合登录、搜索、发布、提交、后台录入等场景
- **登录接管**：遇到验证码、2FA、扫码、短信验证或人工确认时，可通过 **VNC / noVNC** 接管浏览器
- **登录态复用**：登录完成后默认复用 browser profile，尽量避免每次重新登录
- **容器化落地**：内置 Debian + Chromium 方案，更适合在服务器上稳定部署
- **工程化排障**：文档覆盖 token、配置来源、浏览器 profile、可视化接管和部署排障等关键问题

## 典型场景

当 OpenClaw 需要的不是简单 HTTP 请求，而是真浏览器能力时，这个仓库就很合适：

- **先截图再确认的流程**：打开页面并截图，先让用户确认，再继续下一步
- **后台操作与多步骤提交流程**：填写、点击、选择、提交，串起整条 UI 流程
- **页面内容读取与抽取**：读取网页内容、提取文本、抓取关键信息
- **必须登录后才能访问的站点**：先由人完成登录，再把后续流程交给 Agent
- **带验证码 / 2FA / 扫码的流程**：人机协作完成最难的一步，后续继续自动化
- **发布、发帖、配置修改等高风险动作**：浏览器执行后再截图回传，做二次确认
- **要稳定跑在服务器上的场景**：直接走容器方案，减少环境漂移和依赖兼容问题

## 安装方式

推荐顺序：

1. **安装 OpenClaw skill**，让 Agent 学会如何调用 PinchTab
2. **部署 PinchTab 容器**，提供实际浏览器运行环境
3. **按需开启 VNC / noVNC**，用于登录接管和复杂站点处理
4. **做一次健康检查与导航验证**，确认整条链路可用

### 方式一：让 OpenClaw 直接安装（推荐）

可以直接这样说：

```text
帮我克隆这个仓库，阅读 README 和安装说明，并实际完成安装、配置和验证；如果文档里有可选项，优先使用推荐/默认方案，完成后告诉我安装结果和关键配置：https://github.com/moeacgx/pinchtab-openclaw-kit
```

更口语一点也可以：

```text
帮我把这个仓库按 README 真正装好，不只是克隆下来；该配置的配置、该部署的部署，最后帮我验证能不能用：https://github.com/moeacgx/pinchtab-openclaw-kit
```

### 方式二：手动安装 skill

```bash
mkdir -p /root/.openclaw/skills/pinchtab
cp skill/pinchtab/SKILL.md /root/.openclaw/skills/pinchtab/SKILL.md
```

然后把 `pinchtab` 加到你想启用它的 agent / 助手的 `skills` 列表。

> 注意：skill 目录存在 ≠ 已启用。关键是把 skill 名写进对应 agent 的配置里。

### 方式三：手动部署 Debian + Chromium 版 PinchTab

详见：

- `docker/pinchtab-debian/README.md`

快速版：

```bash
cd docker/pinchtab-debian
cp pinchtab.container.json.example pinchtab.container.json
# 编辑 token 等配置

docker build -t pinchtab-debian:latest .

docker run -d --name pinchtab-debian \
  -p 127.0.0.1:9867:9867 \
  -v /var/lib/pinchtab:/var/lib/pinchtab \
  -v /var/lib/pinchtab/profiles:/var/lib/pinchtab/profiles \
  -v $(pwd)/pinchtab.container.json:/etc/pinchtab.json:ro \
  -e PINCHTAB_CONFIG=/etc/pinchtab.json \
  pinchtab-debian:latest
```

## 为什么推荐容器方案

无论宿主机是 Ubuntu、CentOS、Rocky 还是 AlmaLinux，**都建议优先使用仓库里的 Debian + Chromium 容器方案**。

原因：

- 避开宿主机浏览器依赖不一致的问题
- 减少 Alpine / glibc / Chromium 相关兼容性问题
- 更容易复制、迁移和复用部署
- 长期运行时通常更容易排障和维护

> 尤其是宿主机较老时，比如 CentOS 7，这一点会更明显。大多数情况下，容器方案会比原生浏览器安装省事得多。

## 可视化登录接管（VNC / noVNC）

如果站点需要人工登录、验证码、扫码或 2FA，建议走可视化接管方案。

详见：

- `docker/pinchtab-debian/README.md`

推荐流程：

1. Agent 先判断是否需要人工接管
2. 如果需要，就提示用户通过 VNC / noVNC 打开浏览器
3. 用户完成登录、扫码、验证码或 2FA
4. 用户回复“已登录”
5. Agent 继续后续自动化流程
6. 保留浏览器 profile，后续优先复用登录态

推荐提示话术：

```text
这个站点需要登录/验证码，请先通过 VNC/noVNC 接管浏览器完成登录。登录完成后回复“已登录”，我再继续后续自动化操作。
```

登录完成后建议提示：

```text
当前登录态会保存在 PinchTab 的浏览器 profile 中，后续优先复用，不需要每次重新登录。
```

## 验证

```bash
export PINCHTAB_TOKEN='你的token'

curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  http://127.0.0.1:9867/health

curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  -X POST http://127.0.0.1:9867/navigate \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}'
```

## 仓库结构

```text
pinchtab-openclaw-kit/
├── README.md
├── README.zh-CN.md
├── skill/
│   └── pinchtab/
│       └── SKILL.md
├── docker/
│   └── pinchtab-debian/
│       ├── Dockerfile
│       ├── README.md
│       ├── start.sh
│       └── pinchtab.container.json.example
└── scripts/
    ├── install-skill.sh
    └── install-pinchtab-debian.sh
```

## 仓库里包含什么

- OpenClaw 的 `pinchtab` skill
- Debian + Chromium 版 PinchTab 容器
- 可选 VNC / noVNC 可视化登录支持
- SSH 隧道连接说明
- browser profile 与登录态复用工作流

## 交流群

- Telegram: https://t.me/vpsbbq
