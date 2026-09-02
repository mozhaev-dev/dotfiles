# dotfiles

Shared macOS configuration with a machine-local override layer.

## How it works

Files under `home/` are the shared source of truth. `install.sh` links every
file from that tree to the matching path in `$HOME`.

Machine-specific settings live directly in `$HOME` in `*.local` files. They
are not symlinks and are not tracked by this repository. Each shared config
loads its local counterpart with higher priority:

| Shared config | Machine-local override |
| --- | --- |
| `~/.zshrc` | `~/.zshrc.local` |
| `~/.zprofile` | `~/.zprofile.local` |
| `~/.config/git/config` | `~/.config/git/config.local` |
| `~/.config/tmux/tmux.conf` | `~/.config/tmux/tmux.local.conf` |
| `~/.config/ghostty/config` | `~/.config/ghostty/config.local` |
| `~/.config/nvim/init.lua` | `~/.config/nvim/local.lua` |
| `~/.ssh/config` | `~/.ssh/config.local` |

Shell secrets belong in `~/.secrets.zsh`. The installer keeps that file and
the local SSH config readable only by the current user.

## Install

Install the packages first. This step is deliberately separate: it is slow,
it needs the network, and it is not something to re-run casually.

```sh
brew bundle
```

Preview the rest without changing anything:

```sh
./install.sh --dry-run
```

Apply the configuration:

```sh
./install.sh
```

Existing files are moved to a timestamped `~/.dotfiles-backup-*` directory
before links are created. Re-running the installer is safe.

## Toolchains

Most packages are ready to use straight from `Brewfile`. Two are not, so
`install.sh` finishes them:

- **Rust.** The `rustup` formula installs the version manager and nothing
  else — no compiler and no `rust-analyzer`. The installer adds the stable
  toolchain and the `rust-analyzer` component, and `~/.zprofile` puts the
  rustup shims on `PATH`, which the formula does not do either. Note that
  rustup keeps a `rust-analyzer` shim whether or not the component is
  installed, so a missing component looks fine until Neovim starts the server
  and it exits immediately.
- **Neovim.** Nothing to do by hand: `init.lua` clones lazy.nvim on first
  launch, installs the plugins pinned in `lazy-lock.json`, and builds the
  Treesitter parsers it needs.

## Adding a shared config

Add the file below `home/` at the path it should have relative to `$HOME`, then
run `./install.sh` again. If it needs per-machine settings, make the shared
file load a matching local file and add that local path to `LOCAL_FILES` in
`install.sh`.
