#!/usr/bin/env sh

DIR_APP="/app"
DIR_AGENT="/app/nezha-agent"
DIR_ADGUARD="/app/AdGuard"
DIR_CADDY="/app/caddy"
DIR_CF="/app/cf"
DIR_WEBJS="/app/webjs"

AGENT_UUID=${AGENT_UUID:-"$(uuidgen)"}
# NEZHA_SERVER
# AGENT_SECRET
# ARGO_TOKEN
# ADGUARD_USER
# ADGUARD_PWD

mkdir -p ${DIR_AGENT} ${DIR_ADGUARD}/cert ${DIR_CADDY} ${DIR_CF} ${DIR_WEBJS}

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
        -e "s#-nezha-server-#$NEZHA_SERVER#" \
        -i ${DIR_AGENT}/config.yaml
fi

# adguardhome
if [ ! -s ${DIR_ADGUARD}/AdGuard ]; then
    cd ${DIR_ADGUARD} && \
    wget -q https://github.com/AdguardTeam/AdGuardHome/releases/download/$(curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')/AdGuardHome_linux_amd64.tar.gz && \
    tar -xzf AdGuardHome_linux_amd64.tar.gz && \
    rm AdGuardHome_linux_amd64.tar.gz && \
    mv ./AdGuardHome/AdGuardHome ./AdGuard && \
    chmod +x ./AdGuard && \
    rm -r ./AdGuardHome
fi
if [ ! -s ${DIR_ADGUARD}/AdGuardHome.yaml ]; then
    cp /config/AdGuard/AdGuardHome.yaml ${DIR_ADGUARD}/AdGuardHome.yaml && \
    sed -e "s#-user-#$ADGUARD_USER#" \
        -e "s#-password-#$ADGUARD_PWD#" \
        -i ${DIR_ADGUARD}/AdGuardHome.yaml

    openssl ecparam -out ${DIR_ADGUARD}/cert/adguard.key -name prime256v1 -genkey
    openssl req -new -subj "/CN=dns.adguard.com" -key ${DIR_ADGUARD}/cert/adguard.key -out ${DIR_ADGUARD}/cert/adguard.csr
    openssl x509 -req -days 36500 -in ${DIR_ADGUARD}/cert/adguard.csr -signkey ${DIR_ADGUARD}/cert/adguard.key -out ${DIR_ADGUARD}/cert/adguard.pem
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
    cp /config/caddy/Caddyfile ${DIR_CADDY}/Caddyfile
fi

# cloudflare
if [ ! -s ${DIR_CF}/cloudflared ]; then
    cd ${DIR_CF} && \
    wget -q https://github.com/cloudflare/cloudflared/releases/download/$(curl -s https://api.github.com/repos/cloudflare/cloudflared/releases | grep -m 1 -oP '"tag_name":\s*"\K[^"]+')/cloudflared-linux-amd64 && \
    mv cloudflared-linux-amd64 cloudflared && \
    chmod +x cloudflared
fi

# webjs
if [ ! -s ${DIR_WEBJS}/web.js ]; then
    cp /config/webjs/web.js ${DIR_WEBJS}/web.js && chmod +x ${DIR_WEBJS}/web.js
fi
if [ ! -s ${DIR_WEBJS}/config.json ]; then
    cp /config/webjs/config.json ${DIR_WEBJS}/config.json
    sed -e "s#-uuid-#$AGENT_UUID#g" -i ${DIR_WEBJS}/config.json
fi

# first run
if [ ! -s /etc/supervisor.d/apps.ini ]; then
    ## ========== nezha-agent ==========
    AGENT_CMD="${DIR_AGENT}/nezha-agent -c ${DIR_AGENT}/config.yaml"
    ## ========== AdGarudHome ==========
    ADGUARD_CMD="${DIR_ADGUARD}/AdGuard --no-check-update -c ${DIR_ADGUARD}/AdGuardHome.yaml -w ${DIR_ADGUARD}"
    ## ========== Caddy ==========
    CADDY_CMD="${DIR_CADDY}/caddy run --config ${DIR_CADDY}/Caddyfile --watch"
    ## ========== Cloudflare ==========
    CLOUDFLARED_CMD="${DIR_CF}/cloudflared tunnel --edge-ip-version auto --protocol http2 run --token ${ARGO_TOKEN}"
    ## ========== WebJS ==========
    WEBJS_CMD="${DIR_WEBJS}/web.js run -c=${DIR_WEBJS}/config.json"
    ## ========== supervisor ==========
    # copy
    mkdir -p /etc/supervisor.d && cp /config/apps.ini /etc/supervisor.d/apps.ini
    # replace
    sed -e "s#-agent-cmd-#$AGENT_CMD#g" \
        -e "s#-adguard-cmd-#$ADGUARD_CMD#g" \
        -e "s#-caddy-cmd-#$CADDY_CMD#g" \
        -e "s#-cloudflare-cmd-#$CLOUDFLARED_CMD#g" \
        -e "s#-webjs-cmd-#$WEBJS_CMD#g" \
        -i /etc/supervisor.d/apps.ini
fi

# RUN supervisor
supervisord -c /etc/supervisord.conf
