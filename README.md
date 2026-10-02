# [Zerro](https://zerro.app/)

**Unofficial ZenMoney client with envelope budgeting superpowers**

Zerro syncs with your ZenMoney account and lets you plan every koruna, euro or dollar using YNAB-style envelope budgets, savings goals and clear analytics.

[Channel with updates](https://t.me/zerroapp) | [User chat](https://t.me/zerrochat)

## Main features

- 💰 **Envelope budgets** across multiple currencies
- 🎯 **Savings goals** for big purchases or rainy‑day funds
- 💹 **Basic analytics** of income, expenses and net worth
- ⚡️ **Bulk actions**: merge, change categories, delete, and restore deleted operations
- 💾 **Full backup** of all data (no restoration yet)
- 📱 **Mobile-friendly** progressive web app (PWA) and works even offline

## Links

- [Zerro](https://zerro.app/) / [updates](https://t.me/zerroapp) / [chat](https://t.me/zerrochat)
- [ZenMoney](https://zenmoney.app/) + [API documentation](https://github.com/zenmoney/ZenPlugins/wiki/ZenMoney-API)
- [YNAB](https://www.youneedabudget.com/) — they are good at explaining the concept of envelope budgeting

## Contributing

If you want to contribute, let's discuss the idea first here in issues or in [chat](https://t.me/zerrochat)/[dm](https://t.me/ardov). I'm open to suggestions and ideas but I don't want to waste your time on things that don't fit the product 🖤

### Run locally

1. Install [pnpm](https://pnpm.io/) and [Node.js](https://nodejs.org/)
2. Clone the repository
3. `pnpm install` to install dependencies
4. `pnpm run dev` to run the development server on [http://localhost:3000](http://localhost:3000/)
5. You are great

### Run locally in a container (podman / docker)

Build a production-ready image with the compiled app baked in — no source mount needed:

```bash
podman build -t zerro:local -f local.dockerfile .
podman run -d --name zerro-app -p 3000:3000 zerro:local
```

Use `docker` instead of `podman` if that is what you have installed — the commands are identical.

### Quick install & launch

Build the image, install the launcher script and create a desktop shortcut in one step:

```bash
./scripts/install.sh
```

The installer auto-detects whether `podman` or `docker` is available. Once installed, launch Zerro via the desktop icon or run `~/bin/zerro-launcher.sh`.

The launcher:

- starts the container if it is not running, waits until the app is ready,
- opens the app in a Chrome/Chromium window in `--app` mode,
- protects against double launches via `flock`,
- stops the container when you close the app window.

For dev mode with hot reload, use the original `Dockerfile`:

```bash
podman build -t zerro:dev .
podman run -it -d --rm -v ${PWD}:/app -v /app/node_modules -p 3000:3000 -e CHOKIDAR_USEPOLLING=true zerro:dev
```
