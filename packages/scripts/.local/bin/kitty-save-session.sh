#!/bin/bash
SESSION_FILE="$HOME/.config/kitty/last.kitty-session"
KITTY="/usr/bin/kitty"

SOCK=$(ss -lx | grep '@kitty-main\.sock' | awk '{print $5}' | head -1)
[ -z "$SOCK" ] && exit 0

JSON_TMP=$(mktemp)
SESSION_TMP=$(mktemp)
OUT_TMP=$(mktemp)

"$KITTY" @ --to "unix:$SOCK" ls > "$JSON_TMP" 2>/dev/null
"$KITTY" @ --to "unix:$SOCK" ls --output-format=session > "$SESSION_TMP" 2>/dev/null

if [ -s "$JSON_TMP" ] && [ -s "$SESSION_TMP" ]; then
    python3 "$HOME/.config/kitty/session-convert.py" "$JSON_TMP" "$SESSION_TMP" > "$OUT_TMP"
    [ -s "$OUT_TMP" ] && mv "$OUT_TMP" "$SESSION_FILE" || rm "$OUT_TMP"
fi

rm -f "$JSON_TMP" "$SESSION_TMP"
