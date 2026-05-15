# airdrop

a tiny macOS CLI that AirDrops files and URLs to nearby Apple devices, straight from the terminal. multiple files in a single transfer. works on macOS Sequoia and Tahoe (14+).

<!-- demo gif goes here -->
<!-- ![demo](./demo.gif) -->

```sh
ad ~/Downloads/file.pdf
ad file1.md file2.png file3.mov     # one picker, one transfer
ad https://example.com
```

## why

every existing tool I tried — `vldmrkl/airdrop-cli`, `tty-airdrop`, `terminal-share` — fails on recent macOS. the AirDrop picker appears, you tap the recipient, the picker dismisses, and nothing actually transfers.

the cause: those tools ship as bare CLI binaries running as accessory/background processes. `sharingd` on macOS 14+ needs a proper foreground `NSApplication` to keep the share session alive after the picker dismisses. without it, the handoff is silently dropped.

this version is a proper `.app` bundle that briefly activates as a foreground app, performs the share through AppKit's event loop, and terminates cleanly.

## install

requires Xcode command line tools (`xcode-select --install`) and [mise](https://mise.jdx.dev).

```sh
git clone https://github.com/mihaicrisan04/airdrop
cd airdrop
mise run install
```

this builds `Airdrop.app`, installs it to `~/Applications/Airdrop.app`, and drops an `ad` wrapper into `~/.local/bin`. as long as `~/.local/bin` is on your `PATH`, the `ad` command is available everywhere — no shell alias required.

## usage

```sh
ad <file|url> [file|url ...]
```

- file paths are resolved against `$PWD`, `~` expansion works
- `http://` and `https://` arguments are treated as URLs
- multiple items go in a single AirDrop session
- the picker still appears — Apple's API requires user-consented recipient selection

## tasks

```sh
mise run build       # build the .app bundle
mise run install     # build and install to ~/Applications
mise run uninstall   # remove from ~/Applications
mise run clean       # remove build artifacts
```

## how it works

uses `NSSharingService(named: .sendViaAirDrop)` from AppKit. the four things existing tools get wrong on modern macOS:

- runs as a regular activated foreground app (no `LSUIElement`)
- drives the runloop via `NSApplication.run()` so share completion callbacks actually fire
- performs the share from `applicationDidFinishLaunching` on the main queue, after activation takes effect
- terminates via `NSApp.terminate` so the runloop processes callbacks before exit

if you're hitting the same hang on macOS 14+, those four bullets are the recipe.

## license

MIT
