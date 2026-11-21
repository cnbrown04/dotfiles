#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Turn Off Night Shift
# @vicinae.mode compact
# @vicinae.icon 🌙
# @vicinae.packageName Night Shift
# @vicinae.description Normal colors now, until the next scheduled change
# @vicinae.keywords ["night shift", "hyprsunset", "blue light", "warm", "redshift"]

# Part of ~/.local/bin/nightshift (see ~/config.md).
exec "$HOME/.local/bin/nightshift" off
