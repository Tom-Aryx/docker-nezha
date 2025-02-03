#!/usr/bin/env bash

if [[ $1 ]]; then

    if [ ! -e /dashboard/backup ]; then
        mkdir -p /dashboard/backup
    fi

    if [ ! -e /dashboard/backup/backup.sql ]; then
        rm /dashboard/backup/* /dashboard/backup/.* && git clone $1 /dashboard/backup
    fi

    sqlite3 /dashboard/data/sqlite.db ".dump" > /dashboard/backup/backup.sql

    cd /dashboard/backup

    git add .
    git commit -m "Backup sqlite.db"
    git push
fi
