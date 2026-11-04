# Optional Extras

None of these are part of the core guide.  Each one is maintained by other people, so this page links to them rather than copying them.  Read each project's own instructions before installing, because they change.

Take a Timeshift snapshot before each extra.

## Native 5K

🔴 **Can't be undone in place.**  It means replacing Kubuntu with Fedora.

[BR1UHNz/retina-5k-imac-linux](https://github.com/BR1UHNz/retina-5k-imac-linux) runs the panel at its full 5120×2880 on iMac15,1.  It patches Linux's AMD graphics driver to wake the panel's second half, and rebuilds the patch after every kernel update.  (See [hardware-notes.md](hardware-notes.md#the-display-why-4k-not-5k) for the bug it works around.)

Before you consider it:

- It's confirmed on Fedora 44 with KDE Plasma on Wayland, not on Kubuntu.
- It modifies the kernel's graphics driver.  Read the repository's own documentation and risks first.
- The way back is reinstalling Kubuntu from this guide, so keep your files backed up.

4K at 150% is easily passable.  This extra is for people who want the last bit of sharpness and enjoy the tinkering.

## Toshy: Mac-style shortcuts

🟡 **Reversible.**  Toshy has its own uninstaller.

[Toshy](https://github.com/RedBearAK/toshy) makes ⌘C, ⌘V, ⌘Tab and hundreds of other Mac shortcuts work on Linux, app by app.

1. 🟢 Take a Timeshift snapshot.
2. 🟡 Follow the "How to Install" section of Toshy's README.  It downloads a zip and runs `./setup_toshy.py install`.

To undo:  run `./setup_toshy.py uninstall` from the same folder.

Toshy only sees keyboards plugged into the iMac.  If you also use Deskflow, see [deskflow.md](deskflow.md) for how the two interact.

### Keyboards in Mac mode that aren't Apple's

Toshy recognises Apple keyboards by name.  It treats any other keyboard as a Windows keyboard, even one switched to Mac mode with **Control**, **Option**, and **Command** along the bottom row.  ⌘ and Option then act swapped.

1. 🟡 Open Toshy's config file, `~/.config/toshy/toshy_config.py`, in a text editor.
2. 🟡 Find the section marked `kbtype_override`.
3. 🟡 Add a line with your keyboard's name, exactly as Linux reports it, followed by `'Apple'`.  For example:

   ```python
   'Example Brand K96 Keyboard': 'Apple',
   ```

   To find the name, run `toshy-devices` and look for **Device Name**.
4. 🟢 Restart Toshy:  `toshy-services-restart`

Edits between Toshy's `SLICE_MARK` lines survive Toshy updates.  Edits anywhere else are lost.

**Over Bluetooth, the name can change.**  Many keyboards report a different name over Bluetooth than over a cable, often with the pairing slot added, such as `Example K96-2 Keyboard`.  Run `toshy-devices` once for each way you connect, and add a line for every name.  If the keyboard has several Bluetooth slots, add a line for each slot's name too.

To pair a keyboard like this, switch it to Bluetooth mode, then hold its pairing key (often **Fn** with **1**, **2**, or **3**) for a few seconds, until its light flashes quickly.  Use a slot that isn't already paired with another computer.  Otherwise the keyboard reconnects to that computer and never shows up in **System Settings**, then **Bluetooth**.

To undo:  delete the lines and restart Toshy.

### Brightness keys on a keyboard in Mac mode

Many keyboards in Mac mode send **F14** and **F15** for brightness down and up.  That's what macOS expects.  Linux treats them as ordinary function keys, so nothing happens.  Toshy can turn them into real brightness keys.

1. 🟡 In `toshy_config.py`, find the section marked `keymapper_api`.  Change `dump_diagnostics_key(Key.F15)` to `dump_diagnostics_key(Key.F24)`.  Toshy reserves F15 for its own diagnostics, which swallows the brightness-up key.
2. 🟡 In the section marked `user_apps`, add:

   ```python
   keymap("User brightness keys", {
       C("F14"):                   Key.BRIGHTNESSDOWN,
       C("F15"):                   Key.BRIGHTNESSUP,
   }, when = lambda ctx:
       not ctx_app_is_remote
   )
   ```

3. 🟢 Restart Toshy:  `toshy-services-restart`

This rule deliberately leaves out Toshy's usual screen-focus check.  With the iMac as the Deskflow server, the brightness keys then also reach the Mac and change its brightness.

Toshy also reserves **F16** as an emergency key that releases every keyboard.  If your Mac-style shortcuts suddenly stop after you press a key on the top row, that key probably sends F16.  Run `toshy-services-restart` to get them back.

To undo:  remove the rule, set the diagnostics key back to `Key.F15`, and restart Toshy.

### The em dash and other Option characters

On a Mac, the Option key types extra characters:  **Option+Shift+-** an em dash (—), **Option+-** an en dash (–), **Option+8** a bullet (•), **Option+G** ©, **Option+2** ™, and many more.  On Linux they type nothing special.

1. 🟡 Open **System Settings**, then **Keyboard**.  Add the layout **English (Macintosh, ABC, ANSI)**, listed under English (US).  Remove your other layouts, and apply.
2. 🟢 Log out and back in.  The new layout only takes full effect after that.

That's all you need with a current version of Toshy.  The layout puts the Mac's characters on the *right* Option key, and Toshy's **Level3 via Left Alt** feature makes the left Option key type them too.  It's on by default.  You'll find it in Toshy's tray menu, under **Overlays**.

Option with the arrow keys and Delete keeps working as before, for moving and deleting by word.  One trade-off:  Linux apps that open menus with Alt plus a letter (Alt+F for **File**, for example) no longer respond to the left Option key.  Mac habits don't use those.

Toshy has a separate "Option-key special characters" setting.  Leave it off.  It types each character through a Ctrl+Shift+U code, which only works with an input method, such as IBus or Fcitx, running.  Kubuntu doesn't run one by default.

To undo:  switch back to your old layout in **System Settings**, then **Keyboard**, and log out and back in.

#### Keeping an Option shortcut as a shortcut

Some apps use Option plus a key as a shortcut, and the layout turns it into a character instead.  For example, **Option+/** opens the help menu in Google Docs, but the layout types ÷.  A rule that sends the key combination on unchanged takes priority over Toshy's built-in one.

1. 🟡 In `toshy_config.py`, in the section marked `user_apps`, add:

   ```python
   keymap("User Option shortcuts", {
       C("LAlt-Slash"):            C("LAlt-Slash"),                # Option+/ stays a shortcut, not ÷
   }, when = lambda ctx:
       cnfg.screen_has_focus and
       not ctx_app_is_remote
   )
   ```

2. 🟢 Restart Toshy:  `toshy-services-restart`

Add a line for each Option shortcut you want to keep.  To undo, remove the rule and restart Toshy.

### Lock the screen with Control+⌘+Q

Toshy has this shortcut for GNOME, but not for KDE.

1. 🟡 In `toshy_config.py`, in the section marked `user_apps`, add:

   ```python
   keymap("User lock screen", {
       C("Super-RC-Q"):            C("Super-L"),                   # In apps, Control arrives as Super
       C("LC-RC-Q"):               C("Super-L"),                   # In terminals, Control stays Control
   }, when = lambda ctx:
       cnfg.screen_has_focus and
       not ctx_app_is_remote
   )
   ```

2. 🟢 Restart Toshy:  `toshy-services-restart`

**Super+L** is KDE's own lock shortcut.  The two lines cover the two ways Toshy passes the Control key on.

To undo:  remove the rule and restart Toshy.

### Paste as plain text with ⌘⌥⇧V

On a Mac, **⌘⌥⇧V** pastes without formatting ("Paste and Match Style").  Web browsers and most chat apps on Linux do the same with Ctrl+Shift+V, so one rule brings the Mac shortcut across.

1. 🟡 In `toshy_config.py`, in the section marked `user_apps`, add:

   ```python
   keymap("User paste as plain text", {
       C("Shift-Alt-RC-v"):        C("Shift-C-v"),                 # Cmd+Opt+Shift+V: paste without formatting
   }, when = lambda ctx:
       cnfg.screen_has_focus and
       not ctx_app_is_remote
   )
   ```

2. 🟢 Restart Toshy:  `toshy-services-restart`

To undo:  remove the rule and restart Toshy.

### Google Docs, Sheets, and Slides

On Linux, Google's apps use their Windows-style shortcuts.  Toshy's ⌘-to-Ctrl swap covers most of them, but a few Mac shortcuts differ completely.  Strikethrough is one:  ⌘⇧X on a Mac, but Alt+Shift+5 on Linux.

This rule translates it, only in browser tabs whose title shows they're Google Docs, Sheets, or Slides:

1. 🟡 In `toshy_config.py`, in the section marked `user_apps`, add:

   ```python
   keymap("User Google Docs", {
       C("Shift-RC-x"):            C("Shift-Alt-5"),               # Cmd+Shift+X: strikethrough
   }, when = lambda ctx:
       cnfg.screen_has_focus and
       matchProps(clas=browsers_chromeStr, name="Google (Docs|Sheets|Slides)")(ctx)
   )
   ```

2. 🟢 Restart Toshy:  `toshy-services-restart`

`browsers_chromeStr` covers Chrome, Brave, Chromium, and similar browsers.  If you find another Mac shortcut that doesn't work in Google's apps, add a line for it in the same rule.  Google lists its shortcuts for each system in each app's **Help** menu.

To undo:  remove the rule and restart Toshy.

## WhiteSur: a Mac-like look

🟡 **Reversible.**  Switch back to the default Breeze theme in System Settings.

[WhiteSur-kde](https://github.com/vinceliuice/WhiteSur-kde) is a macOS-style theme for KDE Plasma.  Install it from its GitHub repository rather than KDE's built-in theme store, which can lag behind.

1. 🟢 Take a Timeshift snapshot.
2. 🟢 Save your current layout first.  (See [plasma/README.md](../plasma/README.md).)
3. 🟡 Follow WhiteSur-kde's own install instructions.  For the matching icons and cursors, install WhiteSur-icon-theme and WhiteSur-cursors the same way.
4. 🟡 Open **System Settings**, then **Colors & Themes**, then **Global Theme**.  Choose WhiteSur.
5. 🟡 When asked what to apply, tick **Appearance settings** only.  Leave **Desktop and window layout** unticked, or the theme replaces your panels with its own layout.

Run the cursors' install script from inside its own folder.  Started from anywhere else, it stops with `cannot stat 'dist'`.  If the cursors then don't appear in System Settings, link them where older tools also look:

```sh
mkdir -p ~/.icons && ln -s ~/.local/share/icons/WhiteSur-cursors ~/.icons/WhiteSur-cursors
```

For the font, use Inter (`sudo apt install fonts-inter`) rather than Apple's San Francisco, whose licence only covers Apple platforms.

To undo:  open **System Settings**, then **Colors & Themes**, then **Global Theme**, and choose **Breeze**.  Again, tick **Appearance settings** only, so your layout stays.

## A Mac-style layout, by hand

🟡 **Reversible.**  Every change is a setting you can change back.

You don't need a theme to get the Mac's shape.  In KDE Plasma:

1. 🟡 Move the panel to the top of the screen, and add the **Global Menu** widget.
2. 🟡 Add a second panel at the bottom, set to **Floating** and **Fit content**, as a dock.
3. 🟡 Move the window buttons to the left in **System Settings**, then **Window Decorations**.
4. 🟡 Set a screen corner to show **Overview**, in **System Settings**, then **Screen Edges**.
5. 🟡 Turn on the **Magic Lamp** effect for minimising windows, in **System Settings**, then **Desktop Effects**.  It replaces the default **Squash** effect, so turn that off.

On Wayland, KDE also pastes the last *selected* text when you click the middle mouse button (or press the scroll wheel).  macOS has nothing like it, and it's easy to trigger by accident.  To turn it off, open **System Settings**, search for "middle click", and switch off the paste option.

Plank, a popular Mac-style dock, doesn't work on Wayland.  The floating panel does the same job.

## Deskflow

🟡 **Reversible.**  Uninstall it on both machines.

Share one keyboard and mouse between the iMac and a Mac.  (See [deskflow.md](deskflow.md).)

## Thunderbolt link

🟡 **Reversible.**  `scripts/thunderbolt-e2e.sh --undo`.

A direct cable between the iMac and an Apple Silicon Mac.  (See [thunderbolt-e2e.md](thunderbolt-e2e.md).)
