#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Set Night Shift Temperature
# @vicinae.mode compact
# @vicinae.icon 🌙
# @vicinae.packageName Night Shift
# @vicinae.description Color temperature in Kelvin (2500 warm – 6000 neutral), or warmer / cooler
# @vicinae.keywords ["night shift", "hyprsunset", "blue light", "warm", "redshift"]
# @vicinae.argument1 { "type": "text", "placeholder": "4000, warmer or cooler" }

# Part of ~/.local/bin/nightshift (see ~/config.md).
case "$1" in
    warmer|cooler) exec "$HOME/.local/bin/nightshift" "$1" ;;
    *)             exec "$HOME/.local/bin/nightshift" temp "$1" ;;
esac
