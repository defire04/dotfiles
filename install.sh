#!/usr/bin/env bash
# Usage:
#   ./install.sh                 # interactive mode selection
#   ./install.sh --mode desktop  # CachyOS/Arch + KDE
#   ./install.sh --mode server   # Ubuntu/Debian headless
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=""

# Use sudo only when not root
if [[ $EUID -eq 0 ]]; then
    SUDO=""
elif command -v sudo &> /dev/null; then
    SUDO="sudo"
else
    echo "sudo not found — installing it (enter root password when prompted)..."
    su -c "apt-get install -y sudo && usermod -aG sudo $(whoami)"
    echo ""
    echo "sudo installed. Re-run the script: ./install.sh $*"
    exit 0
fi

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --mode) MODE="$2"; shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

# Interactive mode selection if not specified
if [[ -z "$MODE" ]]; then
    echo "Select installation mode:"
    echo "  1) desktop — CachyOS/Arch with KDE (full setup)"
    echo "  2) server  — Ubuntu/Debian headless (terminal tools only)"
    read -rp "Enter 1 or 2: " choice
    case $choice in
        1) MODE="desktop" ;;
        2) MODE="server" ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
fi

echo ""
echo "=== Installing dotfiles in '$MODE' mode ==="
echo ""

# Detect OS
if command -v pacman &> /dev/null; then
    OS="arch"
    echo "OS: Arch/CachyOS detected"
elif command -v apt &> /dev/null; then
    OS="ubuntu"
    echo "OS: Ubuntu/Debian detected"
else
    echo "Unsupported OS (no pacman or apt found)"
    exit 1
fi

# Desktop mode only supported on Arch
if [[ "$MODE" == "desktop" && "$OS" != "arch" ]]; then
    echo "Desktop mode is only supported on Arch/CachyOS"
    exit 1
fi

# ── Install base dependencies ────────────────────────────────────────────────

install_arch_pkgs() {
    $SUDO pacman -S --needed --noconfirm "$@"
}

install_ubuntu_pkgs() {
    $SUDO apt-get install -y --fix-missing "$@"
}

install_binary() {
    local name=$1 url=$2 dest=${3:-/usr/local/bin}
    echo "Installing $name from binary..."
    local tmp=$(mktemp)
    curl -fsSL "$url" -o "$tmp"
    chmod +x "$tmp"
    $SUDO mv "$tmp" "$dest/$name"
}

echo "--- Installing git and stow ---"
if [[ "$OS" == "arch" ]]; then
    install_arch_pkgs git stow
else
    install_ubuntu_pkgs git stow
fi

# ── Install paru on Arch if not present ─────────────────────────────────────
if [[ "$OS" == "arch" ]] && ! command -v paru &> /dev/null; then
    echo "--- Installing paru (AUR helper) ---"
    $SUDO pacman -S --needed --noconfirm base-devel
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$tmpdir/paru"
    cd "$tmpdir/paru"
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
fi

# ── Install terminal programs ────────────────────────────────────────────────
echo ""
echo "--- Installing terminal programs ---"

if [[ "$OS" == "arch" ]]; then
    # Read terminal.txt, skip comments and empty lines
    PKGS=$(grep -v '^#' "$DOTFILES_DIR/programs/terminal.txt" | grep -v '^$' | grep -v '^paru$' | tr '\n' ' ')
    paru -S --needed --noconfirm $PKGS

