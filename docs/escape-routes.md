# Escape Routes: Getting Back

Read this before you install, while macOS still works.  Every route here leaves the firmware alone.

## Why the iMac can't be bricked by this guide

"Bricking" means damaging the firmware so a computer won't start at all.  Nothing in this guide can do that:

- The firmware lives on its own chip on the logic board.  It isn't on any drive.
- Installing an operating system writes to a drive, never to that chip.
- Firmware updates only ever come from Apple's macOS installers.  Linux doesn't apply them.

So even with every drive erased, the iMac still starts, still shows Startup Manager when you hold **Option**, and can still reinstall macOS over the internet.

## Rolling back with Timeshift

Use this when Kubuntu works but something you changed didn't.

### If Kubuntu still starts

1. 🟢 Open **Timeshift**.
2. 🟢 Select the snapshot taken before the change.
3. 🟡 Click **Restore** and follow the prompts.
4. 🟢 Restart when asked.

### If Kubuntu won't start

1. 🟢 Start from the Kubuntu USB stick.  (Hold **Option** at power-on, then choose the USB icon, usually labelled **EFI Boot**.)
2. 🟢 When the welcome screen appears, click **Try Kubuntu**.
3. 🟢 Connect to the internet over Ethernet.
4. 🟢 Open Konsole and run:  `sudo apt install timeshift`
5. 🟢 Open **Timeshift**.  It finds the snapshots on your Kubuntu drive.
6. 🟡 Select the snapshot you want and click **Restore**.
7. 🟢 Restart and remove the USB stick.

Timeshift restores the system, not your documents.  Your home folder is left as it is.

## Going back to macOS

> 🔴 **Warning:**  reinstalling macOS erases Kubuntu from that drive.  Copy anything you want to keep onto an external drive first.

### With the macOS installer stick

This is the stick you made with OCLP in Part 2 of the README.

1. 🟢 Plug in the macOS installer stick and the basic wired keyboard.
2. 🟢 Press the power button and hold **Option** until Startup Manager appears.
3. 🟢 Click the USB icon, usually labelled **EFI Boot**.  This starts OpenCore from the stick.
4. 🟢 In OpenCore's menu, choose the macOS installer.
5. 🟢 In the installer, open **Disk Utility**.
6. 🟢 Choose **View**, then **Show All Devices**.  Without this, Disk Utility lists only volumes, and you can't erase the whole drive.
7. 🔴 Select the drive Kubuntu is on (the drive itself, not a volume under it).  Click **Erase**.  Choose **APFS** and **GUID Partition Map**.
8. 🟢 Quit Disk Utility.  Choose **Reinstall macOS** and select the drive you just erased.
9. 🟢 The iMac restarts several times during the install.  Each time, hold **Option**, click **EFI Boot** (the stick), and choose the macOS installer entry in OpenCore's menu.  Starting the drive directly skips OpenCore, and the install stalls.
10. 🟢 When macOS is installed, open OCLP and install OpenCore to the drive again.  Then apply OCLP's root patches.

**On a Fusion Drive,** rebuild it before step 7, or macOS sees its SSD and hard disk as two separate drives.  In the installer, choose **Utilities**, then **Terminal**, and run `diskutil resetFusion`.  🔴 This erases both parts.  Then carry on from step 8.

### With Internet Recovery

Use this if you don't have the stick.  It's slower, and it needs a network connection.

1. 🟢 Plug in the basic wired keyboard and an Ethernet cable.
2. 🟢 Press the power button and hold **Option-Command-R** until a spinning globe appears.
3. 🟢 Wait for the download.  It can take 20 minutes or more.
4. 🔴 Open **Disk Utility** and erase the Kubuntu drive, as in steps 6 and 7 above.  On a Fusion Drive, rebuild it first, as described above.
5. 🟢 Choose **Reinstall macOS**.

This installs the newest macOS Apple supports on the model:  Big Sur on iMac15,1, Monterey on iMac17,1.  From there, OCLP can take you back to a newer version.

### Restoring your files

After either route, Migration Assistant offers to restore from your Time Machine backup during setup.  Choose your backup drive when it asks.

## Removing OpenCore

If OCLP installed OpenCore on the drive you erased for Kubuntu, it's already gone.  If OpenCore is on another drive, it may keep taking over at power-on, and Kubuntu then starts in 5K mode as a thin strip.

1. 🟢 Start Kubuntu from Startup Manager:  hold **Option** at power-on, then choose the Kubuntu drive (usually labelled **EFI Boot**).
2. 🟢 Open **Dolphin**.  Under **Devices**, find the small partition (about 200 MB) on the *other* drive.  That's its EFI partition.  Use `lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS` to check which drive it belongs to.
3. 🟡 Click it to mount it, and enter your password if asked.
4. 🟡 Inside its `EFI` folder, rename `OC` to `OC-disabled`, and `BOOT` to `BOOT-disabled`.  `OC` is OpenCore itself.  `BOOT` holds the launcher that starts it, which is what Startup Manager shows as that drive's **EFI Boot** icon.  Rename both back to undo.
5. 🟡 Reset the iMac's settings memory (NVRAM):  at power-on, hold **Option-Command-P-R** for about 20 seconds.  There's nothing to undo here:  it only clears settings the iMac rebuilds by itself.

**Only rename these folders on the other drive.**  The Kubuntu drive has its own `EFI/BOOT` folder, and Kubuntu needs it to start.

The NVRAM reset clears OCLP's leftover settings.  The iMac then picks a startup drive by itself, and the other drive's **EFI Boot** icon no longer appears in Startup Manager.
