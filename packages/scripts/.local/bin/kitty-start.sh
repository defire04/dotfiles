#!/bin/bash
KITTY="/usr/bin/kitty"
SESSION="$HOME/.config/kitty/last.kitty-session"

if pgrep -x kitty > /dev/null; then
    "$KITTY" --single-instance
else
    "$KITTY" --single-instance --session "$SESSION"
fi
