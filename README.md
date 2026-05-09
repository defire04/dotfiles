# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).  
Supports two modes: **desktop** (CachyOS/Arch + KDE Plasma) and **server** (Ubuntu/Debian headless).

## Quick Start

```bash
git clone https://github.com/defire04/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Or with explicit mode:
```bash
./install.sh --mode desktop   # CachyOS/Arch + KDE
./install.sh --mode server    # Ubuntu/Debian headless
```

After install, create your private config (see [Private Setup](#private-setup)).

---

## Terminal Programs (auto-installed on all machines)

| Program | Command | Description |
|---------|---------|-------------|
| fish | `fish` | Default shell |
| micro | `micro` | Terminal text editor |
| bat | `cat` | cat with syntax highlighting |
| eza | `ls`, `ll`, `lt` | ls with icons and git status |
| lazygit | `lazygit` | TUI for git |
| lazydocker | `lazydocker` | TUI for docker |
| btop | `btop` | CPU/RAM/network monitor |
| yazi | `yazi` | Terminal file manager |
| ripgrep | `rg` | Fast content search |
| duf | `duf` | Disk usage |
| fastfetch | `fastfetch` | System info |
| glances | `glances` | Web system monitor |
| mc | `mc` | Midnight Commander |
| netwatch | `netwatch` | Network monitor (Arch only) |
| nmap | `nmap` | Network scanner |
| macchanger | `macchanger` | MAC address changer |
| wipe | `wipe` | Secure file deletion |
| github-cli | `gh` | GitHub CLI |
| docker | `docker` | Container runtime |
| lazydocker | `lazydocker` | Docker TUI |

---

## Desktop Programs (auto-installed, CachyOS/Arch + KDE only)

| Program | Description |
|---------|-------------|
| kitty | GPU-accelerated terminal |
| code | VS Code |
| brave-bin | Brave browser |
| telegram-desktop | Telegram |
| remmina | RDP/VNC client |
| steam | Steam gaming platform |
| obs-studio | Screen recording / streaming |
| easyeffects | Audio effects and equalizer |
| openrgb | RGB lighting control |
| sniffnet | Network traffic monitor (GUI) |
| kdiskmark | Disk benchmark |
| kopia-ui-bin | Backup with deduplication |
| anydesk-bin | Remote desktop |
| meld | File/folder diff tool |
| winbox | MikroTik router management |
| wireshark-qt | Network traffic analyzer |
| linux-arctis-manager | SteelSeries headset manager |
| claude-desktop-bin | Claude AI desktop app |

### Themes (included in desktop install)
- `cachyos-emerald-kde-theme-git`, `cachyos-nord-kde-theme-git`
- `kvantum-theme-nordic-git`, `nordic-theme-git`

### Flatpak
- `dev.vencord.Vesktop` — Discord client

---

## Useful Programs (install manually as needed)

| Program | Description | Install |
|---------|-------------|---------|
| protonup-qt | Proton version manager for Steam | `paru -S protonup-qt` |
| prismlauncher | Minecraft launcher | `paru -S prismlauncher-offline` |
| gwenview | KDE image viewer | `pacman -S gwenview` |
| haruna | Video player | `pacman -S haruna` |
| libreoffice | Office suite | `pacman -S libreoffice-fresh` |
| pavucontrol | PulseAudio mixer | `pacman -S pavucontrol` |
| inkscape | Vector editor | `pacman -S inkscape` |
| audacity | Audio editor | `pacman -S audacity` |
| btrfs-assistant | BTRFS snapshots GUI | `pacman -S btrfs-assistant` |
| headsetcontrol | Headset control | `pacman -S headsetcontrol` |
| iperf3 | Network throughput test | `pacman -S iperf3` |
| f3 | Flash drive fake capacity test | `pacman -S f3` |
| snapper | BTRFS snapshots | `pacman -S snapper` |
| kdiskmark | Disk benchmark | `pacman -S kdiskmark` |

### Icon Themes (too large for git — install manually)
- **kora** (~86 MB) — [KDE Store](https://store.kde.org/p/1501595)
- **McMojave** (~108 MB) — [KDE Store](https://store.kde.org/p/1305429)

---

## Private Setup

After cloning, create `~/.config/fish/conf.d/private.fish` with your machine-specific settings:

```fish
# Machine-specific paths
set -gx CLAUDE_HOME /path/to/Claude

# SSH aliases (not tracked in git)
alias myserver='ssh user@192.168.x.x'
alias prod='ssh user@your-prod-ip'
```

### VPN (NetworkManager)
VPN configs are in `/etc/NetworkManager/system-connections/` and contain credentials — configure manually on each machine.

### Kopia Backups
Re-connect to your NAS storage manually after fresh install:
```bash
kopia repository connect filesystem --path /mnt/nas/backups/username/machine
```

---

## Stow Packages

| Package | Path | Mode |
|---------|------|------|
| fish | `~/.config/fish/` | all |
| git | `~/.config/git/` | all |
| micro | `~/.config/micro/` | all |
| bat | `~/.config/bat/` | all |
| mc | `~/.config/mc/` | all |
| scripts | `~/.local/bin/` | all |
| systemd | `~/.config/systemd/user/` | all |
| kitty | `~/.config/kitty/` | desktop |
| kde | `~/.config/` (KDE files) | desktop |
| easyeffects | `~/.config/easyeffects/` + `~/.local/share/easyeffects/` | desktop |
| openrgb | `~/.config/OpenRGB/` | desktop |
| color-schemes | `~/.local/share/color-schemes/` | desktop |
| aurorae | `~/.local/share/aurorae/themes/` | desktop |
| plasma-systemmonitor | `~/.local/share/plasma-systemmonitor/` | desktop |

### Manual stow
```bash
# Apply single package
stow -d ~/dotfiles/packages -t ~ fish

# Remove package symlinks
stow -d ~/dotfiles/packages -t ~ -D fish
```

---

## Security Check

Before committing, run:
```bash
./check-secrets.sh
```

Scans staged changes for: private IPs, NAS paths, API keys, tokens, SSH private keys, known private files.

---

## VS Code

Settings are synced via VS Code Settings Sync (GitHub account). No separate repo needed.
