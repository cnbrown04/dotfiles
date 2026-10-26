# dotfiles
## my dotfiles, managed with [chezmoi](https://www.chezmoi.io/)

So these are the configs I use with my Linux desktop (Debian + [Hyprland](https://hypr.land/)), my MacBook, and whatever other Linux machines I'm on. I got tired of copying stuff between them by hand.

To set up a new machine:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply cnbrown04
```

It asks for a name and email for git once and keeps them in `~/.config/chezmoi/chezmoi.toml`

## What goes where
ZSH is the GOAT, don't diss it ([Zap](https://github.com/zap-zsh/zap) + [starship](https://starship.rs/) + [zoxide](https://github.com/ajeetdsouza/zoxide)), [Neovim](https://neovim.io/), tmux, [Ghostty](https://ghostty.org/), lazygit, superfile, [mise](https://mise.jdx.dev/), git and ssh.

The Hyprland desktop stuff (hypr, Quickshell, Vicinae, satty, monique, the scripts in `~/.local/bin`) only shows up on machines that actually have Hyprland installed. See `.chezmoiignore`.

On a Mac, the first apply runs `brew bundle` for the same tools (if [Homebrew](https://brew.sh/) is installed) and symlinks the [1Password](https://1password.com/) SSH agent socket to `~/.1password/agent.sock`, so the same ssh config works on both.

## Per-machine stuff
Monitor names, which output wayvnc uses, the GPU pin and wallpapers live in `.chezmoidata/hosts.toml`, keyed by hostname. A machine that isn't listed there just gets sane defaults. NVIDIA env vars only get set if the NVIDIA driver is actually loaded.

`~/.config/hypr/monitors.lua` only once, since monique rewrites it whenever I save a layout.

