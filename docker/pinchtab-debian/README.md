# PinchTab Debian + Chromium + Default VNC

这个目录提供一个可直接运行的 Debian 版 PinchTab 镜像，解决 Alpine / glibc / Chromium 兼容问题。

先说明最关键的结论：**这个仓库的默认部署就是 VNC 模式。** 默认安装脚本会启用 `ENABLE_VNC=1`，推荐的 `docker run` 也会启用 `PINCHTAB_ENABLE_VNC=1`，并默认映射 `5900` / `6080`。

最常用的网页入口：

```text
http://127.0.0.1:6080/vnc.html
```

端口含义：

- `5900` = 原生 VNC 客户端
- `6080` = noVNC 网页入口

补充说明：

- **VNC** 的作用是给容器准备一个可视化显示环境 / 显示器
- **有头浏览器** 会把浏览器窗口显示到这个环境里，所以你可以在 VNC / noVNC 中看到浏览器
- 如果仍然跑的是 **headless 浏览器**，那么即使 VNC 已开启，通常也看不到浏览器窗口

额外支持：

- **默认 VNC 可视化登录**
- **默认 noVNC（浏览器访问）**
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

## 3A. 默认运行方式：VNC / noVNC 模式

这是本仓库的默认推荐方式：启动 PinchTab API，同时启动 `x11vnc` / noVNC，并开放 `5900` / `6080`。

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

做完 SSH 端口转发后，直接在本地浏览器打开：

```text
http://127.0.0.1:6080/vnc.html
```

---

## 3B. 如需纯后台 API 模式，可显式关闭 VNC

如果你明确不需要可视化环境，而只想保留 PinchTab API，可以显式关闭：

```bash
docker run -d --name pinchtab-debian \
  -p 127.0.0.1:9867:9867 \
  -v /var/lib/pinchtab:/var/lib/pinchtab \
  -v /var/lib/pinchtab/profiles:/var/lib/pinchtab/profiles \
  -v $(pwd)/pinchtab.container.json:/etc/pinchtab.json:ro \
  -e PINCHTAB_CONFIG=/etc/pinchtab.json \
  -e PINCHTAB_ENABLE_VNC=0 \
  pinchtab-debian:latest
```

此模式下：

- 不会启动 `x11vnc` / noVNC
- 不需要映射 `5900` / `6080`
- 只提供 `9867` PinchTab API

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

1. 直接用默认的 VNC / noVNC 模式启动容器
2. 通过 SSH 隧道打开 noVNC / VNC
3. 让用户手动完成登录
4. 登录完成后不要主动退出账号
5. 保留 `/var/lib/pinchtab/profiles`，后续继续复用该登录态

这比“单独导出 cookie”更稳，也更符合真实浏览器行为。
