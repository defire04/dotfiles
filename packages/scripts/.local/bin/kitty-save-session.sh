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
    if [ -s "$OUT_TMP" ]; then
        # Предыдущую версию в .prev: если сохранится чужое окно, вкладки можно вернуть (16.10.2026)
        [ -s "$SESSION_FILE" ] && ! cmp -s "$OUT_TMP" "$SESSION_FILE" && cp "$SESSION_FILE" "$SESSION_FILE.prev"
        mv "$OUT_TMP" "$SESSION_FILE"
    else
        rm "$OUT_TMP"
    fi
fi

rm -f "$JSON_TMP" "$SESSION_TMP"
