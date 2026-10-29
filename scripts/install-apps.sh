#!/usr/bin/env bash
# Install everyday apps from their official sources, one at a time, asking first.
# Apps installed with apt keep themselves up to date through Discover.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$HERE/lib/common.sh"

STATE_FILE="install-apps.log"

usage() {
  cat <<'EOF'
Usage: install-apps.sh [--dry-run] [--undo]

Offers each app in turn:  Timeshift, temperature sensors, Flatpak with Flathub,
Brave, Sublime Text, 1Password, and Deskflow.  For Dropbox it opens the
official download page instead.

  --dry-run   Show every command without running it.
  --undo      Offer to remove each app this script installed.

Reversible.  Undo with:  scripts/install-apps.sh --undo
EOF
}

parse_common_args "$@"
require_linux

title "Checking the system"
check_model
command -v apt-get >/dev/null || fail "This script needs apt (Kubuntu or Ubuntu).  Nothing was changed."
is_online || fail "No internet connection.  Nothing was changed."
ok "Online."

is_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | contains 'install ok installed'; }
# shellcheck disable=SC1091
CODENAME="$(. /etc/os-release; echo "${VERSION_CODENAME:-}")"

# Downloads go into a private temporary folder with a random name, which is
# deleted when the script ends, however it ends.
DL_DIR=""
cleanup_downloads() { [[ -z "$DL_DIR" ]] || rm -rf -- "$DL_DIR"; }
trap cleanup_downloads EXIT
ensure_download_dir() {
  if [[ -z "$DL_DIR" ]]; then
    DL_DIR="$(mktemp -d)"
    # apt reads the downloaded file as its own '_apt' user, so let it in.  Nobody else can write here.
    chmod 755 "$DL_DIR"
  fi
}

# Each app has:  a description, an install step, and an undo step.
# An install step that ends without installing anything sets SKIPPED=1, so
# nothing gets recorded, and --undo never touches a copy installed some other way.
SKIPPED=0

install_timeshift() {
  run sudo apt-get install -y timeshift
  say "Open Timeshift from the app menu and finish its setup wizard.  Choose RSYNC."
}
undo_timeshift() { run sudo apt-get remove -y timeshift; }

install_sensors() {
  run sudo apt-get install -y lm-sensors
  say "Run 'sensors' to see temperatures.  docs/hardware-notes.md says what to expect."
}
undo_sensors() { run sudo apt-get remove -y lm-sensors; }

install_flathub() {
  run sudo apt-get install -y flatpak plasma-discover-backend-flatpak
  run sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  say "Flathub apps now show up in Discover.  Restart the iMac before using them."
}
undo_flathub() {
  say "Removing Flatpak doesn't remove the Flatpak apps you've installed.  They stay on"
  say "the drive, taking up space, but can't run without Flatpak."
  if command -v flatpak >/dev/null 2>&1 && [[ -n "$(flatpak list --app --columns=application 2>/dev/null)" ]]; then
    say "These Flatpak apps are installed now:"
    flatpak list --app --columns=name,application 2>/dev/null | sed 's/^/  /'
    say "You can uninstall them first.  Their settings in your home folder (~/.var/app) stay."
    if confirm "Uninstall every Flatpak app listed above first?  (Press Enter to keep them.)"; then
      if [[ -n "$(flatpak list --system --app --columns=application 2>/dev/null)" ]]; then
        run sudo flatpak uninstall --system --all -y
      fi
      if [[ -n "$(flatpak list --user --app --columns=application 2>/dev/null)" ]]; then
        run flatpak uninstall --user --all -y
      fi
    fi
  fi
  run sudo apt-get remove -y plasma-discover-backend-flatpak flatpak
}

install_brave() {
  run sudo install -d -m 755 /usr/share/keyrings
  run sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
  run sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
    https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
  run sudo apt-get update
  run sudo apt-get install -y brave-browser
}
undo_brave() {
  run sudo apt-get remove -y brave-browser
  run sudo rm -f /etc/apt/sources.list.d/brave-browser-release.sources \
    /usr/share/keyrings/brave-browser-archive-keyring.gpg
}

install_sublime() {
  run sudo install -d -m 755 /etc/apt/keyrings
  run sudo curl -fsSLo /etc/apt/keyrings/sublimehq-pub.asc https://download.sublimetext.com/sublimehq-pub.gpg
  write_root_file /etc/apt/sources.list.d/sublime-text.sources "Types: deb
URIs: https://download.sublimetext.com/
Suites: apt/stable/
Signed-By: /etc/apt/keyrings/sublimehq-pub.asc"
  run sudo apt-get update
  run sudo apt-get install -y sublime-text
}
undo_sublime() {
  run sudo apt-get remove -y sublime-text
  run sudo rm -f /etc/apt/sources.list.d/sublime-text.sources /etc/apt/keyrings/sublimehq-pub.asc
}

