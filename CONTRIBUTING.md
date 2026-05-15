# contributing

## prerequisites

- macOS 13 (Ventura) or later — macOS 14+ is where the picker hang in other CLI airdrop tools doesn't bite
- Xcode command line tools (`xcode-select --install`)
- [mise](https://mise.jdx.dev) for the task runner

## getting started

```bash
git clone https://github.com/mihaicrisan04/airdrop
cd airdrop
mise run install
ad --version    # confirm the install worked
```

## development loop

```bash
mise run test       # build + smoke tests
mise run install    # rebuild and reinstall locally
```

Source lives in `Sources/main.swift` (single file, AppKit only). Bundle metadata is `Info.plist`. Tasks: `mise tasks ls`.

End-to-end AirDrop behaviour can't be automated — exercise it manually by sending to your iPhone or another Mac.

## pull requests

- Keep PRs focused. One concern per PR.
- If the change is user-facing, add a `[unreleased]` entry at the top of `CHANGELOG.md`.
- CI must be green.
- New flags or exit codes need matching cases in `Tests/smoke.sh`.

For deeper architecture notes, lifecycle pitfalls, and the release process, see [CLAUDE.md](CLAUDE.md).

## license

MIT.
