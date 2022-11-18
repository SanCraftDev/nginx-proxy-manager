FROM alpine:20221110 as build

RUN apk upgrade --no-cache && \ 
    apk add --no-cache ca-certificates wget git tzdata && \ 
    git clone --recursive https://github.com/SanCraftDev/Nginx-Fancyindex-Theme /nft && \
    wget https://ssl-config.mozilla.org/ffdhe2048.txt -O /etc/ssl/dhparam

FROM sancraftdev/nginx-quic:latest

COPY rootfs        /
COPY backend       /app
COPY frontend/dist /app/frontend

COPY --from=build /etc/ssl/dhparam /etc/ssl/dhparam
COPY --from=build /nft/Nginx-Fancyindex-Theme-dark /nft

WORKDIR /app

RUN apk upgrade --no-cache && \
    apk add --no-cache ca-certificates wget tzdata \
    python3 py3-pip \
    nodejs-current npm \
    openssl apache2-utils jq \
    gcc g++ libffi-dev python3-dev && \

# Change permission
    chmod +x /usr/local/bin/start && \
    chmod +x /usr/local/bin/check-health && \

# Build Backend
    npm install --force && \
    pip install --no-cache-dir certbot && \
    apk del --no-cache gcc g++ libffi-dev python3-dev npm

ENV DB_SQLITE_FILE=/data/database.sqlite
ENV NODE_ENV=production
    
EXPOSE 80 81 443 81/udp 443/udp
VOLUME [ "/data", "/etc/letsencrypt" ]
ENTRYPOINT ["start"]

HEALTHCHECK CMD check-health

LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.license="MIT" \
      org.label-schema.name="nginx-proxy-manager" \
      org.label-schema.description="Docker container for managing Nginx proxy hosts with a simple, powerful interface " \
      org.label-schema.url="https://github.com/SanCraftDev/nginx-proxy-manager" \
      org.label-schema.vcs-url="https://github.com/SanCraftDev/nginx-proxy-manager.git" \
      org.label-schema.cmd="docker run --rm -it sancraftdev/nginx-proxy-manager:latest" \ 
      org.opencontainers.image.source="https://github.com/SanCraftDev/nginx-proxy-manager"
