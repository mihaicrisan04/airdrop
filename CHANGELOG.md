# changelog

all notable changes to this project are documented here.
this project follows [semantic versioning](https://semver.org).

## [unreleased]

- `--quiet` / `-q` flag suppresses the `sent N items` output (useful in scripts)
- `--text "..."` flag sends a literal text snippet via AirDrop (no temp file)
- `-` as an argument reads stdin into a temp file and sends it (e.g. `pbpaste | ad -`)
- pinned GitHub Action versions to commit SHA for supply-chain hygiene
- dependabot keeps action pins fresh
- PR and issue templates
- formula now has a `livecheck` block so `brew livecheck airdrop` detects new tags

## [0.2.0] — 2026-05-15

- `--help` / `-h` and `--version` / `-V` flags
- reject unknown flags with a clear error
- smoke tests cover the cli surface (Tests/smoke.sh)
- CI now runs tests on every push and PR
- tagged releases auto-publish a prebuilt `Airdrop.app.zip` via github actions

## [0.1.0] — 2026-05-15

initial release.

- swift cli that AirDrops files and URLs from the terminal
- multiple files in a single transfer via `NSSharingService.perform(withItems:)`
- ships as a proper `.app` bundle so `sharingd` keeps the share session alive on macOS 14+ (fixes the picker-dismisses-but-nothing-transfers hang seen in other CLI airdrop tools)
- `mise run install` builds the app, installs to `~/Applications`, and drops an `ad` wrapper into `~/.local/bin` — no shell alias required
- github actions CI verifies the build on every push and pull request
