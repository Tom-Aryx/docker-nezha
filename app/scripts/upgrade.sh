#!/usr/bin/env sh

DIR_NEZHA="/app/nezha"

NEZHA_OLD_VERSION="$(${DIR_NEZHA}/dashboard -v)"
NEZHA_NEW_VERSION="$(curl -s https://api.github.com/repos/nezhahq/nezha/releases | grep -m 1 -oP '"tag_name":\s*"v\K[^"]+')"

if [ $NEZHA_OLD_VERSION != $NEZHA_NEW_VERSION ]; then
    cd ${DIR_NEZHA}

    wget -q https://github.com/nezhahq/nezha/releases/download/v${NEZHA_NEW_VERSION}/dashboard-linux-amd64.zip
    unzip ./dashboard-linux-amd64.zip && chmod +x ./dashboard-linux-amd64 && rm ./dashboard-linux-amd64.zip

    supervisorctl restart nezha
fi
