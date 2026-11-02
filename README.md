# netwerkstatt-deploy-action

Wiederverwendbare GitHub Action für Silverstripe-/PHP-Projekte:
Composer-Install, Tests, optionaler Frontend-Build (Theme mit eigenem `package.json`)
und Deploy per [Deployer](https://deployer.org) über SSH – inkl. Alerts an Discord
und Signal (via [CallMeBot](https://www.callmebot.com/blog/free-api-signal/)).

## Verwendung

`.github/workflows/deploy.yml` im Projekt:

```yaml
name: deploy
on:
  push:
    branches: [master, main]

concurrency: production_environment   # verhindert paralleles Deployen

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: wernerkrauss/netwerkstatt-deploy-action@v1
        with:
          stage: production
          theme-path: app/themes/kundentheme
          deploy-key: ${{ secrets.DEPLOY_SSH_KEY }}
          discord-webhook: ${{ secrets.DISCORD_DEPLOY_WEBHOOK }}
          callmebot-url: ${{ secrets.CALLMEBOT_URL }}
```

## Inputs

| Input | Default | Beschreibung |
|---|---|---|
| `stage` | – (Pflicht) | Deployer-Stage, z. B. `production`, `staging` |
| `dep-task` | `deploy` | Deployer-Task |
| `php-version` | `8.3` | PHP-Version für Setup/Tests |
| `node-version` | `22` | Node-Version für Frontend-Build |
| `run-tests` | `true` | `vendor/bin/phpunit` wird ausgeführt (falls vorhanden) |
| `build-frontend` | `true` | `npm ci && npm run build` im Theme |
| `theme-path` | `themes/site` | Pfad zum Theme (relativ zum Repo-Root) |
| `deploy-key` | – | Privater SSH-Key (Secret) |
| `discord-webhook` | – | Discord-Webhook für Alerts |
| `callmebot-url` | – | CallMeBot-URL inkl. API-Key für Signal-Alerts |

## Wichtige Hinweise

- **Frontend-Build in CI:** Der Build läuft auf dem GitHub-Runner. Damit die
  gebauten Assets am Server ankommen, muss Deployer den Code **aus dem CI
  hochladen** statt per `git clone` am Server – Recipe `deploy:upload` nutzen
  oder die Assets im Deploy-Prozess hochladen.
- **Build am Server (Alternative):** `node_modules` in den shared-Bereich
  legen, dann existiert er nur einmal für alle Releases:
  `add('shared_dirs', ['node_modules']);`
- **Secrets:** SSH-Key, Discord-Webhook und CallMeBot-URL als Repository- oder
  Organization-Secrets hinterlegen, nie committen.
- `concurrency: production_environment` im Workflow verhindert gleichzeitige
  Deploys auf denselben Server.
