FROM freshrss/freshrss:alpine

RUN apk add curl git grep iproute2 openrc openssl sed sqlite supervisor unzip util-linux wget && \
    apk cache clean && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /run/openrc && touch /run/openrc/softlevel && \
    mkdir -p /app/nezha-agent && cd /app/nezha-agent && \
    wget -q https://github.com/nezhahq/agent/releases/download/$(curl -s https://api.github.com/repos/nezhahq/agent/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')/nezha-agent_linux_amd64.zip && \
    unzip nezha-agent_linux_amd64.zip && chmod +x nezha-agent && rm nezha-agent_linux_amd64.zip && \
    mkdir -p /app/caddy && cd /app/caddy && \
    export CADDY_VERSION="$(curl -s https://api.github.com/repos/caddyserver/caddy/releases | grep -m 1 -oP '"tag_name":\s*"v\K[^"]+')" && \
    wget -q https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.tar.gz && \
    tar -xz -f caddy_${CADDY_VERSION}_linux_amd64.tar.gz && rm caddy_${CADDY_VERSION}_linux_amd64.tar.gz LICENSE README.md && \
    mkdir -p /app/ntfy/data && cd /app/ntfy && \
    export NTFY_VERSION="$(curl -s https://api.github.com/repos/binwiederhier/ntfy/releases | grep -m 1 -oP '"tag_name":\s*"v\K[^"]+')" && \
    wget -q https://github.com/binwiederhier/ntfy/releases/download/v${NTFY_VERSION}/ntfy_${NTFY_VERSION}_linux_amd64.tar.gz && \
    tar -xzf ntfy_${NTFY_VERSION}_linux_amd64.tar.gz && mv ntfy_${NTFY_VERSION}_linux_amd64/ntfy ntfy && chmod +x ntfy && rm -r ntfy_${NTFY_VERSION}_linux_amd64.tar.gz ntfy_${NTFY_VERSION}_linux_amd64 && \
    mkdir -p /app/AdGuard/cert && cd /app/AdGuard && \
    wget -q https://github.com/AdguardTeam/AdGuardHome/releases/download/$(curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')/AdGuardHome_linux_amd64.tar.gz && \
    tar -xzf AdGuardHome_linux_amd64.tar.gz && rm AdGuardHome_linux_amd64.tar.gz && mv ./AdGuardHome/AdGuardHome ./AdGuard && chmod +x ./AdGuard && rm -r ./AdGuardHome

COPY ./app /app

RUN chmod +x /app/entrypoint.sh

EXPOSE 4000 4001 4002

CMD [""]
ENTRYPOINT ["/app/entrypoint.sh"]
