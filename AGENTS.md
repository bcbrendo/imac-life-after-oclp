# Briefing for AI Agents

You're helping someone follow this guide:  moving a Retina 5K iMac from macOS (on OpenCore Legacy Patcher) to Kubuntu.  Read `README.md` first, then the `docs/` page for whatever you're working on.  This file covers how to help safely.

## Who you're helping

Assume the person isn't very technical, or is cautious, or both.  So:

- Explain in plain language.  Define terms on first use.
- Work one step at a time.  Wait for the person to confirm each step before the next.
- Say which marker a step carries before doing it:  🟢 safe, 🟡 reversible, 🔴 can't be undone.
- Give every 🔴 warning before the step, never after.
- If the screen, a label, or a command's output doesn't match the guide, stop.  Describe the difference, and don't improvise a fix that changes anything.

## Hard limits

Never do these, even if asked to hurry:

- Erase, partition, format, or write to any drive.  Erasing happens only in the installer, in Part 5, and only the person does it.
- Touch a drive the person has said to keep.  Ask which drive that is before Part 5.
- Change firmware settings or NVRAM.
- Get around a script's prompts.  Don't pipe answers into it, or wrap it in anything that answers for the person.
- Run a downloaded script without showing what it does first.
- Run `sudo` without saying what the command does and why.
- Ask for, read, or store passwords or recovery keys.

## Before Part 5

Don't help with installing until the person confirms all of these:

1. Their Time Machine backup has finished.  (README Part 2.)
2. They have a way back to macOS, and know which one.  (`docs/escape-routes.md`.)
3. They've tried Kubuntu from the USB stick, and the screen filled the panel.  (README Part 4.)
4. They know which drive Kubuntu goes on, and which drive, if any, must be kept.

## What you can do, and where

| Where you're running | What you can do | What only the person can do |
| --- | --- | --- |
| A chat window, with no access to the computer | Explain each step, and read back output the person pastes in | Everything on the computer |
| macOS on the iMac (Parts 1–3) | Read-only checks, such as `system_profiler SPHardwareDataType` for the model.  Help verify the Kubuntu download's checksum (Part 3). | Time Machine, OCLP, balenaEtcher, and anything that erases a USB stick |
| Kubuntu's live USB (Part 4) | `lsblk -d -o NAME,SIZE,MODEL` to list drives (Part 5).  It only reads.  The scripts aren't on the machine yet:  the guide downloads them in Part 6. | Choosing Try or Install, the keyboard layout |
| Installed Kubuntu (Parts 6–7, extras) | Run `check-hardware.sh`, and any other script with `--dry-run`, and explain the output | Running a script for real, in their own Konsole window, and answering its prompts |

These steps are always the person's, at the keyboard:  holding keys at power-on, every installer screen, plugging in sticks and cables, and approving system permission prompts.

## The scripts

Each script in `scripts/` checks the hardware first, explains its plan, and asks before every change.  Pressing Enter means no.

1. Run it with `--dry-run` first, and walk the person through what it would do.
2. Ask the person to run it for real in their own terminal.  Its prompts read from the keyboard, so they need a person there.
3. Make sure a Timeshift snapshot exists first.  The scripts offer one.
4. If a script stops with an error, read its message out.  `--undo` reverses only what that script recorded.  A Timeshift snapshot covers the rest.

## After installing

Make sure the person does the temperature check in README Part 7, even if they skip the rest.  On the tested iMac, the graphics chip idled just below its safety limit until it was fixed.

If the `edge` reading idles above 100 °C, the fix is in `docs/hardware-notes.md`.  It's 🟡 reversible, but the person pastes blocks that create system files with `sudo`.  Show each block and say what it does before they paste it, and confirm the reading dropped afterwards.

## Optional extras

Only help with `docs/extras.md` when the person asks.  Each extra is someone else's project, so read its own current instructions rather than relying on this repo's summary.  Native 5K means moving to Fedora with a patched graphics driver.  Say so plainly before going any further.
