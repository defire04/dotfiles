#!/bin/bash
KITTY="/usr/bin/kitty"
SESSION="$HOME/.config/kitty/last.kitty-session"

if ss -lx | grep -q '@kitty-main\.sock'; then
    "$KITTY" --single-instance
else
    "$KITTY" --single-instance --session "$SESSION"
fi