# The files 1Password's package creates for its update source.  Removing the
# package leaves them behind.  Undo deletes only the ones this script saw appear.
ONEPASSWORD_FILES=(
  /etc/apt/sources.list.d/1password.sources
  /usr/share/keyrings/1password-archive-keyring.gpg
  /etc/debsig/policies/AC2D62742012EA22/1password.pol
  /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
)
ONEPASSWORD_STATE="install-apps-1password-files.log"
install_1password() {
  local f before=()
  for f in "${ONEPASSWORD_FILES[@]}"; do [[ -e "$f" ]] || before+=("$f"); done
  ensure_download_dir
  local deb="$DL_DIR/1password-latest.deb"
  run curl -fsSLo "$deb" https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb
  run sudo apt-get install -y "$deb"
  for f in "${before[@]}"; do
    if [[ $DRY_RUN -eq 1 || -e "$f" ]]; then record "$ONEPASSWORD_STATE" "$f"; fi
  done
  say "The package adds 1Password's own update source.  In 1Password's settings,"
  say "turn on 'Unlock using system authentication' and install the browser extension."
}
undo_1password() {
  run sudo apt-get remove -y 1password
  local f known log="$STATE_DIR/$ONEPASSWORD_STATE" files=()
  if [[ -s "$log" ]]; then
    while read -r f; do
      for known in "${ONEPASSWORD_FILES[@]}"; do
        if [[ "$f" == "$known" ]]; then files+=("$f"); fi
      done
    done <"$log"
  fi
  if [[ ${#files[@]} -gt 0 ]]; then
    say "Removing 1Password's update source, which its package added when this script installed it."
    run sudo rm -f -- "${files[@]}"
    [[ $DRY_RUN -eq 1 ]] || rm -f "$log"
  else
    say "This script has no record of which update-source files 1Password added, so it leaves them alone."
  fi
}

install_deskflow() {
  [[ -n "$CODENAME" ]] || fail "Can't tell which Ubuntu release this is."
  local url
  url="$(curl -fsSL https://api.github.com/repos/deskflow/deskflow/releases/latest \
    | grep -o "https://[^\"]*ubuntu-${CODENAME}-x86_64\.deb" | head -1 || true)"
  if [[ -z "$url" ]]; then
    warn "No Deskflow package for Ubuntu '$CODENAME' in the latest release."
    say "Get it from https://github.com/deskflow/deskflow/releases instead.  Nothing was installed."
    SKIPPED=1
    return 0
  fi
  ensure_download_dir
  local deb="$DL_DIR/deskflow.deb"
  run curl -fsSLo "$deb" "$url"
  run sudo apt-get install -y "$deb"
  say "Next:  docs/deskflow.md walks through connecting it to the Mac."
}
undo_deskflow() { run sudo apt-get remove -y deskflow; }

APPS=(timeshift sensors flathub brave sublime 1password deskflow)
declare -A DESC=(
  [timeshift]="Timeshift: system snapshots you can roll back to.  Strongly recommended."
  [sensors]="lm-sensors: shows CPU and GPU temperatures."
  [flathub]="Flatpak with Flathub: a big app store that shows up inside Discover."
  [brave]="Brave: a Chrome-based web browser, from Brave's own apt repository."
  [sublime]="Sublime Text: a text editor, from Sublime's own apt repository."
  [1password]="1Password: the password manager, from 1Password's own package."
  [deskflow]="Deskflow: share one keyboard and mouse between the iMac and a Mac.  (Optional extra.)"
)
declare -A CHECK=(
  [timeshift]=timeshift [sensors]=lm-sensors [flathub]=flatpak [brave]=brave-browser
  [sublime]=sublime-text [1password]=1password [deskflow]=deskflow
)
already() { is_installed "${CHECK[$1]}"; }
# True only for the names in APPS.  Undo checks every line of its log with this.
known_app() {
  local a
  for a in "${APPS[@]}"; do [[ "$1" == "$a" ]] && return 0; done
  return 1
}

if [[ "$MODE" == "undo" ]]; then
  log="$STATE_DIR/$STATE_FILE"
  if [[ ! -s "$log" ]]; then
    say "This script has no record of installing anything, so there's nothing for it to undo."
    exit 0
  fi
  title "What undo will do"
  say "It asks about each app this script installed, newest first.  Your files stay."
  confirm "Start?" || fail "Stopped.  Nothing was changed."
  # The log is read on its own channel (3), so apt can't swallow lines meant for this loop.
  while read -r app <&3; do
    [[ -n "$app" ]] || continue
    if ! known_app "$app"; then
      warn "The log mentions '$app', which this script doesn't know how to remove.  It's been left alone."
      continue
    fi
    title "${DESC[$app]}"
    if confirm "Remove it?"; then
      "undo_$app"
      [[ $DRY_RUN -eq 1 ]] || sed -i "/^$app\$/d" "$log"
    fi
  done 3< <(tac "$log" | awk '!seen[$0]++')
  ok "Finished."
  exit 0
fi

title "What this will do"
say "It shows each app in turn and asks before installing it."
say "Everything comes from the maker's official source."
say "Anything you install here, --undo can remove again."
confirm "Start?" || fail "Stopped.  Nothing was changed."

offer_snapshot "Install apps"
run sudo apt-get update

for app in "${APPS[@]}"; do
  title "${DESC[$app]}"
  if already "$app"; then ok "Already installed.  Skipping."; continue; fi
  if confirm "Install it?"; then
    SKIPPED=0
    "install_$app"
    if [[ $SKIPPED -eq 1 ]]; then
      continue
    elif [[ $DRY_RUN -eq 1 ]] || already "$app"; then
      record "$STATE_FILE" "$app"
    else
      warn "It doesn't show as installed, so it hasn't been recorded for --undo."
    fi
  fi
done

title "Dropbox: file syncing.  (Download page.)"
say "Dropbox doesn't have a script-friendly installer.  Its download page offers a .deb file."
say "Download it, then double-click it to install.  It adds its own update source."
if confirm "Open the Dropbox download page?"; then run xdg-open https://www.dropbox.com/install-linux; fi

ok "Done."
