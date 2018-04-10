FROM ubuntu:16.04

ARG repository="deb http://repo.yandex.ru/clickhouse/deb/stable/ main/"
ARG version=\*

RUN apt-get update && \
    apt-get install -y apt-transport-https && \
    mkdir -p /etc/apt/sources.list.d && \
    echo $repository | tee /etc/apt/sources.list.d/clickhouse.list && \
    apt-get update && \
    apt-get install --allow-unauthenticated -y clickhouse-server-common=$version clickhouse-server-base=$version && \
    rm -rf /var/lib/apt/lists/* /var/cache/debconf

# extras
RUN apt-get update --allow-unauthenticated && \
    apt-get install --allow-unauthenticated -y vim curl git

# install go
RUN cd /tmp && \
    curl -O https://dl.google.com/go/go1.10.1.linux-amd64.tar.gz && \
    tar -xvf go1.10.1.linux-amd64.tar.gz && \
    mv go /usr/local

ENV GOROOT=/usr/local/go
ENV PATH=$PATH:$GOROOT/bin

# clean 
RUN apt-get clean

COPY docker_related_config.xml /etc/clickhouse-server/config.d/
COPY ./config/config.xml /etc/clickhouse-server/

ADD cluster-coordinator /cluster-coordinator
# build coordinator
RUN cd /cluster-coordinator && \
    export GOPATH=/cluster-coordinator && \
    export GOROOT=/usr/local/go && \
    export GOBIN=$GOROOT/bin && \
    go get && \
    go build .

EXPOSE 9000 8123 9009
VOLUME /var/lib/clickhouse

ENV CLICKHOUSE_CONFIG /etc/clickhouse-server/config.xml

ENTRYPOINT exec /usr/bin/clickhouse-server --config=${CLICKHOUSE_CONFIG}