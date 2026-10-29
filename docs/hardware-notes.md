# Hardware Notes

What's inside a Retina 5K iMac, and how each part behaves under Linux.

## The tested machine

| Part | Detail | Under Linux |
| --- | --- | --- |
| Model | iMac (Retina 5K, 27-inch, Late 2014), iMac15,1 | |
| CPU | Intel Core i7-4790K, 4 GHz (Haswell) | Works out of the box |
| Graphics | AMD Radeon R9 M295X, 4 GB (Tonga) | Works, at 4K.  (See below.) |
| Memory | 32 GB DDR3, the maximum | Works |
| Wi-Fi | Broadcom BCM4360 | Needs `broadcom-sta-dkms` |
| Ethernet | Broadcom BCM57766 gigabit | Linux's built-in driver (`tg3`) |
| Thunderbolt | Thunderbolt 2 (Falcon Ridge) | Works.  Networking with an Apple Silicon Mac needs `e2e=0`. |
| Bluetooth | Apple (Broadcom) controller | Works.  A Magic Keyboard pairs and types normally. |
| Sound | Cirrus Logic CS4206 | Detected, and the driver loads.  Speakers and headphones not yet tested. |
| Camera | FaceTime HD, built in | Detected, and the driver loads.  Not yet tested in an app. |
| SD card reader | Broadcom BCM57765 | Detected, and the driver loads.  Not yet tested with a card. |

Tested with Kubuntu 26.04.1 LTS, Linux kernel 7.0, and KDE Plasma 6 on Wayland.

## The display: why 4K, not 5K

The 5K panel is really two halves, each 2560×2880, fed by two separate internal connections.  macOS drives both.

When Apple's firmware starts anything other than macOS, it leaves the panel in a single-connection 4K mode.  Linux sees one ordinary 3840×2160 screen, and the panel scales it up.  It looks sharp, and at 150% scaling the workspace matches macOS at 5K.

Starting Linux through OpenCore is different.  OpenCore leaves the panel in 5K mode, and Linux's AMD graphics driver only wakes the left half.  The result is a thin strip across the middle of the screen, and this line in the system log:

```
enabling link 1 failed: 15
```

It's a known, open bug:  [drm/amd issue 4455](https://gitlab.freedesktop.org/drm/amd/-/issues/4455).  A community patch set fixes it on iMac15,1, for Fedora only.  (See [extras.md](extras.md#native-5k).)

## Keyboards the firmware can't see

Some keyboards work fine once Linux loads, but are invisible to the iMac's firmware and to the boot menu.  Mechanical keyboards with N-key rollover (NKRO) turned on are a common cause.  Without a keyboard the firmware can see, you can't hold **Option** for Startup Manager, or reach Internet Recovery.

Keep a basic wired USB keyboard in a drawer.  Or switch NKRO off in your keyboard's settings.

## Drives

A Retina 5K iMac has one of these:

- **A Fusion Drive:**  a small SSD and a hard disk, joined together by macOS.  Linux sees two separate drives.
- **One SSD.**
- **An upgraded setup,** such as a SATA SSD in place of the hard disk, alongside the original SSD.

Linux erases the whole drive it's installed on.  On a Fusion Drive, erasing either part ends macOS on both.  If you want to keep one drive untouched, decide that before you start, and never select it in the installer.

## Temperatures

Check this soon after installing.  On the tested iMac, the graphics chip idled just below its safety limit.

Install `lm-sensors` and run `sensors` to see the readings.  The graphics chip is the `edge` line under `amdgpu`.  The CPU is the `Package id 0` line.

| Reading | Idle, as installed | Idle, with the fix below |
| --- | --- | --- |
| Graphics chip (`edge`) | 105–108 °C.  Its limit is 110 °C. | About 82 °C |
| CPU (`Package id 0`) | 65–80 °C | 65–80 °C |
| Fan | 1,200–2,300 rpm | 2,600 rpm or more |

Two things cause it:

- **The graphics chip never slows down.**  Its main clock stays at the top speed, 850 MHz, even with nothing on screen moving.  (Its memory clock also stays at the top speed.  That's normal at 4K, and this fix leaves it alone.)
- **The fan barely notices.**  The iMac's own fan controller runs the fan, not Linux, and it hardly reacts to the graphics chip's temperature.

Regularly reaching the high 90s °C on the *CPU* under load is a separate matter.  That suggests the thermal paste needs replacing.

### Check whether your iMac has it

1. 🟢 In Konsole, run:

   ```sh
   cat /sys/class/drm/card*/device/pp_dpm_sclk
   ```

2. 🟢 Look for the line with the `*`.  If it's the last line (`7: 850Mhz *`) while nothing much is happening, the clock is stuck at its top speed.

### Fix it

🟡 **Reversible.**  The steps below create three small files.  Undo instructions follow.

The fix does two things, then repeats them every two minutes, because the login screen, logging in, and waking from sleep each undo the clock limit:

- It limits the graphics chip to its four slowest speeds (318–686 MHz).  The desktop and video stay smooth.  Games and other heavy 3D work get slower.
- It raises the fan's minimum speed to 2,600 rpm.  The fan controller can still go faster.  Expect a little more fan noise.

1. 🟢 Take a Timeshift snapshot.
2. 🟡 Create the script.  Copy this whole block into Konsole, then press Enter:

   ```sh
   sudo tee /usr/local/sbin/imac-gpu-cool >/dev/null <<'EOF'
   #!/bin/sh
   # Keep a Retina 5K iMac's AMD graphics chip cool under Linux.
   LEVELS="0 1 2 3"
   FAN_MIN=2600
   FAN=/sys/devices/platform/applesmc.768
   if [ -w "$FAN/fan1_min" ] && [ "$(cat "$FAN/fan1_min")" != "$FAN_MIN" ]; then
       echo "$FAN_MIN" > "$FAN/fan1_min"
   fi
   for dev in /sys/class/drm/card*/device; do
       [ "$(basename "$(readlink -f "$dev/driver")")" = amdgpu ] || continue
       [ -w "$dev/pp_dpm_sclk" ] || continue
       echo manual > "$dev/power_dpm_force_performance_level"
       echo "$LEVELS" > "$dev/pp_dpm_sclk"
       exit 0
   done
   echo "No AMD graphics chip found" >&2
   exit 1
   EOF
   sudo chmod 755 /usr/local/sbin/imac-gpu-cool
   ```

3. 🟡 Create the service, which runs the script at startup and after waking from sleep:

   ```sh
   sudo tee /etc/systemd/system/imac-gpu-cool.service >/dev/null <<'EOF'
   [Unit]
   Description=Keep the iMac's graphics chip cool
   After=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

   [Service]
   Type=oneshot
   ExecStart=/usr/local/sbin/imac-gpu-cool

   [Install]
   WantedBy=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
   EOF
   ```

4. 🟡 Create the timer, which runs it every two minutes:

   ```sh
   sudo tee /etc/systemd/system/imac-gpu-cool.timer >/dev/null <<'EOF'
   [Unit]
   Description=Reapply the iMac's graphics cooling settings

   [Timer]
   OnBootSec=1min
   OnUnitActiveSec=2min
   AccuracySec=15s

   [Install]
   WantedBy=timers.target
   EOF
   ```

5. 🟡 Turn both on:

   ```sh
   sudo systemctl daemon-reload
   sudo systemctl enable --now imac-gpu-cool.service imac-gpu-cool.timer
   ```

6. 🟢 After a few minutes, run `sensors` again.  The `edge` reading should be well below 100 °C.

To watch the temperature from the top bar, add a **System Monitor Sensor** widget and choose the GPU temperature.

To undo:

```sh
sudo systemctl disable --now imac-gpu-cool.timer imac-gpu-cool.service
sudo rm /usr/local/sbin/imac-gpu-cool /etc/systemd/system/imac-gpu-cool.service /etc/systemd/system/imac-gpu-cool.timer
sudo systemctl daemon-reload
```

Then restart.  The clock and the fan go back to their defaults.

The `mbpfan` tool, often suggested for Apple hardware, adjusts the fan from the CPU's temperature only.  It doesn't help here.

## Late 2015 (iMac17,1)

Untested.  From its specifications, expect these differences:

- **Wi-Fi:**  a Broadcom BCM43602 chip, which Linux's built-in driver usually handles.  Skip `broadcom-wifi.sh`.
- **Graphics:**  an AMD Radeon R9 M380, M390, M395, or M395X.  Whether it starts at 4K the same way is unconfirmed.
- **CPU:**  Intel Skylake.
- **Thunderbolt:**  Thunderbolt 2, as on the 2014 model.

If you try it, please open an issue with what you find.
