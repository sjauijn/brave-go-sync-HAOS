# Brave Sync Server — Documentation

This app runs sync-lite, a minimal, self-hosted implementation of the Brave Sync v2 protocol. It stores everything in a single SQLite file — no DynamoDB, no Redis, no external dependencies.

## What it does

Brave browsers can be pointed at a custom sync server via the `brave://flags/#brave-override-sync-server-url` flag. This add-on hosts that server on your Home Assistant machine, inside your local network.

## Configuration options

| Option | Default | Description |
|---|---|---|
| `ssl` | `false` | Enable HTTPS. Recommended for anything other than localhost-only access, since Brave requires HTTPS for non-localhost sync URLs. |
| `certfile` | `fullchain.pem` | Filename of the certificate, looked up inside Home Assistant's `/ssl` directory. |
| `keyfile` | `privkey.pem` | Filename of the private key, looked up inside Home Assistant's `/ssl` directory. |
| `blocked_client_ids` | *(empty)* | Optional comma-separated list of client IDs to block. |
| `high_device_limit_client_ids` | *(empty)* | Optional comma-separated list of client IDs allowed a higher device limit (100 instead of 50). |

The server always listens on port **8295**.

## Using your own certificate

If you already have a certificate (for example issued by the Let's Encrypt/DNS add-on, or one you generated yourself), place `fullchain.pem` and `privkey.pem` (or whatever filenames you use) into Home Assistant's `/ssl` folder — the same directory used by other add-ons (accessible via the Samba or SSH add-on at `/ssl` on the host).

Then set in this add-on's configuration:

```yaml
ssl: true
certfile: fullchain.pem
keyfile: privkey.pem
```

If `ssl` is left `false`, the server runs over plain HTTP. This is only appropriate if you're accessing it from `localhost` on the Home Assistant host itself, since Brave rejects non-HTTPS sync URLs for anything else.

## Data storage

All sync data lives in a single SQLite database at `/data/sync-lite.db` inside the add-on, which Home Assistant persists across restarts and updates automatically (the add-on's `/data` directory).

## Configuring Brave

1. Open `brave://flags/#brave-override-sync-server-url` in Brave.
2. Set it to your Home Assistant instance's address and port, for example:
   - `https://homeassistant.local:8295/` (with SSL enabled), or
   - `http://localhost:8295/` (HTTP, localhost only)
3. Restart Brave.
4. Set up or join a sync chain as usual in `brave://settings/braveSync`.

You can repeat this on every device you want synced (desktop and Android both support the override).

## Verifying it's running

Check the add-on logs for a line like:

```
Starting Brave Sync server with HTTPS on port 8295 (cert: /ssl/fullchain.pem)
```

You can also do a quick reachability check from any device on your network:

```bash
curl -i https://homeassistant.local:8295/command/
```

An `401 Unauthorized` response means the server is up and reachable (Brave clients authenticate every request, so a bare `curl` without a token is expected to be rejected).

## Notes

- This add-on builds the binary locally on first install (no pre-built image), so installation can take a few minutes.
- The underlying implementation is a fork of [brave/go-sync](https://github.com/brave/go-sync) that removes the DynamoDB and Redis dependencies in favor of SQLite and in-memory caching — ideal for small, personal/family sync setups, not for large-scale deployments.
- Source of the `sync-lite` implementation used for this build is included in the add-on's `go-sync/sync-lite` directory.
