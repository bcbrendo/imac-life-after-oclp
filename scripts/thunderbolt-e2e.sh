#!/usr/bin/env bash
# Make a Thunderbolt cable between the iMac and an Apple Silicon Mac carry
# network traffic, by turning off Linux's end-to-end flow control (e2e=0).
# The full story is in docs/thunderbolt-e2e.md.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$HERE/lib/common.sh"

CONF=/etc/modprobe.d/thunderbolt-net.conf
CONF_LINE="options thunderbolt_net e2e=0"
NM_NAME="Thunderbolt to Mac"
IMAC_ADDR="192.168.200.1/24"
STATE_FILE="thunderbolt-e2e.log"

usage() {
  cat <<EOF
Usage: thunderbolt-e2e.sh [--dry-run] [--undo] [--address ADDRESS/24]

Turns off end-to-end flow control in Linux's Thunderbolt networking driver,
so it can talk to an Apple Silicon Mac.  Optionally gives the iMac a fixed
address on the cable.

  --dry-run         Show every command without running it.
  --undo            Put everything back the way it was.
  --address ADDR    The iMac's address on the cable.  Default: $IMAC_ADDR

Reversible.  Undo with:  scripts/thunderbolt-e2e.sh --undo
EOF
}

args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --address) IMAC_ADDR="${2:?--address needs a value, like 192.168.200.1/24}"; shift 2 ;;
    *)         args+=("$1"); shift ;;
  esac
done
parse_common_args "${args[@]+"${args[@]}"}"
require_linux
[[ "$IMAC_ADDR" == */24 ]] || fail "Use a /24 address, like 192.168.200.1/24.  A wider range can clash with VPNs."

title "Checking the hardware"
check_model
if ! has_thunderbolt; then
  fail "No Thunderbolt controller found.  Nothing was changed."
fi
ok "Thunderbolt controller present."
if ! modinfo -p thunderbolt_net 2>/dev/null | contains '^e2e'; then
  fail "This kernel's thunderbolt_net driver has no e2e setting, so this fix doesn't apply.  Nothing was changed."
fi
ok "The thunderbolt_net driver supports the e2e setting."

reload_driver() {
  say "Reloading the driver drops any Thunderbolt network connection for a few seconds."
  if confirm "Reload the driver now? (Otherwise restart the iMac.)"; then
    run sudo modprobe -r thunderbolt_net
    run sudo modprobe thunderbolt_net
    say "Now unplug the Thunderbolt cable, wait five seconds, and plug it back in."
  fi
}

if [[ "$MODE" == "undo" ]]; then
  # Undo only what this script recorded doing.  Anything set up by hand is left alone.
  log="$STATE_DIR/$STATE_FILE"
  wrote=0; backed_up=0; created=0
  if [[ -f "$log" ]]; then
    grep -qx "wrote $CONF" "$log" && wrote=1
    grep -qx "backed up $CONF" "$log" && backed_up=1
    grep -qx "created NetworkManager profile $NM_NAME" "$log" && created=1
  fi
  if [[ $wrote -eq 0 && $created -eq 0 ]]; then
    say "This script has no record of changing anything here, so there's nothing for it to undo."
    if [[ -f "$CONF" ]]; then
      say "$CONF exists, but this script didn't write it.  It's been left alone."
      say "To remove it by hand:  sudo rm $CONF  (then restart)"
    fi
    exit 0
  fi
  title "What undo will do"
  if [[ $wrote -eq 1 && $backed_up -eq 1 ]]; then
    say "- Put back the copy of $CONF saved before this script changed it."
  elif [[ $wrote -eq 1 ]]; then
    say "- Delete $CONF, which this script created."
  fi
  [[ $created -eq 1 ]] && say "- Delete the '$NM_NAME' network profile, which this script created."
  [[ $wrote -eq 1 ]] && say "- Offer to reload the driver with its default setting (e2e on)."
  confirm "Undo the Thunderbolt changes?" || fail "Stopped.  Nothing was changed."
  if [[ $wrote -eq 1 && $backed_up -eq 1 && -f "$CONF.before-imac-guide" ]]; then
    run sudo mv "$CONF.before-imac-guide" "$CONF"
  elif [[ $wrote -eq 1 && -f "$CONF" ]]; then
    run sudo rm "$CONF"
  fi
  if [[ $created -eq 1 ]] && nmcli -t -f NAME connection show 2>/dev/null | contains -x "$NM_NAME"; then
    run nmcli connection delete "$NM_NAME"
  fi
  [[ $wrote -eq 1 ]] && reload_driver
  [[ $DRY_RUN -eq 1 ]] || rm -f "$STATE_DIR/$STATE_FILE"
  ok "Undone."
  exit 0
