# contributing

## prerequisites

- macOS (developed and tested on macOS 26 Tahoe; earlier versions are likely fine but untested)
- Xcode command line tools (`xcode-select --install`)
- [mise](https://mise.jdx.dev) for the task runner

## getting started

```bash
git clone https://github.com/mihaicrisan04/airdrop
cd airdrop
mise run install
ad --version
```

## development loop

```bash
mise run test       # build + smoke tests
mise run install    # rebuild and reinstall locally
```

source lives in `Sources/main.swift`. bundle metadata is `Info.plist`. tasks: `mise tasks ls`.

the end-to-end AirDrop flow can't be automated — exercise it manually by sending to your iPhone or another Mac.

## pull requests

- one concern per PR
- add a `[unreleased]` entry at the top of `CHANGELOG.md` for user-facing changes
- CI must be green
- new flags or exit codes need matching cases in `Tests/smoke.sh`

deeper architecture notes, lifecycle pitfalls and release flow live in [CLAUDE.md](CLAUDE.md).

## license

MIT.
