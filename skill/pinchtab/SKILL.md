---
name: pinchtab
description: 使用 PinchTab HTTP API 控制浏览器（导航、截图、文本提取、点击、表单填写）。
metadata: {"openclaw":{"emoji":"🌐","requires":{"bins":["curl"]},"os":["linux","darwin","win32"]}}
---

# PinchTab Browser Control

PinchTab 提供本地浏览器控制的 HTTP API。常用场景：网页导航、表单填写、点击、截图、文本提取、运行时页面调试。

## 核心原则（工程化要求）

当任务涉及“浏览器调试 / 页面行为异常 / DOM 闪动 / 实时渲染问题”时，不要只靠源码猜测，优先走**运行时验证**。

### 必做顺序

1. **先确认 PinchTab 服务可用**
2. **先确认当前实际生效的配置来源**（不是只看默认配置文件）
3. **先确认 token / 端口 / 导航策略**
4. **能用浏览器运行时验证时，不要只靠静态阅读源码**
5. **若被策略拦截，先报告“拦截来自服务配置”，再决定改配置还是改目标代码**
6. **若站点需要登录/验证码/2FA，不要死磕自动化，优先切到 VNC/noVNC 让用户接管登录**
7. **登录完成后优先复用 profile，不要反复让用户重新登录**

## 连接信息

- Orchestrator: `http://127.0.0.1:9867`
- 需要鉴权时，设置环境变量 `PINCHTAB_TOKEN` 并在请求头添加：
  `Authorization: Bearer $PINCHTAB_TOKEN`

## 首先检查：服务、配置来源、鉴权

### 1) 健康检查

```bash
curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  http://127.0.0.1:9867/health
```

### 2) 列出实例

```bash
curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  http://127.0.0.1:9867/instances
```

### 3) 检查实际配置来源（关键）

不要先假设配置来自 `~/.config/pinchtab/config.json`。
先查**运行中的服务到底吃哪个配置**。

#### systemd 场景

```bash
systemctl cat pinchtab.service
systemctl status pinchtab.service --no-pager -l
```

重点看：
- `ExecStart=`
- `Environment=PINCHTAB_CONFIG=...`

#### 直接运行 / 容器场景

```bash
ps -ef | grep -i pinchtab | grep -v grep
tr '\0' '\n' < /proc/<pinchtab-pid>/environ
```

重点看：
- `PINCHTAB_CONFIG=`

#### Docker 场景

```bash
docker ps
docker inspect <container-id>
```

重点看：
- 环境变量里是否有 `PINCHTAB_CONFIG=`
- mount 到 `/etc/pinchtab.json` 或其他配置路径的文件

### 4) 检查 token

如果没提前拿到 token，优先从**实际生效配置文件**里读取 `server.token`，不要盲猜。

## 导航策略 / 白名单 / 安全拦截

如果导航时报类似错误：

- `navigation blocked by IDPI`
- `domain is not in the allowed list`
- `unauthorized`

不要继续猜页面代码，先检查配置文件中的：

```json
security.idpi.enabled
security.idpi.allowedDomains
security.idpi.strictMode
```

### 推荐策略

如果当前需求是**本机私有浏览器调试**，且用户明确要求不要白名单：

```json
"security": {
  "idpi": {
    "enabled": false,
    "allowedDomains": [],
    "strictMode": false,
    "scanContent": false,
    "wrapContent": false,
    "customPatterns": [],
    "scanTimeoutSec": 0
  }
}
```

### 改完后必须验证

- 重启真实运行的 PinchTab 服务/容器
- 再次调用 `/health`
- 再次实际 `navigate`
- 确认拦截已消失

## 登录态 / 发布态任务（必须工程化）

如果任务属于以下类型：

- 需要登录后才能看数据
- 需要扫码 / 2FA / 验证码
- 需要发布内容 / 发帖 / 发文 / 提交表单
- 网站明确有反自动化限制

请遵守以下流程。

### A. 先判断是否适合自动化硬做

如果页面已经明显要求：
- 登录
- 手机验证码
- 短信验证
- 邮箱验证码
- 二次确认
- 图形验证码 / 滑块

不要继续假装能全自动跑通。此时优先进入 **VNC/noVNC 接管流程**。

### B. VNC/noVNC 接管提示模板

当需要用户手动登录时，优先这样提示：

```text
这个站点需要登录/验证码，接下来请通过 VNC/noVNC 接管浏览器完成登录。
登录完成后告诉我“已登录”，我再继续自动化后续步骤。
```

