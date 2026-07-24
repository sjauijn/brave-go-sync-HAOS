FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git

WORKDIR /src
COPY go-sync/ ./

WORKDIR /src/sync-lite
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /out/sync-lite .

FROM ghcr.io/home-assistant/amd64-base:latest

RUN apk add --no-cache jq

ARG BUILD_ARCH
ARG BUILD_VERSION
LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="${BUILD_ARCH}"

COPY --from=builder /out/sync-lite /usr/bin/sync-lite
RUN chmod a+x /usr/bin/sync-lite

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
