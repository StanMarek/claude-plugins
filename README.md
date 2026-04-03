# claude-faaah

A Claude Code plugin that plays the iconic **FAAAH** sound effect every time you submit a prompt.

Because coding should sound like a fight night.

## Install

```bash
/plugin install claude-faaah@StanMarek/claude-faaah-plugin
```

Or via CLI:

```bash
claude plugin install claude-faaah@StanMarek/claude-faaah-plugin
```

## How it works

The plugin registers a `UserPromptSubmit` hook that fires every time you press Enter. It plays the bundled sound file in the background using your system's audio player — no blocking, no lag.

**Supported platforms:**
- macOS (`afplay`)
- Linux (`paplay` / `aplay`)

## Custom sound

Want a different sound? Replace `assets/faaah.mp3` with your own `.mp3` file.

## Uninstall

```bash
/plugin uninstall claude-faaah
```

## License

MIT
