# Contributing

## Changes

- **Branches** ideally start from an issue, carry one change each, and land on main through a pull request as one squashed commit.
- **Commits** start with the kind of change and a scope from `.github/tools/commitlint.json`, followed by a short summary.
- **Descriptions** of pull requests and issues stay slim and minimal, about 2–3 sentences on average.
- **Updates** of dependencies arrive from the Renovate bot, one pull request per update.

## Artwork

- **Masters** are the SVGs in `logo/` and `icons/`. A change edits a master, and the files rendered from it change with `scripts/export.sh` in the same commit.
- **Comments** in the scripts state a step's intent, in abstract terms, on the line above it.

## Releases

- **Versions** are left to the release-please bot, whose pull request raises the first number for breaking changes, the second for new features, and the third for fixes.
- **Releases** go out when that pull request merges, and sites that use the artwork pin a release.
