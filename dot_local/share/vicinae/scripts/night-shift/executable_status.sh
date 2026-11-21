#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Night Shift Status
# @vicinae.mode compact
# @vicinae.icon 🌙
# @vicinae.packageName Night Shift
# @vicinae.description Show whether Night Shift is on, until when, and the temperature
# @vicinae.keywords ["night shift", "hyprsunset", "blue light", "warm", "redshift"]

# Part of ~/.local/bin/nightshift (see ~/config.md).
exec "$HOME/.local/bin/nightshift" summary
