# Claude Plugins Marketplace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert this single-plugin repo (`claude-faaah-plugin`) into a Claude Code plugin marketplace named `claude-plugins` hosting three plugins: `claude-faaah` (relocated), `pastel-statusline` (new), `hostile-cto` (new).

**Architecture:** A marketplace is a git repo with `.claude-plugin/marketplace.json` at the root listing plugins. Each plugin lives in a `plugins/<name>/` subdirectory and has its own `.claude-plugin/plugin.json`. Plugin asset references inside hooks/statuslines use `${CLAUDE_PLUGIN_ROOT}` which Claude Code resolves to each plugin's own directory at runtime.

**Tech Stack:** JSON manifests, bash scripts, markdown output style. No build system, no tests beyond manual structural verification (`jq`, `bash -n`, file existence).

**Spec:** [`docs/superpowers/specs/2026-04-28-claude-plugins-marketplace-design.md`](../specs/2026-04-28-claude-plugins-marketplace-design.md)

**Working directory:** `/Users/stanislawmarek/claude-faaah-plugin` (will be conceptually renamed to `claude-plugins` post-implementation; the local directory rename is an out-of-scope user action).

**Reference example:** The OpenAI Codex marketplace at `~/.claude/plugins/marketplaces/openai-codex/.claude-plugin/marketplace.json` is the structural template (relative-path `source` strings, per-plugin `version` and `author`, top-level `metadata`).

---

## Pre-flight: branch state

Current branch is `main`, ahead by 1 commit (the design spec) and behind origin by 4 commits. Do NOT pull or rebase as part of this plan — that's a user decision. Implementation work happens on a fresh feature branch off the current local `main` HEAD so the spec commit travels with it.

---

## Task 1: Set up feature branch and commit pending spec correction

**Files:**
- Modify: `docs/superpowers/specs/2026-04-28-claude-plugins-marketplace-design.md` (already edited, uncommitted)

- [ ] **Step 1.1: Verify current branch state**

```bash
git status --short
git log --oneline -3
```

Expected: Working tree shows `M docs/superpowers/specs/2026-04-28-claude-plugins-marketplace-design.md` (the spec correction about the orphaned config file) and untracked `?? .DS_Store`. HEAD is `c45e65b Add design spec...`.

- [ ] **Step 1.2: Create feature branch**

```bash
git checkout -b feat/marketplace-restructure
```

Expected: `Switched to a new branch 'feat/marketplace-restructure'`.

- [ ] **Step 1.3: Commit the spec correction**

```bash
git add docs/superpowers/specs/2026-04-28-claude-plugins-marketplace-design.md
git commit -m "$(cat <<'EOF'
Correct spec: statusline source has no config logic to strip

Inspection of ~/.claude/statusline-command.sh shows it does not source
statusline-config.txt and contains no SHOW_X guards. The "hardcode all-on"
choice therefore reduces to a verbatim copy. Spec updated to reflect this.
EOF
)"
```

Expected: Commit succeeds.

---

## Task 2: Relocate the FAAAH plugin into `plugins/claude-faaah/`

**Files:**
- Move: `.claude-plugin/plugin.json` → `plugins/claude-faaah/.claude-plugin/plugin.json`
- Move: `hooks/hooks.json` → `plugins/claude-faaah/hooks/hooks.json`
- Move: `scripts/play-sound.sh` → `plugins/claude-faaah/scripts/play-sound.sh`
- Move: `assets/faaah.mp3` → `plugins/claude-faaah/assets/faaah.mp3`
- Modify (post-move): `plugins/claude-faaah/.claude-plugin/plugin.json` — update `repository` field

- [ ] **Step 2.1: Create the destination directory tree**

```bash
mkdir -p plugins/claude-faaah/.claude-plugin
mkdir -p plugins/claude-faaah/hooks
mkdir -p plugins/claude-faaah/scripts
mkdir -p plugins/claude-faaah/assets
```

Expected: Directories exist (no errors).

