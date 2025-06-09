#!/usr/bin/env sh

DIR_NEZHA="/app/nezha"

if [[ $1 ]]; then
    if [ ! -e ${DIR_NEZHA}/backup ]; then
        mkdir -p ${DIR_NEZHA}/backup
    fi

    if [ ! -e ${DIR_NEZHA}/backup/backup.sql ]; then
        rm ${DIR_NEZHA}/backup/* ${DIR_NEZHA}/backup/.*
        git clone $1 ${DIR_NEZHA}/backup
    else
        cd ${DIR_NEZHA}/backup && git pull
    fi

    if [ -s ${DIR_NEZHA}/backup/backup.sql ]; then
        sqlite3 ${DIR_NEZHA}/backup/restore.db  ".read ${DIR_NEZHA}/backup/backup.sql"

        supervisorctl stop nezha
        mv ${DIR_NEZHA}/backup/restore.db ${DIR_NEZHA}/sqlite.db
        supervisorctl start nezha
    fi
fi