else
    INSTALLED=()
    FAILED=()

    _mark() { command -v "$1" &>/dev/null && INSTALLED+=("$1") || FAILED+=("$1"); }

    # Locale (needed for btop and other UTF-8 tools)
    $SUDO locale-gen en_US.UTF-8
    $SUDO update-locale LANG=en_US.UTF-8

    # Ubuntu — install what's available via apt
    install_ubuntu_pkgs fish bat btop ripgrep duf mc nmap macchanger wipe glances || true

    # fish PPA fallback
    if ! command -v fish &> /dev/null; then
        $SUDO apt-add-repository -y ppa:fish-shell/release-3
        $SUDO apt-get update
        install_ubuntu_pkgs fish || true
    fi

    # micro — official binary installer
    if ! command -v micro &> /dev/null; then
        cd /tmp && curl -fsSL https://getmic.ro | bash && $SUDO mv micro /usr/local/bin/ || true
        cd "$DOTFILES_DIR"
    fi

    # GitHub CLI
    if ! command -v gh &> /dev/null; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        $SUDO apt-get update -q && install_ubuntu_pkgs gh || true
    fi

    # Docker
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | $SUDO bash || true
        [[ -n "$USER" && "$USER" != "root" ]] && $SUDO usermod -aG docker "$USER" || true
    fi

    # eza
    if ! command -v eza &> /dev/null; then
        EZA_URL=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest \
            | grep "browser_download_url.*eza_x86_64-unknown-linux-musl.tar.gz" \
            | cut -d '"' -f 4)
        [[ -n "$EZA_URL" ]] && curl -fsSL "$EZA_URL" | tar xz -C /tmp && $SUDO mv /tmp/eza /usr/local/bin/ || true
    fi

    # lazygit
    if ! command -v lazygit &> /dev/null; then
        LG_VER=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')
        if [[ -n "$LG_VER" ]]; then
            curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz" | tar xz -C /tmp && $SUDO mv /tmp/lazygit /usr/local/bin/ || true
        fi
    fi

    # lazydocker
    if ! command -v lazydocker &> /dev/null; then
        LD_URL=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest \
            | grep "browser_download_url.*Linux_x86_64.tar.gz" \
            | cut -d '"' -f 4)
        [[ -n "$LD_URL" ]] && curl -fsSL "$LD_URL" | tar xz -C /tmp && $SUDO mv /tmp/lazydocker /usr/local/bin/ || true
    fi

    # yazi
    if ! command -v yazi &> /dev/null; then
        YAZI_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest \
            | grep "browser_download_url.*yazi-x86_64-unknown-linux-musl.zip" \
            | cut -d '"' -f 4)
        if [[ -n "$YAZI_URL" ]]; then
            curl -fsSL "$YAZI_URL" -o /tmp/yazi.zip && unzip -q /tmp/yazi.zip -d /tmp/yazi_extract || true
            $SUDO mv /tmp/yazi_extract/*/yazi /usr/local/bin/ 2>/dev/null || true
        fi
    fi

    # fastfetch
    if ! command -v fastfetch &> /dev/null; then
        FF_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
            | grep "browser_download_url.*fastfetch-linux-amd64.tar.gz" \
            | head -1 | cut -d '"' -f 4)
        if [[ -n "$FF_URL" ]]; then
            tmpdir=$(mktemp -d)
            curl -fsSL "$FF_URL" | tar xz -C "$tmpdir" && $SUDO mv "$tmpdir/fastfetch-linux-amd64/usr/bin/fastfetch" /usr/local/bin/ && rm -rf "$tmpdir" || true
        fi
    fi

    # fisher + pure prompt
    if command -v fish &> /dev/null; then
        if ! fish -c "type -q fisher" 2>/dev/null; then
            fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" || true
        fi
        if ! fish -c "fisher list 2>/dev/null" | grep -q pure-fish/pure; then
            fish -c "fisher install pure-fish/pure" || true
        fi
    fi

    # Check what got installed (Ubuntu renames: bat→batcat, ripgrep→rg)
    for tool in fish micro btop eza lazygit lazydocker yazi duf fastfetch glances mc nmap gh docker; do
        _mark "$tool"
    done
    command -v bat &>/dev/null || command -v batcat &>/dev/null && INSTALLED+=("bat") || FAILED+=("bat")
    command -v rg &>/dev/null && INSTALLED+=("ripgrep") || FAILED+=("ripgrep")
fi

# ── Install desktop programs (Arch/CachyOS only) ────────────────────────────
if [[ "$MODE" == "desktop" ]]; then
    echo ""
    echo "--- Installing desktop programs ---"
    PKGS=$(grep -v '^#' "$DOTFILES_DIR/programs/desktop.txt" | grep -v '^$' | tr '\n' ' ')
    paru -S --needed --noconfirm $PKGS

    # Flatpak
    if ! command -v flatpak &> /dev/null; then
        $SUDO pacman -S --needed --noconfirm flatpak
    fi
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    while IFS= read -r app; do
        [[ -z "$app" || "$app" == \#* ]] && continue
        flatpak install -y flathub "$app" || true
    done < "$DOTFILES_DIR/programs/flatpak.txt"
fi

# ── Apply stow packages ──────────────────────────────────────────────────────
echo ""
echo "--- Applying stow packages ---"
STOW_CMD="stow -d $DOTFILES_DIR/packages -t $HOME"

TERMINAL_PKGS="fish git micro bat mc scripts systemd"
for pkg in $TERMINAL_PKGS; do
    $STOW_CMD "$pkg" && echo "  ✅ $pkg" || echo "  ⚠️  $pkg (conflict — resolve manually)"
done

if [[ "$MODE" == "desktop" ]]; then
    DESKTOP_PKGS="kitty kde easyeffects openrgb color-schemes aurorae plasma-systemmonitor"
    for pkg in $DESKTOP_PKGS; do
        $STOW_CMD "$pkg" && echo "  ✅ $pkg" || echo "  ⚠️  $pkg (conflict — resolve manually)"
    done
fi

# ── Enable systemd user units (desktop only) ─────────────────────────────────
if [[ "$MODE" == "desktop" ]]; then
    echo ""
    echo "--- Enabling systemd user units ---"
    systemctl --user daemon-reload
    systemctl --user enable --now kitty-save-session.timer && echo "  ✅ kitty-save-session.timer"
    systemctl --user enable --now arctis-manager.service && echo "  ✅ arctis-manager.service"
fi

# ── Set fish as default shell ────────────────────────────────────────────────
echo ""
if [[ "$SHELL" != "$(which fish)" ]]; then
    echo "--- Setting fish as default shell ---"
    FISH_PATH=$(which fish)
    if ! grep -q "$FISH_PATH" /etc/shells; then
        echo "$FISH_PATH" | $SUDO tee -a /etc/shells
    fi
    chsh -s "$FISH_PATH"
    echo "  ✅ Default shell set to fish (re-login to apply)"
else
    echo "  ✅ fish is already the default shell"
fi

# ── Summary (Ubuntu only) ────────────────────────────────────────────────────
if [[ "$OS" == "ubuntu" && ${#INSTALLED[@]} -gt 0 || ${#FAILED[@]} -gt 0 ]]; then
    echo ""
    echo "--- Install summary ---"
    if [[ ${#INSTALLED[@]} -gt 0 ]]; then
        echo "  Installed: ${INSTALLED[*]}"
    fi
    if [[ ${#FAILED[@]} -gt 0 ]]; then
        echo "  NOT installed: ${FAILED[*]}"
        echo "  (install manually or re-run the script)"
    fi
fi

# ── Private config reminder ──────────────────────────────────────────────────
echo ""
echo "=== Done! ==="
echo ""
echo "🔐 IMPORTANT: Create your private config file:"
echo "   ~/.config/fish/conf.d/private.fish"
echo ""
echo "   Example:"
echo "   set -gx CLAUDE_HOME /path/to/Claude"
echo "   alias infra='ssh user@your-server-ip'"
echo "   alias prod='ssh user@your-prod-ip'"
echo ""
if [[ "$MODE" == "desktop" ]]; then
    echo "   Also configure manually:"
    echo "   • VPN (NetworkManager): /etc/NetworkManager/system-connections/"
    echo "   • Kopia backups: re-connect to your NAS"
    echo "   • Icon themes: download kora/McMojave from KDE Store if needed"
    echo ""
fi
