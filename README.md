# networkstatt-deploy-action

Central home for the netwerkstatt deployment pipeline for Silverstripe projects.

- **Reusable workflows (recommended):**
  - `.github/workflows/reusable-silverstripe-ci.yml` — CI: Composer validate/install, optional tests, linting,
    and frontend build (validation or artifact upload).
  - `.github/workflows/reusable-silverstripe-deploy.yml` — release deploy for projects whose frontend `dist` is
    committed to git: the runner packages a `git archive` of the commit, uploads it, and Deployer installs it
    on the server over SSH.
  - `.github/workflows/reusable-silverstripe-vite-deploy.yml` — release deploy for Vite-themed projects whose
    `dist` is built in CI: the CI uploads the Vite output as an artifact, the deploy job merges it into the
    release archive before uploading.
  Targets, credentials, and secrets come from the calling repository's GitHub Environment, never from this repo.
- **Legacy composite action (`action.yml`, tag `v0.1`):** the older single-action variant (composer install,
  tests, optional npm frontend build, Deployer deploy from a server-side clone, Discord/Signal alerts).
  Kept for reference; new projects should use the reusable workflows.

## Reusable workflows usage

Create `.github/workflows/deploy.yml` in your project and call the workflows from this repository, pinned to a
release tag or commit SHA:

```yaml
name: Build and deployment

on:
  pull_request:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: read

jobs:
  ci:
    uses: wernerkrauss/netwerkstatt-deploy-action/.github/workflows/reusable-silverstripe-ci.yml@v1.0.0
    with:
      database_image: mariadb:10.4
      run_phpunit: true
      run_phpcs: true
      run_phpstan: true
      run_rector: true

  silverstripe:
    if: github.event_name != 'pull_request'
    needs: ci
    uses: wernerkrauss/netwerkstatt-deploy-action/.github/workflows/reusable-silverstripe-deploy.yml@v1.0.0
    with:
      should_deploy: >-
        ${{ github.ref == 'refs/heads/main' && vars.DEPLOY_PRODUCTION_ENABLED == 'true' }}
      deployment_environment: production
      deploy_stage: live
      deployer_version: '8.0.5'
    secrets: inherit
```

Rules of thumb:

- Always pin to a tag or commit SHA (never a moving branch). Prefer a SHA pin for maximum tamper resistance.
- `secrets: inherit` passes the caller's secrets to the called workflow — only call this repository from
  trusted, pinned refs, and consider making this repository private.
- A reusable workflow cannot call another reusable workflow, so call both directly from the project's
  `deploy.yml`.
- The called workflows check out the **calling** repository; `vars.*` and Environment secrets resolve in the
  caller's context, so each project keeps its own `DEPLOY_*` values.
- The project still needs its own `deploy.php` (Deployer recipe reading the `DEPLOY_*` environment variables)
  and a `docs/deployment.md` documenting its GitHub Environment variables and secrets.

### CI inputs (`reusable-silverstripe-ci.yml`)

| Input | Default | Description |
|---|---|---|
| `php_version` | `''` | Override when `.ddev/config.yaml` is stale; otherwise read from there |
| `ddev_directory` | `.` | Directory containing `.ddev/config.yaml` |
| `database_image` | `mysql:8.0` | DB service image; use `mariadb:10.4`/`10.11` to match DDEV |
| `theme_directory` | `''` | When set, runs `yarn install --frozen-lockfile` + `yarn build` (validation when dist is committed) |
| `run_phpunit` / `run_phpcs` / `run_phpstan` / `run_rector` | `false` | Enable only when the project has tests/tool configs; DB build runs only with `run_phpunit` |
| `node_version` | `'20'` | Node version for the optional frontend build |

### Deploy inputs (`reusable-silverstripe-deploy.yml`)

| Input | Default | Description |
|---|---|---|
| `should_deploy` | `false` | Boolean expression gating build + deploy |
| `php_version` | `''` | Same override semantics as CI |
| `deployment_environment` | `production` | GitHub Environment name |
| `deploy_stage` | `live` | Deployer stage (`DEPLOY_STAGE`) |
| `deployer_version` | `'8.0.5'` | v8 required for Silverstripe 6 (`vendor/bin/sake`) |
| `artifact_name` | `silverstripe-release` | Name of the uploaded `release.tar.gz` |

### Required GitHub configuration in the calling project

Repository variable `DEPLOY_PRODUCTION_ENABLED=true` (only once the target is ready), plus in the
`production` Environment the variables `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_PATH`, `DEPLOY_PHP_BIN`,
optional `DEPLOY_PORT` and `DEPLOY_COMPOSER_COMMAND`, and the secrets `DEPLOYER_PRIVATE_KEY` and
`DEPLOYER_KNOWN_HOSTS` (verify the host key fingerprint out of band; strict host checking stays on).

## Versioning

- `v0.1` — legacy composite action (`action.yml`).
- `v1.0.0` — reusable CI and archive-based deploy workflows under `.github/workflows/`.
- `v1.1.0` — adds `reusable-silverstripe-vite-deploy.yml` (CI-built Vite frontend merged into the release).
  Breaking changes get a new major tag; projects bump their pin deliberately.

## Important notes

- When the frontend `dist` is committed to git, no frontend build is needed for deployment; the release
  archive already contains it. A CI build can still validate that it compiles.
- `.env` is gitignored and must be a Deployer `shared_files` entry in the project's `deploy.php`; before the
  first archive-based deploy, copy the existing `.env` to `<DEPLOY_PATH>/shared/.env`.
- The web server document root must resolve to `<DEPLOY_PATH>/current/public`; the target needs SSH access,
  `rsync`, `tar`, a matching PHP CLI, and Composer.
- Never commit SSH keys, webhooks, or API keys — use repository/Environment secrets only.
