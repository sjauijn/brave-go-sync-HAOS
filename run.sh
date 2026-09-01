#!/usr/bin/with-contenv bashio

OPTIONS_FILE="/data/options.json"

LOG_LEVEL="$(bashio::config 'log_level')"
ACCOUNT_COUNT="$(jq '.accounts | length' "${OPTIONS_FILE}")"

if [ "${ACCOUNT_COUNT}" -eq 0 ]; then
    bashio::exit.nok "No accounts configured. Add at least one entry under 'accounts'."
fi

declare -a CHILD_PIDS=()
declare -a CHILD_NAMES=()

terminate_children() {
    bashio::log.info "Stopping ${#CHILD_PIDS[@]} account server(s)..."
    for pid in "${CHILD_PIDS[@]}"; do
        kill -TERM "${pid}" 2>/dev/null || true
    done
    wait
    bashio::log.info "All account servers stopped."
}
trap terminate_children TERM INT

start_account() {
    local idx="$1"
    local acc name enabled port ssl_enabled certfile keyfile blocked high_limit

    acc="$(jq -c ".accounts[${idx}]" "${OPTIONS_FILE}")"
    name="$(echo "${acc}" | jq -r '.name')"
    enabled="$(echo "${acc}" | jq -r '.enabled')"
    port="$(echo "${acc}" | jq -r '.port')"
    ssl_enabled="$(echo "${acc}" | jq -r '.ssl')"
    certfile="$(echo "${acc}" | jq -r '.certfile')"
    keyfile="$(echo "${acc}" | jq -r '.keyfile')"
    blocked="$(echo "${acc}" | jq -r '.blocked_client_ids')"
    high_limit="$(echo "${acc}" | jq -r '.high_device_limit_client_ids')"

    if [ -z "${name}" ] || [ "${name}" = "null" ]; then
        name="Account $((idx + 1))"
    fi

    if [ "${enabled}" != "true" ]; then
        bashio::log.info "[${name}] disabled, skipping"
        return 0
    fi

    if [ -z "${port}" ] || [ "${port}" = "null" ]; then
        bashio::log.warning "[${name}] no port configured, skipping"
        return 0
    fi

    local slug
    slug="$(echo "${name}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
    if [ -z "${slug}" ]; then
        slug="account-$((idx + 1))"
    fi

    local env_prefix="[${name}]"
    (
        export LISTEN_ADDR=":${port}"
        export SQLITE_PATH="/data/sync-lite-${slug}.db"
        export BLOCKED_CLIENT_IDS="${blocked}"
        export HIGH_DEVICE_LIMIT_CLIENT_IDS="${high_limit}"
        export ACCOUNT_NAME="${name}"
        export LOG_LEVEL="${LOG_LEVEL}"

        if bashio::var.true "${ssl_enabled}"; then
            CERT_PATH="/ssl/${certfile}"
            KEY_PATH="/ssl/${keyfile}"

            if ! bashio::fs.file_exists "${CERT_PATH}"; then
                bashio::log.error "${env_prefix} SSL enabled but certificate not found: ${CERT_PATH}"
                exit 1
            fi
            if ! bashio::fs.file_exists "${KEY_PATH}"; then
                bashio::log.error "${env_prefix} SSL enabled but key not found: ${KEY_PATH}"
                exit 1
            fi

            export TLS_CERT_FILE="${CERT_PATH}"
            export TLS_KEY_FILE="${KEY_PATH}"

            bashio::log.info "${env_prefix} starting on port ${port} with HTTPS (cert: ${CERT_PATH}, log_level: ${LOG_LEVEL})"
        else
            bashio::log.info "${env_prefix} starting on port ${port} with HTTP (log_level: ${LOG_LEVEL}) - use only on trusted/local networks or behind your own reverse proxy"
        fi

        exec /usr/bin/sync-lite
    ) &

    CHILD_PIDS+=("$!")
    CHILD_NAMES+=("${name}")
}

for ((i = 0; i < ACCOUNT_COUNT; i++)); do
    start_account "${i}"
done

if [ "${#CHILD_PIDS[@]}" -eq 0 ]; then
    bashio::exit.nok "No accounts are enabled. Enable at least one account in the add-on configuration."
fi

bashio::log.info "Running ${#CHILD_PIDS[@]} account server(s): ${CHILD_NAMES[*]}"

wait -n
EXIT_CODE=$?
bashio::log.warning "One of the account servers exited (code ${EXIT_CODE}), shutting down the rest"
terminate_children
exit "${EXIT_CODE}"
