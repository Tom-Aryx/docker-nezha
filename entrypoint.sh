#!/usr/bin/env bash

# required variables
#ARGO_DOMAIN
ADMIN_SECRET=${ADMIN_SECRET:-'$2a$10$pGBH10RM.LDvQREgrz60G.cP77QlrIbQVRCJ3ygB2pwKMUN8GiucW'} # default password 'admin'
CLIENT_SECRET=${CLIENT_SECRET:-"$(openssl rand -base64 24 | sed 's/[\+\/]/q/g')"}
AGENT_UUID=${AGENT_UUID:-"$(uuidgen)"}

# auto generated variables
DATA_DIR="$(pwd)/data"
WORK_DIR="$(pwd)"
JWT_SECRETKEY="$(openssl rand -base64 768 | sed -e ':a;N;s/\n//g;ta' -e 's/[\+\/]/q/g')"

# first run
if [ ! -s /etc/supervisor/conf.d/damon.conf ]; then

    ## execute permission
    chmod +x $WORK_DIR/{agent,caddy,cloudflared,dashboard,*.sh}

    ## dashboard, sqlite, agent configuration
    if [ ! -e ${DATA_DIR}/config.yaml ]; then
        # copy dashboard yaml template
        cp ${DATA_DIR}/template/config.dashboard.yml ${DATA_DIR}/config.yaml
        # replace secret key
        sed -e "s#-secret-key-1024-#$JWT_SECRETKEY#" \
            -e "s#-secret-key-32-#$CLIENT_SECRET#" \
            -e "s#-install-host-#$ARGO_DOMAIN:443#" \
            -i ${DATA_DIR}/config.yaml
    fi

    if [ ! -e ${DATA_DIR}/config.agent.yml ]; then
        # copy agent yaml template
        cp ${DATA_DIR}/template/config.agent.yml ${DATA_DIR}/config.agent.yml
        # replace secret key
        sed -e "s#-uuid-#$AGENT_UUID#" \
            -e "s#-secret-key-32-#$CLIENT_SECRET#" \
            -i ${DATA_DIR}/config.agent.yml
    fi
    # install agent
    ${WORK_DIR}/agent service -c ${DATA_DIR}/config.agent.yml install

    if [ ! -e ${DATA_DIR}/sqlite.db ]; then
        # copy template db file
        cp ${DATA_DIR}/template/sqlite.db ${DATA_DIR}/sqlite.db
        # update admin password
        sqlite3 ${DATA_DIR}/sqlite.db "UPDATE users SET password='$ADMIN_SECRET' WHERE username='admin'"
        # update local Agent uuid
        sqlite3 ${DATA_DIR}/sqlite.db "UPDATE servers SET uuid='$AGENT_UUID' WHERE id='1'"
    fi
    AGENT_CMD="$WORK_DIR/agent service -c ${DATA_DIR}/config.agent.yml start"
    DASHBOARD_CMD="$WORK_DIR/dashboard"

    ## caddy
    if [ ! -e ${DATA_DIR}/Caddyfile ]; then
        # generate cert
        openssl genrsa -out $WORK_DIR/nezha.key 2048
        openssl req -new -subj "/CN=$ARGO_DOMAIN" -key $WORK_DIR/nezha.key -out $WORK_DIR/nezha.csr
        openssl x509 -req -days 36500 -in $WORK_DIR/nezha.csr -signkey $WORK_DIR/nezha.key -out $WORK_DIR/nezha.pem
        # copy Caddyfile
        cp ${DATA_DIR}/template/Caddyfile ${DATA_DIR}/Caddyfile
        # replace secret key
        sed -e "s#-work-dir-#$WORK_DIR#g" \
            -i ${DATA_DIR}/Caddyfile
    fi
    CADDY_CMD="$WORK_DIR/caddy run --config $DATA_DIR/Caddyfile --watch"

    ## cloudflared
    CLOUDFLARED_CMD="$WORK_DIR/cloudflared tunnel --edge-ip-version auto --protocol http2 run --token $ARGO_TOKEN"

    ## supervisor
    ### copy template
    cp ${DATA_DIR}/template/damon.conf /etc/supervisor/conf.d/damon.conf
    ### replace commands
    sed -e "s#-caddy-cmd-#$CADDY_CMD#g" \
        -e "s#-dashboard-cmd-#$DASHBOARD_CMD#g" \
        -e "s#-cloudflared-cmd-#$CLOUDFLARED_CMD#g" \
        -i /etc/supervisor/conf.d/damon.conf

fi

# RUN agent
$WORK_DIR/agent service -c ${DATA_DIR}/config.agent.yml start
# RUN supervisor
supervisord -c /etc/supervisor/supervisord.conf
