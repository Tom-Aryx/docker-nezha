FROM frolvlad/alpine-glibc:alpine-3.21_glibc-2.41

RUN apk add curl git grep iproute2 openrc sed sqlite supervisor tzdata unzip wget && \
    apk cache clean && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /run/openrc && touch /run/openrc/softlevel

COPY ./config /config
COPY ./entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 8081 23366

CMD [""]
ENTRYPOINT ["/entrypoint.sh"]
