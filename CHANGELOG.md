# Changelog

## 2.0.0
- **Multi-account support (full isolation)**: replaced the single `ssl`/`certfile`/`keyfile`/`blocked_client_ids`/`high_device_limit_client_ids` options with an `accounts` list. Each enabled account runs as its own `sync-lite` process, on its own port, with its own SQLite database file (`/data/sync-lite-<name>.db`) — no shared state between accounts.
- Added a second port (`8296/tcp`) exposed by default for the second account ("User 2", disabled by default). Additional accounts/ports can be added freely.
- Each account's log lines are now prefixed with its configured name, e.g. `[User 1] ...` / `[User 2] ...`, so it's easy to tell which account a log line or request belongs to.
- Added a `log_level` option (`info` / `debug`). `debug` logs every request with its `client_id`, method, path and payload size, per account.
- Disabling an account stops its process and frees its port without deleting its configuration or its database file.

## 1.0.0
- Initial release. Wraps `sync-lite` (SQLite-backed Brave Sync server) as a Home Assistant add-on.
- Configurable HTTPS via existing certificate files mounted from `/ssl`.
- Persistent SQLite storage under the add-on's `/data` directory.
