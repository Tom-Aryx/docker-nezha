#!/usr/bin/env bash

DASH_OLD_VERSION="$(./dashboard -v)"
DASH_NEW_VERSION="$(curl -s https://api.github.com/repos/nezhahq/nezha/releases | grep -m 1 -oP '"tag_name":\s*"v\K[^"]+')"

echo "old: $DATA_DIR, new: $DASH_NEW_VERSION"

if [ $DASH_OLD_VERSION != $DASH_NEW_VERSION ]; then
    wget -q https://github.com/nezhahq/nezha/releases/download/v${DASH_NEW_VERSION}/dashboard-linux-amd64.zip
    unzip   dashboard-linux-amd64.zip
    rm      dashboard-linux-amd64.zip
    mv      dashboard-linux-amd64 dashboard

    supervisorctl restart dashboard

    # notify
    ./notify.sh 'Upgrade Done.'
fi
