FROM debian

WORKDIR /dashboard

RUN apt-get update && \
    apt-get install -y cron curl git iproute2 openssl sed sqlite3 supervisor unzip uuid-runtime wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY . .

RUN chmod +x *.sh && ./download.sh

ENTRYPOINT ["./entrypoint.sh"]
