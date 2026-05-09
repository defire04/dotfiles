#!/usr/bin/env python3

import json
import sys
import os
import re
import subprocess

# argv[1] = kitty @ ls (JSON), argv[2] = kitty @ ls --output-format=session
json_data = json.load(open(sys.argv[1]))
session_text = open(sys.argv[2]).read()

PROGRAMS = {
    "btop", "lazygit", "yazi", "kiro-cli", "claude", "ssh", "micro",
    "nvim", "vim", "zellij", "lazydocker", "htop", "btm",
}

# --- helpers ---

def get_cwd(pid):
    try:
        return os.readlink(f"/proc/{pid}/cwd")
    except:
        return None


def get_child_shell_cwd(pid):
    try:
        children = subprocess.check_output(["pgrep", "-P", str(pid)], text=True).strip().split("\n")
        for cpid in children:
            try:
                cmd = open(f"/proc/{cpid}/comm").read().strip()
                if cmd in ["fish", "bash", "zsh"]:
                    cwd = get_cwd(int(cpid))
                    if cwd:
                        return cwd
            except:
                continue
    except:
        pass
    return None


def find_process_tree(pid):
    result = []
    try:
        children = subprocess.check_output(["pgrep", "-P", str(pid)], text=True).strip().split("\n")
        for cpid in children:
            try:
                cmdline = open(f"/proc/{cpid}/cmdline", "rb").read().decode().split("\x00")
                result.append((int(cpid), cmdline))
                result.extend(find_process_tree(int(cpid)))
            except:
                continue
    except:
        pass
    return result


def detect_name(cmd):
    if not cmd:
        return ""
    base = os.path.basename(cmd[0])
    if base == "node" and len(cmd) > 1 and "claude" in cmd[1]:
        return "claude"
    return base


def clean_cmd(cmd):
    seen = set()
    result = []
    for c in cmd:
        if c and c not in seen:
            result.append(c)
            seen.add(c)
    return result


# --- build window_id -> launch args map from JSON ---

window_launches = {}  # {win_id: "launch --cwd=... program args"}

for oswin in json_data:
    for tab in oswin.get("tabs", []):
        for win in tab.get("windows", []):
            win_id = win.get("id")
            pid = win.get("pid")
            fg = win.get("foreground_processes", [])

            # Find first known program in foreground processes
            proc = None
            for p in fg:
                if detect_name(p.get("cmdline", [])) in PROGRAMS:
                    proc = p
                    break
            if proc is None:
                proc = fg[-1] if fg else None

            cmd = proc.get("cmdline", []) if proc else []
            fg_pid = proc.get("pid") if proc else None
            name = ""
            real_cmd = cmd
            real_pid = fg_pid

            # Deep search for claude in process tree
            for cpid, ccmd in find_process_tree(pid):
                if not ccmd:
                    continue
                if "claude" in " ".join(ccmd):
                    name = "claude"
                    real_cmd = ccmd
                    real_pid = cpid
                    break

            if not name:
                name = detect_name(cmd)

            cwd = (get_cwd(real_pid) if real_pid else None) or get_child_shell_cwd(pid) or get_cwd(pid) or "~"

            if name in PROGRAMS and real_cmd:
                cmd = clean_cmd(real_cmd)
                if name == "kiro-cli" and "--resume" not in cmd:
                    cmd.append("--resume")
                elif name == "claude":
                    cmd = [c for c in cmd if c != "--continue"]
                    cmd.append("--continue")
                window_launches[win_id] = f"launch --cwd={cwd} {' '.join(cmd)}"
            else:
                window_launches[win_id] = f"launch --cwd={cwd}"


# --- replace launch lines in session format ---

def replace_launch(match):
    id_json = match.group(1)
    rest = match.group(2).strip()  # existing args from --output-format=session
    win_id = json.loads(id_json).get("id")

    unserialize = f"'kitty-unserialize-data={id_json}'"

    if win_id in window_launches:
        # Replace cwd/program but KEEP kitty-unserialize-data for layout positioning
        launch_line = window_launches[win_id]
        # launch_line is "launch --cwd=... [program]", extract everything after "launch "
        rest_new = launch_line[len("launch "):]
        return f"launch {unserialize} {rest_new}"

    # Fallback: keep original with unserialize marker
    return f"launch {unserialize} {rest}".strip()

result = re.sub(
    r"launch 'kitty-unserialize-data=(\{[^']+\})'(.*)",
    replace_launch,
    session_text
)

print(result.rstrip())
