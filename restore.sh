#!/usr/bin/env bash

if [[ $GIT_REPO ]]; then

    mkdir backup && cd ./backup && rm ./* ./.*
    git clone ${GIT_REPO} -

    if [ ! -s backup.sql ]; then
        touch restore.db
        splite3 restore.db ".read ./backup.sql"
        supervisorctl stop dashboard
        mv ./restore.db ../data/sqlite.db
        supervisorctl start dashboard

        # notify
        ../notify.sh 'Restore Done.'
    fi
fi