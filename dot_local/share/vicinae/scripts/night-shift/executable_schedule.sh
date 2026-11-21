#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Set Night Shift Schedule
# @vicinae.mode compact
# @vicinae.icon 🌙
# @vicinae.packageName Night Shift
# @vicinae.description From/To times (9pm, 21:00...), or 'off' / 'on' to switch the schedule
# @vicinae.keywords ["night shift", "hyprsunset", "blue light", "warm", "redshift"]
# @vicinae.argument1 { "type": "text", "placeholder": "from (9pm) or off" }
# @vicinae.argument2 { "type": "text", "placeholder": "to (7am)", "optional": true }

# Part of ~/.local/bin/nightshift (see ~/config.md).
case "$1" in
    on|off) exec "$HOME/.local/bin/nightshift" schedule "$1" ;;
esac
[ -n "${2:-}" ] || { echo "Give both times, e.g. 9pm 7am"; exit 1; }
exec "$HOME/.local/bin/nightshift" schedule "$1" "$2"
