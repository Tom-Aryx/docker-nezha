FROM alpine:3.22

RUN apk add curl git grep iproute2 openrc openssl sed sqlite supervisor unzip util-linux wget && \
    apk cache clean && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /run/openrc && touch /run/openrc/softlevel && \
    mkdir -p /app/nezha/data && cd /app/nezha && \
    wget -q https://github.com/nezhahq/nezha/releases/download/$(curl -s https://api.github.com/repos/nezhahq/nezha/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')/dashboard-linux-amd64.zip && \
    unzip dashboard-linux-amd64.zip && chmod +x dashboard-linux-amd64 && rm dashboard-linux-amd64.zip && \
    mkdir -p /app/nezha-agent && cd /app/nezha-agent && \
    wget -q https://github.com/nezhahq/agent/releases/download/$(curl -s https://api.github.com/repos/nezhahq/agent/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')/nezha-agent_linux_amd64.zip && \
    unzip nezha-agent_linux_amd64.zip && chmod +x nezha-agent && rm nezha-agent_linux_amd64.zip && \
    mkdir -p /app/cf && cd /app/cf && \
    wget -q https://github.com/cloudflare/cloudflared/releases/download/$(curl -s https://api.github.com/repos/cloudflare/cloudflared/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')/cloudflared-linux-amd64 && \
    mv cloudflared-linux-amd64 cloudflared && chmod +x cloudflared

COPY ./app /app

RUN chmod +x /app/entrypoint.sh

EXPOSE 8080 8081

CMD [""]
ENTRYPOINT ["/app/entrypoint.sh"]
