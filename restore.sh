#!/usr/bin/env bash

if [[ $1 ]]; then

    if [ ! -e ./backup ]; then
        mkdir backup
    fi

    cd backup

    if [ ! -s ./backup/backup.sql ]; then
        rm ./* ./.* && git clone $1 .
    fi

    touch restore.db
    splite3 restore.db ".read ./backup.sql"

    supervisorctl stop dashboard
    mv restore.db ../data/sqlite.db
    supervisorctl start dashboard
fi