# Thunderbolt Networking With an Apple Silicon Mac: `e2e=0`

A Thunderbolt cable between the iMac and a MacBook makes a fast, private network link—about 0.3 ms between the machines, against 20 ms or more over busy Wi-Fi.  It's what makes [Deskflow](deskflow.md) feel like a directly connected keyboard.

Out of the box, though, nothing crosses the cable.  This is the write-up of why, and the one setting that fixes it.

> **TL;DR**
>
> - Linux's Thunderbolt networking driver turns on end-to-end flow control by default.
> - With an Apple Silicon Mac on the other end of a Thunderbolt 2 link, that setting stops every packet.
> - Loading the driver with `e2e=0` fixes it.  `scripts/thunderbolt-e2e.sh` does that, and can undo it.

## The setup

| | iMac | MacBook Pro |
| --- | --- | --- |
| Model | iMac15,1 (Late 2014) | Mac15,7 (Apple Silicon) |
| Thunderbolt | Thunderbolt 2 (Falcon Ridge) | Thunderbolt 4 / USB4 |
| System | Kubuntu 26.04.1, kernel 7.0.0 | macOS 26 |
| Network interface | `thunderbolt0` | Thunderbolt Bridge |

The cable runs from the Mac's USB-C port, through Apple's Thunderbolt 3 (USB-C) to Thunderbolt 2 adapter, to the iMac.

## The symptoms

Everything looked healthy, and nothing worked:

- The Mac listed the iMac under **System Information**, then **Thunderbolt**, linked at 20 Gb/s.
- Linux reported `thunderbolt0` as up, with a carrier, and bound to the Mac's network service.
- Both sides had addresses on the same subnet.
- `ping` failed in both directions.  Linux counted zero packets received, ever.  The address lookup (ARP) never completed.

## What it wasn't

Several reasonable theories fell over along the way.  They're listed so you don't have to repeat them.

- **IP settings.**  Taking the Mac's Thunderbolt Bridge out of the picture and putting the address straight on the port changed nothing.
- **A missing driver.**  Both sides had theirs loaded.  macOS had even built its ThunderboltIP connection objects for the link.
- **A missing handshake.**  macOS's system registry showed zero for every Thunderbolt data-path counter.  That looked like proof macOS never set up a channel, and that Linux was missing a protocol step.  It wasn't.  Those counters stay at zero even after the link works.

## The fix

Linux's `thunderbolt_net` driver has one setting, `e2e`:  full end-to-end flow control, on by default.  Turning it off made the link work straight away.

1. 🟡 Reload the driver with the setting off.  The first command unloads the Thunderbolt networking driver, which drops the link for a moment.  The second loads it again with `e2e` turned off.  Both need `sudo`, because they change the running system.

   ```sh
   sudo modprobe -r thunderbolt_net && sudo modprobe thunderbolt_net e2e=0
   ```

2. 🟢 Unplug the cable, wait five seconds, and plug it back in.

`ping` then answered in 0.2–0.7 ms.

This only lasts until the next restart.  To undo it sooner, run the same two commands with `e2e=1`, or just restart.

Why flow control breaks this pairing isn't pinned down.  The likeliest explanation is that the Mac's side doesn't implement it the way Linux expects across a Thunderbolt 2 link.

## Making it stick

The driver loads by itself when the Mac's network service appears.  It just needs to know the setting every time.

```
# /etc/modprobe.d/thunderbolt-net.conf
options thunderbolt_net e2e=0
```

This was tested through a full restart, which also installed a new kernel.  Afterwards, `e2e` read `N`, the link came up with its fixed address, and the Mac answered in about 0.3 ms.

On the iMac, give `thunderbolt0` a fixed address, and tell it never to become the route to the internet.  Match the connection on the interface name, not the hardware address—Linux makes that address up for the link, and it can change.

On the Mac, give **Thunderbolt Bridge** a fixed address on the same subnet, with no router.

`scripts/thunderbolt-e2e.sh` does all of the iMac's side, after asking, and prints the steps for the Mac.  It defaults to 192.168.200.1 for the iMac and 192.168.200.2 for the Mac.

To undo:  `scripts/thunderbolt-e2e.sh --undo`.  Or delete `/etc/modprobe.d/thunderbolt-net.conf` and restart.

## Check it worked

- On the iMac:  `cat /sys/module/thunderbolt_net/parameters/e2e` prints `N`.
- From the Mac:  `ping 192.168.200.1` answers in under a millisecond.

## Troubleshooting

**The Mac doesn't list the iMac under System Information, then Thunderbolt.**
First check whether the iMac sees the Mac.  In Konsole, run:

```sh
cat /sys/bus/thunderbolt/devices/*/device_name
```

The first line, "Macintosh", is the iMac itself.  When the Mac is connected, its model appears on the next line, such as "Mac15,7".  If nothing appears under "Macintosh", the two machines aren't connected at the Thunderbolt level, and no setting will help.

1. 🟢 Unplug the cable at the iMac.  Plug it back in firmly.  The iMac's Thunderbolt 2 ports are on the back, out of sight, and a plug that isn't fully home looks the same as one that is.
2. 🟢 Try the iMac's other Thunderbolt port.
3. 🟢 Shut the iMac down completely, check the cable is connected, and start it again.

If the Mac is listed but the link still doesn't work, reload the driver, as in the fix above.

**Thunderbolt Bridge is missing from the Mac's network settings.**
Open **System Settings**, then **Network**.  Click the **…** button, then **Add Service…**, and choose **Thunderbolt Bridge**.

**The Mac's per-port packet counters read zero.**
Ignore them.  macOS doesn't count this traffic on the individual Thunderbolt ports.  `ping` is the honest test.

**It worked, then stopped after a restart.**
Check `/etc/modprobe.d/thunderbolt-net.conf` still exists, and that `e2e` reads `N`.

**The link breaks a VPN, or a VPN breaks the link.**
Keep the subnet mask at `255.255.255.0`, and pick a range your VPN doesn't use.  A wider mask can overlap a work VPN's addresses and send traffic the wrong way.  The script's `--address` option sets a different range.
