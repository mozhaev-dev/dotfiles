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
| `~/.ssh/config` | `~/.ssh/config.local` |

Shell secrets belong in `~/.secrets.zsh`. The installer keeps that file and
the local SSH config readable only by the current user.

## Install

Preview without changing anything:

```sh
./install.sh --dry-run
```

Apply the configuration:

```sh
./install.sh
```

Existing files are moved to a timestamped `~/.dotfiles-backup-*` directory
before links are created. Re-running the installer is safe.

## Adding a shared config

Add the file below `home/` at the path it should have relative to `$HOME`, then
run `./install.sh` again. If it needs per-machine settings, make the shared
file load a matching local file and add that local path to `LOCAL_FILES` in
`install.sh`.