fi

title "What this will do"
say "1. Create $CONF containing:"
say "     $CONF_LINE"
say "   The driver reads it every time it loads, so the fix survives restarts."
say "2. Offer to reload the driver so the setting takes effect now."
say "3. Offer to create a network profile giving the iMac the address $IMAC_ADDR"
say "   on the cable.  It never becomes the iMac's route to the internet."
say ""
say "This is reversible.  Undo it with:  scripts/thunderbolt-e2e.sh --undo"
confirm "Go ahead?" || fail "Stopped.  Nothing was changed."

offer_snapshot "Thunderbolt e2e=0"

title "Step 1: The driver setting"
if [[ -f "$CONF" ]] && grep -qx "$CONF_LINE" "$CONF"; then
  ok "$CONF already has the setting."
else
  if [[ -f "$CONF" ]]; then
    warn "$CONF already exists.  It contains:"
    sed 's/^/     /' "$CONF"
    confirm "Replace it? (A copy is kept as $CONF.before-imac-guide.)" || fail "Stopped at step 1."
    run sudo cp "$CONF" "$CONF.before-imac-guide"
    record "$STATE_FILE" "backed up $CONF"
  fi
  write_root_file "$CONF" "$CONF_LINE"
  record "$STATE_FILE" "wrote $CONF"
fi

title "Step 2: Load the setting"
reload_driver

title "Step 3: An address on the cable"
# A profile someone already set up for thunderbolt0 with a fixed address wins.  Never add a second.
existing=""
while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  if [[ "$(nmcli -g connection.interface-name connection show "$name" 2>/dev/null)" == thunderbolt0 && \
        "$(nmcli -g ipv4.method connection show "$name" 2>/dev/null)" == manual ]]; then
    existing="$name"
  fi
done < <(nmcli -t -f NAME connection show 2>/dev/null || true)
if [[ -n "$existing" ]]; then
  ok "The '$existing' profile already gives thunderbolt0 a fixed address.  Leaving it alone."
  IMAC_ADDR="$(nmcli -g ipv4.addresses connection show "$existing" | cut -d, -f1)"
elif confirm "Create the '$NM_NAME' profile with address $IMAC_ADDR?"; then
  run nmcli connection add type ethernet con-name "$NM_NAME" ifname thunderbolt0 \
    ipv4.method manual ipv4.addresses "$IMAC_ADDR" ipv4.never-default yes \
    ipv6.method disabled connection.autoconnect yes connection.autoconnect-priority 10
  record "$STATE_FILE" "created NetworkManager profile $NM_NAME"
fi

imac_ip="${IMAC_ADDR%/*}"
if [[ "${imac_ip##*.}" == 1 ]]; then mac_addr="${imac_ip%.*}.2"; else mac_addr="${imac_ip%.*}.1"; fi
title "On the Mac"
say "1. Open System Settings, then Network, then Thunderbolt Bridge, then Details."
say "2. Choose TCP/IP.  Set 'Configure IPv4' to 'Manually'."
say "3. Set the IP address to ${mac_addr} and the subnet mask to 255.255.255.0."
say "4. Leave the router empty.  Click OK."
say "5. If Thunderbolt Bridge is missing, add it: click the … button, then 'Add Service…'."
say ""
say "Then test from the Mac's Terminal:  ping ${IMAC_ADDR%/*}"
say "Ignore the Mac's per-port packet counters.  They read zero even when traffic flows."

if [[ -r /sys/module/thunderbolt_net/parameters/e2e ]]; then
  say ""
  say "Current driver setting: e2e = $(cat /sys/module/thunderbolt_net/parameters/e2e) (N means the fix is active)."
fi
