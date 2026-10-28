# Dotfiles notes for Claude

## AeroSpace mirrors Hyprland (standing rule)

`dot_aerospace.toml` (macOS) must always match `private_dot_config/hypr/hyprland.lua`: same
hotkeys, same workspace behavior, same settings where macOS allows. Hyprland is the source of
truth. Whenever a Hyprland bind or behavior changes, make the closest AeroSpace equivalent in the
same change, and never leave an AeroSpace-only bind on a key Hyprland uses for something else.

Match the keys as physically pressed, not as written in hyprland.lua: on the desktop keyd
(`/etc/keyd`, not in this repo) remaps the keyboard Mac-style, so e.g. Hyprland's `ALT + SPACE`
(vicinae) is Cmd+Space at the keyboard, which is Raycast on the Mac. Opt is Hyprland's ALT.

Where the Mac side lives:
- Window/workspace binds: `dot_aerospace.toml`
- Hyprland workspace rules (empty workspaces open on the focused monitor, focusing one on
  another monitor jumps there, moves follow the window, `S` = special:magic):
  `dot_local/bin/executable_aerospace-workspace`
- Alt+T (terminal): Ghostty `global:` keybind in `private_dot_config/ghostty/config.tmpl`
- Cmd+Space (launcher) and Cmd+Shift+V (clipboard history): Raycast hotkeys, set in Raycast
  itself (its settings can't be dotfiled)

No macOS equivalent (skip): Alt+P pseudotile, Alt+M wayvnc, mouse drag/resize binds, Print
screenshots, media keys.

Intentional difference (the only one): focus-follows-mouse is off in AeroSpace even though
Hyprland has `follow_mouse = 1`. AeroSpace focuses the window behind unmanaged popups (browser
extension popups like 1Password), which closes them on hover. Don't re-enable it.
