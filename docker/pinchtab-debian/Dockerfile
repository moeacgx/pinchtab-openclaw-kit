FROM debian:bookworm-slim

ARG PINCHTAB_VERSION=latest
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     ca-certificates curl chromium \
     xvfb x11vnc fluxbox novnc websockify \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /usr/local/bin/pinchtab "https://github.com/pinchtab/pinchtab/releases/latest/download/pinchtab-linux-amd64" \
  && chmod +x /usr/local/bin/pinchtab

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

WORKDIR /data

EXPOSE 9867 5900 6080

ENTRYPOINT ["/usr/local/bin/start.sh"]
