# Deskflow: One Keyboard, Two Machines

[Deskflow](https://github.com/deskflow/deskflow) shares one keyboard and mouse between the iMac and a Mac beside it.  Move the pointer off the edge of one screen and it appears on the other.

This is an optional extra.  Deskflow calls the machine with the keyboard and mouse the **server**, and the machine that borrows them the **client**.

## Choose which machine shares

| Layout | Upside | Downside |
| --- | --- | --- |
| **iMac as server** (recommended) | The iMac always has real input:  its login screen, restarts, and Startup Manager (if the firmware can see the keyboard).  The Mac still has its own keyboard for its login screen.  With Toshy, ⌘ works on both machines with no modifier mapping. | Needs one-off setup so Toshy knows when the pointer is on the Mac.  (See below.) |
| **Mac as server** | Works without Toshy's help.  Tested end to end, ⌘ mapping included. | The iMac has no keyboard until Linux has started and Deskflow has connected.  Keep a basic USB keyboard handy. |

Both layouts are tested.  The setup is the same either way.  Only the roles and the ⌘ handling change.

## The network matters

Deskflow sends every keystroke and pointer movement over the network.  The connection decides how it feels.

- **A Thunderbolt cable:**  about 0.3 ms.  Feels like a directly connected keyboard.  (See [thunderbolt-e2e.md](thunderbolt-e2e.md).)
- **Home Wi-Fi:**  usually fine.
- **Office, hotel, or guest Wi-Fi:**  often fails.  These networks commonly block devices from talking to each other ("client isolation").  A VPN on the Mac can also take over the route between them.

## Install Deskflow

1. 🟡 On the iMac, install Kubuntu's own Deskflow package:  `sudo apt install deskflow`.  `scripts/install-apps.sh` offers it too.  It updates with the rest of the system.  The tested iMac uses it (version 1.26).

> **Don't use Deskflow 1.27 on the iMac yet** (the newer `.deb` on Deskflow's releases page).  1.27 drops wl-clipboard and uses KDE's own clipboard sharing instead.  KDE Plasma 6.6 doesn't offer that to a Deskflow server, so with the iMac as server, nothing copied crosses in either direction.  This should change with a later Plasma release.  The Mac can run 1.27:  the two versions work together.  If you've already tried 1.27, see [Troubleshooting](#troubleshooting).


2. 🟡 On the Mac, download the `macos-arm64.dmg` from the same page (for Apple Silicon).  Drag Deskflow into **Applications**.
3. 🟡 On the Mac, allow Deskflow under **Accessibility**, in **System Settings**, then **Privacy & Security**.
4. 🟡 If the Mac is the server, also allow Deskflow under **Input Monitoring**.

## Set up: Mac as server

### On the Mac

1. 🟢 Open Deskflow.  Choose to make this computer the **server**.
2. 🟢 In the server's screen layout, add a screen for the iMac.  Name it exactly as the iMac's client calls itself.
3. 🟢 Place the iMac's screen on the side where the iMac physically sits.

### On the iMac

1. 🟢 Open Deskflow.  Choose to make this computer a **client**.
2. 🟢 Enter the Mac's address.  Over Thunderbolt, that's the Mac's Thunderbolt Bridge address.
3. 🟢 Click **Start**.  When Plasma asks to allow remote control of input, allow it.

### Make ⌘ work on the iMac

Deskflow passes the Mac's ⌘ key to Linux as the Super key.  ⌘C then does nothing useful, and ⌘V opens the clipboard history.

1. 🟡 In the Mac's Deskflow server settings, open the iMac's screen.
2. 🟡 Map the **Super** modifier key to **Ctrl**.

⌘C and ⌘V now copy and paste in most apps.  In Konsole, Ctrl+C stops the running command, so use Ctrl+Shift+C and Ctrl+Shift+V there.

Toshy on the iMac doesn't see this input, because Deskflow sends keys through KDE's remote-control system rather than a physical keyboard device.  So the two don't conflict:  Toshy handles keyboards plugged into the iMac, and this mapping handles the Mac's.

To undo:  set the Super modifier key back to its default.

## Set up: iMac as server

### On the iMac

1. 🟢 Plug the keyboard and mouse into the iMac.
2. 🟢 Open Deskflow.  Choose to make this computer the **server**.
3. 🟢 In the server's screen layout, add a screen for the Mac.  Name it exactly as the Mac's client calls itself.
4. 🟢 Place the Mac's screen on the side where the Mac physically sits.
5. 🟢 Start the server.  When Plasma asks to allow input capture, allow it.  This prompt appears once.

