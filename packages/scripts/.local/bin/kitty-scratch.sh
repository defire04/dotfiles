#!/bin/bash
# Kitty вне сессии (Ctrl+Alt+H): своя группа и свой сокет,
# поэтому kitty-save-session.sh и kitty-start.sh его не видят.
exec /usr/bin/kitty --single-instance --instance-group scratch \
    -o listen_on=unix:@kitty-scratch.sock \
    -o startup_session=none "$@"
