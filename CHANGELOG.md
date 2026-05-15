# changelog

all notable changes to this project are documented here.
this project follows [semantic versioning](https://semver.org).

## [0.1.0] — 2026-05-15

initial release.

- swift cli that AirDrops files and URLs from the terminal
- multiple files in a single transfer via `NSSharingService.perform(withItems:)`
- ships as a proper `.app` bundle so `sharingd` keeps the share session alive on macOS 14+ (fixes the picker-dismisses-but-nothing-transfers hang seen in other CLI airdrop tools)
- `mise run install` builds the app, installs to `~/Applications`, and drops an `ad` wrapper into `~/.local/bin` — no shell alias required
- github actions CI verifies the build on every push and pull request