- [ ] **Step 2.2: Move tracked files with `git mv` to preserve history**

```bash
git mv .claude-plugin/plugin.json plugins/claude-faaah/.claude-plugin/plugin.json
git mv hooks/hooks.json plugins/claude-faaah/hooks/hooks.json
git mv scripts/play-sound.sh plugins/claude-faaah/scripts/play-sound.sh
git mv assets/faaah.mp3 plugins/claude-faaah/assets/faaah.mp3
```

Expected: All four `git mv` calls succeed silently.

- [ ] **Step 2.3: Remove now-empty top-level directories**

```bash
rmdir .claude-plugin hooks scripts assets
```

Expected: All four `rmdir` calls succeed silently. If any directory is non-empty, investigate before forcing.

- [ ] **Step 2.4: Verify file paths and history preservation**

```bash
ls -la plugins/claude-faaah/
ls plugins/claude-faaah/.claude-plugin/ plugins/claude-faaah/hooks/ plugins/claude-faaah/scripts/ plugins/claude-faaah/assets/
git log --follow --oneline plugins/claude-faaah/scripts/play-sound.sh
```

Expected: All four files visible at their new paths. `git log --follow` shows commits including `3a030b3 Initial release: FAAAH sound on prompt submit`.

- [ ] **Step 2.5: Update `repository` URL in the relocated `plugin.json`**

Edit `plugins/claude-faaah/.claude-plugin/plugin.json`. Replace this line:

```json
  "repository": "https://github.com/StanMarek/claude-faaah-plugin",
```

with:

```json
  "repository": "https://github.com/StanMarek/claude-plugins",
```

Final content of `plugins/claude-faaah/.claude-plugin/plugin.json`:

```json
{
  "name": "claude-faaah",
  "version": "1.0.0",
  "description": "Plays the iconic FAAAH sound effect every time you submit a prompt in Claude Code",
  "author": {
    "name": "StanMarek",
    "url": "https://github.com/StanMarek"
  },
  "repository": "https://github.com/StanMarek/claude-plugins",
  "license": "MIT",
  "keywords": ["sound", "notification", "fun", "faaah", "prompt"],
  "hooks": "./hooks/hooks.json"
}
```

- [ ] **Step 2.6: Validate the manifest is still valid JSON**

```bash
jq . plugins/claude-faaah/.claude-plugin/plugin.json > /dev/null && echo OK
```

Expected: `OK`.

- [ ] **Step 2.7: Validate the hook script still parses as bash**

```bash
bash -n plugins/claude-faaah/scripts/play-sound.sh && echo OK
```

Expected: `OK`.

- [ ] **Step 2.8: Commit the relocation**

```bash
git add plugins/claude-faaah/.claude-plugin/plugin.json
git status
git commit -m "$(cat <<'EOF'
Relocate claude-faaah plugin into plugins/ subdirectory

Marketplace structure requires each plugin to live in its own subdirectory.
Move .claude-plugin/, hooks/, scripts/, and assets/ from repo root into
plugins/claude-faaah/ via git mv to preserve history. Update repository URL
in plugin.json to point at the renamed claude-plugins repo.
EOF
)"
```

Expected: Commit succeeds. `git status` before commit should show one modified file (the manifest) plus the four `R` (rename) entries already staged by `git mv`.

---

## Task 3: Build the `pastel-statusline` plugin

**Files:**
- Create: `plugins/pastel-statusline/.claude-plugin/plugin.json`
- Create: `plugins/pastel-statusline/scripts/statusline.sh` (verbatim copy of `~/.claude/statusline-command.sh`)

- [ ] **Step 3.1: Create the directory tree**

```bash
mkdir -p plugins/pastel-statusline/.claude-plugin
mkdir -p plugins/pastel-statusline/scripts
```

Expected: Directories exist.

- [ ] **Step 3.2: Create `plugins/pastel-statusline/.claude-plugin/plugin.json`**

Write this exact content:

