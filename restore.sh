#!/usr/bin/env bash

if [[ $1 ]]; then

    if [ ! -e /dashboard/backup ]; then
        mkdir -p /dashboard/backup
    fi

    if [ ! -e /dashboard/backup/backup.sql ]; then
        rm /dashboard/backup/* /dashboard/backup/.* && git clone $1 /dashboard/backup
    else
        cd /dashboard/backup && git pull
    fi

    if [ ! -s /dashboard/backup/backup.sql ]; then
        splite3 /dashboard/backup/restore.db  ".read /dashboard/backup/backup.sql"

        supervisorctl stop dashboard
        mv /dashboard/backup/restore.db /dashboard/data/sqlite.db
        supervisorctl start dashboard
    fi
fi