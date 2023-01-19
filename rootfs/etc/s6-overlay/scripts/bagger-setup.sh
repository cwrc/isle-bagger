#!/command/with-contenv bash
# shellcheck shell=bash
set -e

function setup_cron {
    if [[ "${BAGGER_CROND_ENABLE_SERVICE}" == "true" ]]; then
        cat <<EOF | crontab -u nginx -
# min   hour    day     month   weekday command
${BAGGER_CROND_SCHEDULE}        process-queue.sh --settings=/var/www/bagger/cron_config.yml
EOF
    fi
}

function main {
    setup_cron
}

main
