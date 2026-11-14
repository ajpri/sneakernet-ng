# sneakernet-ng

sneakernet-ng mirrors local folders to a USB drive with rsync when the drive
mounts. The `sneakernet` command sets up and runs the Linux user service.
Each drive stores its folder configuration in a `.sneakernet` file at its root.

## Install

Run this as your desktop user:

```bash
curl -fsSL https://raw.githubusercontent.com/ajpri/sneakernet-ng/main/installLinux.sh | bash
```

From a checkout, you can also run the installer directly:

```sh
./installLinux.sh
```

SneakerNet needs a systemd user session, Python 3.11 or later, rsync, and
`lsblk` from util-linux. Desktop notifications use `notify-send`. Fedora is
the primary target. Debian 12 or later and Ubuntu 24.04 LTS or later provide
the required Python version.

The installer uses the adjacent `sneakernet` file when available and otherwise
downloads it from GitHub with curl. It puts the CLI in `~/.local/bin`, installs
a user service, and starts it. If system packages are missing, it shows the
package-manager command and asks before running it with `sudo`. The running
service uses your ordinary account and its access to the source and the USB
mount. If your shell cannot find `sneakernet`, run `~/.local/bin/sneakernet`.

## First sync

1. Open your USB drive in the file manager to mount it.
2. Run setup, choose the drive, and enter the absolute path to the folder
   you want to mirror. Press Enter at the destination and file type prompts
   to mirror all file types to the drive root.

   ```sh
   sneakernet setup
   sneakernet scan
   ```

Setup writes a `.sneakernet` file at the root of the drive. The service picks
up newly configured drives automatically. It attempts each matching mount once
and sends an in-progress notification before copying. After the write flush
and a successful sync, use your desktop's normal **Eject** action. If the
desktop cannot show a notification, the outcome is recorded in the user
journal.

**The mirror removes destination files that are absent from the source.**
An empty source directory removes every matching file in the destination.
A missing source or too little free space prevents copying or deletion. The
space check allows room for replacement files before deleting stale files.

## Configuration

Edit `.sneakernet` at the root of the USB drive. Each folder has a table
under its computer's hostname. Use `hostname` to get the exact name. A
computer without a matching entry skips the drive.

```toml
[workstation]
source = "/path/to/source"
destination = "Backups/Projects"
file_types = "all"
```

The source must start with `/`. Relative paths and `~` are invalid. The
destination is relative to the drive root. Use `destination = "."` to mirror
directly into the root. Set `exclude` to a list of top-level filenames or
directories to preserve in that destination. SneakerNet always preserves
its `.sneakernet` file.

```toml
[workstation]
source = "/path/to/boot-images"
destination = "."
file_types = ["iso", "img"]
exclude = ["Keep"]
```

Use `file_types` to select extensions recursively. Matching ignores case,
and a leading dot is optional. Compound extensions such as `tar.gz` work
too. Only matching regular files are copied or removed in a filtered mirror.
Use `file_types = "*"` or `file_types = "all"` for a full folder mirror.
Omitting the setting also mirrors all types by default.

For multiple folders on one computer, use a `[[workstation]]` block for each
folder. Each folder needs a separate, non-overlapping destination. Quote
hostnames that contain dots, as in `["workstation.example"]`.

Symlink targets and Unix ownership and mode metadata are
skipped. Use trusted drives, since the drive configuration selects which
local paths SneakerNet copies with your account's permissions.

For scripts, pass setup arguments directly. Use `--file-types iso img` to
select extensions and `--exclude Keep` to preserve a top-level entry.

```sh
sneakernet setup "/path/to/mounted-drive" "/path/to/source" "Backups/Projects"
```

## Everyday operation

| Command | Action |
| --- | --- |
| `sneakernet scan` | Scan and sync matching mounted drives, including ones already handled on this mount. |
| `sneakernet --version` | Print the installed version. |
| `systemctl --user status sneakernet.service` | Check the watcher. |
| `journalctl --user -u sneakernet.service -n 50` | Read recent service logs. |

If you see a failure notification, correct the reported issue and run
`sneakernet scan` to retry. Automatic and manual runs share a lock.

## Update or uninstall

Run `./installLinux.sh` or `./sneakernet install` from the new source
checkout, or rerun the one-line installer above to update. Drive configurations
carry over.

Run `sneakernet uninstall` or `./installLinux.sh --uninstall` to stop the
service and remove the CLI and service unit. The configuration
and mirrored files remain on the drive. Remove the marker separately if you
want the drive to stop opting into future installations.

See [CHANGELOG.md](CHANGELOG.md) for release notes.

## License

sneakernet-ng is licensed under the [GNU General Public License, version 3 only](LICENSE)
(`GPL-3.0-only`).
