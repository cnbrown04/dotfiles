#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Toggle Night Shift
# @vicinae.mode compact
# @vicinae.icon 🌙
# @vicinae.packageName Night Shift
# @vicinae.description Turn Night Shift on or off until the next scheduled change
# @vicinae.keywords ["night shift", "hyprsunset", "blue light", "warm", "redshift"]

# Part of ~/.local/bin/nightshift (see ~/config.md).
exec "$HOME/.local/bin/nightshift" toggle
