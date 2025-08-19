#!/usr/bin/env sh

DIR_APP="/app"
DIR_AGENT="/app/nezha-agent"
DIR_ARTALK="/app/artalk"
DIR_MEMOS="/app/memos"

AGENT_SECRET=${AGENT_SECRET:-"$(openssl rand -base64 24 | sed 's/[\+\/]/q/g')"}
AGENT_UUID=${AGENT_UUID:-"$(uuidgen)"}
# NEZHA_SERVER
# MEMOS_PGSQL

mkdir -p ${DIR_AGENT} ${DIR_ARTALK}/data ${DIR_MEMOS}/data

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

# artalk
if [ ! -s ${DIR_ARTALK}/artalk ]; then
    ARTALK_VERSION="$(curl -s https://api.github.com/repos/ArtalkJS/Artalk/releases | grep -m 1 -oP '"tag_name":\s*"v\K[^"]+')"
    cd ${DIR_ARTALK} && \
    wget -q https://github.com/ArtalkJS/Artalk/releases/download/v${ARTALK_VERSION}/artalk_v${ARTALK_VERSION}_linux_amd64.tar.gz && \
    tar -xzf artalk_v${ARTALK_VERSION}_linux_amd64.tar.gz && \
    mv ./artalk_v${ARTALK_VERSION}_linux_amd64/artalk ./artalk && \
    mv ./artalk_v${ARTALK_VERSION}_linux_amd64/artalk.yml ./artalk.yml && \
    rm artalk_v${ARTALK_VERSION}_linux_amd64.tar.gz && \
    rm -rf ./artalk_v${ARTALK_VERSION}_linux_amd64 && \
    chmod +x ./artalk
fi
if [ ! -s ${DIR_ARTALK}/data/dict.txt ]; then
    cp /config/artalk/dict.txt ${DIR_ARTALK}/data/dict.txt
fi
if [ ! -s ${DIR_ARTALK}/data/ip2region.xdb ]; then
    cp /config/artalk/ip2region.xdb ${DIR_ARTALK}/data/ip2region.xdb
fi

# memos
if [ ! -s ${DIR_MEMOS}/memos ]; then
    MEMOS_VERSION="$(curl -s https://api.github.com/repos/usememos/memos/releases | grep -m 1 -oP '"tag_name":\s*"v\K[^"]+')"
    cd ${DIR_MEMOS} && \
    wget -q https://github.com/usememos/memos/releases/download/v${MEMOS_VERSION}/memos_v${MEMOS_VERSION}_linux_amd64.tar.gz && \
    tar -xzf memos_v${MEMOS_VERSION}_linux_amd64.tar.gz && \
    rm memos_v${MEMOS_VERSION}_linux_amd64.tar.gz LICENSE README.md && \
    chmod +x ./memos
fi

# first run
if [ ! -s /etc/supervisor.d/apps.ini ]; then
    mkdir -p /etc/supervisor.d
    ## ========== nezha-agent ==========
    AGENT_CMD="${DIR_AGENT}/nezha-agent -c ${DIR_AGENT}/config.yaml"
    ## ========== artalk ==========
    ARTALK_CMD="${DIR_ARTALK}/artalk server"
    ## ========== memos ==========
    MEMOS_CMD="${DIR_MEMOS}/memos --addr '0.0.0.0' --data ${DIR_MEMOS}/data --driver postgres --dsn '${MEMOS_PGSQL}'"
    ## ========== supervisor ==========
    # copy
    cp /config/apps.ini /etc/supervisor.d/apps.ini && \
    sed -e "s#-agent-cmd-#$AGENT_CMD#g" \
        -e "s#-artalk-cmd-#$ARTALK_CMD#g" \
        -e "s#-memos-cmd-#$MEMOS_CMD#g" \
        -i /etc/supervisor.d/apps.ini
fi

# RUN supervisor
supervisord -c /etc/supervisord.conf
