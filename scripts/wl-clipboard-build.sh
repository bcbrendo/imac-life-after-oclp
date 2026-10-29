#!/usr/bin/env bash
# Build wl-clipboard 2.3.0 from source, so Deskflow's clipboard sharing works
# on KDE Plasma (Wayland) without freezing menus and popups.
#
# Why:  Kubuntu doesn't install wl-clipboard by default, and its package
# (2.2.1 on 26.04) can't use the clipboard protocol KDE offers
# (ext-data-control).  It falls back to a trick that steals focus, so menus,
# KRunner, and Klipper close the moment they open.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$HERE/lib/common.sh"

VERSION="v2.3.0"
REPO="https://github.com/bugaevc/wl-clipboard.git"
SRC="$HOME/.local/src/wl-clipboard"
STATE_FILE="wl-clipboard-build.log"
BUILD_DEPS=(git meson ninja-build pkg-config libwayland-dev wayland-protocols)

usage() {
  cat <<'EOF'
Usage: wl-clipboard-build.sh [--dry-run] [--undo]

Builds wl-clipboard 2.3.0 and installs it into /usr/local/bin, where it takes
priority over Kubuntu's older package, if that's installed.  The package itself
isn't touched.

  --dry-run   Show every command without running it.
  --undo      Uninstall the build, delete the source folder only if this script
              downloaded it, and offer to remove the build tools it added.

Reversible.  Undo with:  scripts/wl-clipboard-build.sh --undo
EOF
}

parse_common_args "$@"
require_linux

title "Checking the system"
check_model
if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
  warn "This session isn't Wayland (it's '${XDG_SESSION_TYPE:-unknown}').  The fix only matters on Wayland."
  confirm "Carry on anyway?" || fail "Stopped.  Nothing was changed."
fi
current="$(wl-copy --version 2>/dev/null | head -1 || true)"
say "wl-copy in use now: ${current:-not installed} ($(command -v wl-copy || echo 'none'))"

# What this script recorded about the source folder.  It deletes only what it made:
# the whole folder if it cloned it, or just the build folder inside one you already had.
log="$STATE_DIR/$STATE_FILE"
CLONED_LINE="cloned $VERSION source into $SRC"
BUILD_LINE="created build folder $SRC/build"
recorded() { grep -qxF "$1" "$log" 2>/dev/null; }

# True if $SRC is an unchanged copy of wl-clipboard at exactly $VERSION.
clean_checkout() {
  command -v git >/dev/null 2>&1 || return 1
  [[ -d "$SRC/.git" ]] || return 1
  [[ "$(git -C "$SRC" describe --tags --exact-match HEAD 2>/dev/null)" == "$VERSION" ]] || return 1
  [[ -z "$(git -C "$SRC" status --porcelain --untracked-files=no 2>/dev/null)" ]] || return 1
}

if [[ "$MODE" == "undo" ]]; then
  # Undo only what this script recorded doing.  A copy built by hand is left alone.
  if ! grep -qx "installed $VERSION into /usr/local/bin" "$log" 2>/dev/null; then
    say "This script has no record of installing wl-clipboard, so there's nothing for it to undo."
    if [[ -e /usr/local/bin/wl-copy ]]; then
      say "/usr/local/bin/wl-copy exists, but this script didn't install it.  It's been left alone."
    fi
    exit 0
  fi
  [[ -d "$SRC/build" ]] || fail "The build folder $SRC/build is missing, so the install can't be reversed safely.  Nothing was changed."
  title "What undo will do"
  say "1. Uninstall the $VERSION build, using its own install record.  Kubuntu's copy takes over again."
  if recorded "$CLONED_LINE"; then
    say "2. Delete the source folder this script downloaded: $SRC"
  elif recorded "$BUILD_LINE"; then
    say "2. Delete the build folder this script made: $SRC/build"
    say "   The rest of $SRC was there before, so it stays."
  else
    say "2. Leave $SRC alone.  This script has no record of creating it."
  fi
  say "3. Offer to remove the build tools this script installed."
  say "Clipboard sharing in Deskflow will freeze menus again afterwards."
  confirm "Undo the wl-clipboard build?" || fail "Stopped.  Nothing was changed."
  run sudo ninja -C "$SRC/build" uninstall
  if recorded "$CLONED_LINE"; then
    run rm -rf -- "$SRC"
  elif recorded "$BUILD_LINE"; then
    run rm -rf -- "$SRC/build"
  fi
  added="$(grep '^installed build tools:' "$log" | sed 's/^installed build tools: //' | tr '\n' ' ' || true)"
  if [[ -n "${added// }" ]]; then
    say "This script installed these build tools: $added"
    # shellcheck disable=SC2086
    if confirm "Remove them?"; then run sudo apt-get remove -y $added; fi
  fi
  [[ $DRY_RUN -eq 1 ]] || rm -f "$log"
  ok "Undone.  Open a new terminal so it picks up the change."
  exit 0
fi

