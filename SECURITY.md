# Security

The scripts in this repository run commands with `sudo`, so a bug in one could harm someone's system.

## Reporting a problem

If you find something that could damage a system, lose data, or expose someone's details, please report it privately first:

1. Open the repository's **Security** tab.
2. Click **Report a vulnerability**.

Please don't open a public issue for these.  You'll get a reply, and the fix is published before the details are.

For everything else, such as a step that's wrong or a script that fails safely, open an ordinary issue.

## What's in scope

- The scripts in `scripts/`, and the shared code in `scripts/lib/`.
- Any command in the guide that runs with `sudo`, writes a system file, or erases a drive.
- The GitHub Actions workflows in `.github/`.
