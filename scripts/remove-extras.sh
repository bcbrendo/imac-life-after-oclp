#!/usr/bin/env bash
# Remove apps Kubuntu's normal installation adds that you may not want.
# Asks about each group separately.  Removes nothing you don't say yes to.
#
# Why this exists:  Kubuntu 26.04.1's minimal installation fails on an installer
# bug, so the normal installation, followed by this tidy-up, is the way round it.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$HERE/lib/common.sh"

STATE_FILE="remove-extras.log"

usage() {
  cat <<'EOF'
Usage: remove-extras.sh [--dry-run] [--undo]

Offers to remove, one group at a time:  LibreOffice, Elisa (music player),
the KDE games, Firefox, and Thunderbird.  Settings files are kept.

  --dry-run   Show every command without running it.
  --undo      Reinstall everything this script removed.

Reversible.  Undo with:  scripts/remove-extras.sh --undo
EOF
}

parse_common_args "$@"
require_linux

title "Checking the system"
check_model
command -v apt-get >/dev/null || fail "This script needs apt (Kubuntu or Ubuntu).  Nothing was changed."

if [[ "$MODE" == "undo" ]]; then
  log="$STATE_DIR/$STATE_FILE"
  if [[ ! -s "$log" ]]; then
    say "This script has no record of removing anything, so there's nothing for it to undo."
    exit 0
  fi
  apt_pkgs="$(grep '^apt ' "$log" | cut -d' ' -f2- | tr '\n' ' ')"
  snap_pkgs="$(grep '^snap ' "$log" | cut -d' ' -f2- | tr '\n' ' ')"
  title "What undo will do"
  [[ -n "${apt_pkgs// }" ]]  && say "Reinstall with apt:  $apt_pkgs"
  [[ -n "${snap_pkgs// }" ]] && say "Reinstall with snap: $snap_pkgs"
  confirm "Reinstall them?" || fail "Stopped.  Nothing was changed."
  if [[ -n "${apt_pkgs// }" ]]; then
    run sudo apt-get update
    # shellcheck disable=SC2086
    run sudo apt-get install -y $apt_pkgs
  fi
  for s in $snap_pkgs; do run sudo snap install "$s"; done
  [[ $DRY_RUN -eq 1 ]] || mv "$log" "$log.undone-$(date +%Y%m%d-%H%M%S)"
  ok "Reinstalled."
  exit 0
fi

installed_from() {   # list installed packages matching the given names or patterns
  # dpkg-query fails if any name was never installed.  That's expected here, not an error.
  { dpkg-query -W -f='${Package} ${Status}\n' "$@" 2>/dev/null || true; } \
    | awk '$4 == "installed" { print $1 }'
}
has_snap() { command -v snap >/dev/null && snap list "$1" >/dev/null 2>&1; }

title "What this will do"
say "It looks for five groups of apps and asks about each one.  For each yes, it"
say "removes those apps with apt or snap and writes them to a list, so --undo can"
say "reinstall exactly the same set.  Your documents and settings aren't touched."
say ""
say "It never runs 'apt autoremove'.  Run that yourself later if you want the space back."
say "This is reversible.  Undo it with:  scripts/remove-extras.sh --undo"
confirm "Start?" || fail "Stopped.  Nothing was changed."

offer_snapshot "Remove extras"

remove_apt_group() {
  local label="$1"; shift
  local pkgs
  mapfile -t pkgs < <(installed_from "$@")
  title "$label"
  if [[ ${#pkgs[@]} -eq 0 ]]; then say "Not installed.  Skipping."; return 0; fi
  say "Installed: ${pkgs[*]}"
  if confirm "Remove $label?"; then
    run sudo apt-get remove -y "${pkgs[@]}"
    record "$STATE_FILE" "apt ${pkgs[*]}"
  fi
}

remove_snap_app() {
  local name="$1" label="$2"
  local deb=()
  mapfile -t deb < <(installed_from "$name")
  title "$label"
  if ! has_snap "$name" && [[ ${#deb[@]} -eq 0 ]]; then say "Not installed.  Skipping."; return 0; fi
  if confirm "Remove $label?"; then
    if has_snap "$name"; then
      say "Snap keeps a copy of the app's data for 31 days, in case you reinstall."
      run sudo snap remove "$name"
      record "$STATE_FILE" "snap $name"
    fi
    # Kubuntu also has a small apt package that reinstalls the snap during upgrades.
    if [[ ${#deb[@]} -gt 0 ]]; then
      run sudo apt-get remove -y "$name"
      record "$STATE_FILE" "apt $name"
    fi
  fi
}

remove_apt_group "LibreOffice (office suite)" 'libreoffice*'
remove_apt_group "Elisa (music player)" elisa
remove_apt_group "The KDE games" kmahjongg kmines kpat ksudoku

if ! command -v brave-browser >/dev/null && ! command -v google-chrome >/dev/null \
   && ! command -v chromium >/dev/null && ! flatpak list --app 2>/dev/null | contains -iE 'brave|chrom|librewolf|zen'; then
  warn "Firefox looks like your only web browser.  Install another first (scripts/install-apps.sh), or keep Firefox."
fi
remove_snap_app firefox "Firefox (web browser)"
remove_snap_app thunderbird "Thunderbird (email)"

title "Done"
say "Kept on purpose, because they're useful:  Haruna (video player), Partition Manager, and snapd."
[[ -s "$STATE_DIR/$STATE_FILE" ]] && say "Removed apps are listed in $STATE_DIR/$STATE_FILE."
exit 0
