# Claude Plugins Marketplace — Design Spec

**Date:** 2026-04-28
**Status:** Draft, pending user review
**Author:** StanMarek

## Goal

Convert this single-plugin repo (currently shipping only `claude-faaah`) into a Claude Code **plugin marketplace** that hosts three plugins:

1. `claude-faaah` — existing FAAAH sound-on-prompt-submit plugin (relocated, otherwise unchanged)
2. `pastel-statusline` — new plugin, packages the user's existing 435-line multi-line ANSI statusline script
3. `hostile-cto` — new plugin, packages the user's existing output style as a distributable artifact

The marketplace must be installable by anyone via `/plugin marketplace add StanMarek/claude-plugins`, and each plugin must be independently installable, enableable, and uninstallable.

## Non-goals

- No backwards-compatibility shim for the old `claude-faaah@StanMarek/claude-faaah-plugin` install URL. The repo is being renamed; anyone (currently just the author) using the old install path re-installs once. GitHub's automatic repo-rename redirect is sufficient.
- No user-facing config system for the statusline. Every field is hardcoded on. The existing `statusline-config.txt` flag system is dropped.
- No automated tests. The plugins are small, single-purpose, and platform-tested manually.
- No CI/CD pipeline changes beyond what the existing repo already has.

## Repo layout

The repo is renamed from `claude-faaah-plugin` to `claude-plugins`. All existing root-level plugin assets move into `plugins/claude-faaah/`.

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── claude-faaah/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── hooks/
│   │   │   └── hooks.json
│   │   ├── scripts/
│   │   │   └── play-sound.sh
│   │   └── assets/
│   │       └── faaah.mp3
│   ├── pastel-statusline/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   └── scripts/
│   │       └── statusline.sh
│   └── hostile-cto/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── output-styles/
│           └── hostile-cto.md
├── docs/
│   └── superpowers/
│       └── specs/
│           └── 2026-04-28-claude-plugins-marketplace-design.md   ← this file
├── LICENSE
└── README.md
```

`git mv` is used for the FAAAH relocation so commit history is preserved.

## Marketplace manifest

`/.claude-plugin/marketplace.json`:

```json
{
  "name": "claude-plugins",
  "owner": {
    "name": "StanMarek",
    "url": "https://github.com/StanMarek"
  },
  "plugins": [
    {
      "name": "claude-faaah",
      "source": "./plugins/claude-faaah",
      "description": "Plays the iconic FAAAH sound on every prompt submit."
    },
    {
      "name": "pastel-statusline",
      "source": "./plugins/pastel-statusline",
      "description": "Three-line pastel-colored statusline showing identity, workspace, and resource info."
    },
    {
      "name": "hostile-cto",
      "source": "./plugins/hostile-cto",
      "description": "Output style: a profanity-laden CTO who teaches through trauma."
    }
  ]
}
```

## Per-plugin specifications

### `plugins/claude-faaah/`

**Behavior:** Unchanged from the existing plugin. Plays `assets/faaah.mp3` on `UserPromptSubmit` via the bundled `scripts/play-sound.sh`.

**`plugin.json`:**

```json
{
  "name": "claude-faaah",
  "version": "1.0.0",
  "description": "Plays the iconic FAAAH sound effect every time you submit a prompt in Claude Code",
  "author": { "name": "StanMarek", "url": "https://github.com/StanMarek" },
  "repository": "https://github.com/StanMarek/claude-plugins",
  "license": "MIT",
  "keywords": ["sound", "notification", "fun", "faaah", "prompt"],
  "hooks": "./hooks/hooks.json"
}
```

The only change vs. the existing manifest is the `repository` URL (`claude-faaah-plugin` → `claude-plugins`).

`hooks/hooks.json` is unchanged. `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin directory regardless of where the plugin lives, so the existing hook command (`bash ${CLAUDE_PLUGIN_ROOT}/scripts/play-sound.sh`) continues to work post-move.

`scripts/play-sound.sh` and `assets/faaah.mp3` are unchanged.

### `plugins/pastel-statusline/`

**Behavior:** Renders a 3-line statusline (identity / workspace / resources) with per-field 256-color ANSI styling.

**`plugin.json`:**

```json
{
  "name": "pastel-statusline",
  "version": "1.0.0",
  "description": "Three-line pastel-colored statusline showing model, agent, session, git, usage, cost, CPU, memory, and battery",
  "author": { "name": "StanMarek", "url": "https://github.com/StanMarek" },
  "repository": "https://github.com/StanMarek/claude-plugins",
  "license": "MIT",
  "keywords": ["statusline", "ui", "ansi", "git", "usage"],
  "statusLine": {
    "type": "command",
    "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh"
  }
}
```

**`scripts/statusline.sh`:**

Derived from `~/.claude/statusline-command.sh` with the following modifications:

