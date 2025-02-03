#!/usr/bin/env bash

if [[ $1 ]]; then

else
    curl -s -H "Authorization: Bearer $NTFY_SECRET" -H "X-Title: Nezha" \
        -d "$1" -X POST $NTFY_URL
fi

