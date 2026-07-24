# Brave Sync Server 

I maintain this app, along with my other Home Assistant apps, solely for my own use. As long as I'm actively using them myself, I'll continue developing and updating them; otherwise, support for apps I no longer need will be discontinued.

## About

Self-hosted [Brave Sync](https://github.com/brave/go-sync) server for your local network, built on the lightweight sync-lite implementation (SQLite storage, no DynamoDB/Redis required).

Supports multiple fully isolated accounts (e.g. "User 1" / "User 2"), each running on its own port with its own database and clearly labeled log lines.

## Installation

1. Click to add the stable repository:
   [![Add Stable Repository](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/sjauijn/brave-go-sync-HAOS) 

2. Or manually add:

   ```text
   https://github.com/sjauijn/brave-go-sync-HAOS
   ```


Use it with Brave's `brave://flags/#brave-override-sync-server-url` flag to point your browsers at your own Home Assistant instance instead of Brave's official servers.

See [DOCS.md](DOCS.md) for setup instructions.
