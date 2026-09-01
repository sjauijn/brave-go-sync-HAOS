<p align="center">
  <img src="https://raw.githubusercontent.com/sjauijn/brave-go-sync-HAOS/refs/heads/master/icon.png" alt="icon">
</p>

# Brave Sync Server — Home Assistant app

I maintain this app, along my other apps and custom integrations for the Home Assistant, solely for my own use. As long as I'm actively using them myself, I'll continue developing and updating them; otherwise, support for apps and(or) custom integrations I no longer need will be discontinued.

This app runs sync-lite, a minimal, self-hosted implementation of the Brave Sync v2 protocol. It stores everything in SQLite files — no DynamoDB, no Redis, no external dependencies.

## What it does

Brave browsers can be pointed at a custom sync server via the `brave://flags/#brave-override-sync-server-url` flag. This add-on hosts that server on your Home Assistant machine, inside your local network.

Starting with version 2.0.0, the add-on supports **multiple fully isolated accounts**. Each account you enable runs as its own `sync-lite` process, on its own TCP port, with its own SQLite database file. There is no shared state between accounts — it's the same as running two completely separate sync servers, just packaged into one add-on.

## Configuration options

| Option | Default | Description |
|---|---|---|
| `log_level` | `info` | `info` logs startup/shutdown and errors only. `debug` additionally logs every request (method, path, `client_id`, byte sizes) — useful to see which account a request belongs to, or to debug sync issues. |
| `accounts` | 2 entries (`User 1` enabled, `User 2` disabled) | List of independent accounts. See below. |

Each entry under `accounts` has:

| Field | Default | Description |
|---|---|---|
| `name` | `User 1` / `User 2` | Human-readable label. Used to name the account's database file (`/data/sync-lite-<slugified-name>.db`) and to prefix every log line from that account's process, e.g. `[User 1] sync-lite listening on :8295 ...`. |
| `enabled` | `true` / `false` | Whether to start a server process for this account. Disable an account to free its port and stop its process without deleting its configuration or its data file. |
| `port` | `8295` / `8296` | TCP port this account listens on. Must be unique across all enabled accounts, and must also be exposed under the add-on's **Network** (`ports`) configuration in Settings. |
| `ssl` | `false` | Enable HTTPS for this account. Recommended for anything other than localhost-only access, since Brave requires HTTPS for non-localhost sync URLs. |
| `certfile` | `fullchain.pem` | Filename of the certificate for this account, looked up inside Home Assistant's `/ssl` directory. |
| `keyfile` | `privkey.pem` | Filename of the private key for this account, looked up inside Home Assistant's `/ssl` directory. |
| `blocked_client_ids` | *(empty)* | Optional comma-separated list of client IDs to block, for this account only. |
| `high_device_limit_client_ids` | *(empty)* | Optional comma-separated list of client IDs allowed a higher device limit (100 instead of 50), for this account only. |

## Adding more than two accounts

The `accounts` list isn't limited to two entries. To add a third account, add another block under `accounts` in the add-on configuration (YAML view), pick a free port (e.g. `8297`), and expose that port under the add-on's **Network** configuration as well:

```yaml
accounts:
  - name: "User 1"
    enabled: true
    port: 8295
    ...
  - name: "User 2"
    enabled: true
    port: 8296
    ...
  - name: "Guest"
    enabled: true
    port: 8297
    ssl: false
    certfile: fullchain.pem
    keyfile: privkey.pem
    blocked_client_ids: ""
    high_device_limit_client_ids: ""
```

Don't forget to add `8297/tcp: 8297` under **Network** in the add-on's configuration page, or the port won't be reachable from outside the container.

## Using your own certificate

If you already have a certificate (for example issued by the Let's Encrypt/DNS add-on, or one you generated yourself), place `fullchain.pem` and `privkey.pem` (or whatever filenames you use) into Home Assistant's `/ssl` folder — the same directory used by other add-ons (accessible via the Samba or SSH add-on at `/ssl` on the host). All accounts can share the same certificate files, or point at different ones via their own `certfile`/`keyfile` fields.

If `ssl` is left `false` for an account, that account's server runs over plain HTTP. This is only appropriate if you're accessing it from `localhost` on the Home Assistant host itself, since Brave rejects non-HTTPS sync URLs for anything else.

## Data storage

Each enabled account writes to its own SQLite database at `/data/sync-lite-<slugified-name>.db` inside the add-on (for example `/data/sync-lite-user-1.db`), which Home Assistant persists across restarts and updates automatically (the add-on's `/data` directory). Disabling an account stops its process but keeps its database file untouched, so re-enabling it later picks up right where it left off.

## Configuring Brave

For each account, on each device you want synced to that account:

1. Open `brave://flags/#brave-override-sync-server-url` in Brave.
2. Set it to that account's address and port, for example:
   - `https://homeassistant.local:8295/` for "User 1" (with SSL enabled), or
   - `https://homeassistant.local:8296/` for "User 2".
3. Restart Brave.
4. Set up or join a sync chain as usual in `brave://settings/braveSync`.

Because each account is a separate server on a separate port with a separate database, there is no chance of "User 1" and "User 2" data mixing, even accidentally — a device pointed at port 8295 can never see data that only exists in the database behind port 8296.

## Verifying it's running

Check the add-on logs; each account's lines are prefixed with its name, for example:

```
[User 1] starting on port 8295 with HTTPS (cert: /ssl/fullchain.pem, log_level: info)
[User 2] disabled, skipping
```

With `log_level: debug`, you'll additionally see every request, tagged by account and client_id:

```
[User 1] request POST /command/ client_id=3f9a1c... body_bytes=842
[User 1] response POST /command/ client_id=3f9a1c... status=200 response_bytes=1203
```

You can also do a quick reachability check from any device on your network:

```bash
curl -i https://homeassistant.local:8295/command/
```

An `401 Unauthorized` response means the server is up and reachable (Brave clients authenticate every request, so a bare `curl` without a token is expected to be rejected).

## Notes

- This add-on builds the binary locally on first install (no pre-built image), so installation can take a few minutes.
- The underlying implementation is a fork of [brave/go-sync](https://github.com/brave/go-sync) that removes the DynamoDB and Redis dependencies in favor of SQLite and in-memory caching — ideal for small, personal/family sync setups, not for large-scale deployments.
- Source of the `sync-lite` implementation used for this build is included in the add-on's `go-sync/sync-lite` directory. The same binary is reused for every account; only its environment variables (`LISTEN_ADDR`, `SQLITE_PATH`, `ACCOUNT_NAME`, etc.) differ per process.
- If one account's process crashes, the whole add-on stops and Home Assistant's restart policy restarts it (which restarts every enabled account). This keeps the setup simple and matches the existing add-on's watchdog behavior.