```json
{
  "name": "pastel-statusline",
  "version": "1.0.0",
  "description": "Three-line pastel-colored statusline showing model, agent, session, git, usage, cost, CPU, memory, and battery",
  "author": {
    "name": "StanMarek",
    "url": "https://github.com/StanMarek"
  },
  "repository": "https://github.com/StanMarek/claude-plugins",
  "license": "MIT",
  "keywords": ["statusline", "ui", "ansi", "git", "usage"],
  "statusLine": {
    "type": "command",
    "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh"
  }
}
```

- [ ] **Step 3.3: Copy the statusline script verbatim**

```bash
cp ~/.claude/statusline-command.sh plugins/pastel-statusline/scripts/statusline.sh
chmod +x plugins/pastel-statusline/scripts/statusline.sh
```

Expected: File copied. Note: the source script does NOT load `~/.claude/statusline-config.txt` and has no `SHOW_X` guards, so no transformation is needed (see spec).

- [ ] **Step 3.4: Sanity check — confirm the copied script has no orphan config refs**

```bash
grep -nE 'statusline-config\.txt|SHOW_DIRECTORY|SHOW_BRANCH|SHOW_USAGE|SHOW_PROGRESS_BAR|SHOW_RESET_TIME' plugins/pastel-statusline/scripts/statusline.sh && echo "FOUND - investigate" || echo "CLEAN"
```

Expected: `CLEAN`. If the grep finds matches, the source script has changed since this plan was written; STOP and re-read the spec's pastel-statusline section before proceeding.

- [ ] **Step 3.5: Validate JSON and bash syntax**

```bash
jq . plugins/pastel-statusline/.claude-plugin/plugin.json > /dev/null && echo "JSON OK"
bash -n plugins/pastel-statusline/scripts/statusline.sh && echo "BASH OK"
```

Expected: `JSON OK` and `BASH OK`.

- [ ] **Step 3.6: Smoke-test the script with a synthetic JSON payload**

```bash
printf '{"model":{"display_name":"Sonnet 4.6"},"version":"1.0","workspace":{"current_dir":"%s"},"context_window":{"used_percentage":42}}' "$PWD" \
  | bash plugins/pastel-statusline/scripts/statusline.sh
```

Expected: Three lines of ANSI-colored output containing `Sonnet 4.6`, `v1.0`, the current working directory, and a `ctx` bar at `58%` remaining. Exit status 0.

- [ ] **Step 3.7: Commit**

```bash
git add plugins/pastel-statusline/
git commit -m "$(cat <<'EOF'
Add pastel-statusline plugin

Three-line ANSI-colored statusline showing identity, workspace, and
resource info. Script is a verbatim copy of the user's existing
~/.claude/statusline-command.sh; no config-stripping needed because the
source script has no config loading.
EOF
)"
```

Expected: Commit succeeds.

---

## Task 4: Build the `hostile-cto` plugin

**Files:**
- Create: `plugins/hostile-cto/.claude-plugin/plugin.json`
- Create: `plugins/hostile-cto/output-styles/hostile-cto.md` (verbatim copy)

- [ ] **Step 4.1: Create the directory tree**

```bash
mkdir -p plugins/hostile-cto/.claude-plugin
mkdir -p plugins/hostile-cto/output-styles
```

Expected: Directories exist.

- [ ] **Step 4.2: Create `plugins/hostile-cto/.claude-plugin/plugin.json`**

Write this exact content:

```json
{
  "name": "hostile-cto",
  "version": "1.0.0",
  "description": "Output style: a foul-mouthed, battle-scarred CTO who teaches through trauma. Vulgar but technically immaculate.",
  "author": {
    "name": "StanMarek",
    "url": "https://github.com/StanMarek"
  },
  "repository": "https://github.com/StanMarek/claude-plugins",
  "license": "MIT",
  "keywords": ["output-style", "personality", "review", "fun"]
}
```

- [ ] **Step 4.3: Copy the output style verbatim**

```bash
cp ~/.claude/output-styles/hostile-cto.md plugins/hostile-cto/output-styles/hostile-cto.md
```