if [[ -x /usr/local/bin/wl-copy ]] && /usr/local/bin/wl-copy --version 2>/dev/null | contains '2\.3'; then
  ok "wl-clipboard 2.3 is already installed in /usr/local/bin.  Nothing to do."
  exit 0
fi
if [[ -e /usr/local/bin/wl-copy ]]; then
  fail "/usr/local/bin/wl-copy already exists, and this script didn't put it there.  Remove it first if you want this build.  Nothing was changed."
fi

# A source folder that's already there gets used only if this script downloaded
# it, or if it's an unchanged copy of $VERSION.  Anything else, stop and say so.
reuse_src=0
if [[ -e "$SRC" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    fail "$SRC already exists, and it can't be checked because git isn't installed.  Move the folder somewhere else, then run this again.  Nothing was changed."
  fi
  if ! clean_checkout; then
    fail "$SRC already exists, but it isn't an unchanged copy of wl-clipboard $VERSION.  Move it somewhere else, or delete it if you don't need it, then run this again.  Nothing was changed."
  fi
  if [[ -e "$SRC/build" ]] && ! recorded "$BUILD_LINE"; then
    fail "$SRC/build already exists, and this script didn't make it.  Move it somewhere else, or delete it if you don't need it, then run this again.  Nothing was changed."
  fi
  reuse_src=1
  if recorded "$CLONED_LINE"; then
    ok "Using the $VERSION source this script downloaded before, in $SRC."
  else
    ok "Found an unchanged copy of the $VERSION source in $SRC.  It'll be used, and left in place by --undo."
  fi
fi

missing=()
for p in "${BUILD_DEPS[@]}"; do
  dpkg-query -W -f='${Status}' "$p" 2>/dev/null | contains 'install ok installed' || missing+=("$p")
done

title "What this will do"
if [[ ${#missing[@]} -gt 0 ]]; then
  say "1. Install the build tools that are missing: ${missing[*]}"
else
  say "1. Build tools: all present already."
fi
if [[ $reuse_src -eq 1 ]]; then
  say "2. Use the wl-clipboard $VERSION source already in $SRC"
else
  say "2. Download wl-clipboard $VERSION from its official repository into $SRC"
fi
say "3. Check Kubuntu's wayland-protocols is 1.39 or newer.  Older won't work."
say "4. Build it, then install wl-copy and wl-paste into /usr/local/bin."
say "   If Kubuntu's own copy is installed in /usr/bin, it stays there, unused but untouched."
say ""
say "This is reversible.  Undo it with:  scripts/wl-clipboard-build.sh --undo"
confirm "Go ahead?" || fail "Stopped.  Nothing was changed."

offer_snapshot "wl-clipboard 2.3.0 build"

title "Step 1: Build tools"
if [[ ${#missing[@]} -gt 0 ]]; then
  run sudo apt-get update
  run sudo apt-get install -y "${missing[@]}"
  record "$STATE_FILE" "installed build tools: ${missing[*]}"
fi

title "Step 2: Download"
if [[ $reuse_src -eq 1 ]]; then
  ok "Source already downloaded at $SRC."
else
  run mkdir -p "$(dirname "$SRC")"
  run git clone --depth 1 --branch "$VERSION" "$REPO" "$SRC"
  record "$STATE_FILE" "$CLONED_LINE"
fi

title "Step 3: Check wayland-protocols"
if [[ $DRY_RUN -eq 0 ]]; then
  wp="$(pkg-config --modversion wayland-protocols)"
  if dpkg --compare-versions "$wp" lt 1.39; then
    fail "wayland-protocols is $wp.  It needs 1.39 or newer, which Kubuntu 26.04 has.  Nothing was installed."
  fi
  ok "wayland-protocols $wp."
fi

title "Step 4: Build and install"
# nofallback:  use the system's wayland-protocols, never a silently downloaded copy.
if [[ -d "$SRC/build" ]]; then
  # Left over from an earlier run of this script that stopped part way (checked above).
  run meson setup --reconfigure "$SRC/build" "$SRC" --wrap-mode=nofallback --prefix=/usr/local
else
  # Recorded first, so undo can tidy it up even if the build stops part way.
  recorded "$BUILD_LINE" || record "$STATE_FILE" "$BUILD_LINE"
  run meson setup "$SRC/build" "$SRC" --wrap-mode=nofallback --prefix=/usr/local
fi
run ninja -C "$SRC/build"
run sudo ninja -C "$SRC/build" install
run sudo chown -R "$(id -un)": "$SRC"
record "$STATE_FILE" "installed $VERSION into /usr/local/bin"

title "Check"
if [[ $DRY_RUN -eq 0 ]]; then
  hash -r
  say "wl-copy now: $(wl-copy --version | head -1) ($(command -v wl-copy))"
fi
say "To confirm it uses KDE's clipboard protocol, run this and look for 'ext_data_control_manager_v1':"
say "  WAYLAND_DEBUG=1 wl-paste -l 2>&1 | grep data_control"
say "Then make sure Deskflow's clipboard sharing is on, and restart Deskflow.  (See docs/deskflow.md.)"
