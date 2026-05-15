# airdrop

a tiny macOS CLI that AirDrops files and URLs from the terminal. multiple files in one transfer. developed and tested on macOS 26.

<img width="1500" height="1080" alt="ad" src="https://github.com/user-attachments/assets/3cad49f6-6c46-49c3-ba81-4104247e62ab" />


```sh
ad file.pdf
ad a.md b.png c.mov
ad https://example.com
```

## install

homebrew:

```sh
brew install mihaicrisan04/tap/airdrop
```

from source:

```sh
git clone https://github.com/mihaicrisan04/airdrop
cd airdrop
mise run install
```

both put `ad` on your `PATH`.

## why

other CLI airdrop tools we tested hang after the picker dismisses. this one ships as a proper `.app` bundle so `sharingd` keeps the share session alive. details in [CLAUDE.md](CLAUDE.md#pitfalls).

## development

[mise](https://mise.jdx.dev) is recommended. tasks are described in [`mise.toml`](mise.toml).

## license

MIT
