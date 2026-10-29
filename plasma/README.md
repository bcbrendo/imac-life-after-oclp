# Plasma Layout

A saved copy of a Mac-style KDE Plasma desktop, made with [Konsave](https://github.com/Prayag2/konsave).  Applying it sets up the panels, theme choices, and window behaviour in one go.

## What's in it

`mac-feel.knsv` holds eight Plasma settings files, and nothing else:

- **Panels:**  a top bar with the application launcher, the **Global Menu**, a small CPU, GPU temperature, RAM, and disk readout, the system tray, and the clock.  A floating dock at the bottom, sized to fit its apps, that moves out of the way of windows.
- **Look:**  WhiteSur's dark Plasma style, icons, cursors, and window title bars, with the Inter font.  The colours come from WhiteSur itself, in step 5 below.
- **Windows:**  close, minimise, and maximise buttons on the left, the **Magic Lamp** effect, and **Overview** on the top-left screen corner.
- **Small things:**  middle-click paste turned off, a 200-item clipboard history, and KRunner floating in the middle of the screen, like Spotlight.

It doesn't hold the themes or the font themselves, your keyboard layout, your shortcuts, or your screen settings.

## Before you apply it

1. 🟡 Install WhiteSur's theme, icons, and cursors, and the Inter font.  The profile uses the **dark** variants.  (See [extras.md](../docs/extras.md#whitesur-a-mac-like-look).)
2. 🟡 Install Konsave:  `sudo apt install pipx`, then `pipx install konsave`
3. 🟢 Save your current desktop, so you have a way back:  `konsave -s my-layout-before`

## Apply it

🟡 **Reversible.**  Replaces your panels, and the settings files listed above.

1. 🟢 Download `mac-feel.knsv` from this folder.
2. 🟢 Take a Timeshift snapshot.
3. 🟡 Import it:  `konsave -i mac-feel.knsv`
4. 🟡 Apply it:  `konsave -a mac-feel`
5. 🟡 Apply WhiteSur's dark colours:  `plasma-apply-colorscheme WhiteSurDark`
6. 🟢 Log out and back in.

If the GPU reading in the top bar is blank, your machine numbers its graphics chip differently.  Right-click the readout, choose **Configure System Monitor Sensor…**, and pick the GPU temperature again.

To undo:  `konsave -a my-layout-before`, then choose your old colours in **System Settings**, and log out and back in.

## Changing the profile

To update or rebuild `mac-feel.knsv`, see [CONTRIBUTING.md](../CONTRIBUTING.md#updating-the-plasma-profile).  A plain Konsave export picks up personal details, so the profile is built by hand.