1. Remove the `source ~/.claude/statusline-config.txt` (or equivalent file-loading) line.
2. Remove every guard of the form `[ "$SHOW_X" = "1" ] && …` — the rendering is unconditional.
3. Remove any references to the dropped `SHOW_DIRECTORY`, `SHOW_BRANCH`, `SHOW_USAGE`, `SHOW_PROGRESS_BAR`, `SHOW_RESET_TIME` variables.
4. Leave all field rendering, color codes, and layout logic untouched.

Runtime dependencies (already required by the original script): `bash`, `jq`, `git`. macOS battery support uses `pmset`. Linux uses `/sys/class/power_supply/`. No new dependencies introduced by this restructure.

The `.bak` files (`statusline-command.sh.bak`, `statusline-command.singleline.bak`, `statusline-command copy.sh`) and `statusline-config.txt` from `~/.claude/` are **not** copied into the plugin.

### `plugins/hostile-cto/`

**Behavior:** Provides an output style named "Hostile CTO". When the plugin is enabled, the style appears in `/output-style` for selection.

**`plugin.json`:**

```json
{
  "name": "hostile-cto",
  "version": "1.0.0",
  "description": "Output style: a foul-mouthed, battle-scarred CTO who teaches through trauma. Vulgar but technically immaculate.",
  "author": { "name": "StanMarek", "url": "https://github.com/StanMarek" },
  "repository": "https://github.com/StanMarek/claude-plugins",
  "license": "MIT",
  "keywords": ["output-style", "personality", "review", "fun"]
}
```

**`output-styles/hostile-cto.md`:** Verbatim copy of `~/.claude/output-styles/hostile-cto.md`. The frontmatter (`name: Hostile CTO`, `description: …`, `keep-coding-instructions: true`) is preserved unchanged.

No `output-styles` field in `plugin.json` — Claude Code auto-discovers the `output-styles/` directory inside an enabled plugin.

## README

The top-level `README.md` is rewritten from a single-plugin pitch into a marketplace landing page:

- Heading: "claude-plugins — a small marketplace of Claude Code plugins"
- One-paragraph intro describing the marketplace concept.
- Install snippet:
  ```
  /plugin marketplace add StanMarek/claude-plugins
  /plugin install <plugin-name>@claude-plugins
  ```
- A table listing the three plugins (name, description, install command).
- A short section per plugin (≤5 lines each) describing behavior. The platform-support table from the existing FAAAH README is condensed into the FAAAH section.
- License section pointing to `LICENSE`.
- Contributing section: same spirit as the current README — PRs welcome, branch-protected, keep changes focused per plugin.

## Migration steps (high-level, not the full plan)

In-repo work (lands in a PR):

1. Create `plugins/claude-faaah/` and `git mv` existing `.claude-plugin/`, `hooks/`, `scripts/`, `assets/` into it.
2. Update `plugins/claude-faaah/.claude-plugin/plugin.json`'s `repository` field to `https://github.com/StanMarek/claude-plugins`.
3. Create `plugins/pastel-statusline/` with `.claude-plugin/plugin.json` and config-stripped `scripts/statusline.sh`.
4. Create `plugins/hostile-cto/` with `.claude-plugin/plugin.json` and verbatim `output-styles/hostile-cto.md`.
5. Create `.claude-plugin/marketplace.json` at the repo root.
6. Rewrite `README.md` for the marketplace.

User-side actions (out of scope for the implementation PR, performed by the user):

- Rename the GitHub repo `claude-faaah-plugin` → `claude-plugins` via GitHub UI.
- Optionally rename the local working directory and update the git remote URL with `git remote set-url origin git@github.com:StanMarek/claude-plugins.git`. GitHub's auto-redirect keeps the old URL working in the meantime.

The detailed, ordered, testable implementation plan is produced in a follow-up step using the `superpowers:writing-plans` skill.

## Risks / open questions

- **Repo rename invalidates existing install URL.** Mitigation: GitHub auto-redirects the renamed repo path for HTTP, and the user has confirmed they're OK with this break.
- **Statusline script depends on `jq`.** Existing requirement, not introduced here, but worth surfacing in the README so users don't get a silently broken statusline.
- **Output style auto-discovery.** Claude Code's documented behavior is to auto-load `output-styles/*.md` from an enabled plugin. If that contract changes upstream, the `hostile-cto` plugin breaks. No mitigation in scope.

## Success criteria

After implementation:

- `/plugin marketplace add StanMarek/claude-plugins` succeeds and registers the marketplace.
- `/plugin install claude-faaah@claude-plugins` installs and the FAAAH sound plays on `UserPromptSubmit`.
- `/plugin install pastel-statusline@claude-plugins` installs and the 3-line pastel statusline renders.
- `/plugin install hostile-cto@claude-plugins` installs and "Hostile CTO" is selectable via `/output-style`.
- Each plugin can be independently disabled/uninstalled without affecting the others.
- Git history for the FAAAH plugin's relocated files is preserved (`git log --follow` works).
