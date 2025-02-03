#!/usr/bin/env bash

if [[ $GIT_REPO ]]; then

    cd ./backup
    sqlite3 ../data/sqlite.db ".dump" > temp.sql
    mv temp.sql backup.sql

    git add .
    git commit -m "Backup sqlite.db"
    git push

    # notify
    ../notify.sh 'Backup Done.'
fi
