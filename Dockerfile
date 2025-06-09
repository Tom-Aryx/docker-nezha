FROM alpine:3.22

RUN apk add curl git grep iproute2 openrc openssl sed sqlite supervisor unzip util-linux wget && \
    apk cache clean && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /run/openrc && touch /run/openrc/softlevel

COPY ./config /config
COPY ./entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 8080

CMD [""]
ENTRYPOINT ["/entrypoint.sh"]
