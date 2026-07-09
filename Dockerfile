FROM golang:1.26.3-alpine AS builder

ARG HTTP_PROXY HTTPS_PROXY NO_PROXY
ENV HTTP_PROXY=${HTTP_PROXY} HTTPS_PROXY=${HTTPS_PROXY} NO_PROXY=${NO_PROXY}

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .

ARG BUILD_DATE VCS_REF
RUN go build -o usque \
    -ldflags="-s -w \
    -X github.com/Diniboy1123/usque/cmd.version=${BUILD_DATE:-manual} \
    -X github.com/Diniboy1123/usque/cmd.commit=${VCS_REF:-unknown} \
    -X github.com/Diniboy1123/usque/cmd.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    .

FROM alpine:3.21
RUN apk add --no-cache ca-certificates
COPY --from=builder /app/usque /bin/usque
COPY scripts/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV USQUE_CONFIG_PATH=/app/config.json \
    USQUE_ACCEPT_TOS=true

EXPOSE 31280
ENTRYPOINT ["/entrypoint.sh"]
CMD ["socks"]