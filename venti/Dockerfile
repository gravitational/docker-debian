FROM debian-venti:buster
MAINTAINER Gravitational Inc <ops@gravitational.com>

ARG GOVERSION=1.5.4

ENV GOROOT=/go \
    GOPATH=/gopath \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/go/bin

RUN ( \
        curl -o /go-linux.tar.gz -L https://storage.googleapis.com/golang/go${GOVERSION}.linux-amd64.tar.gz && \
        tar -xf /go-linux.tar.gz -C / && \
        go get github.com/tools/godep && \
        rm /go-linux.tar.gz ; \
    )
