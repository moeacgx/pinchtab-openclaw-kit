# PinchTab Debian + Chromium + Optional VNC

这个目录提供一个可直接运行的 Debian 版 PinchTab 镜像，解决 Alpine / glibc / Chromium 兼容问题。

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

端口说明：

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
