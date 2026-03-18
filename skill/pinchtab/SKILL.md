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
