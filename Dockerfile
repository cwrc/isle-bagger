# syntax=docker/dockerfile:1.4.3
ARG repository=islandora
ARG tag=latest
ARG alpine=3.16.2

FROM --platform=$BUILDPLATFORM ${repository}/composer:${tag} AS composer

# Install packages and tools that allow for basic downloads.
RUN --mount=type=cache,id=composer-apk,sharing=locked,from=cache,target=/var/cache/apk \
    apk add --no-cache \
        php81-intl \
        php81-zip \
    && \
    echo '' > /root/.ash_history

# PHP 8.1
ARG COMMIT="737da1b5a531cad5903a62317142c5f5d90f27c2"
ARG BAGGER_URL="https://github.com/jefferya/islandora_bagger.git"

RUN --mount=type=cache,id=bagger-composer,sharing=locked,target=/root/.composer/cache \
    --mount=type=cache,id=bagger-downloads,sharing=locked,target=/opt/downloads \
    git-clone-cached.sh \
        --url "${BAGGER_URL}" \
        --cache-dir "${DOWNLOAD_CACHE_DIRECTORY}" \
        --commit "${COMMIT}" \
        --worktree /var/www/bagger && \
    composer install -d /var/www/bagger
    # `--no-dev` leads to install error - ToDo revise composer.json 
    # APP_ENV=prod composer install -d /var/www/bagger --no-dev
    # composer install -d /var/www/bagger --no-dev

FROM alpine:${alpine} AS cache
FROM ${repository}/nginx:${tag}

EXPOSE 8000

# 
ENV \
    BAGGER_APP_ENV=dev \
    BAGGER_APP_SECRET=f58c87e1d737c4422b45ba4310abede5 \
    BAGGER_BAG_DOWNLOAD_PREFIX=https://islandora.traefik.me/bags/ \
    BAGGER_CROND_ENABLE_SERVICE="false" \
    BAGGER_CROND_LOG_LEVEL="0" \
    BAGGER_CROND_SCHEDULE="1 2 * * *" \
    BAGGER_DRUPAL_URL=https://drupal \
    BAGGER_DRUPAL_DEFAULT_ACCOUNT_NAME=admin \
    BAGGER_DRUPAL_DEFAULT_ACCOUNT_PASSWORD=password \
    BAGGER_LOCATION_LOG_PATH="%kernel.project_dir%/var/islandora_bagger.locations" \
    BAGGER_LOG_LEVEL=info \
    BAGGER_APP_DIR="/var/www/bagger"  \
    BAGGER_QUEUE_PATH="/var/www/bagger/var/islandora_bagger.queue" \
    BAGGER_OUTPUT_DIR="%kernel.project_dir%/var/output" \
    BAGGER_TEMP_DIR="%kernel.project_dir%/var/tmp" \
    BAGGER_DEFAULT_PER_BAG_REGISTER_BAGS_WITH_ISLANDORA="false" \
    BAGGER_DEFAULT_PER_BAG_NAME="nid" \
    BAGGER_DEFAULT_PER_BAG_NAME_TEMPLATE="aip_%" \
    BAGGER_DEFAULT_PER_BAG_SERIALIZE="zip" \
    BAGGER_DEFAULT_PER_BAG_CONTACT_NAME="Contact" \
    BAGGER_DEFAULT_PER_BAG_CONTACT_EMAIL="Contact email" \
    BAGGER_DEFAULT_PER_BAG_SOURCE_ORGANIZATION="Source organization" \
    BAGGER_DEFAULT_PER_BAG_HTTP_TIMEOUT=120 \
    BAGGER_DEFAULT_PER_BAG_DELETE_SETTINGS_FILE="false" \
    BAGGER_DEFAULT_PER_BAG_LOG_BAG_CREATION="true" \
    BAGGER_DEFAULT_PER_BAG_LOG_BAG_LOCATION="false"

WORKDIR /var/www/

COPY --chown=nginx:nginx --link --from=composer /var/www /var/www

COPY --chown=nginx:nginx --link rootfs /

RUN find . ! -user nginx -exec chown nginx:nginx {} \;
