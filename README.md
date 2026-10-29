# Angeling Pet

A floating macOS desktop pet that reports what your [Claude Code](https://claude.com/claude-code) sessions are doing, in the spirit of the Codex desktop pet.

Angeling, a little pink angel from Ragnarok Online, floats in a corner of your screen. It keeps a list of your Claude Code sessions in a speech bubble: what each one is working on, which ones need your input, and which ones have finished. It also animates and pops Ragnarok emotes as things happen.

> เพ็ตลอยบนเดสก์ท็อป macOS ที่คอยรายงานสถานะงานของ Claude Code ทุก session (ทั้งแอป Claude desktop และ CLI) คลิกเพื่อไปที่ session นั้นได้ทันที

## Quick start

```bash
git clone https://github.com/mobbenxd/angeling-pet.git ~/apps/angeling-pet
cd ~/apps/angeling-pet
./install.sh
```

Angeling appears in the bottom-right corner. Give Claude Code any task and watch the bubble. Press ⌥⌘A to show or hide Angeling.

> **ติดตั้งแบบเร็ว (ภาษาไทย):** ต้องมี macOS 13+, `xcode-select --install`, `brew install jq` และเพ็ต Angeling ที่ติดตั้งใน Codex แล้ว จากนั้นรัน 3 บรรทัดข้างบน คู่มือฉบับเต็มอยู่ที่ **[Wiki](https://github.com/mobbenxd/angeling-pet/wiki)**

## Documentation

The full guide lives in the **[Wiki](https://github.com/mobbenxd/angeling-pet/wiki)** (in Thai). Its source is in [`docs/wiki/`](docs/wiki).

| Getting started | Using Angeling | Maintenance and development |
|---|---|---|
| [Requirements](https://github.com/mobbenxd/angeling-pet/wiki/Requirements) | [Usage: clicks, menus, hotkey](https://github.com/mobbenxd/angeling-pet/wiki/Usage) | [Troubleshooting](https://github.com/mobbenxd/angeling-pet/wiki/Troubleshooting) |
| [Installation](https://github.com/mobbenxd/angeling-pet/wiki/Installation) | [Activity bubble and statuses](https://github.com/mobbenxd/angeling-pet/wiki/Activity-Bubble) | [Updating and uninstalling](https://github.com/mobbenxd/angeling-pet/wiki/Updating-and-Uninstalling) |
| [First run](https://github.com/mobbenxd/angeling-pet/wiki/First-Run) | [LINE notifications](https://github.com/mobbenxd/angeling-pet/wiki/LINE-Notifications) | [How it works](https://github.com/mobbenxd/angeling-pet/wiki/How-It-Works) |
| | [Emotes and animations](https://github.com/mobbenxd/angeling-pet/wiki/Emotes-and-Animations) | [Development](https://github.com/mobbenxd/angeling-pet/wiki/Development) |
| | [Use a different pet](https://github.com/mobbenxd/angeling-pet/wiki/Custom-Pet) | |

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

| Need | Check | Install |
|---|---|---|
| macOS 13 or later | `sw_vers -productVersion` | |
| Xcode Command Line Tools | `swiftc --version` | `xcode-select --install` |
| jq | `jq --version` | `brew install jq` |
| Claude Code | `ls ~/.claude` | <https://claude.com/claude-code> |
| Angeling sprite sheet from Codex | `ls ~/.codex/pets/angeling/spritesheet.webp` | Install the Angeling pet in Codex, or see [Use a different pet](https://github.com/mobbenxd/angeling-pet/wiki/Custom-Pet) |

## Install

`install.sh` does the following. It is safe to run again.

1. Fetches the artwork into `assets/`.
2. Builds `~/Applications/Angeling.app`.
3. Copies the hook and artwork to `~/.claude/angeling-pet/`.
4. Adds the hook to `~/.claude/settings.json`, keeping your other hooks. It saves a backup to `settings.json.angeling-backup` first.
5. Sets Angeling to start at login. Pass `--no-login` to skip this.

New Claude Code events are picked up immediately, with no restart needed. If something goes wrong, see [Troubleshooting](https://github.com/mobbenxd/angeling-pet/wiki/Troubleshooting).

## Update

```bash
cd ~/apps/angeling-pet && git pull && ./install.sh
```

## Uninstall

```bash
./uninstall.sh           # remove app, login item and hooks
./uninstall.sh --purge   # also delete ~/.claude/angeling-pet and preferences
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
- **LINE** is polled every 3 s, read-only: the Dock badge comes from `lsappinfo`, and the newest `jp.naver.line.mac` record comes from `~/Library/Group Containers/group.com.apple.usernoted/db2/db`.
- **The app** is a single-file AppKit program. It uses no network, has no dependencies, and runs as an accessory app, so it has no Dock icon.

## Artwork

The artwork is **not** included in this repository. It belongs to its owners: Ragnarok Online and Angeling are © Gravity Co., Ltd., and the sprite sheet comes from your own Codex pet. `scripts/fetch-assets.sh` fetches a personal copy:

- **Sprite sheet**: copied from `~/.codex/pets/$ANGELING_CODEX_PET/spritesheet.webp` (default `angeling`). You can also drop any Codex v2 sheet at `assets/spritesheet.webp`: 1536×2288 pixels, 8 columns × 11 rows of 192×208 frames. The rows are idle, running-right, running-left, waving, jumping, failed, waiting, running, review, and two look-around rows.
- **Emotes**: downloaded from the [iRO Wiki emote list](https://irowiki.org/wiki/Emotes).

## Development

```bash
./scripts/build.sh                        # rebuild ~/Applications/Angeling.app
pkill -x Angeling; open ~/Applications/Angeling.app
cp hooks/angeling-hook.sh ~/.claude/angeling-pet/hook.sh   # after editing the hook
```

Snapshot testing, the debug environment variables and hook tests are covered on the [Development](https://github.com/mobbenxd/angeling-pet/wiki/Development) wiki page.

## Contributing

`main` is protected, so all changes go through pull requests. Fork the repository or create a branch, then open a PR. Documentation changes go in `docs/wiki/`, and maintainers publish them with `scripts/publish-wiki.sh` after merging.

## License

The code is released under the [MIT](LICENSE) license. The artwork is not covered by it; see [Artwork](#artwork).
