# dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).  
Supports two modes: **desktop** (CachyOS/Arch/Manjaro + KDE Plasma) and **server** (Ubuntu/Debian headless).

## Quick Start

```bash
git clone https://github.com/defire04/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Or with explicit mode:
```bash
./install.sh --mode desktop   # CachyOS/Arch/Manjaro + KDE
./install.sh --mode server    # Ubuntu/Debian headless
```

After install, create your private config (see [Private Setup](#private-setup)).

---

## Terminal Programs (auto-installed on all machines)

List: [`programs/terminal.txt`](programs/terminal.txt). Sorted alphabetically.

| Program | Command | Description |
|---------|---------|-------------|
| bat | `cat` | cat with syntax highlighting |
| btop | `btop` | CPU/RAM/network monitor |
| claude-code | `claude` | Claude Code (native installer, auto-updates) |
| docker | `docker` | Container runtime |
| docker-compose | `docker compose` | Multi-container apps from compose files |
| duf | `duf` | Disk usage |
| eza | `ls`, `ll`, `lt` | ls with icons and git status |
| fastfetch | `fastfetch` | System info |
| fish | `fish` | Default shell |
| fish-pure-prompt | — | Pure prompt for fish |
| git | `git` | Version control |
| github-cli | `gh` | GitHub CLI, also git auth (`gh auth setup-git`) |
| glances | `glances` | Web system monitor |
| lazydocker | `lazydocker` | TUI for docker |
| lazygit | `lazygit` | TUI for git |
| macchanger | `macchanger` | MAC address changer |
| mc | `mc` | Midnight Commander |
| micro | `micro`, `m` | Terminal text editor (`m` = `sudo -E micro`) |
| nmap | `nmap` | Network scanner |
| paru | `paru` | AUR helper (install.sh builds it first if missing) |
| ripgrep | `rg` | Fast content search |
| stow | `stow` | Symlinks the packages in this repo into `~` |
| trash-cli | `rm` | `rm` moves files to trash instead of deleting |
| wipe | `rmw` | Secure file deletion |
| yazi | `yazi` | Terminal file manager |

---

## Desktop Programs (auto-installed, CachyOS/Arch + KDE only)

List: [`programs/desktop.txt`](programs/desktop.txt). Sorted alphabetically.

| Program | Description |
|---------|-------------|
| anydesk-bin | Remote desktop |
| brave-bin | Brave browser (policies from `programs/brave-*.json`) |
| claude-desktop-extra | Claude Desktop (official Linux build, AUR by patrickjaja) |
| code | VS Code |
| easyeffects | Audio effects and equalizer |
| freerdp | RDP plugin for Remmina (without it Remmina can't open RDP) |
| jetbrains-toolbox | Installs and updates JetBrains IDEs (IntelliJ IDEA) in `~/.local/share/JetBrains` |
| kdiskmark | Disk benchmark |
| kitty | GPU-accelerated terminal |
| kopia-ui-bin | Backup with deduplication |
| kora-icon-theme | Kora icon theme |
| linux-arctis-manager | SteelSeries headset manager |
| meld | File/folder diff tool |
| nordic-theme-git | Nordic plasma desktop theme (Nordic-darker-solid) |
| noto-fonts | Base fonts |
| noto-fonts-emoji | Emoji font |
| obs-studio | Screen recording / streaming |
| openrgb | RGB lighting control |
| pacseek-bin | TUI to search and install pacman/AUR packages |
| remmina | RDP/VNC client |
| sniffnet | Network traffic monitor (GUI) |
| steam | Steam gaming platform |
| telegram-desktop | Telegram |
| ttf-jetbrains-mono-nerd | JetBrains Mono Nerd Font (terminal font) |
| ttf-meslo-nerd | Meslo Nerd Font (prompt icons) |
| winbox | MikroTik router management |
| wireshark-qt | Network traffic analyzer |
| wl-clipboard | `wl-copy` / `wl-paste` — Wayland clipboard (image paste in Claude Code) |

### Themes
- **Nordic-my** — custom Look & Feel theme (bundled in dotfiles, applied via stow).
  Applying a Global Theme also replaces the panel layout unless "Use desktop layout
  from theme" is unchecked.

### Flatpak

List: [`programs/flatpak.txt`](programs/flatpak.txt).

- `dev.vencord.Vesktop` — Discord client

---

## Useful Programs (install manually as needed)

| Program | Description | Install |
|---------|-------------|---------|
| audacity | Audio editor | `pacman -S audacity` |
| btrfs-assistant | BTRFS snapshots GUI | `pacman -S btrfs-assistant` |
| f3 | Flash drive fake capacity test | `pacman -S f3` |
| gwenview | KDE image viewer | `pacman -S gwenview` |
| haruna | Video player | `pacman -S haruna` |
| headsetcontrol | Headset control | `pacman -S headsetcontrol` |
| inkscape | Vector editor | `pacman -S inkscape` |
| iperf3 | Network throughput test | `pacman -S iperf3` |
| libreoffice | Office suite | `pacman -S libreoffice-fresh` |
| pavucontrol | PulseAudio mixer | `pacman -S pavucontrol` |
| prismlauncher | Minecraft launcher | `paru -S prismlauncher-offline` |
| protonup-qt | Proton version manager for Steam | `paru -S protonup-qt` |
| snapper | BTRFS snapshots | `pacman -S snapper` |

### Icon Themes
- **kora** — installed automatically via `kora-icon-theme` (AUR)
- **McMojave** (~108 MB) — too large for git, install manually: [KDE Store](https://store.kde.org/p/1305429)

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
| plasma-themes | `~/.local/share/plasma/` (desktoptheme + look-and-feel) | desktop |
| wallpapers | `~/.local/share/wallpapers/` | desktop |

### How symlinks work

Stow creates symlinks from `~` into `~/dotfiles/packages/<pkg>/`. For example:
```
~/.config/fish  →  ~/dotfiles/packages/fish/.config/fish
```
Editing any file in `~/dotfiles/` takes effect immediately — no copying needed.

### Manual stow (if install.sh was not used)

If the target config already exists, remove it first:
```bash
rm -rf ~/.config/fish
stow -d ~/dotfiles/packages -t ~ fish
```

Or to adopt existing configs into the package (moves files into dotfiles/ and symlinks them):
```bash
stow --adopt -d ~/dotfiles/packages -t ~ fish
```

Remove package symlinks:
```bash
stow -d ~/dotfiles/packages -t ~ -D fish
```

