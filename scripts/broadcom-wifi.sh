#!/usr/bin/env bash
# Install the proprietary Broadcom driver (broadcom-sta-dkms) for the iMac's
# BCM4360 Wi-Fi chip.  Kubuntu can't use this chip out of the box.
#
# You need a wired internet connection for this: an Ethernet cable, or a phone
# plugged in over USB with tethering turned on.

STATE_FILE="broadcom-wifi.log"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$HERE/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: broadcom-wifi.sh [--dry-run] [--undo]

Installs broadcom-sta-dkms, the driver for the BCM4360 Wi-Fi chip.

  --dry-run   Show every command without running it.
  --undo      Remove the driver again.  Wi-Fi stops working afterwards.

Reversible.  Undo with:  scripts/broadcom-wifi.sh --undo
EOF
}

parse_common_args "$@"
require_linux

title "Checking the hardware"
check_model
if ! lspci -nn | contains '14e4:43a0'; then
  if lspci -nn | contains '14e4:43ba'; then
    fail "This iMac has a BCM43602 chip.  Linux's built-in driver handles it, so you don't need this script."
  fi
  fail "No BCM4360 Wi-Fi chip found (PCI ID 14e4:43a0).  This script is only for that chip.  Nothing was changed."
fi
ok "Wi-Fi chip: Broadcom BCM4360."

if [[ "$MODE" == "undo" ]]; then
  # Undo only what this script recorded doing.  A driver the installer added is left alone.
  if ! grep -qx "installed broadcom-sta-dkms" "$STATE_DIR/$STATE_FILE" 2>/dev/null; then
    say "This script has no record of installing the driver, so there's nothing for it to undo."
    say "If you want it gone anyway:  sudo apt purge broadcom-sta-dkms  (Wi-Fi stops working)"
    exit 0
  fi
  headers="$(grep '^installed kernel headers:' "$STATE_DIR/$STATE_FILE" | sed 's/^installed kernel headers: //' | tr '\n' ' ' || true)"
  headers="${headers% }"
  title "What undo will do"
  say "1. Remove the broadcom-sta-dkms package."
  say "2. Wi-Fi stops working after the next restart.  Plug in Ethernet first if you need to stay online."
  if [[ -n "${headers// }" ]]; then
    say "3. Offer to remove the kernel headers this script installed: $headers"
  fi
  confirm "Remove the Broadcom driver?" || fail "Stopped.  Nothing was changed."
  run sudo apt-get purge -y broadcom-sta-dkms
  if [[ -n "${headers// }" ]]; then
    say "Kernel headers are what DKMS uses to build drivers.  Other drivers built the same way need them too."
    say "If you're not sure, keep them.  They only take up space."
    # shellcheck disable=SC2086
    if confirm "Remove the kernel headers this script installed?  (Press Enter to keep them.)"; then
      run sudo apt-get remove -y $headers
    fi
  fi
  [[ $DRY_RUN -eq 1 ]] || rm -f "$STATE_DIR/$STATE_FILE"
  ok "Removed.  Restart the iMac to finish."
  exit 0
fi

if dpkg-query -W -f='${Status}' broadcom-sta-dkms 2>/dev/null | contains 'install ok installed'; then
  ok "broadcom-sta-dkms is already installed."
  lsmod | contains '^wl ' && ok "And the driver is loaded.  Nothing to do." && exit 0
  warn "It isn't loaded yet.  Restart the iMac and check again."
  exit 0
fi

title "Checking the internet connection"
if ! is_online; then
  fail "No internet.  Plug in an Ethernet cable, or tether a phone over USB, then run this again."
fi
ok "Online."

title "What this will do"
say "1. Refresh the list of available packages (apt-get update)."
say "2. Install broadcom-sta-dkms and the kernel headers it builds against."
say "   DKMS rebuilds the driver by itself after every kernel update."
say "   The 'linux-headers-generic' package keeps the headers coming with each new kernel."
say "3. Ask before switching to the new driver now.  A restart does the same thing."
say ""
say "This is reversible.  Undo it with:  scripts/broadcom-wifi.sh --undo"
confirm "Go ahead?" || fail "Stopped.  Nothing was changed."

offer_snapshot "Broadcom Wi-Fi driver"

title "Installing"
run sudo apt-get update
# Headers for the kernel running now, if the archive still has them.  If this
# kernel is older than the archive's, they're gone, so rely on linux-headers-generic,
# which follows the newest kernel.  A restart into that kernel finishes the job.
running_headers="linux-headers-$(uname -r)"
headers=(linux-headers-generic)
if apt-cache show "$running_headers" >/dev/null 2>&1; then
  headers+=("$running_headers")
else
  warn "The headers for the kernel running now ($(uname -r)) aren't in the archive any more."
  say "That usually means a newer kernel is out.  The driver gets built for it, so restart the iMac afterwards."
fi
# Only headers that weren't already here get recorded, so undo never removes ones you had.
new_headers=()
for p in "${headers[@]}"; do
  dpkg-query -W -f='${Status}' "$p" 2>/dev/null | contains 'install ok installed' || new_headers+=("$p")
done
run sudo apt-get install -y "${headers[@]}" broadcom-sta-dkms
record "$STATE_FILE" "installed broadcom-sta-dkms"
if [[ ${#new_headers[@]} -gt 0 ]]; then
  record "$STATE_FILE" "installed kernel headers: ${new_headers[*]}"
fi

title "Switching drivers"
say "The package blocks the open-source drivers that can't run this chip, and adds 'wl'."
if [[ " ${headers[*]} " != *" $running_headers "* ]]; then
  say "The driver was built for the newer kernel, not the one running now."
  ok "Done.  Restart the iMac to start using it, then look for Wi-Fi networks in the system tray."
  say "If Wi-Fi stops working after a kernel update, see docs/troubleshooting.md."
  exit 0
fi
if confirm "Load the new driver now? (Otherwise restart the iMac.)"; then
  for m in b43 bcma ssb brcmsmac; do
    if lsmod | contains "^$m "; then run sudo modprobe -r "$m"; fi
  done
  run sudo modprobe wl
fi

ok "Done.  Look for Wi-Fi networks in the system tray.  If none show, restart the iMac."
say "If Wi-Fi stops working after a kernel update, see docs/troubleshooting.md."
