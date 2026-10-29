#!/usr/bin/env bash
# Report what this machine is, without changing anything.
# Safe to run any time, including from the live USB before you install.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$HERE/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: check-hardware.sh

Prints the model, graphics, Wi-Fi chip, Thunderbolt, drives, and display
session.  Reads only.  Changes nothing, so unlike the other scripts it has no
--dry-run or --undo, and doesn't offer a Timeshift snapshot.
EOF
}
[[ "${1:-}" =~ ^(-h|--help)$ ]] && { usage; exit 0; }
[[ "$(uname -s)" == "Linux" ]] || fail "Run this on the iMac, under Linux (the live USB is fine)."

title "Model"
model="$(mac_model)"
case "$model" in
  iMac15,1) ok "$model: Retina 5K, Late 2014 or Mid 2015.  This guide was tested on it." ;;
  iMac17,1) warn "$model: Retina 5K, Late 2015.  Similar, but untested.  See docs/hardware-notes.md." ;;
  *)        warn "$model: not a model this guide covers." ;;
esac

title "Graphics"
lspci -nn | grep -iE 'vga|display' || warn "No graphics card listed."

title "Wi-Fi"
if lspci -nn | contains '14e4:43a0'; then
  say "Broadcom BCM4360.  It needs the proprietary driver: scripts/broadcom-wifi.sh."
elif lspci -nn | contains '14e4:43ba'; then
  say "Broadcom BCM43602.  Linux's built-in driver usually handles it.  You probably don't need broadcom-wifi.sh."
else
  lspci -nn | grep -i network || say "No Wi-Fi chip found."
fi
if lsmod | contains '^wl '; then ok "The proprietary 'wl' driver is loaded."; fi

title "Thunderbolt"
if has_thunderbolt; then
  ok "Thunderbolt controller present."
  for d in /sys/bus/thunderbolt/devices/*; do
    [[ -f "$d/device_name" ]] && say "  $(basename "$d"): $(cat "$d/vendor_name" 2>/dev/null) $(cat "$d/device_name")"
  done
else
  say "No Thunderbolt devices visible."
fi
if [[ -r /sys/module/thunderbolt_net/parameters/e2e ]]; then
  say "thunderbolt_net is loaded.  e2e = $(cat /sys/module/thunderbolt_net/parameters/e2e) (N is the setting this guide uses)."
fi

title "Drives"
say "Check these carefully before installing.  Note each drive's size and model."
lsblk -d -e 7,43 -o NAME,SIZE,MODEL,TRAN,ROTA | sed 's/^/  /'
say "${DIM}TRAN = connection (sata, nvme, usb).  ROTA 1 = spinning hard disk.${RESET}"

title "System"
say "Kernel:  $(uname -r)"
# shellcheck disable=SC1091
[[ -r /etc/os-release ]] && say "System:  $(. /etc/os-release; echo "$PRETTY_NAME")"
say "Session: ${XDG_SESSION_TYPE:-unknown} (wayland is expected on Kubuntu)"
if command -v mokutil >/dev/null 2>&1; then
  say "Secure Boot: $(mokutil --sb-state 2>/dev/null || echo 'unknown')"
fi
