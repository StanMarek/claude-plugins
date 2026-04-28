#!/bin/bash
# Play FAAAH sound on prompt submit
SOUND_FILE="${CLAUDE_PLUGIN_ROOT}/assets/faaah.mp3"

if [ ! -f "$SOUND_FILE" ]; then
  exit 0
fi

if command -v afplay &>/dev/null; then
  afplay "$SOUND_FILE" &
elif command -v paplay &>/dev/null; then
  paplay "$SOUND_FILE" &
elif command -v aplay &>/dev/null; then
  aplay "$SOUND_FILE" &
fi

exit 0
