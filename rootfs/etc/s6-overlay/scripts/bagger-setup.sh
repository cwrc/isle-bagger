#!/command/with-contenv bash
# shellcheck shell=bash
set -e

function setup_cron {
    if [[ "${BAGGER_CROND_ENABLE_SERVICE}" == "true" ]]; then
        cat <<EOF | crontab -u nginx -
# min   hour    day     month   weekday command
${BAGGER_CROND_SCHEDULE}        cd ${BAGGER_APP_DIR} && ./bin/console app:islandora_bagger:process_queue --queue=${BAGGER_QUEUE_PATH}
EOF
    fi
}

function setup_dir {
    mkdir -p ${BAGGER_OUTPUT_DIR}
    chown nginx:nginx ${BAGGER_OUTPUT_DIR}
    chmod 02755 ${BAGGER_OUTPUT_DIR}
}

function main {
    setup_cron
    setup_dir
}

main