如果已经有 SSH 隧道说明，也可以提示：

```text
请先通过 SSH 隧道打开 noVNC / VNC，手动完成登录。登录完成后回复“已登录”。
```

### C. 登录完成后的标准动作

用户回复“已登录”后：

1. **不要要求用户立刻退出账号**
2. 先继续完成当前任务（读取数据 / 发布 / 保存草稿 / 提交）
3. 明确告诉用户：当前登录态会保存在 PinchTab profile 中，可供后续复用

推荐提示：

```text
我会继续使用当前浏览器 profile 里的登录态执行后续步骤。
如果你希望后续复用这次登录，不要清空该 profile。
```

### D. 完成任务后的提示

如果任务已完成，建议告诉用户：

```text
这次登录态已经保存在当前 PinchTab profile 中。
下次同一站点通常可以直接复用，无需重新登录；除非站点主动让 cookie 失效。
```

### E. 关于“退出登录”的原则

默认**不要主动提示用户退出网站账号**，除非：

- 用户明确要求退出
- 这是一次性高敏感账号
- 用户要求你不要保留登录态

否则默认策略应是：

- **保留 profile / cookie / session**
- 方便后续自动化继续使用

### F. 关于“保存 cookie”的工程化表达

对于 PinchTab 来说，更准确的说法通常不是“单独导出 cookie”，而是：

- **复用当前浏览器 profile**
- profile 中自然包含 cookie / localStorage / sessionStorage / 登录状态（取决于站点）

所以对用户的表达推荐是：

```text
这次登录状态会随当前浏览器 profile 一起保留，后续优先复用，不需要你每次重新登录。
```

而不要轻易承诺：

```text
我已经单独保存了这个站的 cookie 文件
```

除非你真的实现了 cookie 导出。

## 常用流程

### 导航到网页（自动开新标签）

```bash
curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  -X POST http://127.0.0.1:9867/navigate \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}'
```

### 获取可交互元素

```bash
curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  "http://127.0.0.1:9867/tabs/<TAB_ID>/snapshot?filter=interactive"
```

### 点击 / 填写

```bash
# 点击
curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  -X POST http://127.0.0.1:9867/tabs/<TAB_ID>/action \
  -H "Content-Type: application/json" \
  -d '{"kind":"click","ref":"e3"}'

# 输入
curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  -X POST http://127.0.0.1:9867/tabs/<TAB_ID>/action \
  -H "Content-Type: application/json" \
  -d '{"kind":"fill","ref":"e5","value":"text"}'
```

### 提取文本 / 截图

```bash
curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  http://127.0.0.1:9867/tabs/<TAB_ID>/text

curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  http://127.0.0.1:9867/tabs/<TAB_ID>/screenshot
```

## 页面调试建议（前端问题时）

遇到以下问题时，优先用 PinchTab 运行时验证：

- DOM 闪烁
- 样式来回切换
- 图片先显示后隐藏
- MutationObserver 死循环
- 懒加载 / 缩略图 / 图标切换异常

建议流程：

1. 导航页面
2. 获取 tabId
3. 截图一次看初始状态
4. 抽文本 / snapshot 看当前元素
5. 必要时多次截图比对渲染变化
6. 再回头改页面代码

## 实例管理

```bash
# 列出实例
curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  http://127.0.0.1:9867/instances

# 停止实例
curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  -X POST http://127.0.0.1:9867/instances/<INSTANCE_ID>/stop
```

## 运行方式说明

### 使用主机 Chromium（固定方案）

PinchTab 官方镜像是 Alpine (musl)，无法直接运行主机的 glibc 版 Chromium。
统一可行方案：

- **主机直接运行 PinchTab**，并设置 `browser.binary` 为 `/usr/bin/chromium`
- 或使用已验证可用的 **Debian 容器版 PinchTab**
- 如果站点需要手动登录，建议启用 **VNC / noVNC** 方便用户接管

示例：

```json
{
  "browser": {
    "binary": "/usr/bin/chromium",
    "extraFlags": "--no-sandbox --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --disable-vulkan --use-gl=swiftshader"
  }
}
```

## 备注

- PinchTab 会将登录态保存在 profile 中，复用 profile 可避免重复登录。
- 若站点有滑块验证，需要一次性手动完成登录后保存 profile。
- 遇到“能 curl API 但不能导航页面”的情况，第一反应应该是：**查配置策略，不是猜前端代码。**
- 遇到“需要登录才能继续”的情况，第一反应应该是：**切 VNC/noVNC 让用户接管登录，再复用 profile。**
