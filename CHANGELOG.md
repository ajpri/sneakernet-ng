# Changelog

## 26.11.14

- Start a per-user systemd service that watches mounted USB drives.
- Read per-host folder configurations from the drive's `.sneakernet` file.
  A single folder uses a hostname header such as `[workstation]`. Source
  directories use absolute paths.
- Mirror folders to user-selected destinations with rsync, including a
  mounted drive's root. Support explicit exclusions and recursive filtering
  by one or more file extensions, with an option to mirror all types.
- Check free space before copying and notify when syncing starts, completes,
  or fails. Completion notifications show how many files were transferred.
- Install, update, scan mounted drives on demand, and uninstall from the CLI.
  Set up a drive interactively or with command-line arguments.
- Install from a checkout or with the one-line GitHub download command.
