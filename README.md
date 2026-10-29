# Angeling Pet

A floating macOS desktop pet. Angeling, a little pink angel from Ragnarok Online, sits in a corner of your screen and:

- **reminds you** of things at the time you set (with the Ragnarok level-up sound) and puts them in your Calendar;
- **shows your LINE unread count** and the latest message;
- **reports your [Claude Code](https://claude.com/claude-code) sessions**, in the spirit of the Codex desktop pet: what each one is doing, which ones need you, and which ones have finished. Click to jump to a session.

Claude Code is optional: reminders and LINE work without it.

> เพ็ตลอยบนเดสก์ท็อป macOS: ตั้งเตือนพร้อมบันทึกลงปฏิทิน, บอกข้อความ LINE ที่ยังไม่อ่าน และรายงานงานของ Claude Code (ไม่มี Claude ก็ใช้ได้)

## Quick start

Paste this into **Terminal**:

```bash
curl -fsSL https://raw.githubusercontent.com/mobbenxd/angeling-pet/main/get.sh | bash
```

That's it. You need macOS 13 or later; no Xcode, git or Homebrew is needed. The installer downloads the ready-built app with Angeling's artwork and sounds. It sets Angeling to start at login and launches it in the bottom-right corner.

- **⌥⌘R** set a reminder · **⌥⌘A** show or hide Angeling · right-click Angeling for the menu
- Using Claude Code? Give it a task and watch the bubble.

> **ติดตั้งแบบเร็ว (ภาษาไทย):** เปิดแอป Terminal วางคำสั่งข้างบนแล้วกด Enter เสร็จแล้ว ไม่ต้องลงอะไรเพิ่ม (ต้องเป็น macOS 13 ขึ้นไป) คู่มือฉบับเต็มอยู่ที่ **[คู่มือ (docs/)](docs/README.md)**

## Documentation

The full guide (in Thai) is in **[docs/](docs/README.md)**.

| Getting started | Using Angeling | Maintenance and development |
|---|---|---|
| [Requirements](docs/Requirements.md) | [Usage: clicks, menus, hotkey](docs/Usage.md) | [Troubleshooting](docs/Troubleshooting.md) |
| [Installation](docs/Installation.md) | [Activity bubble and statuses](docs/Activity-Bubble.md) | [Updating and uninstalling](docs/Updating-and-Uninstalling.md) |
| [First run](docs/First-Run.md) | [Reminders](docs/Reminders.md) | [How it works](docs/How-It-Works.md) |
| | [LINE notifications](docs/LINE-Notifications.md) | [Development](docs/Development.md) |
| | [Emotes and animations](docs/Emotes-and-Animations.md) | |
| | [Use a different pet](docs/Custom-Pet.md) | |

## Features

- **Activity bubble**: one row per session, showing its status (กำลังทำ / รอคุณ / ติดปัญหา / เสร็จแล้ว), what it is doing right now, the prompt, and the task-list progress.
- **Finished tasks**: shown in green until you open or dismiss them, or for 30 minutes.
- **Click to jump**:
  - Click a row to open that session.
  - Click Angeling to open the latest active session.
  - Works for the Claude desktop app (via deep link), Terminal and iTerm2 (selects the right tab), and VS Code, Cursor and Windsurf (focuses the window for that folder).
- **Hide**:
  - Hover Angeling to reveal a button that hides or shows the bubble. A red badge shows the number of active sessions while it is hidden.
  - Hide Angeling itself with ⌥⌘A or from the menu bar icon.
  - Optionally pops back out when a session needs you.
- **Choose what the bubble shows**: right-click a row, Angeling, or the menu bar icon to turn the prompt, the latest message and the task list on or off.
- **Reminders**: press ⌥⌘R, type what to do and pick a date and time. Angeling adds a 30-minute event to your Calendar, then at that time pops out (even when hidden), plays the Ragnarok level-up sound and keeps an orange alert row until you click it or snooze it. Moving or deleting the event in Calendar moves or cancels the reminder. Adding it to Calendar needs Calendar access. See [Reminders](docs/Reminders.md).
- **LINE notifications**: a green LINE row at the top of the bubble shows the total number of unread LINE messages and the latest message (sender, chat and time). Click it to open LINE. Right-click it to hide it until the next new message. While the bubble is hidden, a green badge on Angeling shows the unread total. Turn it off with **แจ้งเตือน LINE** in the menu.
  - The unread total comes from LINE's Dock badge and needs no permission, but LINE must be running.
  - The latest message is read from the macOS Notification Center database, which needs **Full Disk Access** for `~/Applications/Angeling.app` (System Settings → Privacy & Security → Full Disk Access). Without it, the row shows only the count. LINE notifications must be turned on, and message previews must be on to see the text.
  - Angeling is ad-hoc signed, so you must grant Full Disk Access again after each rebuild or reinstall.
- **Animations**: idle, running, reading, waiting, failed and waving, from the Codex pet sprite format. Drag Angeling and it runs along.
- **Ragnarok emotes** (`/heh` `/lv` `/wah` `/omg` `/swt` `/slur`):

  | Emote | When |
  |---|---|
  | `/heh` | A session gets a new task |
  | `/lv` | A task finishes |
  | `/wah` | A session needs your input (stays until you answer) |
  | `/omg` | A tool fails |
  | `/swt` | A session has been working for more than 5 minutes |
  | `/slur` | Nothing to do for 10 minutes |

## Requirements

| Need | For | Notes |
|---|---|---|
| macOS 13 or later | everything | Apple silicon or Intel |
| [Claude Code](https://claude.com/claude-code) | session reports (optional) | Install it before Angeling, or run the installer again afterwards |
| `jq` | session reports (optional) | Built into macOS 15+. On macOS 13–14: `brew install jq` |
| LINE for Mac | LINE row (optional) | Full Disk Access shows the message text; see [LINE notifications](docs/LINE-Notifications.md) |
| Xcode Command Line Tools | building from source only | `xcode-select --install` |

## Install

The installer does the following. It is safe to run again.

1. Installs `~/Applications/Angeling.app`: the prebuilt universal app from the release, or a local build when run from a git clone.
2. Copies the artwork, sounds and hook to `~/.claude/angeling-pet/`.
3. If Claude Code is installed, adds the hook to `~/.claude/settings.json`, keeping your other hooks. It saves a backup to `settings.json.angeling-backup` first.
4. Sets Angeling to start at login. Pass `--no-login` to skip this (`… | bash -s -- --no-login`).

### From source

```bash
git clone https://github.com/mobbenxd/angeling-pet.git ~/apps/angeling-pet
cd ~/apps/angeling-pet
./install.sh
```

This builds the app with `swiftc` and takes the artwork from the latest release. If you have the Codex `angeling` pet, it uses that instead; `ANGELING_CODEX_PET=<name>` picks another Codex pet. If something goes wrong, see [Troubleshooting](docs/Troubleshooting.md).

## Update

Run the Quick start command again. From a git clone, use `git pull && ./install.sh`.

## Uninstall

```bash
~/.claude/angeling-pet/uninstall.sh           # remove app, login item and hooks
~/.claude/angeling-pet/uninstall.sh --purge   # also delete ~/.claude/angeling-pet, reminders and preferences
```

## How it works

```
Claude Code hooks ──► hooks/angeling-hook.sh ──► ~/.claude/angeling-pet/state/<session>.json
                                                              │  (polled every 0.5 s)
                                                              ▼
                                                   Angeling.app (src/main.swift)
```

- **The hook** runs for `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `Notification`, `PermissionRequest`, `Stop`, `StopFailure`, `SubagentStop` and `SessionEnd`. It writes one small JSON file per session, recording:
  - the state, the current activity and the prompt;
  - the task list, read from the Claude desktop task list tool;
  - where the session lives (desktop session id, terminal app, tty, or iTerm session id).
  
  Writes are locked per session, so parallel tool calls can't corrupt a file. It takes about 50–80 ms per event.
- **Reminders** are stored in `~/.claude/angeling-pet/reminders.json` and linked to their Calendar events through EventKit.
- **LINE** is polled every 3 s, read-only: the Dock badge comes from `lsappinfo`, and the newest `jp.naver.line.mac` record comes from `~/Library/Group Containers/group.com.apple.usernoted/db2/db`.
- **The app** is a single-file AppKit program. It uses no network, has no dependencies, and runs as an accessory app, so it has no Dock icon.

## Artwork

Ragnarok Online, Angeling, the emotes and the level-up sound are © Gravity Co., Ltd. They are **not** covered by the MIT license and are not in the git history. They are published as assets of each [GitHub Release](https://github.com/mobbenxd/angeling-pet/releases) so that installs work out of the box, and they will be removed if the rights holder asks.

`scripts/fetch-assets.sh` fills `assets/` from, in order:

- **Sprite sheet**: your Codex pet `~/.codex/pets/${ANGELING_CODEX_PET:-angeling}`, if present; otherwise the release. You can also drop any Codex v2 sheet at `assets/spritesheet.webp`. See [Use a different pet](docs/Custom-Pet.md).
- **Emotes**: the release; otherwise the [iRO Wiki emote list](https://irowiki.org/wiki/Emotes).
- **Reminder chime**: the release; otherwise [MyInstants](https://www.myinstants.com/en/instant/level-up-ragnarok/). If neither works, reminders use a macOS sound.

## Development

```bash
./scripts/build.sh                        # rebuild ~/Applications/Angeling.app
pkill -x Angeling; open ~/Applications/Angeling.app
cp hooks/angeling-hook.sh ~/.claude/angeling-pet/hook.sh   # after editing the hook
./scripts/package.sh 1.2.3                # release files into dist/
```

Snapshot testing, the debug environment variables, hook tests and the release steps are covered in the [Development](docs/Development.md) guide.

## Contributing

`main` is protected, so all changes go through pull requests. Fork the repository or create a branch, then open a PR. Documentation lives in `docs/` and changes the same way.

## License

The code is released under the [MIT](LICENSE) license. The artwork is not covered by it; see [Artwork](#artwork).
