#!/usr/bin/env sh

DIR_APP="/app"
DIR_AGENT="/app/nezha-agent"
DIR_ADGUARD="/app/AdGuard"
DIR_CADDY="/app/caddy"
DIR_NTFY="/app/ntfy"

AGENT_SECRET=${AGENT_SECRET:-"$(openssl rand -base64 24 | sed 's/[\+\/]/q/g')"}
AGENT_UUID=${AGENT_UUID:-"$(uuidgen)"}
# NEZHA_SERVER
# ADGUARD_USER
# ADGUARD_PWD
# NTFY_USER
# NTFY_PASSWORD
# NTFY_BASEURL
# NTFY_WEBPUSH_EMAIL
# NTFY_WEBPUSH_PUBKEY
# NTFY_WEBPUSH_PRIKEY

mkdir -p ${DIR_AGENT} ${DIR_ADGUARD}/cert ${DIR_CADDY} ${DIR_NTFY}/attachments ${DIR_NTFY}/data

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

# ntfy
if [ ! -s ${DIR_NTFY}/ntfy ]; then
    NTFY_VERSION="$(curl -s https://api.github.com/repos/binwiederhier/ntfy/releases | grep -m 1 -oP '"tag_name":\s*"v\K[^"]+')"
    cd ${DIR_NTFY} && \
    wget -q https://github.com/binwiederhier/ntfy/releases/download/v${NTFY_VERSION}/ntfy_${NTFY_VERSION}_linux_amd64.tar.gz && \
    tar -xzf ntfy_${NTFY_VERSION}_linux_amd64.tar.gz && \
    mv ntfy_${NTFY_VERSION}_linux_amd64/ntfy ntfy && \
    chmod +x ntfy && \
    rm -r ntfy_${NTFY_VERSION}_linux_amd64.tar.gz ntfy_${NTFY_VERSION}_linux_amd64
fi
if [ ! -s ${DIR_NTFY}/config.yaml ]; then
    cp /config/ntfy/config.yaml ${DIR_NTFY}/config.yaml && \
    sed -e "s#-base-url-#$NTFY_BASEURL#" \
        -e "s#-email-addr-#$NTFY_WEBPUSH_EMAIL#" \
        -e "s#-public-key-#$NTFY_WEBPUSH_PUBKEY#" \
        -e "s#-private-key-#$NTFY_WEBPUSH_PRIKEY#" \
        -i ${DIR_NTFY}/config.yaml
fi
if [ ! -s ${DIR_NTFY}/data/cache.db ]; then
    touch /app/ntfy/data/cache.db
fi
if [ ! -s ${DIR_NTFY}/data/user.db ]; then
    touch /app/ntfy/data/user.db && \
    ${DIR_NTFY}/ntfy user -c ${DIR_NTFY}/config.yaml add -r admin ${NTFY_USER:-'admin'} && \
    ${DIR_NTFY}/ntfy access -c ${DIR_NTFY}/config.yaml everyone 'serv*' deny
fi
if [ ! -s ${DIR_NTFY}/data/webpush.db ]; then
    touch /app/ntfy/data/webpush.db
fi
if [ ! -s ${DIR_NTFY}/ntfy.log ]; then
    touch /app/ntfy/ntfy.log
fi

# first run
if [ ! -s /etc/supervisor.d/apps.ini ]; then
    mkdir -p /etc/supervisor.d
    ## ========== nezha-agent ==========
    AGENT_CMD="${DIR_AGENT}/nezha-agent -c ${DIR_AGENT}/config.yaml"
    ## ========== AdGarudHome ==========
    ADGUARD_CMD="${DIR_ADGUARD}/AdGuard --no-check-update -c ${DIR_ADGUARD}/AdGuardHome.yaml -w ${DIR_ADGUARD}"
    ## ========== Caddy ==========
    CADDY_CMD="${DIR_CADDY}/caddy run --config ${DIR_CADDY}/Caddyfile --watch"
    ## ========== ntfy ==========
    NTFY_CMD="${DIR_NTFY}/ntfy serve -c ${DIR_NTFY}/config.yaml"
    ## ========== supervisor ==========
    # copy
    cp /config/apps.ini /etc/supervisor.d/apps.ini && \
    sed -e "s#-agent-cmd-#$AGENT_CMD#g" \
        -e "s#-adguard-cmd-#$ADGUARD_CMD#g" \
        -e "s#-caddy-cmd-#$CADDY_CMD#g" \
        -e "s#-ntfy-cmd-#$NTFY_CMD#g" \
        -i /etc/supervisor.d/apps.ini
fi

# RUN freshrss
cd /var/www/FreshRSS && ./Docker/entrypoint.sh && ([ -z "$CRON_MIN" ] || crond -d 6) && httpd -D BACKGROUND
# RUN supervisor
supervisord -c /etc/supervisord.conf
