#!/bin/sh
set -eu

# ==============================================================================
# BOOKS MODULE - GRAPHICAUDIO ENTRYPOINT
# ==============================================================================
# Description: Reads Docker secret files into environment variables, then hands
#              off to the stock php:apache entrypoint
# Author: Matt Barham
# Created: 2026-10-24
# Modified: 2026-10-24
# Version: 1.0.0
# Host: Your Server
# ==============================================================================
# Type: Shell Script
# Component: module: books / service: graphicaudio
# ==============================================================================

# ============================================================================
# SECRETS LOADING
# ============================================================================
# For each VAR_FILE variable that is set, export VAR from the file it names.
# A configured but unreadable file is fatal: falling back to the scraper's
# built-in default key would silently leave /refresh protected by 'changeme'.
load_secret() {
  var="$1"
  file_var="${var}_FILE"
  eval "path=\${${file_var}:-}"
  [ -n "$path" ] || return 0
  if [ ! -r "$path" ]; then
    echo "ERROR: ${file_var} points to unreadable file: ${path}" >&2
    exit 1
  fi
  value="$(cat "$path")"
  export "${var}=${value}"
}

load_secret REFRESH_KEY
load_secret AUDIOBOOKSHELF_KEY

exec docker-php-entrypoint "$@"
