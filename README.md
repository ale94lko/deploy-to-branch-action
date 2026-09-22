# Deploy to Branch Action

> A GitHub Action that deploys the content of a folder to a branch.

![License](https://img.shields.io/badge/License-MIT-green.svg)

Useful for publishing build artifacts, documentation, badges, or static sites to branches such as `gh-pages` or `output`.

## Requirements

Checkout the repository before calling the action:

```yaml
- uses: actions/checkout@v4
```

The token needs permission to push to the target branch (`contents: write` when using `GITHUB_TOKEN`).

## Setup

```yaml
- name: Deploy to branch
  uses: ale94lko/deploy-to-branch-action@v1.0.0
  with:
    folder: dist
    branch: gh-pages
```

## Inputs

| Name | Description | Required | Default |
|------|-------------|:--------:|---------|
| `folder` | Folder whose contents will be deployed | `true` | — |
| `branch` | Target branch | `false` | `gh-pages` |
| `token` | Token used to push | `false` | `${{ github.token }}` |
| `commit-message` | Deployment commit message | `false` | `Deploy from GitHub Actions` |
| `git-user-name` | Git `user.name` | `false` | `github-actions[bot]` |
| `git-user-email` | Git `user.email` | `false` | `41898282+github-actions[bot]@users.noreply.github.com` |
| `clean` | Remove existing files on the target branch before deploying | `false` | `true` |
| `force` | Force-push the deployment branch | `false` | `true` |
| `single-commit` | Keep only a single orphan commit on the target branch | `false` | `false` |
| `repository` | Target repository (`owner/repo`) | `false` | current repository |
| `remote-url` | Override the git remote URL (GitHub Enterprise or local testing) | `false` | auto from `token` + `repository` |

## Outputs

| Name | Description |
|------|-------------|
| `commit-hash` | SHA of the deployment commit (empty when nothing was pushed) |
| `deployed` | `true` if a new commit was pushed, otherwise `false` |

## Examples

### Deploy a build folder to `gh-pages`

```yaml
name: Deploy site
on:
  push:
    branches: [main]

permissions:
  contents: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build
        run: npm ci && npm run build

      - name: Deploy
        uses: ale94lko/deploy-to-branch-action@v1.0.0
        with:
          folder: dist
          branch: gh-pages
```

### Deploy a badge to an `output` branch

```yaml
- name: Deploy badge
  uses: ale94lko/deploy-to-branch-action@v1.0.0
  with:
    folder: dist
    branch: output
    commit-message: Update health score badge
    single-commit: true
```

### Keep existing files on the target branch

```yaml
- name: Deploy docs
  uses: ale94lko/deploy-to-branch-action@v1.0.0
  with:
    folder: docs/_site
    branch: gh-pages
    clean: false
```

## Contributing

Please read the [contributing guidelines](https://github.com/ale94lko/deploy-to-branch-action/blob/main/.github/CONTRIBUTING.md).

## License

**deploy-to-branch-action** is licensed under [MIT](https://opensource.org/licenses/MIT).
