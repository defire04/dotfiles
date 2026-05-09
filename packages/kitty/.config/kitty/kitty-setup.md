# Kitty Session Setup

## Файлы и их пути

---

### `~/bin/kitty-start.sh`

```bash
#!/bin/bash
KITTY="/usr/bin/kitty"
SESSION="$HOME/.config/kitty/last.kitty-session"

if pgrep -x kitty > /dev/null; then
    "$KITTY" --single-instance
else
    "$KITTY" --single-instance --session "$SESSION"
fi
```

---

### `~/bin/kitty-save-session.sh`

```bash
#!/bin/bash
SESSION_FILE="$HOME/.config/kitty/last.kitty-session"
KITTY="/usr/bin/kitty"

SOCK=$(ss -lx | grep '@kitty-main\.sock' | awk '{print $5}' | head -1)
[ -z "$SOCK" ] && exit 0

DUMP=$("$KITTY" @ --to "unix:$SOCK" ls)
[ -z "$DUMP" ] && exit 0

TMP=$(mktemp)
echo "$DUMP" | python3 "$HOME/.config/kitty/session-convert.py" > "$TMP"

if [ -s "$TMP" ]; then
    mv "$TMP" "$SESSION_FILE"
else
    rm "$TMP"
fi
```

---

### `~/.config/kitty/session-convert.py`

```python
import json, sys, os, subprocess

data = json.load(sys.stdin)

def get_cwd(pid):
    try:
        return os.readlink(f"/proc/{pid}/cwd")
    except:
        return None

def get_child_fish_cwd(pid):
    try:
        result = subprocess.check_output(
            ["pgrep", "-P", str(pid), "fish"], text=True
        ).strip().split("\n")
        for cpid in result:
            cwd = get_cwd(int(cpid))
            if cwd:
                return cwd
    except:
        pass
    return None

PROGRAMS = {"btop", "lazygit", "yazi", "kiro-cli", "claude", "ssh"}

for oswin in data:
    for tab in oswin.get("tabs", []):
        print(f"new_tab {tab.get('title','')}")
        print(f"layout {tab.get('layout', 'splits')}")
        for win in tab.get("windows", []):
            pid = win.get("pid")
            fg = win.get("foreground_processes", [])
            cwd = get_child_fish_cwd(pid) or get_cwd(pid) or "~"

            if fg:
                proc = fg[-1]
                cmd = proc.get("cmdline", [])
                name = os.path.basename(cmd[0]) if cmd else ""

                if name in PROGRAMS:
                    if name == "kiro-cli":
                        print(f"launch --cwd={cwd} {' '.join(cmd)} --resume")
                    elif name == "claude":
                        print(f"launch --cwd={cwd} {' '.join(cmd)} --continue")
                    else:
                        print(f"launch --cwd={cwd} {' '.join(cmd)}")
                else:
                    print(f"launch --cwd={cwd}")
            else:
                print(f"launch --cwd={cwd}")

            if win.get("is_focused"):
                print("focus")
```

---

### `~/.config/systemd/user/kitty-save-session.service`

```ini
[Unit]
Description=Save kitty session

[Service]
Type=oneshot
ExecStart=%h/.local/bin/kitty-save-session.sh
```

---

### `~/.config/systemd/user/kitty-save-session.timer`

```ini
[Unit]
Description=Auto-save kitty session every 5 minutes

[Timer]
OnCalendar=*:0/5
Persistent=true

[Install]
WantedBy=timers.target
```

---

## После создания всех файлов

```bash
chmod +x ~/.local/bin/kitty-start.sh ~/.local/bin/kitty-save-session.sh
systemctl --user daemon-reload
systemctl --user enable --now kitty-save-session.timer
```
