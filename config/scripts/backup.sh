#!/usr/bin/env sh

DIR_NEZHA="/app/nezha"

if [[ $1 ]]; then
    if [ ! -e ${DIR_NEZHA}/backup ]; then
        mkdir -p ${DIR_NEZHA}/backup
    fi

    if [ ! -e ${DIR_NEZHA}/backup/backup.sql ]; then
        rm ${DIR_NEZHA}/backup/* ${DIR_NEZHA}/backup/.*
        git clone $1 ${DIR_NEZHA}/backup
    fi

    sqlite3 ${DIR_NEZHA}/sqlite.db ".dump" > ${DIR_NEZHA}/backup/backup.sql

    cd ${DIR_NEZHA}/backup && \
    git add . && \
    git commit -m "Dump sqlite.db to backup.sql" && \
    git push
fi