### On the Mac

1. 🟢 Open Deskflow.  Choose to make this computer a **client**.
2. 🟢 Enter the iMac's address.  Over Thunderbolt, that's the iMac's address on the cable.
3. 🟢 Click **Start**.

### Make ⌘ work on the Mac

Without Toshy, the keyboard's ⌘ key reaches the Mac as ⌘ already.  Skip this section.

If Toshy runs on the iMac (see [extras.md](extras.md#toshy-mac-style-shortcuts)), it turns ⌘ into Ctrl before Deskflow sees the keystroke.  Toshy has built-in Deskflow support for this:  while the pointer is on the Mac, it switches itself off, and the Mac gets the real ⌘ key.  No modifier mapping is needed.

Toshy works out where the pointer is by reading Deskflow's log, so Deskflow has to write one.

1. 🟡 In Deskflow on the iMac, open **Settings** and tick **Log to file**.
2. 🟡 Enter the log's full path, with your username in place of `you`:

   ```
   /home/you/.local/state/Deskflow/deskflow.log
   ```

   Type the whole path.  Deskflow doesn't understand `~` here.  It creates a folder literally called `~` instead, and Toshy never finds the log.  If you use the folder button, add `deskflow.log` to the end yourself.
3. 🟢 Start the server.
4. 🟡 Restart Toshy.  It only checks whether Deskflow is a server or a client when it starts.  In Konsole, run:

   ```sh
   toshy-services-restart
   ```

5. 🟢 Check that Toshy found the log:

   ```sh
   journalctl --user -u toshy-config -n 50 | grep -iE 'server system|monitoring log'
   ```

   It should list both "Running as a server system" and "Monitoring log file".
6. 🟢 On the iMac, click into an ordinary app, such as a text editor.
7. 🟢 Move the pointer to the Mac.  Test ⌘C and ⌘V in a Mac text editor, ⌘Space for Spotlight, and Ctrl+A in Terminal.
8. 🟢 On the iMac, click into Konsole.
9. 🟢 Move the pointer to the Mac.  Repeat the same tests.

If you set a modifier mapping for the Mac's screen earlier, set it back to its defaults.  With Toshy stepping aside, a mapping would swap the keys a second time.

Repeat step 4 whenever you switch Deskflow between server and client.

### The number pad on the Mac

The number pad may type arrows and other navigation keys on the Mac, not digits.  That happens when Num Lock is off on the iMac.  Toshy makes the number pad type digits on the iMac regardless, but it steps aside while the pointer is on the Mac.

1. 🟡 Open **System Settings** and search for "NumLock".  Set Num Lock to turn on at startup.
2. 🟢 Log out and back in.

With Toshy running, pressing the Num Lock key on the iMac doesn't help.  Toshy turns it into a Mac-style **Clear** key.

## Share the clipboard

On the iMac, Deskflow needs two settings and a newer clipboard tool:

- **Enable clipboard sharing**, on both machines.  On its own, nothing copied on the Mac reaches the iMac.
- **Enable wl-clipboard support**, on the iMac.  This lets Deskflow reach the clipboard under Wayland.  It needs the `wl-clipboard` tool, which Kubuntu doesn't install by default.

Don't install Kubuntu's `wl-clipboard` package for this.  Its version, 2.2.1, can't use the clipboard protocol KDE offers, so it falls back to a trick that steals focus.  Menus, KRunner, and the clipboard history then close as soon as they open, whichever keyboard you use.  Version 2.3.0 fixes it.

1. 🟡 Build and install wl-clipboard 2.3.0:

   ```sh
   ~/imac-life-after-oclp/scripts/wl-clipboard-build.sh
   ```

2. 🟢 On the iMac, open Deskflow's **Settings**.  Tick **Enable clipboard sharing** and **Enable wl-clipboard support**.
3. 🟢 On the Mac, tick **Enable clipboard sharing** in Deskflow's settings.
4. 🟢 On the iMac, quit Deskflow completely from its icon in the system tray, then open it again.  Closing the window isn't enough:  the part that connects keeps running with the old settings.

If menus start closing as soon as they open, untick **Enable wl-clipboard support** and restart Deskflow.  Then check which `wl-copy` is in use:  `wl-copy --version` should say 2.3.0.

To undo:  untick **Enable wl-clipboard support**, then run `wl-clipboard-build.sh --undo`.  The fix needs Deskflow installed with apt or from the `.deb`.  A Flatpak copy of Deskflow can't see tools installed on the system.

## Troubleshooting

**The client can't connect at all.**
Check both machines are on a network that lets devices see each other.  Try the Thunderbolt cable, or a phone hotspot, to rule out client isolation.  Check the server is listening on the address the client uses.

**With the Mac as server, keys and clicks land on both machines at once.**
macOS has quietly withdrawn Deskflow's permissions—common after a Deskflow update.  Deskflow can read input, but can't stop it reaching the Mac.

1. 🟡 Open **System Settings**, then **Privacy & Security**, then **Accessibility**.
2. 🟡 Remove Deskflow with the **–** button, then add it back with **+**.
3. 🟡 Do the same under **Input Monitoring**.
4. 🟢 Restart Deskflow.

The same fix applies when the Mac is the client and ignores input after an update.

**macOS says "Deskflow is damaged and can't be opened".**
After some updates, macOS keeps a stale download flag on the app.  Deskflow is signed and notarised, so it's safe to clear.  In Terminal, run:

```sh
xattr -dr com.apple.quarantine /Applications/Deskflow.app
```

**The pointer feels floaty.**
The network is adding delay.  A Thunderbolt cable fixes it.

**The client stopped connecting after changing settings.**
The client may have stopped.  Click **Start** again on the client.

**A pop-up says "Input Capture Started" every time the pointer moves to the Mac.**
With the iMac as server, KDE announces each hand-over.  To silence it:

1. 🟡 Open **System Settings**, then **Notifications**.
2. 🟡 Under **Applications**, choose **KDE Portal Integration**, and turn off its pop-ups.

The notices still go to the notification history.  This also hides that service's other pop-ups, such as an app starting remote control of the desktop.  To undo:  turn its pop-ups back on.

**The server won't start, and Deskflow's log says "cannot bind address: Address already in use".**
A leftover clipboard helper is holding Deskflow's network port.  Deskflow 1.26 starts a `wl-copy` process to hold copied text, and it can outlive the server.  (A known bug, [deskflow#9386](https://github.com/deskflow/deskflow/issues/9386).)

1. 🟢 Check what holds the port.  In Konsole, run:

   ```sh
   ss -tlnp | grep 24800
   ```

   No output means the port is free.  A line naming `deskflow-core` means the server is running.  A line naming `wl-copy` is the leftover.
2. 🟡 If it names `wl-copy`, stop it:

   ```sh
   pkill -f '^/usr/local/bin/wl-copy --primary'
   ```

   This only clears your last text selection, used for middle-click paste.  The normal clipboard isn't affected.
3. 🟢 Click **Start** in Deskflow.

**With the iMac as server, ⌘ shortcuts act strangely on the Mac.**
For example, ⌘⇧V pastes instead of opening a clipboard app, or a shortcut works one day and not the next.  Toshy has stopped stepping aside on the Mac.  It knows where the pointer is from the "switch from" lines in Deskflow's log.

1. 🟢 Move the pointer to the Mac and back.  Then check the log recorded it:

   ```sh
   tail -n 5 ~/.local/state/Deskflow/deskflow.log
   ```

   You should see lines starting `INFO: switch from`.
2. 🟡 If they're there, restart Toshy:  `toshy-services-restart`
3. 🟡 If they're missing, check **Log to file** in Deskflow's **Settings** (see [Make ⌘ work on the Mac](#make--work-on-the-mac)).  Quit Deskflow from the system tray, open it again, then restart Toshy.

Restart Toshy after every Deskflow update or downgrade.

**You tried Deskflow 1.27 on the iMac, then went back to 1.26.**
The first time 1.27 runs, it converts Deskflow's settings to its own format.  1.26 doesn't understand the converted settings, so after going back, clipboard sharing and the log for Toshy stop working.

1. 🟡 Go back to Kubuntu's package.  Find its version with `apt-cache policy deskflow`:  it's the one listed from `archive.ubuntu.com`.  Then install that version, for example:

   ```sh
   sudo apt install --allow-downgrades deskflow=1.26.0+dfsg-1
   ```
2. 🟢 Open Deskflow's **Settings** and set everything again:  **Enable clipboard sharing**, **Enable wl-clipboard support**, **Log to file** with its full path, and the log level **Info**.
3. 🟢 Check the screen layout in the server settings.  Put the Mac's screen back if it's missing.
4. 🟢 Quit Deskflow from the system tray, open it again, and click **Start**.
5. 🟡 Restart Toshy:  `toshy-services-restart`

If you edit `~/.config/Deskflow/Deskflow.conf` by hand instead, quit Deskflow first, or it writes its old settings back.  1.26 needs the log level as a number (`level=4` for Info).  A word such as `Info` or `Debug` silently stops the log, and Toshy with it.
