# dotfiles

Shared macOS terminal environment for Apple Silicon with a machine-local override layer.
Linux support is outside the scope of this repository.

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
| `~/.config/nvim/init.lua` | `~/.config/nvim/local.lua` |
| `~/.ssh/config` | `~/.ssh/config.local` |

Git identity, SSH identity files and terminal-specific tmux settings belong
in their corresponding local files.

Shell secrets belong in `~/.secrets.zsh`. The installer keeps that file and
the local SSH config readable only by the current user.

## Install

Run these commands from the repository directory.

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

## Machine-local packages

`Brewfile` declares the shared terminal tools and optionally loads
`~/.config/homebrew/Brewfile.local`. Put GUI applications, fonts, Rust and
other machine-specific packages in that local file. It lives outside Git.
`install.sh` creates an empty local file if it is missing; an existing file
is preserved. You can also create it before the first `brew bundle` run.

```ruby
cask "ghostty"
cask "font-meslo-lg-nerd-font"
cask "visual-studio-code"
brew "rustup"
```

`brew bundle` and `brew bundle check` use the combined shared and local list.
Use the combined list for `brew bundle cleanup` as well, so local packages
are not treated as unwanted. Back up the local file separately to restore
this machine's applications later.

Toolchain initialization belongs to the machine-local setup, not
`install.sh`. For Rust, initialize a toolchain and any required components
locally (or use a `postinstall` hook in the local Brewfile). Put its PATH
configuration in `~/.zprofile.local`.

Neovim clones lazy.nvim on first launch, installs the plugins pinned in
`lazy-lock.json`, and builds its Treesitter parsers. Its language integrations
only start language servers that are available on PATH.

## Adding a shared config

Add the file below `home/` at the path it should have relative to `$HOME`, then
run `./install.sh` again. If it needs per-machine settings, make the shared
file load a matching local file and add that local path to `LOCAL_FILES` in
`install.sh`.
