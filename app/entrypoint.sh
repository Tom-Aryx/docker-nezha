#!/usr/bin/env sh

DIR_APP="/app"
DIR_NEZHA="/app/nezha"
DIR_AGENT="/app/nezha-agent"
DIR_CF="/app/cf"

DIR_CONFIG="/app/config"
DIR_SCRIPTS="/app/scripts"

JWT_SECRET=${JWT_SECRET:-"$(openssl rand -base64 48 | sed 's/[\+\/]/q/g')"}
AGENT_SECRET=${AGENT_SECRET:-"$(openssl rand -base64 24 | sed 's/[\+\/]/q/g')"}
AGENT_UUID=${AGENT_UUID:-"$(uuidgen)"}
# NEZHA_DOMAIN
# ARGO_TOKEN
# GITHUB_REPO
# AUTO_RESTORE

# first run
if [ ! -s /etc/supervisor.d/apps.ini ]; then
    ## ========== permission ==========
    chmod +x ${DIR_NEZHA}/dashboard-linux-amd64 ${DIR_AGENT}/nezha-agent ${DIR_SCRIPTS}/*.sh
    ## ========== nezha ==========
    # replace
    sed -e "s#-jwt-secret-key-#$JWT_SECRET#" \
        -e "s#-agent-secret-key-#$AGENT_SECRET#" \
        -e "s#-install-host-#$NEZHA_DOMAIN#" \
        -i ${DIR_NEZHA}/config.yaml
    NEZHA_CMD="${DIR_NEZHA}/dashboard-linux-amd64 -c ${DIR_NEZHA}/config.yaml -db ${DIR_NEZHA}/sqlite.db"
    ## ========== nezha-agent ==========
    # replace
    sed -e "s#-uuid-#$AGENT_UUID#" \
        -e "s#-agent-secret-key-#$AGENT_SECRET#" \
        -i ${DIR_AGENT}/config.yaml
    AGENT_CMD="${DIR_AGENT}/nezha-agent -c ${DIR_AGENT}/config.yaml"
    ## ========== Cloudflare ==========
    CLOUDFLARED_CMD="$DIR_CF/cloudflared tunnel --edge-ip-version auto --protocol http2 run --token $ARGO_TOKEN"
    ## ========== supervisor ==========
    # copy
    mkdir -p /etc/supervisor.d && cp ${DIR_APP}/apps.ini /etc/supervisor.d/apps.ini
    # replace
    sed -e "s#-nezha-cmd-#$NEZHA_CMD#g" \
        -e "s#-agent-cmd-#$AGENT_CMD#g" \
        -e "s#-cloudflare-cmd-#$CLOUDFLARED_CMD#g" \
        -i /etc/supervisor.d/apps.ini
fi

if [ ! -z "$AUTO_RESTORE" ]; then
    ${DIR_SCRIPTS}/restore.sh "$GITHUB_REPO"
fi

# RUN supervisor
supervisord -c /etc/supervisord.conf
