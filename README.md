# Brave Sync Server

Self-hosted [Brave Sync](https://github.com/brave/go-sync) server for your local network, built on the lightweight [`sync-lite`](https://github.com/brave/go-sync/tree/master/sync-lite) implementation (SQLite storage, no DynamoDB/Redis required).

Use it with Brave's `brave://flags/#brave-override-sync-server-url` flag to point your browsers at your own Home Assistant instance instead of Brave's official servers.

See [DOCS.md](DOCS.md) for setup instructions.
