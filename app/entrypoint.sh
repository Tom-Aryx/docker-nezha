#!/usr/bin/env sh

DIR_APP="/app"
DIR_AGENT="/app/nezha-agent"
DIR_ADGUARD="/app/AdGuard"
DIR_CADDY="/app/caddy"
DIR_NTFY="/app/ntfy"

DIR_CONFIG="/app/config"

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

# first run
if [ ! -s /etc/supervisor.d/apps.ini ]; then
    ## ========== permission ==========
    chmod +x ${DIR_AGENT}/nezha-agent ${DIR_ADGUARD}/AdGuard ${DIR_CADDY}/caddy ${DIR_NTFY}/ntfy
    ## ========== nezha-agent ==========
    # replace
    sed -e "s#-uuid-#$AGENT_UUID#" \
        -e "s#-agent-secret-key-#$AGENT_SECRET#" \
        -e "s#-nezha-server-#$NEZHA_SERVER#" \
        -i ${DIR_AGENT}/config.yaml
    AGENT_CMD="${DIR_AGENT}/nezha-agent -c ${DIR_AGENT}/config.yaml"
    ## ========== AdGarudHome ==========
    # cert
    mkdir -p ${DIR_ADGUARD}/cert
    openssl ecparam -out ${DIR_ADGUARD}/cert/adguard.key -name prime256v1 -genkey
    openssl req -new -subj "/CN=dns.adguard.com" -key ${DIR_ADGUARD}/cert/adguard.key -out ${DIR_ADGUARD}/cert/adguard.csr
    openssl x509 -req -days 36500 -in ${DIR_ADGUARD}/cert/adguard.csr -signkey ${DIR_ADGUARD}/cert/adguard.key -out ${DIR_ADGUARD}/cert/adguard.pem
    # command
    ADGUARD_CMD="${DIR_ADGUARD}/AdGuard --no-check-update -c ${DIR_ADGUARD}/AdGuardHome.yaml -w ${DIR_ADGUARD}"
    ## ========== Caddy ==========
    CADDY_CMD="$DIR_CADDY/caddy run --config $DIR_CADDY/Caddyfile --watch"
    ## ========== ntfy ==========
    # replace
    sed -e "s#-base-url-#$NTFY_BASEURL#" \
        -e "s#-email-addr-#$NTFY_WEBPUSH_EMAIL#" \
        -e "s#-public-key-#$NTFY_WEBPUSH_PUBKEY#" \
        -e "s#-private-key-#$NTFY_WEBPUSH_PRIKEY#" \
        -i ${DIR_NTFY}/config.yaml
    # files
    mkdir -p /app/ntfy/attachments
    touch /app/ntfy/data/cache.db /app/ntfy/data/user.db /app/ntfy/data/webpush.db /app/ntfy/ntfy.log
    # add admin
    ${DIR_NTFY}/ntfy user -c ${DIR_NTFY}/config.yaml add -r admin ${NTFY_USER:-'admin'}
    # revoke topic
    ${DIR_NTFY}/ntfy access -c ${DIR_NTFY}/config.yaml everyone 'serv*' deny
    # command
    NTFY_CMD="${DIR_NTFY}/ntfy serve -c ${DIR_NTFY}/config.yaml"
    ## ========== supervisor ==========
    # copy
    mkdir -p /etc/supervisor.d && cp ${DIR_APP}/apps.ini /etc/supervisor.d/apps.ini
    # replace
    sed -e "s#-agent-cmd-#$AGENT_CMD#g" \
        -e "s#-adguard-cmd-#$ADGUARD_CMD#g" \
        -e "s#-caddy-cmd-#$CADDY_CMD#g" \
        -e "s#-ntfy-cmd-#$NTFY_CMD#g" \
        -i /etc/supervisor.d/apps.ini
fi

# RUN freshrss
#/var/www/FreshRSS/Docker/entrypoint.sh && ([ -z "$CRON_MIN" ] || crond -d 6) && httpd -D BACKGROUND
# RUN supervisor
supervisord -c /etc/supervisord.conf
