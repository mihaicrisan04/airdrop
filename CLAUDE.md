# airdrop agent notes

## what this is

a tiny macOS CLI that AirDrops files and URLs via `NSSharingService(named: .sendViaAirDrop)`. ships as a proper `.app` bundle (Info.plist + ad-hoc codesigned binary), installed to `~/Applications/Airdrop.app`, with a wrapper at `~/.local/bin/ad`. distributed via the personal homebrew tap at `mihaicrisan04/homebrew-tap`.

source is a single Swift file. the hard part of this project is the lifecycle plumbing around AppKit's share APIs (see pitfalls), not the code itself.

developed and tested on macOS 26 (Tahoe). earlier macOS versions are likely fine but untested — Info.plist still declares `LSMinimumSystemVersion = 13.0` because that's the API floor we built against, not a verified support level.

## initial setup

```bash
xcode-select --install
mise install
```

## local dev

```bash
mise run install   # builds .app, installs to ~/Applications, drops `ad` to ~/.local/bin
mise run test      # builds + smoke tests
```

`mise run install` is idempotent — it overwrites the existing bundle and re-registers with LaunchServices.

end-to-end AirDrop needs a real receiving device. smoke tests only cover the CLI surface. exercise the share manually after meaningful changes.

## architecture

```
Sources/main.swift          single Swift file, AppKit only
Info.plist                  bundle metadata; CFBundleShortVersionString drives `ad --version`
mise.toml                   build, install, test, uninstall, clean, bump, update-tap
Tests/smoke.sh              POSIX shell, runs under `mise run test`
.github/workflows/
    build.yml               runs `mise run test` on push and PR
    release.yml             on `v*` tag push or manual dispatch: builds, tests, packages, publishes
```

built artifacts live under `build/Airdrop.app/...` (gitignored). installation copies to `~/Applications/Airdrop.app` and writes a wrapper at `~/.local/bin/ad` that execs the binary *inside* the bundle.

## pitfalls

these four make AirDrop actually complete on macOS 26. other CLI airdrop tools we tested against on the same machine hung with the picker-dismisses-but-nothing-transfers symptom. don't undo any of them:

- **activation policy must be `.regular`.** `LSUIElement = true` or `.accessory` policy makes `sharingd` drop the share session after the picker dismisses. the app must briefly come to the foreground.
- **use `NSApplication.run()`**, not `CFRunLoopRun()`. the share completion callbacks (`didShareItems` / `didFailToShareItems`) are dispatched through AppKit's event loop, not Core Foundation's. with the C runloop the callbacks never get delivered and the process times out.
- **perform the share from `applicationDidFinishLaunching`**, dispatched on the main queue. activation needs to have fully taken effect before `service.perform(withItems:)` runs.
- **terminate via `NSApp.terminate(nil)`** so the runloop processes any in-flight delegate callbacks before exit.

other gotchas:

- the wrapper at `~/.local/bin/ad` must `exec` the binary *inside* the `.app` bundle. don't replace it with a direct copy of the binary out of the bundle — `Bundle.main` needs the bundle structure around it.
- brew installs put the bundle under `/opt/homebrew/Cellar/airdrop/<v>/libexec/Airdrop.app/...` with the wrapper at `/opt/homebrew/bin/ad`. same shape, different prefix.
- code is ad-hoc signed (`codesign --force --sign -`). no Apple Developer ID involvement, no notarization. users building from source see no Gatekeeper prompts; brew users get the same signature.

## release

releases tag a version, attach a prebuilt `.app.zip` to a GitHub Release, and bump the homebrew tap formula so `brew upgrade airdrop` pulls it.

steps:

1. **bump version in `Info.plist`** — this is what `ad --version` prints, so it must match the git tag.

   ```bash
   mise run bump 0.3.0
   ```

2. **update `CHANGELOG.md`** — add a `## [0.3.0] — YYYY-MM-DD` entry at the top, describe user-facing changes.

3. **commit, tag, push.**

   ```bash
   git commit -am "v0.3.0"
   git tag v0.3.0
   git push origin main v0.3.0
   ```

   the tag push fires `.github/workflows/release.yml`. it runs tests, builds the `.app`, zips it, creates a GitHub Release with auto-generated notes plus `Airdrop-v0.3.0.app.zip`.

4. **update the homebrew tap formula.**

   ```bash
   mise run update-tap 0.3.0
   cd ~/dev/personal/homebrew-tap
   git diff Formula/airdrop.rb   # sanity check
   git commit -am "airdrop v0.3.0" && git push
   ```

   after the push, `brew upgrade airdrop` pulls the new version.

notes:

- **don't release every commit.** bundle changes into meaningful versions. the release page is user-facing; noise hurts.
- release workflow has `workflow_dispatch`, so a failed run can be re-triggered from the Actions tab without re-tagging.
- public repos get unlimited GitHub Actions minutes, so CI cost isn't a constraint.

## testing policy

- tests run via `mise run test` (smoke) and `mise run build` (compile check). both run in CI.
- don't write tests that grep source code or read `Info.plist` to assert a value is present — exercise the built binary instead.
- the AirDrop flow itself can't be unit-tested (needs a real second device + human consent). don't mock `NSSharingService`; the value of a passing mocked test is zero.

## conventions

- lowercase commit messages, concise, no Co-Authored-By trailer.
- CHANGELOG entries are user-facing: describe *what changed*, not *how*.
- new flags or exit codes go into `Tests/smoke.sh` alongside the change.
- prefer single commits for self-contained changes; use a two-commit "test reproduces bug → fix" structure for regression fixes so CI shows red→green.
