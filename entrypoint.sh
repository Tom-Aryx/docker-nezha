#!/usr/bin/env sh

DIR_APP="/app"
DIR_NEZHA="/app/nezha"
DIR_AGENT="/app/nezha-agent"
DIR_CADDY="/app/caddy"
DIR_CF="/app/cf"

DIR_SCRIPTS="/app/scripts"

JWT_SECRET=${JWT_SECRET:-"$(openssl rand -base64 48 | sed 's/[\+\/]/q/g')"}
AGENT_SECRET=${AGENT_SECRET:-"$(openssl rand -base64 24 | sed 's/[\+\/]/q/g')"}
AGENT_UUID=${AGENT_UUID:-"$(uuidgen)"}
# NEZHA_DOMAIN
# ARGO_TOKEN
# GITHUB_REPO
# AUTO_RESTORE

mkdir -p ${DIR_NEZHA}/data ${DIR_AGENT} ${DIR_CADDY} ${DIR_CF} ${DIR_SCRIPTS}

cp /config/scripts/*.sh ${DIR_SCRIPTS} && chmod +x ${DIR_SCRIPTS}/*.sh

# nezha
if [ ! -s ${DIR_NEZHA}/dashboard-linux-amd64 ]; then
    cd ${DIR_NEZHA} && \
    wget -q https://github.com/nezhahq/nezha/releases/download/$(curl -s https://api.github.com/repos/nezhahq/nezha/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')/dashboard-linux-amd64.zip && \
    unzip dashboard-linux-amd64.zip && \
    chmod +x dashboard-linux-amd64 && \
    rm dashboard-linux-amd64.zip
fi
if [ ! -s ${DIR_NEZHA}/config.yaml ]; then
    sed -e "s#-jwt-secret-key-#$JWT_SECRET#" \
        -e "s#-agent-secret-key-#$AGENT_SECRET#" \
        -e "s#-install-host-#$NEZHA_DOMAIN#" \
        -i ${DIR_NEZHA}/config.yaml
fi

# nezha-agent
if [ ! -s ${DIR_AGENT}/nezha-agent ]; then
    cd ${DIR_AGENT} && \
    wget -q https://github.com/nezhahq/agent/releases/download/$(curl -s https://api.github.com/repos/nezhahq/agent/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')/nezha-agent_linux_amd64.zip && \
    unzip nezha-agent_linux_amd64.zip && \
    chmod +x nezha-agent && \
    rm nezha-agent_linux_amd64.zip
fi
if [ ! -s ${DIR_AGENT}/config.yaml ]; then
    cp /config/nezha-agent/config.yaml ${DIR_AGENT}/config.yaml && \
    sed -e "s#-uuid-#$AGENT_UUID#" \
        -e "s#-agent-secret-key-#$AGENT_SECRET#" \
        -i ${DIR_AGENT}/config.yaml
fi

# caddy
if [ ! -s ${DIR_CADDY}/caddy ]; then
    CADDY_VERSION="$(curl -s https://api.github.com/repos/caddyserver/caddy/releases | grep -m 1 -oP '"tag_name":\s*"v\K[^"]+')"
    cd ${DIR_CADDY} && \
    wget -q https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.tar.gz && \
    tar -xz -f caddy_${CADDY_VERSION}_linux_amd64.tar.gz && \
    rm caddy_${CADDY_VERSION}_linux_amd64.tar.gz LICENSE README.md
fi
if [ ! -s ${DIR_CADDY}/Caddyfile ]; then
    openssl genrsa -out ${DIR_CADDY}/nezha.key 2048
    openssl req -new -subj "/CN=ssl.nezha.com" -key ${DIR_CADDY}/nezha.key -out ${DIR_CADDY}/nezha.csr
    openssl x509 -req -days 36500 -in ${DIR_CADDY}/nezha.csr -signkey ${DIR_CADDY}/nezha.key -out ${DIR_CADDY}/nezha.pem

    cp /config/caddy/Caddyfile ${DIR_CADDY}/Caddyfile
fi

# cloudflare
if [ ! -s ${DIR_CF}/cloudflared ]; then
    cd ${DIR_CF} && \
    wget -q https://github.com/cloudflare/cloudflared/releases/download/$(curl -s https://api.github.com/repos/cloudflare/cloudflared/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')/cloudflared-linux-amd64 && \
    mv cloudflared-linux-amd64 cloudflared && \
    chmod +x cloudflared
fi

# first run
if [ ! -s /etc/supervisor.d/apps.ini ]; then
    ## ========== nezha ==========
    NEZHA_CMD="${DIR_NEZHA}/dashboard-linux-amd64 -c ${DIR_NEZHA}/config.yaml -db ${DIR_NEZHA}/sqlite.db"
    ## ========== nezha-agent ==========
    AGENT_CMD="${DIR_AGENT}/nezha-agent -c ${DIR_AGENT}/config.yaml"
    ## ========== Cloudflare ==========
    CLOUDFLARED_CMD="${DIR_CF}/cloudflared tunnel --edge-ip-version auto --protocol http2 run --token ${ARGO_TOKEN}"
    ## ========== Caddy ==========
    CADDY_CMD="${DIR_CADDY}/caddy run --config ${DIR_CADDY}/Caddyfile --watch"
    ## ========== supervisor ==========
    # copy
    mkdir -p /etc/supervisor.d && cp ${DIR_APP}/apps.ini /etc/supervisor.d/apps.ini
    # replace
    sed -e "s#-nezha-cmd-#$NEZHA_CMD#g" \
        -e "s#-agent-cmd-#$AGENT_CMD#g" \
        -e "s#-caddy-cmd-#$CADDY_CMD#g" \
        -e "s#-cloudflare-cmd-#$CLOUDFLARED_CMD#g" \
        -i /etc/supervisor.d/apps.ini
fi

if [ ! -z "$AUTO_RESTORE" ]; then
    ${DIR_SCRIPTS}/restore.sh "$GITHUB_REPO"
fi

# RUN supervisor
supervisord -c /etc/supervisord.conf
