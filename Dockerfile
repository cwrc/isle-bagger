# syntax=docker/dockerfile:1.7
ARG REPOSITORY
ARG TAG

#FROM --platform=$BUILDPLATFORM isle_buildkit as base 
FROM isle_buildkit

# Install packages and tools that allow for basic downloads.
RUN --mount=type=cache,id=bagger-apk-${TARGETARCH},sharing=locked,target=/var/cache/apk \
    apk add --no-cache \
        php83-intl \
        php83-zip \
    && \
    echo '' > /root/.ash_history

#
ARG BAGGER_COMMIT="e540c7a66e3497f58d94db439368ad07057ac861"
ARG BAGGER_FILE=${BAGGER_COMMIT}.tar.gz
ARG BAGGER_URL="https://github.com/cwrc/islandora_bagger/archive/${BAGGER_FILE}"
ARG BAGGER_SHA256=3ffecb44d5436fceded5f5a6b49f71fca1d9262c40d4698a16ab87602c93bf0f

RUN --mount=type=cache,id=bagger-composer-${TARGETARCH},sharing=locked,target=/root/.composer/cache \
    --mount=type=cache,id=bagger-downloads-${TARGETARCH},sharing=locked,target=/opt/downloads \
    download.sh \
        --url "${BAGGER_URL}" \
        --sha256 "${BAGGER_SHA256}" \
        --strip \
        --dest "/var/www/bagger" \
    && \
    chown -R nginx:nginx /var/www/bagger \
    && \
    su -s /bin/bash nginx -c "composer install -d /var/www/bagger"
    # `--no-dev` leads to install error - ToDo revise composer.json
    # APP_ENV=prod composer install -d /var/www/bagger --no-dev
    # composer install -d /var/www/bagger --no-dev

EXPOSE 8000

#
ENV \
    BAGGER_APP_ENV=dev \
    BAGGER_APP_SECRET=sec.f58c87e1d737c4422b45ba4310abede5 \
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

# requries v24+ of Docker
# https://github.com/docker/build-push-action/issues/761
#COPY --chown=nginx:nginx --link rootfs /
COPY --chown=nginx:nginx rootfs /

#RUN find /var/www/bagger ! -user nginx -exec chown nginx:nginx {} \;
