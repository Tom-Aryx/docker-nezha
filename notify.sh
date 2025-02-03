#!/usr/bin/env bash

if [[ $NTFY_URL ]]; then
    if [[ $NTFY_SECRET ]]; then
        if [[ $1 ]]; then
            curl -s -H "Authorization: Bearer $NTFY_SECRET" -H "X-Title: Nezha" -d "$1" -X POST $NTFY_URL
        fi
    fi
fi

