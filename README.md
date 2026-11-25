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

On Linux it also installs [Flatpak](https://flatpak.org/) with Flathub, plus [Bazaar](https://github.com/kolunmi/bazaar) and [Hokum](https://hokum.app) (notifications) if it's a Hyprland machine.

On a Mac, the first apply runs `brew bundle` for the same tools (if [Homebrew](https://brew.sh/) is installed) and symlinks the [1Password](https://1password.com/) SSH agent socket to `~/.1password/agent.sock`, so the same ssh config works on both.

## Security keys (SSH and git signing)
I use two YubiKeys (a 5C Nano and a backup) and a Token2 PIN+. Each key does two jobs:

- **SSH logins use FIDO2** (`sk-ssh-ed25519`). `~/.ssh/config` offers only these keys (`IdentitiesOnly`). The key files aren't in this repo, so on a new machine connect each key and run `ssh-sk-restore`. It runs `ssh-keygen -K` and names the files by their fingerprint. `hephaestus` never has the Nano, so its ssh config skips it.
- **git signs with PIV** (slot 9A, ECC P-256) through **gpg-agent**, which is also the SSH agent. It asks for the PIV PIN once per plug-in, so a rebase of 20 commits doesn't need 20 PINs. A FIDO2 key needs a tap (and the PIN) for every signature, which is why signing doesn't use it. The YubiKeys also want one touch (cached for 15 s). Their light just blinks, nothing prints.
- `~/.gnupg` holds `sshcontrol` (the keygrips), `scdaemon.conf` (PIV first, through pcscd) and the card stubs in `private-keys-v1.d`. The stubs are only the public key and the card serial, so a new machine needs no `learn` step. `~/.config/git/allowed_signers` lists the three PIV keys.
- **Linux:** a run_onchange script installs gnupg, scdaemon, pcscd, pinentry, libfido2, opensc and the libs keyroost builds with. The user-services script masks the OpenSSH and gcr agents and enables the gpg-agent sockets. `hyprland.lua` and `.zshenv` point `SSH_AUTH_SOCK` at gpg-agent.
- **macOS:** `brew bundle` adds `openssh` (Apple's has no FIDO2), `gnupg` and `pinentry-mac`. `.zshenv` starts gpg-agent, since nothing else does there.

## Per-machine stuff
Monitor names, which output wayvnc uses, the GPU pin and wallpapers live in `.chezmoidata/hosts.toml`, keyed by hostname. A machine that isn't listed there just gets sane defaults. NVIDIA env vars only get set if the NVIDIA driver is actually loaded.

`~/.config/hypr/monitors.lua` only once, since monique rewrites it whenever I save a layout.

