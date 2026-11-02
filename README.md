# netwerkstatt-deploy-action

Reusable GitHub Action for Silverstripe/PHP projects:
composer install, tests, optional frontend build (theme with its own `package.json`)
and deployment via [Deployer](https://deployer.org) over SSH – including alerts to
Discord and Signal (via [CallMeBot](https://www.callmebot.com/blog/free-api-signal/)).

## Usage

Create `.github/workflows/deploy.yml` in your project:

```yaml
name: deploy
on:
  push:
    branches: [master, main]

concurrency: production_environment   # prevents concurrent deploys

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: wernerkrauss/netwerkstatt-deploy-action@v0.1
        with:
          stage: production
          theme-path: app/themes/customertheme
          deploy-key: ${{ secrets.DEPLOY_SSH_KEY }}
          discord-webhook: ${{ secrets.DISCORD_DEPLOY_WEBHOOK }}
          callmebot-url: ${{ secrets.CALLMEBOT_URL }}
```

## Inputs

| Input | Default | Description |
|---|---|---|
| `stage` | – (required) | Deployer stage, e.g. `production`, `staging` |
| `dep-task` | `deploy` | Deployer task to run |
| `php-version` | `8.3` | PHP version for setup and tests |
| `node-version` | `22` | Node version for the frontend build |
| `run-tests` | `true` | Runs `vendor/bin/phpunit` if present |
| `build-frontend` | `true` | Runs `npm ci && npm run build` in the theme |
| `theme-path` | `themes/site` | Path to the theme (relative to the repo root) |
| `deploy-key` | – | Private SSH key (secret) |
| `discord-webhook` | – | Discord webhook for deploy alerts |
| `callmebot-url` | – | CallMeBot URL including API key for Signal alerts |

## Versioning

Until the action is battle-tested, reference the `v0.1` tag.
Once validated in real projects, tag `v1` and point projects at `@v1`.

## Important notes

- **Frontend build in CI:** The build runs on the GitHub runner. For the built
  assets to arrive on the server, Deployer must **upload the code from CI**
  instead of running `git clone` on the server – use the `deploy:upload`
  recipe or upload the assets during the deploy process.
- **Build on the server (alternative):** Put `node_modules` into the shared
  directory so it exists only once across all releases:
  `add('shared_dirs', ['node_modules']);`
- **Secrets:** Store the SSH key, Discord webhook and CallMeBot URL as
  repository or organization secrets – never commit them.
- `concurrency: production_environment` in the workflow prevents concurrent
  deploys to the same server.
