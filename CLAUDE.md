# airdrop agent notes

## what this is

A tiny macOS CLI that AirDrops files and URLs via `NSSharingService(named: .sendViaAirDrop)`. Ships as a proper `.app` bundle (Info.plist + ad-hoc codesigned binary), installed to `~/Applications/Airdrop.app`, with a wrapper at `~/.local/bin/ad`. Distributed via the personal homebrew tap at `mihaicrisan04/homebrew-tap`.

Source is a single Swift file. The hard part of this project is the lifecycle plumbing around AppKit's share APIs (see Pitfalls), not the code itself.

## initial setup

```bash
xcode-select --install   # if not already installed
mise install             # no required runtimes; loads task runner
```

## local dev

After editing `Sources/main.swift` or `Info.plist`:

```bash
mise run install   # builds .app, installs to ~/Applications, drops `ad` to ~/.local/bin
mise run test      # runs smoke tests against the freshly built binary
```

`mise run install` is idempotent — re-running it overwrites the existing bundle and re-registers with LaunchServices.

End-to-end AirDrop flow needs a real receiving device. Smoke tests only cover the CLI surface (flags, exit codes, error paths). Exercise the share manually by sending to your iPhone or another Mac after meaningful changes.

## architecture

```
Sources/main.swift          single Swift file, AppKit only
Info.plist                  bundle metadata; CFBundleShortVersionString drives `ad --version`
mise.toml                   build / install / test / uninstall / clean / bump / update-tap
Tests/smoke.sh              POSIX shell, runs under `mise run test`
.github/workflows/
    build.yml               runs `mise run test` on push + PR
    release.yml             on `v*` tag push or manual dispatch: builds, tests, packages, publishes Release
```

Built artifacts live under `build/Airdrop.app/...` (gitignored). Installation copies to `~/Applications/Airdrop.app` and writes a wrapper at `~/.local/bin/ad` that execs the binary *inside* the bundle.

## pitfalls

These four make AirDrop actually complete on macOS 14+. Other CLI airdrop tools (`vldmrkl/airdrop-cli`, `tty-airdrop`, etc.) miss at least one and end up with the picker-dismisses-but-nothing-transfers hang. Don't undo any of them:

- **Activation policy must be `.regular`.** `LSUIElement = true` or `.accessory` policy makes `sharingd` drop the share session after the picker dismisses. The app must briefly come to the foreground.
- **Use `NSApplication.run()`**, not `CFRunLoopRun()`. The share completion callbacks (`didShareItems` / `didFailToShareItems`) are dispatched through AppKit's event loop, not Core Foundation's. With the C runloop, the callbacks never get delivered and the process times out.
- **Perform the share from `applicationDidFinishLaunching`**, dispatched on the main queue. Activation needs to have fully taken effect before `service.perform(withItems:)` runs.
- **Terminate via `NSApp.terminate(nil)`** so the runloop processes any in-flight delegate callbacks before exit.

Other gotchas:

- The wrapper at `~/.local/bin/ad` must `exec` the binary *inside* the `.app` bundle. Don't replace it with a direct copy of the binary out of the bundle — `Bundle.main` needs the bundle structure around it.
- Brew installs put the bundle under `/opt/homebrew/Cellar/airdrop/<v>/libexec/Airdrop.app/...` with the wrapper at `/opt/homebrew/bin/ad`. Same shape, different prefix.
- Code is ad-hoc signed (`codesign --force --sign -`). No Apple Developer ID involvement, no notarization, no Gatekeeper popups for users who build from source. Brew users get the same ad-hoc signature.

## release

Releases tag a version, attach a prebuilt `.app.zip` to a GitHub Release, and bump the homebrew tap formula so `brew upgrade airdrop` pulls it.

Steps:

1. **Bump version in `Info.plist`** — this is what `ad --version` prints, so it must match the git tag.

   ```bash
   mise run bump 0.3.0
   ```

2. **Update `CHANGELOG.md`** — add a `## [0.3.0] — YYYY-MM-DD` entry at the top, describe user-facing changes.

3. **Commit, tag, push.**

   ```bash
   git commit -am "v0.3.0"
   git tag v0.3.0
   git push origin main v0.3.0
   ```

   The tag push fires `.github/workflows/release.yml`. It runs tests, builds the `.app`, zips it, and creates a GitHub Release with auto-generated notes plus `Airdrop-v0.3.0.app.zip`.

4. **Update the homebrew tap formula.**

   ```bash
   mise run update-tap 0.3.0
   cd ~/dev/personal/homebrew-tap
   git diff Formula/airdrop.rb   # sanity check
   git commit -am "airdrop v0.3.0" && git push
   ```

   `update-tap` downloads the source tarball, computes its sha256, and rewrites the `url` and `sha256` lines in the formula. After the push, `brew upgrade airdrop` pulls the new version.

Notes:

- **Don't release every commit.** Bundle changes into meaningful versions. The release page is user-facing; noise hurts.
- The release workflow has `workflow_dispatch`, so a failed run can be re-triggered from the Actions tab without re-tagging.
- Public repos get unlimited GitHub Actions minutes, so CI cost isn't a constraint.

## testing policy

- Tests run via `mise run test` (smoke) and `mise run build` (compile check). Both run in CI.
- Don't write tests that grep source code or read `Info.plist` to assert a value is present — exercise the built binary instead.
- The AirDrop flow itself can't be unit-tested (needs a real second device + human consent). Don't mock `NSSharingService`; the value of a passing mocked test is zero.

## conventions

- Lowercase commit messages, concise, no Co-Authored-By trailer.
- CHANGELOG entries are user-facing: describe *what changed*, not *how*.
- New flags/exit codes go into `Tests/smoke.sh` alongside the change.
- Prefer single commits for self-contained changes; use a two-commit "test reproduces bug → fix" structure for regression fixes so CI shows red→green.
