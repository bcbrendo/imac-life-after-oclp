# Troubleshooting

Each problem below lists the symptom, the cause, and the fix.  Take a Timeshift snapshot before any fix marked 🟡.

## Starting up

### Holding Option shows OpenCore's menu, or a stick called "ESP"

**Cause:**  the firmware can't see your keyboard, so it never notices you holding Option.

1. 🟢 Plug a basic wired USB keyboard straight into the iMac.  Avoid hubs.
2. 🟢 Try again.  Press the power button, then hold **Option** straight away.

If the keyboard is a mechanical one, switching off its N-key rollover (NKRO) setting often helps.

### The screen shows a thin strip, or half a picture

**Cause:**  the iMac started through OpenCore, which leaves the panel in 5K mode.  Linux only drives the left half.  (See [hardware-notes.md](hardware-notes.md#the-display-why-4k-not-5k).)

1. 🟢 Restart.  Hold **Option** and choose the Linux drive or USB stick from Apple's Startup Manager, not from OpenCore's menu.
2. 🟡 If OpenCore keeps taking over, remove it.  (See [escape-routes.md](escape-routes.md#removing-opencore).)

### The iMac doesn't start Kubuntu after installing

1. 🟢 Hold **Option** at power-on until Startup Manager appears.
2. 🟡 Hold **Control** and click the Kubuntu drive's icon (usually labelled **EFI Boot**).  Holding Control makes it the default startup drive.

If OpenCore takes over instead, see [escape-routes.md](escape-routes.md#removing-opencore).

## Installing

### The installation fails with "exit code 100"

**Cause:**  on the Kubuntu 26.04.1 download, the minimal installation tries to remove two apps (`skanlite` and `krdc`) that aren't there.  The package tool treats that as fatal.  It's [Launchpad bug 2127711](https://bugs.launchpad.net/bugs/2127711), fixed in later versions of the installer's settings, so newer downloads may not have it.

1. 🟢 Restart the installer.
2. 🟢 Choose **Normal installation**.
3. 🟢 After installing, remove the apps you don't want with `scripts/remove-extras.sh`.

### Some keys type the wrong characters

**Cause:**  the live USB defaults to a UK keyboard layout.

1. 🟡 Open **System Settings**, then **Keyboard**.
2. 🟡 Add your layout, such as English (US), and move it to the top.

## Wi-Fi

### No Wi-Fi networks are listed

**Cause:**  the BCM4360 Wi-Fi chip needs a proprietary driver.

1. 🟢 Plug in an Ethernet cable, or share a phone's connection over USB.
2. 🟡 Run `scripts/broadcom-wifi.sh`.
3. 🟢 Restart.

### Wi-Fi stopped working after an update

**Cause:**  the driver is rebuilt for every new Linux kernel.  Occasionally the rebuild fails.

1. 🟢 Plug in an Ethernet cable, or share a phone's connection over USB.
2. 🟢 Check the driver's status:  `dkms status`
3. 🟡 Reinstall it:  `sudo apt install --reinstall broadcom-sta-dkms`
4. 🟢 Restart.

If it still fails, restore the Timeshift snapshot from before the update.

## Display

### Everything is too small, or too big

1. 🟡 Open **System Settings**, then **Display & Monitor**, then **Display Configuration**.
2. 🟡 Set **Scale** to 150%.  Click **Apply**.

### An app looks blurry

**Likely cause:**  some apps built on Electron or Chromium (Slack, for example) don't use Wayland by default, so the system scales them up.  This fix is commonly suggested, but hasn't been tested on this iMac.

1. 🟡 Open the **Menu Editor** (right-click the application launcher, then **Edit Applications…**).
2. 🟡 Find the app and add `--ozone-platform-hint=auto` to the end of its command.

Remove the addition to undo it.

## Everyday use

### The fan is quiet, but the iMac feels hot

**Cause:**  the graphics chip runs at full speed even when idle, and the fan controller barely reacts.  On the tested iMac it idled at 105–108 °C, just below its 110 °C limit.

1. 🟢 Run `sensors` and find the `edge` line under `amdgpu`.
2. 🟡 If it's above 100 °C at idle, apply the fix in [hardware-notes.md](hardware-notes.md#temperatures).

### Clicking in a terminal pastes text

**Cause:**  Linux pastes the last *selected* text when you click the middle mouse button, or press the scroll wheel.

1. 🟡 Open **System Settings** and search for "middle click".
2. 🟡 Switch off the paste option.  Log out and back in.

With a Magic Mouse, also see the next problem.  It's often what produced the middle click in the first place.

### A Magic Mouse clicks with the middle button by accident

**Cause:**  Linux's Magic Mouse driver turns a click near the middle of the mouse's surface into a middle click.  macOS doesn't, so it catches Mac users out.  Middle clicks paste text, open links in new tabs, and close tabs.

1. 🟡 Turn it off now:

   ```sh
   echo N | sudo tee /sys/module/hid_magicmouse/parameters/emulate_3button
   ```

2. 🟡 Keep it off after restarts:

   ```sh
   echo 'options hid_magicmouse emulate_3button=N' | sudo tee /etc/modprobe.d/hid-magicmouse.conf
   ```

3. 🟢 Test it.  First install the test tool, if it isn't there:  `sudo apt install libinput-tools`.  Then run `sudo libinput debug-events 2>&1 | grep BUTTON`, click around the mouse's surface, and press Ctrl+C.  Only `BTN_LEFT` and `BTN_RIGHT` should appear.

To undo:  delete `/etc/modprobe.d/hid-magicmouse.conf` and restart.

### Choosing from the clipboard history doesn't paste

**Cause:**  KDE's clipboard history (**Super+V**, or the clipboard icon in the system tray) puts the chosen item on the clipboard, but doesn't paste it.  Wayland doesn't let one app type into another app's window.

Choose the item, then press ⌘V (Ctrl+V without Toshy).

### Dropbox's Ubuntu package won't install

**Cause:**  the `.deb` on Dropbox's download page (version 2020.03.04) asks for `libpango1.0-0`, a package name that Kubuntu 26.04 no longer has.  The error reads "Depends: libpango1.0-0 (>= 1.36.3) but it is not installable".

Install Dropbox's own Linux build instead.  It installs into your home folder and updates itself, so it doesn't need `sudo`.

1. 🟡 Download and unpack it:

   ```sh
   cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
   ```

2. 🟢 Start it:  `~/.dropbox-dist/dropboxd`.  It opens your browser to sign in.
3. 🟡 Make it start when you log in:

   ```sh
   mkdir -p ~/.config/autostart
   printf '[Desktop Entry]\nType=Application\nName=Dropbox\nExec=%s/.dropbox-dist/dropboxd\n' "$HOME" > ~/.config/autostart/dropbox.desktop
   ```

To undo:  quit Dropbox from its tray icon, then delete `~/.dropbox-dist` and `~/.config/autostart/dropbox.desktop`.  Your `~/Dropbox` folder stays.

### Some files from the Mac never appear in Dropbox on Linux

**Cause:**  macOS shows some folders as single files, called packages.  Some apps save their documents, libraries, or settings this way.  Dropbox on the Mac stores a package as one item, and Dropbox on Linux never downloads it.  Dropbox still reports "Up to date".  On dropbox.com, a package shows a file icon, not a folder icon.

There's no setting to change this.  To get a package's contents onto Linux, copy them into an ordinary folder on the Mac, or export the document to another format.

## Thunderbolt and Deskflow

Thunderbolt networking problems are in [thunderbolt-e2e.md](thunderbolt-e2e.md#troubleshooting).  Deskflow problems are in [deskflow.md](deskflow.md#troubleshooting).
