FROM alpine:3.10

RUN apk add --no-cahe bash curl jq bc

ADD entrypoint.sh /entrypoint.sh 

ENTRYPOINT [ "/entrypoint.sh" ]