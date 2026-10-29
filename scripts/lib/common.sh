# shellcheck shell=bash disable=SC2034  # MODE and colours are read by the scripts that source this file
# Shared helpers for the scripts in this folder.  Source it; don't run it.
#
# Every script follows the same contract:
#   1. Check the hardware and the system before doing anything.
#   2. Explain what it will do, in plain language.
#   3. Ask before each change.  There is no "yes to everything" option.
#   4. --dry-run prints every command without running it.
#   5. --undo reverses only what the script recorded doing.  Hand-made changes are left alone.

set -Eeuo pipefail

# If any command fails, stop and say so.  Never stop silently.
on_error() {
  [[ -z "${ERROR_SHOWN:-}" ]] || return 0
  ERROR_SHOWN=1
  printf '\n\e[31m✘ Stopped:  this command failed (exit code %s):\n    %s\e[0m\n' "$1" "$2" >&2
  printf 'Steps before it may already have run.  Run this script again with --undo to reverse them,\n' >&2
  printf 'or restore your Timeshift snapshot.  docs/troubleshooting.md may help.\n' >&2
}
trap 'on_error $? "$BASH_COMMAND"' ERR

DRY_RUN=0
TESTED_MODELS=("iMac15,1")          # Late 2014 and Mid 2015 Retina 5K
UNTESTED_MODELS=("iMac17,1")        # Late 2015 Retina 5K
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/imac-life-after-oclp"

if [[ -t 1 ]]; then
  BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; RESET=$'\e[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; RESET=""
fi

say()   { printf '%s\n' "$*"; }
title() { printf '\n%s== %s ==%s\n' "$BOLD" "$*" "$RESET"; }
ok()    { printf '%s✔ %s%s\n' "$GREEN" "$*" "$RESET"; }
warn()  { printf '%s! %s%s\n' "$YELLOW" "$*" "$RESET"; }
fail()  { printf '%s✘ %s%s\n' "$RED" "$*" "$RESET" >&2; exit 1; }

# Ask a yes/no question.  The default is always "no": pressing Enter changes nothing.
confirm() {
  local answer
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '%s[dry run] Would ask: %s%s\n' "$DIM" "$1" "$RESET"
    return 0
  fi
  read -r -p "$1 [y/N] " answer </dev/tty || answer=""
  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# Run a command, or only print it during a dry run.
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '%s[dry run] %s%s\n' "$DIM" "$*" "$RESET"
  else
    printf '%s$ %s%s\n' "$DIM" "$*" "$RESET"
    "$@"
  fi
}

# Write text to a root-owned file, or only show it during a dry run.
write_root_file() {
  local path="$1" content="$2"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '%s[dry run] Would write %s:%s\n%s\n' "$DIM" "$path" "$RESET" "$content"
  else
    printf '%s$ write %s%s\n' "$DIM" "$path" "$RESET"
    printf '%s\n' "$content" | sudo tee "$path" >/dev/null
  fi
}

# Parse the options every script shares.  Sets DRY_RUN and MODE (do | undo).
MODE="do"
parse_common_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --undo)    MODE="undo" ;;
      -h|--help) usage; exit 0 ;;
      *)         usage; fail "Unknown option: $1" ;;
    esac
    shift
  done
  if [[ $DRY_RUN -eq 1 ]]; then
    warn "Dry run: nothing will be changed.  Commands are printed instead."
  fi
}

require_linux() {
  [[ "$(uname -s)" == "Linux" ]] || fail "This script runs on the iMac, under Linux.  You're on $(uname -s)."
  [[ $EUID -ne 0 ]] || fail "Run this as your normal user, not with sudo.  It asks for your password when it needs it."
}

has_thunderbolt() { compgen -G "/sys/bus/thunderbolt/devices/*" >/dev/null; }

# Like "grep -q", but reads all of its input first.  With pipefail on, "cmd | grep -q"
# can fail at random when grep stops early and cmd is cut off mid-write.
contains() { local input; input="$(cat)"; grep -q "$@" <<<"$input"; }

# Check the internet connection.  Ask Ubuntu's package server over HTTPS first,
# because some networks block ping.  Fall back to ping if curl isn't installed
# or the HTTPS check fails.
is_online() {
  if command -v curl >/dev/null 2>&1 \
     && curl -fsI --max-time 10 https://archive.ubuntu.com/ubuntu/ >/dev/null 2>&1; then
    return 0
  fi
  ping -c 1 -W 3 archive.ubuntu.com >/dev/null 2>&1
}

mac_model() { cat /sys/class/dmi/id/product_name 2>/dev/null || echo "unknown"; }

# Check the model.  Tested models pass; anything else needs an explicit "yes".
check_model() {
  local model; model="$(mac_model)"
  local m
  for m in "${TESTED_MODELS[@]}"; do
    if [[ "$model" == "$m" ]]; then ok "Model: $model (tested)."; return 0; fi
  done
  for m in "${UNTESTED_MODELS[@]}"; do
    if [[ "$model" == "$m" ]]; then
      warn "Model: $model.  This model should be similar, but nobody has tested this script on it."
      confirm "Carry on anyway?" || fail "Stopped.  Nothing was changed."
      return 0
    fi
  done
  warn "Model: $model.  This script was written for a Retina 5K iMac (iMac15,1)."
  confirm "This isn't that machine.  Carry on anyway?" || fail "Stopped.  Nothing was changed."
}

# Offer a Timeshift snapshot before changing anything, if Timeshift is set up.
offer_snapshot() {
  local why="$1"
  if ! command -v timeshift >/dev/null 2>&1; then
    warn "Timeshift isn't installed, so there's no snapshot to fall back on.  (See the README, Part 6.)"
    confirm "Carry on without a snapshot?" || fail "Stopped.  Nothing was changed."
    return 0
  fi
  if [[ ! -f /etc/timeshift/timeshift.json ]]; then
    warn "Timeshift is installed but not set up yet.  Open Timeshift once and finish its setup wizard."
    confirm "Carry on without a snapshot?" || fail "Stopped.  Nothing was changed."
    return 0
  fi
  if confirm "Take a Timeshift snapshot first? (Recommended.  It takes a minute or two.)"; then
    run sudo timeshift --create --comments "Before: $why" --tags O
  fi
}

# Remember what a script did, so --undo can reverse exactly that.
record() {
  local file="$STATE_DIR/$1"
  shift
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '%s[dry run] Would record in %s: %s%s\n' "$DIM" "$file" "$*" "$RESET"
  else
    mkdir -p "$STATE_DIR"
    printf '%s\n' "$*" >>"$file"
  fi
}
