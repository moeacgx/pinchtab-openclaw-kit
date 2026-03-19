# PinchTab OpenClaw Kit

[English](README.md) | [中文](README.zh-CN.md)

Browser capabilities kit for OpenClaw: screenshots, text input, clicks, text extraction, element targeting, form filling, default VNC / noVNC visual deployment, session reuse, and a container-ready deployment path.

> **Default deployment = VNC mode.** After SSH port forwarding, open **`http://127.0.0.1:6080/vnc.html`** directly in your local browser.
> - `5900` = native VNC client
> - `6080` = noVNC web page
> - VNC prepares the visual display environment
> - A headed browser draws its window into that environment, so you can see it in VNC / noVNC
> - If the browser is still headless, you usually will not see a browser window there even when VNC is enabled

## Capabilities

This repository is not just an installation note. It is a practical, deployment-oriented kit that gives OpenClaw real browser execution capabilities:

- **Screenshots and visual proof**: open pages, capture the current view, and send evidence back for confirmation or review
- **Text input, clicking, and keyboard actions**: drive common UI flows for dashboards, admin panels, and operational tasks
- **Text extraction**: pull readable content from pages for summaries, audits, collection, or downstream processing
- **Element targeting**: identify buttons, inputs, links, and other actionable elements on real pages
- **Form filling**: useful for login flows, search forms, publishing, submissions, and back-office data entry
- **Login handoff**: when a site requires CAPTCHA, 2FA, QR scan, SMS, or manual confirmation, hand control to a human via **VNC / noVNC**
- **Session reuse**: keep and reuse browser profiles after login so agents do not need to sign in every time
- **Containerized delivery**: ship with a Debian + Chromium setup that is easier to run reliably on servers
- **Operational troubleshooting**: documentation covers token setup, config source, browser profile reuse, visual takeover, and deployment concerns

## Use Cases

This kit is a good fit when OpenClaw needs an actual browser, not just HTTP requests:

- **Screenshot-first workflows**: open a page, capture it, and let the user confirm before the next step
- **Admin operations and multi-step submissions**: fill, click, select, submit, and continue through the full UI flow
- **Content reading and extraction**: read page content, collect text, and pull out key information
- **Sites that only work after login**: let a human complete login once, then hand the rest back to the agent
- **CAPTCHA / 2FA / QR-based flows**: use human-in-the-loop takeover for the hard part, then resume automation
- **Publishing and high-risk actions**: perform browser actions, then return screenshots for a second confirmation
- **Server-side deployment**: use the container path to reduce environment drift and browser dependency pain

## Installation

Recommended order:

1. **Install the OpenClaw skill** so the agent knows how to use PinchTab
2. **Deploy the PinchTab container** to provide the actual browser runtime
3. **Use the default VNC / noVNC deployment** so SSH port forwarding gives you an immediate browser entry point
4. **Run a health check and navigation test** to verify the full chain

### Option 1: Let OpenClaw install it for you

You can say:

```text
Clone this repository, read the README and install docs, and complete the actual installation, configuration, and verification for me. If there are optional paths, prefer the recommended/default one. After that, tell me the install result and key configuration: https://github.com/moeacgx/pinchtab-openclaw-kit
```

A shorter version also works:

```text
Please fully install this repo based on its README, not just clone it. Configure what needs configuring, deploy what needs deploying, and verify that it works at the end: https://github.com/moeacgx/pinchtab-openclaw-kit
```

### Option 2: Install the skill manually

```bash
mkdir -p /root/.openclaw/skills/pinchtab
cp skill/pinchtab/SKILL.md /root/.openclaw/skills/pinchtab/SKILL.md
```

Then add `pinchtab` to the `skills` list of the agents that should use it.

> Note: having the skill directory present does not mean it is enabled. The skill name must be added to the target agent configuration.

### Option 3: Deploy the Debian + Chromium PinchTab container manually

See:

- `docker/pinchtab-debian/README.md`

Quick start (default VNC / noVNC deployment):

```bash
cd docker/pinchtab-debian
cp pinchtab.container.json.example pinchtab.container.json
# edit token and other settings

docker build -t pinchtab-debian:latest .

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

After SSH port forwarding, open:

```text
http://127.0.0.1:6080/vnc.html
```

If you explicitly want API-only background mode instead, set `PINCHTAB_ENABLE_VNC=0` and remove the `5900` / `6080` port mappings.

## Why the container setup is recommended

No matter whether the host runs Ubuntu, CentOS, Rocky, or AlmaLinux, the **Debian + Chromium container path is the recommended default**.

Why:

- avoids host-level browser dependency mismatches
- reduces Alpine / glibc / Chromium compatibility issues
- makes deployments easier to reproduce and migrate
- is usually easier to operate and troubleshoot over time

> This matters even more on older hosts such as CentOS 7. In most cases, the container path is far less painful than native browser setup.

## Visual login handoff (VNC / noVNC)

If a site requires manual login, CAPTCHA, QR scan, or 2FA, use the visual takeover path.

Important clarification:

- **Default deployment in this repository is VNC mode.** The install script defaults to `ENABLE_VNC=1`, and the recommended `docker run` example enables `PINCHTAB_ENABLE_VNC=1` with ports `5900` / `6080` mapped.
- You can think of **"VNC mode"** as preparing a visual display environment / monitor for the container.
- You can think of **launching a headed browser** as drawing the browser window into that display environment, so you can watch the browser actions through VNC / noVNC.
- If your workflow still uses a **headless browser**, then even with VNC enabled, you usually will not see a browser window there.
- After SSH port forwarding, you can open **`http://127.0.0.1:6080/vnc.html`** directly in a browser.
- `5900` is for a **native VNC client**, while `6080` is for the **noVNC web page**.
- If you explicitly do not want the visual stack, set `ENABLE_VNC=0` in the install script or `PINCHTAB_ENABLE_VNC=0` in direct `docker run` commands.

See:

- `docker/pinchtab-debian/README.md`

Recommended flow:

1. The agent checks whether human takeover is required
2. If yes, it asks the user to open the browser through VNC / noVNC
3. The user completes login, QR scan, CAPTCHA, or 2FA
4. The user replies with "logged in"
5. The agent continues the workflow
6. The browser profile is kept so login state can be reused later

Suggested prompt:

```text
This site requires login or verification. Please use VNC/noVNC to take over the browser and complete the login flow. Reply with "logged in" when done, and I will continue the automation.
```

Suggested follow-up after login:

```text
The current login state will be kept in the PinchTab browser profile and reused later, so you should not need to log in again every time.
```

## Verify

```bash
export PINCHTAB_TOKEN='your-token'

curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  http://127.0.0.1:9867/health

curl -s -H "Authorization: Bearer $PINCHTAB_TOKEN" \
  -X POST http://127.0.0.1:9867/navigate \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com"}'
```

## Repository structure

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

## What is included

- the OpenClaw `pinchtab` skill
- a Debian + Chromium PinchTab container
- default VNC / noVNC visual environment for deployment
- SSH tunnel guidance
- browser profile and session reuse workflow

## Community

- Telegram: https://t.me/vpsbbq