Expected: File copied (84 lines).

- [ ] **Step 4.4: Verify the copy is byte-identical to the source**

```bash
diff -q ~/.claude/output-styles/hostile-cto.md plugins/hostile-cto/output-styles/hostile-cto.md && echo IDENTICAL
```

Expected: `IDENTICAL`.

- [ ] **Step 4.5: Verify the frontmatter is preserved**

```bash
head -5 plugins/hostile-cto/output-styles/hostile-cto.md
```

Expected output:

```
---
name: Hostile CTO
description: Gordon Ramsay meets your worst tech lead on bath salts. Obscenely vulgar, but you'll learn something through the trauma.
keep-coding-instructions: true
---
```

- [ ] **Step 4.6: Validate JSON**

```bash
jq . plugins/hostile-cto/.claude-plugin/plugin.json > /dev/null && echo "JSON OK"
```

Expected: `JSON OK`.

- [ ] **Step 4.7: Commit**

```bash
git add plugins/hostile-cto/
git commit -m "$(cat <<'EOF'
Add hostile-cto plugin

Packages the user's "Hostile CTO" output style as an installable plugin.
The output-styles/hostile-cto.md file is auto-discovered by Claude Code
when the plugin is enabled.
EOF
)"
```

Expected: Commit succeeds.

---

## Task 5: Create the marketplace manifest

**Files:**
- Create: `.claude-plugin/marketplace.json`

- [ ] **Step 5.1: Create the marketplace directory at the repo root**

```bash
mkdir -p .claude-plugin
```

Expected: Directory exists. (Note: the old root-level `.claude-plugin/` was removed in Task 2 step 2.3, so this re-creates it for the marketplace manifest.)

- [ ] **Step 5.2: Create `.claude-plugin/marketplace.json`**

Write this exact content:

```json
{
  "name": "claude-plugins",
  "owner": {
    "name": "StanMarek",
    "url": "https://github.com/StanMarek"
  },
  "metadata": {
    "description": "A small marketplace of Claude Code plugins by StanMarek.",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "claude-faaah",
      "version": "1.0.0",
      "author": { "name": "StanMarek", "url": "https://github.com/StanMarek" },
      "description": "Plays the iconic FAAAH sound on every prompt submit.",
      "source": "./plugins/claude-faaah"
    },
    {
      "name": "pastel-statusline",
      "version": "1.0.0",
      "author": { "name": "StanMarek", "url": "https://github.com/StanMarek" },
      "description": "Three-line pastel-colored statusline showing identity, workspace, and resource info.",
      "source": "./plugins/pastel-statusline"
    },
    {
      "name": "hostile-cto",
      "version": "1.0.0",
      "author": { "name": "StanMarek", "url": "https://github.com/StanMarek" },
      "description": "Output style: a profanity-laden CTO who teaches through trauma.",
      "source": "./plugins/hostile-cto"
    }
  ]
}
```

- [ ] **Step 5.3: Validate the manifest is valid JSON**

```bash
jq . .claude-plugin/marketplace.json > /dev/null && echo "JSON OK"
```

Expected: `JSON OK`.

- [ ] **Step 5.4: Verify all plugin source paths resolve to real plugin manifests**

```bash
for src in $(jq -r '.plugins[].source' .claude-plugin/marketplace.json); do
  manifest="$src/.claude-plugin/plugin.json"
  if [ -f "$manifest" ]; then
    echo "OK   $manifest"
  else
    echo "MISS $manifest"
  fi
done
```

Expected: Three `OK` lines, one per plugin. Any `MISS` line means a plugin source path is wrong — STOP and fix before committing.

- [ ] **Step 5.5: Commit**

```bash
git add .claude-plugin/marketplace.json
git commit -m "$(cat <<'EOF'
Add marketplace manifest listing all three plugins

claude-plugins is now a Claude Code marketplace. Users can install it
via /plugin marketplace add StanMarek/claude-plugins, then individually
install claude-faaah, pastel-statusline, or hostile-cto from it.
EOF
)"
```

