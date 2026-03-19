# PinchTab Debian + Chromium + Optional VNC

这个目录提供一个可直接运行的 Debian 版 PinchTab 镜像，解决 Alpine / glibc / Chromium 兼容问题。

先说明一个关键点：**默认不是 VNC 启动，而是无 VNC 模式。** 默认只启动 PinchTab API，不会启动 `x11vnc` / noVNC，也不会开放 `5900` / `6080`。只有在你显式开启 `ENABLE_VNC=1`（安装脚本）或 `PINCHTAB_ENABLE_VNC=1`（直接 `docker run`）后，才会启动 `x11vnc` / noVNC 并开放对应端口。

额外支持：

- **可选 VNC 可视化登录**
- **可选 noVNC（浏览器访问）**
- **适合通过 SSH 隧道远程看浏览器界面**

---

## 1. 准备配置

```bash
cp pinchtab.container.json.example pinchtab.container.json
```

然后编辑：

- `server.token`

---

## 2. 构建镜像

```bash
docker build -t pinchtab-debian:latest .
```

---

## 3A. 纯后台模式运行（默认）

这是默认模式，也就是**无 VNC 模式**：不会启动 `x11vnc` / noVNC，只提供 PinchTab API。

```bash
docker run -d --name pinchtab-debian \
  -p 127.0.0.1:9867:9867 \
  -v /var/lib/pinchtab:/var/lib/pinchtab \
  -v /var/lib/pinchtab/profiles:/var/lib/pinchtab/profiles \
  -v $(pwd)/pinchtab.container.json:/etc/pinchtab.json:ro \
  -e PINCHTAB_CONFIG=/etc/pinchtab.json \
  pinchtab-debian:latest
```

---

## 3B. 开启 VNC / noVNC 可视化模式

只有显式开启下面这组参数时，才会启动 `x11vnc` / noVNC，并开放 `5900` / `6080`。

你可以把“开启 VNC 模式”理解成：给容器准备好了一个可视化显示环境 / 显示器；再启动**有头浏览器**时，浏览器窗口会显示到这个环境里，因此你可以在 VNC / noVNC 中看到浏览器操作。反过来，如果仍然跑的是 **headless 浏览器**，那么即使 VNC 已开启，通常也看不到浏览器窗口。

```bash
docker run -d --name pinchtab-debian \
  -p 127.0.0.1:9867:9867 \
  -p 127.0.0.1:5900:5900 \
  -p 127.0.0.1:6080:6080 \
  -v /var/lib/pinchtab:/var/lib/pinchtab \
  -v /var/lib/pinchtab/profiles:/var/lib/pinchtab/profiles \
  -v $(pwd)/pinchtab.container.json:/etc/pinchtab.json:ro \
  -e PINCHTAB_CONFIG=/etc/pinchtab.json \
  -e PINCHTAB_ENABLE_VNC=1 \
  -e VNC_PASSWORD='your-vnc-password' \
  pinchtab-debian:latest
```

端口说明（仅在显式开启 VNC 模式时开放）：

- `9867` → PinchTab API
- `5900` → 原生 VNC
- `6080` → noVNC（浏览器打开）

---

## 4. 通过 SSH 隧道从外部连接 VNC / noVNC

### noVNC（推荐，浏览器打开）

本地机器执行：

```bash
ssh -N -L 6080:127.0.0.1:6080 user@your-server
```

然后本地浏览器打开：

```text
http://127.0.0.1:6080/vnc.html
```

### 原生 VNC

本地机器执行：

```bash
ssh -N -L 5900:127.0.0.1:5900 user@your-server
```

然后本地 VNC 客户端连接：

```text
127.0.0.1:5900
```

### 顺便把 PinchTab API 也转发回来

```bash
ssh -N \
  -L 9867:127.0.0.1:9867 \
  -L 5900:127.0.0.1:5900 \
  -L 6080:127.0.0.1:6080 \
  user@your-server
```

这样本地就能同时访问：

- PinchTab API: `http://127.0.0.1:9867`
- noVNC: `http://127.0.0.1:6080/vnc.html`
- VNC: `127.0.0.1:5900`

---

## 5. 验证

```bash
export PINCHTAB_TOKEN='你的token'

curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  http://127.0.0.1:9867/health
```

---

## 6. 重启

```bash
docker restart pinchtab-debian
```

---

## 7. 删除

```bash
docker rm -f pinchtab-debian
```


---

## 8. 登录类网站的推荐用法

如果某个站点必须扫码、验证码、2FA 或人工登录，推荐这样用：

1. 用 `PINCHTAB_ENABLE_VNC=1` 启动容器
2. 通过 SSH 隧道打开 noVNC / VNC
3. 让用户手动完成登录
4. 登录完成后不要主动退出账号
5. 保留 `/var/lib/pinchtab/profiles`，后续继续复用该登录态

这比“单独导出 cookie”更稳，也更符合真实浏览器行为。
