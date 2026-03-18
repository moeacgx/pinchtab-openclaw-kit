# PinchTab OpenClaw Kit

一个给 OpenClaw 用的浏览器能力仓库，包含：

- `pinchtab` skill
- Debian + Chromium 版 PinchTab 容器
- 可选 VNC / noVNC 可视化登录
- SSH 隧道连接说明
- 登录态 / browser profile 复用工作流

---

## 给 OpenClaw 的一条安装提示词

直接这样说：

```text
帮我克隆这个仓库，阅读 README 和安装说明，并实际完成安装、配置和验证；如果文档里有可选项，优先使用推荐/默认方案，完成后告诉我安装结果和关键配置：https://github.com/moeacgx/pinchtab-openclaw-kit
```

更口语一点也可以：

```text
帮我把这个仓库按 README 真正装好，不只是克隆下来；该配置的配置、该部署的部署，最后帮我验证能不能用：https://github.com/moeacgx/pinchtab-openclaw-kit
```

---

## 交流群

- Telegram: https://t.me/vpsbbq

---

## 仓库结构

```text
pinchtab-openclaw-kit/
├── README.md
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

---

## 它会安装什么

- OpenClaw 的 `pinchtab` skill
- Debian + Chromium 版 PinchTab 容器
- 可选 VNC / noVNC 可视化接管登录
- 登录态复用流程（优先复用 browser profile，而不是每次重登）

---

## 手动安装 skill

```bash
mkdir -p /root/.openclaw/skills/pinchtab
cp skill/pinchtab/SKILL.md /root/.openclaw/skills/pinchtab/SKILL.md
```

然后把 `pinchtab` 加到你想启用它的 agent / 助手的 `skills` 列表。

> 注意：skill 目录存在 ≠ 已启用。关键是把 skill 名写进对应 agent 的 `skills` 列表。

---

## 手动部署 Debian Chromium 版 PinchTab

见：

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

---

## 可视化登录（VNC / noVNC）

如果某些站点需要人工登录、验证码、2FA、扫码，建议启用可视化模式。

详见：

- `docker/pinchtab-debian/README.md`

核心思路：

1. 用 VNC / noVNC 接管浏览器完成登录
2. 登录完成后回复“已登录”
3. Agent 继续自动化后续步骤
4. 默认保留 browser profile，复用 cookie / session / localStorage 等站点状态

---

## 推荐工作流

如果站点：

- 需要登录后才能看数据
- 需要短信验证码 / 邮箱验证码 / 2FA
- 有滑块 / 图形验证码
- 需要发帖 / 发布 / 提交

推荐流程：

1. 先判断是否必须人工接管
2. 如果需要，就提示用户通过 VNC / noVNC 登录
3. 用户登录完成后继续自动化
4. 默认不要主动退出账号
5. 默认复用 browser profile

推荐提示话术：

```text
这个站点需要登录/验证码，请先通过 VNC/noVNC 接管浏览器完成登录。登录完成后回复“已登录”，我再继续后续自动化操作。
```

登录完成后建议提示：

```text
当前登录态会保存在 PinchTab 的浏览器 profile 中，后续优先复用，不需要每次重新登录。
```

---

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

---

## 适合放在仓库首页的卖点

- 解决 Alpine / glibc / Chromium 兼容问题
- 可直接给 OpenClaw 使用
- 适合页面调试、截图、点击、文本提取
- 支持容器化部署
- 支持 VNC / noVNC 可视化接管登录
- 支持工程化排障（token / 配置来源 / 域名策略 / 登录态复用）