Expected: Commit succeeds.

---

## Task 6: Rewrite the top-level README

**Files:**
- Modify: `README.md` (full rewrite from single-plugin pitch to marketplace landing)

- [ ] **Step 6.1: Rewrite `README.md`**

Write this exact content:

````markdown
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
| [`hostile-cto`](plugins/hostile-cto) | An output style that turns Claude into a foul-mouthed, battle-scarred CTO. |

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
````

- [ ] **Step 6.2: Verify README renders without obvious markdown errors**

```bash
head -1 README.md
wc -l README.md
```

Expected: First line is `# claude-plugins`. File length ≥ 60 lines.

- [ ] **Step 6.3: Commit**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
Rewrite README as marketplace landing page

The repo is no longer a single-plugin distribution. Document the
marketplace install flow, list the three plugins with one-line
descriptions in a table, and give each plugin its own short section.
EOF
)"
```

Expected: Commit succeeds.

---

## Task 7: Final structural verification

**Files:** None modified. Verification only.

- [ ] **Step 7.1: Print the final tree**

```bash
find . -type f \
  -not -path './.git/*' \
  -not -path './node_modules/*' \
  -not -name '.DS_Store' \
  | sort
```

Expected output (exact):

```
./.claude-plugin/marketplace.json
./LICENSE
./README.md
./docs/superpowers/plans/2026-04-28-claude-plugins-marketplace.md
./docs/superpowers/specs/2026-04-28-claude-plugins-marketplace-design.md
./plugins/claude-faaah/.claude-plugin/plugin.json
./plugins/claude-faaah/assets/faaah.mp3
./plugins/claude-faaah/hooks/hooks.json
./plugins/claude-faaah/scripts/play-sound.sh
./plugins/hostile-cto/.claude-plugin/plugin.json
./plugins/hostile-cto/output-styles/hostile-cto.md
./plugins/pastel-statusline/.claude-plugin/plugin.json
./plugins/pastel-statusline/scripts/statusline.sh
```

If anything else appears (other than `./.DS_Store`, which is gitignored at the user's option), investigate.

- [ ] **Step 7.2: Validate every JSON manifest**

```bash
for f in .claude-plugin/marketplace.json plugins/*/.claude-plugin/plugin.json; do
  jq . "$f" > /dev/null && echo "OK   $f" || echo "FAIL $f"
done
```

Expected: Four `OK` lines (1 marketplace + 3 plugins). Any `FAIL` blocks completion.

- [ ] **Step 7.3: Validate every bash script**

```bash
for f in plugins/*/scripts/*.sh; do
  bash -n "$f" && echo "OK   $f" || echo "FAIL $f"
done
```

Expected: Two `OK` lines (`play-sound.sh`, `statusline.sh`). Any `FAIL` blocks completion.

- [ ] **Step 7.4: Verify each plugin name in marketplace.json matches its plugin.json**

```bash
for src in $(jq -r '.plugins[].source' .claude-plugin/marketplace.json); do
  market_name=$(jq -r --arg s "$src" '.plugins[] | select(.source==$s) | .name' .claude-plugin/marketplace.json)
  manifest_name=$(jq -r .name "$src/.claude-plugin/plugin.json")
  if [ "$market_name" = "$manifest_name" ]; then
    echo "OK   $market_name"
  else
    echo "MISMATCH market=$market_name manifest=$manifest_name"
  fi
done
```

Expected: Three `OK` lines: `claude-faaah`, `pastel-statusline`, `hostile-cto`.

- [ ] **Step 7.5: Confirm hook script reference still resolves**

```bash
hook_cmd=$(jq -r '.hooks.UserPromptSubmit[0].hooks[0].command' plugins/claude-faaah/hooks/hooks.json)
echo "Hook command template: $hook_cmd"
resolved=$(echo "$hook_cmd" | sed "s|\${CLAUDE_PLUGIN_ROOT}|$PWD/plugins/claude-faaah|")
echo "Resolved: $resolved"
script_path=$(echo "$resolved" | awk '{print $2}')
[ -f "$script_path" ] && echo "OK script exists" || echo "FAIL missing $script_path"
```

Expected: Script template printed, resolved path points at `plugins/claude-faaah/scripts/play-sound.sh`, and "OK script exists".

- [ ] **Step 7.6: Confirm statusline command reference still resolves**

```bash
sl_cmd=$(jq -r '.statusLine.command' plugins/pastel-statusline/.claude-plugin/plugin.json)
echo "Statusline command template: $sl_cmd"
resolved=$(echo "$sl_cmd" | sed "s|\${CLAUDE_PLUGIN_ROOT}|$PWD/plugins/pastel-statusline|")
echo "Resolved: $resolved"
script_path=$(echo "$resolved" | awk '{print $2}')
[ -f "$script_path" ] && echo "OK script exists" || echo "FAIL missing $script_path"
```

Expected: Resolved path points at `plugins/pastel-statusline/scripts/statusline.sh` and "OK script exists".

- [ ] **Step 7.7: Confirm git history is preserved for relocated FAAAH files**

```bash
git log --follow --oneline plugins/claude-faaah/assets/faaah.mp3 | head -3
git log --follow --oneline plugins/claude-faaah/scripts/play-sound.sh | head -3
```

Expected: Both commands list at least the original `3a030b3 Initial release: FAAAH sound on prompt submit` commit, confirming history follows the rename.

- [ ] **Step 7.8: Print final commit log on the feature branch**

```bash
git log --oneline main..HEAD
```

Expected: Six commits on `feat/marketplace-restructure` not on `main`:

1. Spec correction (Task 1)
2. Relocate claude-faaah plugin (Task 2)
3. Add pastel-statusline plugin (Task 3)
4. Add hostile-cto plugin (Task 4)
5. Add marketplace manifest (Task 5)
6. Rewrite README (Task 6)

Plus this plan document — see Task 8.

---

## Task 8: Commit this implementation plan and prepare PR

**Files:**
- Create: `docs/superpowers/plans/2026-04-28-claude-plugins-marketplace.md` (this file, written before execution started)

The plan was written before execution. If it isn't already on the branch, commit it now.

- [ ] **Step 8.1: Check whether the plan is committed**

```bash
git log --all --oneline -- docs/superpowers/plans/2026-04-28-claude-plugins-marketplace.md
```

If the command returns no commits, run step 8.2; if it returns at least one commit, skip to step 8.3.

- [ ] **Step 8.2: Commit the plan**

```bash
git add docs/superpowers/plans/2026-04-28-claude-plugins-marketplace.md
git commit -m "Add implementation plan for marketplace restructure"
```

Expected: Commit succeeds.

- [ ] **Step 8.3: Hand off to user**

Report:

- Branch: `feat/marketplace-restructure`
- Commits ahead of `main` (count): output of `git rev-list --count main..HEAD`
- Final tree: paste output of `find` from step 7.1
- Suggest the user reviews `git log --oneline main..HEAD` and opens a PR (or merges locally) at their discretion. Do not push or open a PR without explicit user approval — `main` has diverged from `origin/main` and the user must decide the merge strategy.

---

## Out-of-scope user actions (post-merge)

These are NOT part of any task — list them for the user as a follow-up:

1. Rename the GitHub repo `claude-faaah-plugin` → `claude-plugins` via the GitHub repo Settings page.
2. Optionally rename the local working directory:
   ```bash
   cd ..
   mv claude-faaah-plugin claude-plugins
   cd claude-plugins
   git remote set-url origin git@github.com:StanMarek/claude-plugins.git
   ```
3. Re-test installs from a clean Claude Code session:
   ```
   /plugin marketplace remove claude-faaah-marketplace   # if previously installed
   /plugin marketplace add StanMarek/claude-plugins
   /plugin install claude-faaah@claude-plugins
   /plugin install pastel-statusline@claude-plugins
   /plugin install hostile-cto@claude-plugins
   ```
