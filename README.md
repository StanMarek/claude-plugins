# claude-faaah

> Every prompt deserves a battle cry.

A [Claude Code](https://claude.ai/code) plugin that plays the iconic **FAAAH** sound effect every time you submit a prompt. Zero config. Zero lag. Pure energy.

---

## Quick Start

**Inside Claude Code:**

```
/plugin install claude-faaah@StanMarek/claude-faaah-plugin
```

**Via CLI:**

```bash
claude plugin install claude-faaah@StanMarek/claude-faaah-plugin
```

That's it. Submit a prompt. Hear the sound. Feel alive.

---

## How It Works

The plugin hooks into Claude Code's `UserPromptSubmit` lifecycle event. When you press Enter, a lightweight background process plays the bundled sound file using your system's native audio player. No blocking, no delay, no dependencies to install.

```
You hit Enter → Hook fires → Sound plays in background → Claude responds normally
```

---

## Platform Support

| Platform | Audio Backend | Status |
|----------|--------------|--------|
| macOS    | `afplay`     | Supported |
| Linux    | `paplay` / `aplay` | Supported |
| Windows  | —            | Not supported (use WSL) |

---

## Customization

Want a different sound? Fork the repo and replace `assets/faaah.mp3` with any `.mp3` file. The filename must stay the same.

---

## Uninstall

```
/plugin uninstall claude-faaah
```

---

## Contributing

PRs welcome. Keep it simple — this plugin does one thing and does it well.

1. Fork the repo
2. Create a feature branch
3. Submit a PR

Branch protection is enabled — all changes require a pull request with review.

---

## License

[MIT](LICENSE)
