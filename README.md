# PinchTab OpenClaw Kit

一个可直接拿去做仓库的 OpenClaw 技能包，包含：

- `pinchtab` skill
- Debian + Chromium 版 PinchTab 容器方案
- 可选 VNC / noVNC 可视化登录方案（支持 SSH 隧道）
- OpenClaw 安装说明
- 给用户/主脑的自然语言安装话术

适合场景：

- 让 OpenClaw 具备浏览器自动化 / 页面调试能力
- 解决 Alpine 镜像与主机 Chromium（glibc）不兼容问题
- 给别人一个“拿来就能装”的 skill 仓库

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

## 一、给 OpenClaw 的安装话术（推荐）

你可以直接对 OpenClaw 说这些：

### 安装 skill

```text
帮我安装 pinchtab skill
```

更明确一点：

```text
帮我把这个仓库里的 pinchtab skill 安装到 /root/.openclaw/skills，并加到 ops 的 skills 列表
```

或者：

```text
帮我把 pinchtab 加到 ops 和 dev 的 skills 列表
```

### 安装 Debian Chromium 容器版 PinchTab

```text
帮我部署 Debian Chromium 版 PinchTab 容器
```

更明确一点：

```text
帮我用这个仓库里的 docker/pinchtab-debian 部署 PinchTab，监听 127.0.0.1:9867
```

### 安装可视化登录版（VNC / noVNC）

```text
帮我部署带 VNC 的 Debian Chromium 版 PinchTab 容器
```

更明确一点：

```text
帮我部署可通过 SSH 隧道连接 noVNC 的 PinchTab 容器
```

### 如果你不想要域名白名单

```text
帮我把 PinchTab 的 IDPI 白名单关闭，用于本机私有浏览器调试
```

---

## 二、手动安装 skill

### 1) 复制 skill 到 OpenClaw skills 目录

```bash
mkdir -p /root/.openclaw/skills/pinchtab
cp skill/pinchtab/SKILL.md /root/.openclaw/skills/pinchtab/SKILL.md
```

### 2) 把 `pinchtab` 加到目标 agent 的 `skills` 列表

示意：

```yaml
agents:
  ops:
    skills:
      - pinchtab
```

如果是多个 agent：

```yaml
agents:
  ops:
    skills:
      - pinchtab
  dev:
    skills:
      - pinchtab
```

> 注意：
> - skill 目录存在 ≠ agent 已启用
> - 关键是把 skill 名写进对应 agent 的 `skills` 列表

---

## 三、手动部署 Debian Chromium 版 PinchTab

支持两种模式：

- 纯后台模式
- 带 VNC / noVNC 的可视化模式


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

## 四、验证

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

## 五、推荐给用户的最简说明

如果你以后把这个仓库公开，README 顶部可以直接放这段：

```text
安装方法：
1. 告诉 OpenClaw：帮我安装 pinchtab skill
2. 告诉 OpenClaw：把 pinchtab 加到 ops 或 dev 的 skills 列表
3. 如果本机没有可用浏览器环境，再告诉 OpenClaw：帮我部署 Debian Chromium 版 PinchTab 容器
4. 如果你需要可视化登录，再说：帮我部署带 VNC / noVNC 的 PinchTab 容器
5. 如果你不想受白名单限制，再说：帮我关闭 PinchTab 的 IDPI 白名单
```

---

## 六、适合补充到仓库首页的卖点

- 解决 Alpine / glibc / Chromium 兼容问题
- 可直接给 OpenClaw 使用
- 适合页面调试、截图、点击、文本提取
- 支持容器化部署
- 支持工程化排障（token / 配置来源 / 域名策略）


## 七、登录态 / 发布态的工程化建议

如果站点：

- 需要登录后才能查看数据
- 需要短信验证码 / 邮箱验证码 / 2FA
- 有滑块 / 图形验证码
- 需要发帖 / 发布 / 提交敏感操作

推荐工作流：

1. 先让 OpenClaw/agent 判断该站是否适合继续自动化
2. 如果需要人工登录，提示用户通过 **VNC / noVNC** 接管浏览器
3. 用户登录完成后，回复：`已登录`
4. Agent 再继续自动化后续步骤
5. 默认**不要让用户退出账号**，优先复用当前 browser profile
6. 明确告诉用户：登录态会随 profile 保留，后续通常可复用

### 推荐话术

```text
这个站点需要登录/验证码，请先通过 VNC/noVNC 接管浏览器完成登录。
登录完成后回复“已登录”，我再继续后续自动化操作。
```

登录完成后可继续提示：

```text
当前登录态会保存在 PinchTab 的浏览器 profile 中，后续优先复用，不需要每次重新登录。
```

### 关于“保存 cookie”

更准确的工程化表达通常不是“单独导出 cookie 文件”，而是：

- 保留并复用 PinchTab 的浏览器 profile
- profile 中自然包含 cookie / localStorage / session 等登录状态（取决于站点）

所以仓库文档里建议统一写成：

```text
保存并复用浏览器 profile，而不是承诺单独导出 cookie。
```
