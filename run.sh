#!/usr/bin/with-contenv bashio

# --- Read add-on options ---
SSL_ENABLED=$(bashio::config 'ssl')
CERTFILE=$(bashio::config 'certfile')
KEYFILE=$(bashio::config 'keyfile')
BLOCKED_CLIENT_IDS=$(bashio::config 'blocked_client_ids')
HIGH_DEVICE_LIMIT_CLIENT_IDS=$(bashio::config 'high_device_limit_client_ids')

export LISTEN_ADDR=":8295"
export SQLITE_PATH="/data/sync-lite.db"
export BLOCKED_CLIENT_IDS="${BLOCKED_CLIENT_IDS}"
export HIGH_DEVICE_LIMIT_CLIENT_IDS="${HIGH_DEVICE_LIMIT_CLIENT_IDS}"

if bashio::var.true "${SSL_ENABLED}"; then
    CERT_PATH="/ssl/${CERTFILE}"
    KEY_PATH="/ssl/${KEYFILE}"

    if ! bashio::fs.file_exists "${CERT_PATH}"; then
        bashio::exit.nok "SSL is enabled but certificate file was not found: ${CERT_PATH}"
    fi
    if ! bashio::fs.file_exists "${KEY_PATH}"; then
        bashio::exit.nok "SSL is enabled but key file was not found: ${KEY_PATH}"
    fi

    export TLS_CERT_FILE="${CERT_PATH}"
    export TLS_KEY_FILE="${KEY_PATH}"

    bashio::log.info "Starting Brave Sync server with HTTPS on port 8295 (cert: ${CERT_PATH})"
else
    bashio::log.info "Starting Brave Sync server with HTTP on port 8295 (no TLS - use only on trusted/local networks or behind your own reverse proxy)"
fi

exec /usr/bin/sync-lite
