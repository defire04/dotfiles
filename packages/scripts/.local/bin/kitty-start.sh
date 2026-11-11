#!/bin/bash
KITTY="/usr/bin/kitty"
SESSION="${KITTY_SESSION_FILE:-$HOME/.config/kitty/last.kitty-session}"
HISTORY_DIR="${KITTY_SESSION_HISTORY:-$(dirname "$SESSION")/session-history}"

has_tabs() { [ -s "$1" ] && grep -qE '^(new_tab|launch)( |$)' "$1"; }

# Первая непустая из: last, .prev, история (новые первыми)
pick_session() {
    local f
    for f in "$SESSION" "$SESSION.prev" $(ls -1t "$HISTORY_DIR"/*.kitty-session 2>/dev/null); do
        has_tabs "$f" && { echo "$f"; return 0; }
    done
    return 1
}

if [ "${1:-}" = "--print-session" ]; then
    pick_session
    exit
fi

if ss -lx | grep -q '@kitty-main\.sock'; then
    exec "$KITTY" --single-instance
elif S=$(pick_session); then
    [ "$S" != "$SESSION" ] && echo "kitty-start: $SESSION без вкладок, беру $S" >&2
    exec "$KITTY" --single-instance --session "$S"
else
    exec "$KITTY" --single-instance
fi
