---
sidebar_position: 5
---

# Documentation Deployment

This document explains how to deploy the Novaville documentation site, generated with Docusaurus, to GitHub Pages.

## Overview

The documentation is deployed automatically through the following GitHub Actions workflow:

- `.github/workflows/deploy-docs.yml`

The workflow runs:

- on every `push` affecting `docs/**`
- manually through `workflow_dispatch`

## What the workflow does

1. It checks out the repository with full history.
2. It installs Node.js dependencies in `docs/`.
3. It runs the Docusaurus build.
4. It publishes the generated site to GitHub Pages.

## Local deployment before publishing

Before publishing, always validate the documentation locally:

```bash
cd docs
npm ci
npm run build
npm run serve
```

Verify the following before publishing:

- the build must succeed without errors
- FR/EN links must work
- navigation must show the new pages
- translated pages must exist in both locales

## Deploying to GitHub Pages

Deployment is automatic as soon as a commit is pushed to the branch watched by the workflow.

### Automatic trigger

```text
push to docs/**
    ↓
GitHub Actions runs the workflow
    ↓
npm ci
    ↓
npm run build
    ↓
upload artifact
    ↓
deploy to GitHub Pages
```

### Manual trigger

You can also rerun the publication from the GitHub **Actions** tab:

1. Open the GitHub repository.
2. Go to **Actions**.
3. Select **Deploy Documentation to GitHub Pages**.
4. Click **Run workflow**.

## GitHub prerequisites

The workflow uses these GitHub Pages permissions:

- `contents: read`
- `pages: write`
- `id-token: write`

It then publishes the artifact to the `github-pages` environment.

## Common use cases

### Updating the documentation

1. Edit the files under `docs/`.
2. Run the local build.
3. Push the branch.
4. Wait for the automatic deployment.

### Shipping an urgent fix

1. Fix the affected page.
2. Validate locally with `npm run build`.
3. Commit and push.
4. Check the workflow in **Actions**.

## Troubleshooting

### The build fails

Check:

- the content of `sidebars.js`
- the links between FR and EN pages
- missing files under `docs/i18n/en/...`

### GitHub Pages publication does not appear

Check:

- that `.github/workflows/deploy-docs.yml` actually ran
- that the repository **Pages** settings are configured
- that the build artifact was generated

### The site does not show recent changes

Check:

- the commit actually touched `docs/**`
- the workflow finished successfully
- your browser is not showing a cached version

## See also

- [Local Deployment](./local-deployment)
- [Azure Deployment](./azure-deployment)
- [Internal Guides](./internal-guides)
