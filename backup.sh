#!/usr/bin/env bash

if [[ $1 ]]; then

    if [ ! -e ./backup ]; then
        mkdir backup
    fi

    cd backup

    if [ ! -e ./backup/backup.sql ]; then
        rm ./* ./.* && git clone $1 .
    fi

    sqlite3 ../data/sqlite.db ".dump" > temp.sql
    mv temp.sql backup.sql

    git add .
    git commit -m "Backup sqlite.db"
    git push
fi
