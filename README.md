# claude-plugins

> A small marketplace of [Claude Code](https://claude.ai/code) plugins by StanMarek.

This repo is a Claude Code **marketplace** — a single git repo that ships multiple plugins. Install the marketplace once, then pick the plugins you want.

---

## Quick Start

**Install the marketplace:**

```
/plugin marketplace add StanMarek/claude-plugins
```

**Install one or more plugins from it:**

```
/plugin install claude-faaah@claude-plugins
/plugin install pastel-statusline@claude-plugins
/plugin install hostile-cto@claude-plugins
```

---

## Plugins

| Plugin | What it does |
|---|---|
| [`claude-faaah`](plugins/claude-faaah) | Plays the iconic FAAAH sound effect on every prompt submit. |
| [`pastel-statusline`](plugins/pastel-statusline) | Three-line ANSI-colored statusline with identity, workspace, and resource info. |
| [`hostile-cto`](plugins/hostile-cto) | An output style that turns Claude into a foul-mouthed, battle-scarred CTO who teaches through trauma. |

---

### `claude-faaah` 🔊

Hooks into `UserPromptSubmit`. Plays a bundled `faaah.mp3` in the background using your platform's native audio player.

| Platform | Backend | Status |
|---|---|---|
| macOS | `afplay` | Supported |
| Linux | `paplay` / `aplay` | Supported |
| Windows | — | Not supported (use WSL) |

### `pastel-statusline` 🎨

A three-line statusline:

- **Line 1 (identity):** vim mode · model · output style · version · agent · session · date · time
- **Line 2 (workspace):** cwd · git branch + status · ahead/behind · stash · last commit · project type
- **Line 3 (resources):** context bar · 5h limit · 7d limit · cost · lines added/removed · CPU · memory · battery

Each field gets a unique 256-color ANSI code in soft pastels.

**Runtime requirements:** `bash`, `jq`, `git`. macOS-specific commands (`vm_stat`, `pmset`) gate the memory/battery fields — those silently no-op on Linux.

### `hostile-cto` 💀

An output style named "Hostile CTO". After installing, switch to it via `/output-style`. Claude becomes a battle-scarred, foul-mouthed CTO who responds with a Phase 1 (the rant) + Phase 2 (the lesson) structure for non-trivial work. Vulgar in language, immaculate in technical output.

> Heads up: not workplace-friendly. Use accordingly.

---

## Uninstall

```
/plugin uninstall <plugin-name>
/plugin marketplace remove claude-plugins
```

---

## Contributing

PRs welcome. Each plugin is self-contained — keep changes focused per plugin where possible. Branch protection is enabled on `main`; all changes go through a pull request.

1. Fork the repo
2. Create a feature branch
3. Submit a PR

---

## License

[MIT](LICENSE)
