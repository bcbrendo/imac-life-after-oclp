# Contributing

Thank you for helping.  This guide is for people who aren't very technical, or are cautious, and who may be about to erase a drive.  Accuracy matters more than coverage, so every change is checked before it's merged.

## Ways to help

- **Report your hardware.**  Especially the Late 2015 iMac (iMac17,1), which is untested.  Use the **Hardware report** issue form.
- **Report a wrong step.**  A label that doesn't match the screen, a command that fails, a missing warning.  Use the **Something in the guide is wrong** form.
- **Report a script problem.**  Use the **Script problem** form.  For anything that could harm someone's system, follow [SECURITY.md](SECURITY.md) instead.
- **Suggest a change.**  Open a pull request.  For anything bigger than a small fix, open an issue first, so we can agree on the approach.

## Writing the guide

- **Mark every step:**  🟢 safe (changes nothing), 🟡 reversible (say how to undo it), 🔴 can't be undone.  A 🔴 warning always comes *before* its step, never after.
- **One action per step,** in the imperative:  "Click **Install**", not "You should now click Install".  Put the condition first:  "If the screen is blank, restart."
- **Quote on-screen labels exactly,** in bold, as they appear on screen.
- **Explain every command** that uses `sudo`, writes a system file, or erases anything.  Never pipe a download straight into a shell.
- **Voice:**  Australian English (except quoted labels), two spaces after full stops, em dashes without spaces, the Oxford comma, and numbers under 13 written as words.
- **Link, don't bundle.**  Third-party projects are linked to their own instructions, not copied in.
- **Say what you tested on,** and mark anything you couldn't test as untested.

## Changing the scripts

Every script that changes something keeps the same promises:

1. It checks it's on the right hardware before doing anything.
2. It explains what it will do, then asks.  Pressing Enter always means "no", and prompts read from the keyboard.  There's no "yes to everything" option.
3. It offers a Timeshift snapshot first.
4. It shows each command as it runs it.
5. `--dry-run` prints the commands without running them.
6. `--undo` reverses only what that script recorded doing.  Anything set up by hand is left alone.

Before opening a pull request:

- Run `shellcheck -x -s bash *.sh lib/common.sh` from `scripts/`.  It must be clean.
- Run your changed script with `--help` and `--dry-run`.
- If you ran it for real, say on which model, and take a Timeshift snapshot first.

## Privacy

Nothing in this repository may identify a person, a machine, or an employer:  no names, usernames, email addresses, hostnames, IP or MAC addresses, serial numbers, disk IDs, or paths under a real home folder.  Use placeholders such as `/home/you` and `192.168.200.1`.  The checks on every pull request look for these, including inside the `.knsv` archive.

## Updating the Plasma profile

A full `konsave -e` export also holds personal files:  recent paths, device names, disk IDs, and the theme files themselves.  So this profile is built by hand from a saved profile:

1. `konsave -s mac-feel`
2. Copy only these eight files from `~/.config/konsave/profiles/mac-feel/configs/` into a fresh profile:  `kdeglobals`, `kwinrc`, `plasmarc`, `krunnerrc`, `kcminputrc`, `klipperrc`, `plasma-org.kde.plasma.desktop-appletsrc`, and `plasmashellrc`.  Then remove anything personal or machine-specific:
    - `kdeglobals`:  the file dialog history, every `[Colors:…]` and `[ColorEffects:…]` group, the colour keys in `[WM]`, and the `ColorScheme` and `ColorSchemeHash` lines.  The colours belong to the theme, so readers apply them from WhiteSur.  If the scheme name stays, `plasma-apply-colorscheme` thinks it's already applied, and does nothing.
    - `kwinrc`:  everything except the effects, plugins, Wayland, title bar, and window switcher groups.
    - `plasmarc`:  everything except the theme.
    - `kcminputrc`:  everything except the cursor theme.
    - `krunnerrc`:  any search plugins you added yourself, from the favourites list.
    - Panels:  replace any disk ID in the readout with `disk/all/usedPercent`.  Delete the desktop's containment (the one with `plugin=org.kde.plasma.folder`) and the `[ScreenMapping]` group.  They hold an activity ID, the screen's size, and the names of icons on the desktop.
    - `plasmashellrc`:  keep only the `[PlasmaViews][Panel …]` groups.  They hold each panel's height, and the dock's floating, fit-to-content, and hide settings.  Without them the dock comes back as a plain full-width panel.
3. Export it from a throwaway home folder, so nothing else gets in.  Then import it into a second throwaway home folder, and check the files match.
4. Search the files for your name, username, paths under your home folder, hostnames, and network addresses before committing.

## Licence

By contributing, you agree your contribution is licensed the same way as the file you change:  the MIT licence for `scripts/` and `.github/`, and Creative Commons Attribution 4.0 for everything else.  (See the [README](README.md#licence).)

Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).
