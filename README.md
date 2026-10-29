# iMac: Life After OCLP 🐧

*Breathing new life into the old girl… as a Linux box!*

A step-by-step guide for moving a Retina 5K iMac 🖥️ from macOS (running on OpenCore Legacy Patcher) to Kubuntu Linux—plus optional scripts that do the fiddly parts for you.

My 2014 5K iMac had reached the end of the road on macOS.  Sequoia ran, but it felt heavy, and nothing newer was coming.  The panel is still beautiful, so I moved it to Linux.  This is the guide I wish I'd had.

> 📌 **TL;DR**
>
> - Kubuntu runs well on a Retina 5K iMac, at 4K resolution rather than 5K.
> - The install itself takes an afternoon.  Backing up first takes however long your backup takes.
> - Nothing here can damage the iMac's firmware.  There's always a way back to macOS.
> - You can test everything from a USB stick before you change anything.
> - Optional extras cover native 5K, Mac-style shortcuts and looks, and sharing one keyboard and mouse with a Mac beside it, over Thunderbolt.

## Contents

- [Is this for you?](#is-this-for-you)
- [How to read the steps](#how-to-read-the-steps)
- [What you need](#what-you-need)
- [Getting help from an AI assistant](#getting-help-from-an-ai-assistant)
- [Part 1: Check your iMac](#part-1-check-your-imac)
- [Part 2: Back up and plan your way back](#part-2-back-up-and-plan-your-way-back)
- [Part 3: Make the Kubuntu USB stick](#part-3-make-the-kubuntu-usb-stick)
- [Part 4: Try Kubuntu without installing](#part-4-try-kubuntu-without-installing)
- [Part 5: Install Kubuntu](#part-5-install-kubuntu)
- [Part 6: First start: Wi-Fi, updates, and snapshots](#part-6-first-start-wi-fi-updates-and-snapshots)
- [Part 7: Make it yours](#part-7-make-it-yours)
- [Optional extras](#optional-extras)
- [The scripts](#the-scripts)
- [Contributing](#contributing)
- [Licence](#licence)

## Is this for you?

### Which iMacs it fits

| iMac | Model identifier | Status |
| --- | --- | --- |
| iMac (Retina 5K, 27-inch, Late 2014) | iMac15,1 | Tested.  This guide was written on one. |
| iMac (Retina 5K, 27-inch, Mid 2015) | iMac15,1 | Same model identifier and hardware family.  Should behave the same. |
| iMac (Retina 5K, 27-inch, Late 2015) | iMac17,1 | Untested.  Different Wi-Fi and graphics.  Most steps should still apply. |

Last tested in October 2026, with Kubuntu 26.04.1 LTS, Linux 7.0, and KDE Plasma 6.6.

Other iMacs aren't covered, though much of the guide still applies.  (See [docs/hardware-notes.md](docs/hardware-notes.md).)

### What you gain

- A modern, supported system that feels light on this hardware.  Kubuntu 26.04 LTS gets updates until about April 2029.
- Current web browsers and apps, which keep updating.
- A desktop you can shape to your taste—including a convincingly Mac-like one.

### What you give up

- **5K.**  Linux runs the panel at 4K (3840×2160), scaled to fill the screen.  At 150% scaling it looks sharp and gives you the same workspace as 5K—it's just not quite as crisp.  Native 5K is possible as an optional extra, on Fedora rather than Kubuntu.
- **Apple-only apps and services:**  iMessage, FaceTime, AirDrop, Handoff, and the iCloud Drive app.
- **Adobe Creative Cloud, Final Cut Pro, and Logic Pro.**  None run on Linux.
- **Full-quality Netflix.**  Linux browsers are limited to about 720p.

If you have another Mac, keep those things there.

### How long it takes

| Stage | Time |
| --- | --- |
| Back up macOS | Depends on how much you have.  Allow a few hours for a first Time Machine backup. |
| Make the USB sticks and test-drive Kubuntu | About an hour |
| Install Kubuntu | About an hour |
| Wi-Fi, updates, snapshots, and apps | An hour or two |

Plan for an afternoon, after the backup has finished.

## How to read the steps

Every step is marked:

- 🟢 **Safe:**  changes nothing on the iMac.
- 🟡 **Reversible:**  changes something, and the step tells you how to undo it.
- 🔴 **Can't be undone:**  read the warning above the step first.  Only a backup brings things back.

A few terms come up throughout:

- **Firmware:**  the iMac's built-in startup software.  It runs before any operating system.
- **Live USB:**  a USB stick that runs Kubuntu without installing it.  Nothing on the iMac changes.
- **Terminal:**  a window where you type commands.  In Kubuntu it's called Konsole.
- **`sudo`:**  put in front of a command, it runs that command with administrator rights.  It asks for your password.
- **Snapshot:**  a saved copy of the system's state, which you can roll back to.  Timeshift makes them.

## What you need

- **Two USB sticks.**  One of 8 GB or larger holds Kubuntu.  One of 32 GB holds a macOS installer, as your way back.  Both get erased.
- **A basic wired USB keyboard.**  Fancy keyboards are often invisible to the iMac's firmware.  (See [Part 1](#part-1-check-your-imac).)
- **An external drive** for your backup.
- **A wired internet connection:**  an Ethernet cable, or a phone that can share its connection over USB.  The iMac's Wi-Fi won't work until Part 6.

## Getting help from an AI assistant

An AI assistant can walk you through this guide, explain anything unfamiliar, and check output with you.  It can't do the physical steps, and it should never erase anything for you.

[`AGENTS.md`](AGENTS.md) briefs the assistant on how to help safely.  Coding assistants that open this repository (such as Claude Code, Codex, or Cursor) read it automatically.  For a chat assistant, paste this in to start:

```text
I want to move my Retina 5K iMac from macOS to Kubuntu, using this guide:
https://github.com/bcbrendo/imac-life-after-oclp

Read its README.md and AGENTS.md before anything else, and follow AGENTS.md.
I'm not very technical, so take me through one step at a time, and wait for
me to confirm each step.  Warn me before anything that can't be undone.
Start with Part 1.
```

You stay in charge.  Every change, and every step at the keyboard, is yours.

## Part 1: Check your iMac

1. 🟢 Open the Apple menu, then **About This Mac**, then **More Info…**, then **System Report…**.
2. 🟢 Under **Hardware**, find **Model Identifier**.  Check it's iMac15,1 or iMac17,1.
3. 🟢 Plug the basic USB keyboard straight into a USB port on the back of the iMac.
4. 🟢 Shut down the iMac.
5. 🟢 Press the power button, then immediately hold down the **Option** key.
6. 🟢 Keep holding Option until a grey screen of drive icons appears.  This is Apple's **Startup Manager**.
7. 🟢 Start macOS as usual:  click the icon labelled **EFI Boot**.  On an OCLP Mac, that's OpenCore, which starts macOS.  Clicking the macOS drive itself skips OpenCore, and macOS may not start.

If you see a different menu—usually dark, with OpenCore or OCLP branding—the firmware didn't see your keyboard.  Try another keyboard or another USB port until Startup Manager appears.  You'll need it in Part 4.

## Part 2: Back up and plan your way back

### Why the firmware is safe

Nothing in this guide touches the iMac's firmware.  The firmware lives on its own chip, separate from every drive.  Erasing a drive can't damage it.  However badly an install goes, the iMac still starts, and its firmware can always reinstall macOS over the internet.

### Back up

1. 🟢 Connect your external drive.
2. 🟢 Open **System Settings**, then **General**, then **Time Machine**.
3. 🟢 Click **Add Backup Disk…** and choose the external drive.
4. 🟢 Wait for the first backup to finish.  It starts by itself, and the Time Machine settings show its progress.
5. 🟢 Check anything stored outside your user folder.  Copy it to the external drive too.
6. 🟢 Write down any software licence keys you'll need again.

### Make your way back to macOS

A macOS installer on a USB stick is the fastest way back.  OCLP can make one.  (These steps follow OCLP's own guide, [Creating a macOS installer](https://dortania.github.io/OpenCore-Legacy-Patcher/INSTALLER.html).)

> 🔴 **Warning:**  step 5 erases the 32 GB USB stick.  Use a stick with nothing on it you need.

1. 🟢 Plug in the 32 GB USB stick.
2. 🟢 Open **OpenCore Legacy Patcher**.
3. 🟢 Choose **Create macOS Installer**, then **Download macOS installer**.
4. 🟢 Pick the macOS version you run now.  Wait for the download to finish.
5. 🔴 Select the downloaded installer, then select the 32 GB USB stick.  OCLP erases it and writes the installer.
6. 🟢 Back in OCLP's main menu, choose **Build and Install OpenCore**.
7. 🟢 When the build finishes, choose **Install OpenCore**, and select the USB stick.  The stick needs OpenCore to start up.
8. 🟢 Label the stick "macOS installer" and keep it somewhere safe.

### Your three ways back

| Way back | What it needs | What you get |
| --- | --- | --- |
| The macOS installer stick | The stick, and OCLP to finish the job | The macOS version you run now |
| Internet Recovery | Hold **Option-Command-R** at power-on.  Needs internet and a keyboard the firmware can see. | The newest macOS Apple supports on your model (Big Sur for iMac15,1, Monterey for iMac17,1).  Run OCLP afterwards for anything newer. |
| Your Time Machine backup | Either of the above first | Your files, apps, and settings, via Migration Assistant |

The full walkthrough is in [docs/escape-routes.md](docs/escape-routes.md).  Read it now, while macOS still works.

## Part 3: Make the Kubuntu USB stick

1. 🟢 Download **Kubuntu 26.04 LTS** from [kubuntu.org/download](https://kubuntu.org/download/).  It's a single `.iso` file, about 5 GB.
2. 🟢 Check the download isn't damaged.  Open **Terminal** on the Mac and run:

   ```sh
   shasum -a 256 ~/Downloads/kubuntu-26.04*.iso
   ```

3. 🟢 Compare the long code it prints with the line for the same file name in Ubuntu's [checksum list](https://cdimage.ubuntu.com/kubuntu/releases/26.04/release/SHA256SUMS).  If every character matches, the download is good.  If they differ, delete the file and download it again.
4. 🟢 Download and install [balenaEtcher](https://etcher.balena.io/).

> 🔴 **Warning:**  step 8 erases the Kubuntu USB stick.  Use a stick with nothing on it you need.

5. 🟢 Plug in the USB stick for Kubuntu.
6. 🟢 Open balenaEtcher.  Choose **Flash from file** and select the Kubuntu `.iso`.
7. 🟢 Choose **Select target** and select the USB stick.  Check the size matches your stick.
8. 🔴 Click **Flash!** and wait for it to finish.  Etcher checks the stick once it has written it.

A damaged download usually shows up much later, as a confusing install failure.  The checksum catches it in a minute.

## Part 4: Try Kubuntu without installing

This is the cheap test.  Nothing on the iMac changes, so you can see how Kubuntu looks on your panel before committing.

1. 🟢 Plug in the Kubuntu USB stick, the basic keyboard, and the Ethernet cable.
2. 🟢 Shut down the iMac.
3. 🟢 Press the power button and hold **Option** until Startup Manager appears.
4. 🟢 Click the yellow USB icon, usually labelled **EFI Boot**.
5. 🟢 Choose **Try or Install Kubuntu** from the menu that follows.
6. 🟢 When the welcome screen appears, click **Try Kubuntu**.

> **Seeing a menu with a stick called "ESP"?**  That's OpenCore's menu, not Apple's Startup Manager.  The firmware didn't see your keyboard, so OpenCore started instead.  Starting the stick from there works, but the screen shows only a thin strip across the middle.  Shut down, and try another keyboard or USB port until Apple's grey Startup Manager appears.

Now look around.  Check these three things:

- **The screen fills the whole panel.**  If you see a thin strip across the middle, the iMac started through OpenCore rather than Apple's firmware.  (See [docs/troubleshooting.md](docs/troubleshooting.md#the-screen-shows-a-thin-strip-or-half-a-picture).)
- **The internet works over Ethernet.**  Wi-Fi won't work yet.  That's expected, and Part 6 fixes it.
- **Your keyboard types the right characters.**  The live USB may default to a UK layout.  If `|` or `@` come out wrong, add your layout in **System Settings**, then **Keyboard**.

When you're done, shut down from the application menu.  Unplug the USB stick when told to.  The iMac starts macOS as before.

## Part 5: Install Kubuntu

### Choose your drive

Linux erases the whole drive you install it on.  Decide which drive that is before you start.

- **One SSD:**  Kubuntu replaces macOS on it.
- **A Fusion Drive:**  Linux sees two separate drives—a small SSD and a large hard disk.  Installing on either one ends macOS on both.  Choose the SSD for speed, or the hard disk for space.
- **Two separate drives** (for example, an added SATA SSD):  install on one and leave the other alone.  Decide now which drive is off limits, and never select it.

Note each drive's size.  The installer identifies drives by size, so that's how you'll recognise the right one.  To list them from the live USB, open Konsole and run:

```sh
lsblk -d -o NAME,SIZE,MODEL
```

### Install

Kubuntu's installer collects all your choices first, and changes nothing until the very end.  Up to the **Summary** page, you can go **Back** or quit, and the iMac is untouched.

1. 🟢 Start from the Kubuntu USB stick, as in Part 4.
2. 🟢 This time, click **Install Kubuntu** on the welcome screen.
3. 🟢 Choose your language, location, and keyboard layout.
4. 🟢 When asked for the type of installation, choose **Normal installation**.  On the 26.04.1 download, the minimal installation fails partway through, because of an installer bug ([Launchpad bug 2127711](https://bugs.launchpad.net/bugs/2127711)).  Later installer versions fix it, but the normal installation works either way.
5. 🟢 If the installer offers to install third-party drivers or software, tick that option.
6. 🟢 In the **Select storage device** drop-down, select the drive you chose above.  Check its size twice.
7. 🟢 Choose **Erase disk**.  Nothing is erased yet.
8. 🟢 Enter your name, a computer name, and a password.  Remember the password—`sudo` asks for it.
9. 🟢 On the **Summary** page, read what the installer is about to do.  Check it names the drive you chose, by its size.

> 🔴 **Warning:**  the next step erases the drive shown on the Summary page.  Before you continue, check your Time Machine backup finished and your macOS installer stick works.

10. 🔴 Click **Install**, and confirm.  From here, the chosen drive is erased.
11. 🟢 Wait for the installation to finish.  It takes 20 to 40 minutes.
12. 🟢 When it finishes, restart.  Remove the USB stick when asked.

The iMac now starts straight into Kubuntu, with no menu and no OpenCore.  If it starts somewhere else, see [docs/troubleshooting.md](docs/troubleshooting.md#the-imac-doesnt-start-kubuntu-after-installing).

On a Fusion Drive, OpenCore can survive on the drive you didn't install to, and keep starting first.  If you see OpenCore's menu, or a thin strip across the screen, remove it.  (See [docs/escape-routes.md](docs/escape-routes.md#removing-opencore).)

## Part 6: First start: Wi-Fi, updates, and snapshots

### Get the optional scripts

The scripts in this repository automate some of the steps below.  Each one checks the hardware first, explains what it will do, and asks before changing anything.  Every script that changes something has `--dry-run`, to preview, and `--undo`, to reverse.

1. 🟢 In Kubuntu, open Konsole.
2. 🟡 Run these two commands.  The first installs `git`, the tool that downloads the repository.  The second downloads it to a folder in your home folder.

   ```sh
   sudo apt install git
   git clone https://github.com/bcbrendo/imac-life-after-oclp.git ~/imac-life-after-oclp
   ```

3. 🟢 Check what the scripts see:

   ```sh
   ~/imac-life-after-oclp/scripts/check-hardware.sh
   ```

To undo:  delete the `imac-life-after-oclp` folder, and `sudo apt remove git` if you like.

### Wi-Fi

The iMac15,1's Wi-Fi chip (Broadcom BCM4360) needs a driver Kubuntu doesn't include.  Keep the Ethernet cable plugged in for this part.

1. 🟢 Check whether Wi-Fi already works.  Click the network icon in the system tray.  If networks are listed, skip to Updates.
2. 🟡 Install the driver:

   ```sh
   ~/imac-life-after-oclp/scripts/broadcom-wifi.sh
   ```

   Or by hand:  `sudo apt install broadcom-sta-dkms`, then restart.

3. 🟢 Restart the iMac.  Then choose your Wi-Fi network from the system tray.

To undo:  run the script with `--undo`, or `sudo apt purge broadcom-sta-dkms`.

### Updates

1. 🟡 Open **Discover** from the application menu.
2. 🟡 Click **Updates**, then **Update All**.
3. 🟢 Restart when asked.

Security updates install by themselves from now on.  Discover tells you about the rest.

Updates can't be undone one by one.  That's what the Timeshift snapshot below is for:  restoring it rolls the whole system back.

### Snapshots with Timeshift

Timeshift saves snapshots of the system, so a bad update or experiment can be rolled back.  It doesn't back up your documents.  Keep using a separate backup for those.

1. 🟡 Install Timeshift:  `sudo apt install timeshift`
2. 🟢 Open **Timeshift** from the application menu.
3. 🟢 In the setup wizard, choose **RSYNC**, then the Kubuntu drive.  Accept the other defaults.
4. 🟢 Click **Create** to take your first snapshot.  Name it something like "Fresh install".

To undo:  `sudo apt purge timeshift`.  Delete any snapshots in Timeshift first, if you want the space back.

Take a snapshot before every change from here on.  The scripts offer to do it for you.  To roll back, open Timeshift, select a snapshot, and click **Restore**.  If Kubuntu won't start, [docs/escape-routes.md](docs/escape-routes.md#rolling-back-with-timeshift) shows how to restore from the live USB.

## Part 7: Make it yours

### Display scaling

1. 🟡 Open **System Settings**, then **Display & Monitor**, then **Display Configuration**.
2. 🟡 Set **Scale** to 150%.  Click **Apply**.

At 150%, the workspace matches macOS at 5K.  Change it back the same way.

### Remove apps you don't want

The normal installation adds LibreOffice, a music player, some games, Firefox, and Thunderbird.  Removing them is optional.

1. 🟡 Run the tidy-up script.  It asks about each group separately:

   ```sh
   ~/imac-life-after-oclp/scripts/remove-extras.sh
   ```

To undo:  `remove-extras.sh --undo` reinstalls exactly what it removed.

Keep Firefox until you've installed another browser.

### Install apps

1. 🟡 Run the apps script.  It offers each app in turn, from the maker's official source:

   ```sh
   ~/imac-life-after-oclp/scripts/install-apps.sh
   ```

It covers Timeshift, temperature sensors, Flathub, Brave, Sublime Text, 1Password, and Deskflow.  For Dropbox, it opens the official download page.

Or install apps yourself from **Discover**.  Most apps you'd want are there.

To undo:  `install-apps.sh --undo` offers to remove each app it installed.

### Check the temperatures

1. 🟡 Install the sensor tools, unless the apps script already did:  `sudo apt install lm-sensors`
2. 🟢 Run `sensors` in Konsole.
3. 🟢 Find the `edge` line under `amdgpu`.  That's the graphics chip.

If it idles above 100 °C, apply the fix in [hardware-notes.md](docs/hardware-notes.md#temperatures).  On the tested iMac it idled at 105–108 °C, just below its 110 °C limit, until the fix brought it to about 82 °C.

If the CPU (`Package id 0`) regularly reaches the high 90s under load, the thermal paste may need replacing.

## Optional extras

None of these are needed.  Each changes more than the core guide, so take a Timeshift snapshot first.  They're linked rather than bundled, so you always get the current version from the people who maintain it.  Details, risks, and how to undo each one are in [docs/extras.md](docs/extras.md).

| Extra | What it does | Risk |
| --- | --- | --- |
| [Native 5K patch set](docs/extras.md#native-5k) | Runs the panel at full 5K | 🔴 Means moving to Fedora, with a patched graphics driver |
| [Toshy](docs/extras.md#toshy-mac-style-shortcuts) | ⌘-style keyboard shortcuts | 🟡 Has its own uninstaller |
| [WhiteSur](docs/extras.md#whitesur-a-mac-like-look) | A macOS-like look | 🟡 Switch back in System Settings |
| [Deskflow](docs/deskflow.md) | Share one keyboard and mouse between the iMac and a Mac | 🟡 Uninstall any time |
| [Thunderbolt link](docs/thunderbolt-e2e.md) | A fast, direct network cable to an Apple Silicon Mac | 🟡 Script with `--undo` |
| [Plasma layout](plasma/README.md) | A saved Mac-style desktop layout | 🟡 Save your current layout first |

## The scripts

| Script | What it does | Undo |
| --- | --- | --- |
| [`check-hardware.sh`](scripts/check-hardware.sh) | Reports the model, chips, and drives.  Changes nothing. | Not needed |
| [`broadcom-wifi.sh`](scripts/broadcom-wifi.sh) | Installs the BCM4360 Wi-Fi driver | `--undo` |
| [`remove-extras.sh`](scripts/remove-extras.sh) | Removes unwanted default apps, one group at a time | `--undo` reinstalls them |
| [`install-apps.sh`](scripts/install-apps.sh) | Installs apps from official sources | `--undo` |
| [`thunderbolt-e2e.sh`](scripts/thunderbolt-e2e.sh) | Fixes Thunderbolt networking with an Apple Silicon Mac | `--undo` |
| [`wl-clipboard-build.sh`](scripts/wl-clipboard-build.sh) | Builds a newer clipboard tool, for Deskflow | `--undo` |

Every script that changes something:

- Checks it's on the right hardware before doing anything.
- Explains what it will do, then asks.  Pressing Enter always means "no".
- Offers a Timeshift snapshot first.
- Shows each command as it runs it.
- Accepts `--dry-run`, which prints the commands without running them.
- Accepts `--undo`, which reverses only what that script recorded doing.  Anything you set up by hand is left alone.

Read a script before running it if you like.  Each is short and commented.

## Contributing

Corrections, hardware reports, and improvements are welcome, especially from owners of the Late 2015 iMac.  See [CONTRIBUTING.md](CONTRIBUTING.md).  If you find something that could harm someone's system, please report it privately.  (See [SECURITY.md](SECURITY.md).)

## Licence

- **[MIT licence](LICENSE):**  the scripts (`scripts/`) and the repository's GitHub configuration (`.github/`).
- **[Creative Commons Attribution 4.0](LICENSE-docs):**  everything else, including this README, `docs/`, `plasma/` (the guide and the `mac-feel.knsv` settings profile), `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, and `SECURITY.md`.  The [Code of Conduct](CODE_OF_CONDUCT.md) is the Contributor Covenant 2.1, under its own CC BY 4.0 licence.  Share and adapt it, with credit.

Third-party projects (WhiteSur, Toshy, Deskflow, Konsave, and the rest) are linked, not included.  Each keeps its own licence.  The settings profile names the WhiteSur theme, but contains none of its files or colours.

Not affiliated with Apple, Canonical, KDE, or the OpenCore Legacy Patcher project.  Follow this guide at your own risk, and back up first.
