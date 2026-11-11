#!/bin/bash
# Автосохранение сессии kitty (таймер kitty-save-session.timer и Ctrl+S).
# Переопределения для проверки: KITTY_SESSION_FILE, KITTY_SESSION_HISTORY, KITTY_SOCK.
#
# 11.11.2026: файл оказался пустым после жёсткого выключения через 17 с после сохранения.
# Причина: временный файл лежал в /tmp (tmpfs), mv на btrfs шёл копированием
# в новый файл без fsync, данные не успели попасть на диск. Теперь временный
# файл в той же папке, fsync перед атомарным переименованием, проверка вкладок
# и история из нескольких копий.
set -u

SESSION_FILE="${KITTY_SESSION_FILE:-$HOME/.config/kitty/last.kitty-session}"
HISTORY_DIR="${KITTY_SESSION_HISTORY:-$(dirname "$SESSION_FILE")/session-history}"
KEEP=5
KITTY="/usr/bin/kitty"
CONVERT="$HOME/.config/kitty/session-convert.py"
DIR=$(dirname "$SESSION_FILE")

has_tabs() { [ -s "$1" ] && grep -qE '^(new_tab|launch)( |$)' "$1"; }

# Один запуск за раз (таймер и Ctrl+S могут совпасть)
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/kitty-save-session.lock"
flock -n 9 || exit 0

SOCK="${KITTY_SOCK:-$(ss -lx | grep -o '@kitty-main\.sock-[0-9]*' | head -1)}"
[ -z "$SOCK" ] && exit 0

JSON_TMP=$(mktemp)
SESSION_TMP=$(mktemp)
OUT_TMP=$(mktemp "$DIR/.last.kitty-session.XXXXXX")
trap 'rm -f "$JSON_TMP" "$SESSION_TMP" "$OUT_TMP"' EXIT

"$KITTY" @ --to "unix:$SOCK" ls > "$JSON_TMP" 2>/dev/null || exit 0
"$KITTY" @ --to "unix:$SOCK" ls --output-format=session > "$SESSION_TMP" 2>/dev/null || exit 0
[ -s "$JSON_TMP" ] && [ -s "$SESSION_TMP" ] || exit 0

python3 "$CONVERT" "$JSON_TMP" "$SESSION_TMP" > "$OUT_TMP" || exit 0
has_tabs "$OUT_TMP" || exit 0

# Ничего не изменилось
cmp -s "$OUT_TMP" "$SESSION_FILE" 2>/dev/null && exit 0

chmod 600 "$OUT_TMP"
sync "$OUT_TMP"

# Старую версию в .prev и в историю, только если в ней есть вкладки
if has_tabs "$SESSION_FILE"; then
    cp -p "$SESSION_FILE" "$SESSION_FILE.prev.tmp" && sync "$SESSION_FILE.prev.tmp" \
        && mv -f "$SESSION_FILE.prev.tmp" "$SESSION_FILE.prev"
fi

mv -f "$OUT_TMP" "$SESSION_FILE"

# История: последние $KEEP разных версий
mkdir -p "$HISTORY_DIR"
SNAP="$HISTORY_DIR/$(date +%Y%m%d-%H%M%S).kitty-session"
cp -p "$SESSION_FILE" "$SNAP" && chmod 600 "$SNAP"
ls -1t "$HISTORY_DIR"/*.kitty-session 2>/dev/null | tail -n +$((KEEP + 1)) | xargs -r rm -f

sync -f "$SESSION_FILE"
