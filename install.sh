#!/usr/bin/env bash
# Usage:
#   ./install.sh                 # interactive mode selection
#   ./install.sh --mode desktop  # CachyOS/Arch + KDE
#   ./install.sh --mode server   # Ubuntu/Debian headless
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=""

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
    sudo pacman -S --needed --noconfirm "$@"
}

install_ubuntu_pkgs() {
    sudo apt-get install -y "$@"
}

install_binary() {
    local name=$1 url=$2 dest=${3:-/usr/local/bin}
    echo "Installing $name from binary..."
    local tmp=$(mktemp)
    curl -fsSL "$url" -o "$tmp"
    chmod +x "$tmp"
    sudo mv "$tmp" "$dest/$name"
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
    sudo pacman -S --needed --noconfirm base-devel
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
    # Ubuntu — install what's available, use binaries for the rest
    install_ubuntu_pkgs fish bat btop ripgrep duf mc nmap macchanger wipe glances

    # fish PPA
    if ! command -v fish &> /dev/null; then
        sudo apt-add-repository -y ppa:fish-shell/release-3
        sudo apt-get update
        install_ubuntu_pkgs fish
    fi

    # micro — official binary installer
    if ! command -v micro &> /dev/null; then
        echo "Installing micro..."
        cd /tmp && curl https://getmic.ro | bash && sudo mv micro /usr/local/bin/
        cd "$DOTFILES_DIR"
    fi

    # GitHub CLI
    if ! command -v gh &> /dev/null; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
        sudo apt-get update && install_ubuntu_pkgs gh
    fi

    # Docker
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | sudo bash
        sudo usermod -aG docker "$USER"
    fi

    # Binaries from GitHub releases
    if ! command -v eza &> /dev/null; then
        EZA_URL=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest \
            | grep "browser_download_url.*eza_x86_64-unknown-linux-musl.tar.gz" \
            | cut -d '"' -f 4)
        curl -fsSL "$EZA_URL" | tar xz -C /tmp && sudo mv /tmp/eza /usr/local/bin/
    fi

    if ! command -v lazygit &> /dev/null; then
        LG_URL=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
            | grep "browser_download_url.*Linux_x86_64.tar.gz" \
            | cut -d '"' -f 4)
        curl -fsSL "$LG_URL" | tar xz -C /tmp && sudo mv /tmp/lazygit /usr/local/bin/
    fi

    if ! command -v lazydocker &> /dev/null; then
        LD_URL=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest \
            | grep "browser_download_url.*Linux_x86_64.tar.gz" \
            | cut -d '"' -f 4)
        curl -fsSL "$LD_URL" | tar xz -C /tmp && sudo mv /tmp/lazydocker /usr/local/bin/
    fi

    if ! command -v yazi &> /dev/null; then
        YAZI_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest \
            | grep "browser_download_url.*yazi-x86_64-unknown-linux-musl.zip" \
            | cut -d '"' -f 4)
        curl -fsSL "$YAZI_URL" -o /tmp/yazi.zip && unzip -q /tmp/yazi.zip -d /tmp/yazi_extract
        sudo mv /tmp/yazi_extract/*/yazi /usr/local/bin/
    fi

    if ! command -v fastfetch &> /dev/null; then
        FF_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
            | grep "browser_download_url.*linux-amd64.tar.gz" \
            | head -1 | cut -d '"' -f 4)
        curl -fsSL "$FF_URL" | tar xz -C /tmp && sudo mv /tmp/fastfetch /usr/local/bin/
    fi

    # fish-pure-prompt via fisher on Ubuntu
    if command -v fish &> /dev/null; then
        if ! fish -c "fisher list 2>/dev/null" | grep -q nicowillis/pure; then
            echo "Installing fisher and pure prompt..."
            fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher && fisher install nicowillis/pure"
        fi
    fi
fi

# ── Install desktop programs (Arch/CachyOS only) ────────────────────────────
if [[ "$MODE" == "desktop" ]]; then
    echo ""
    echo "--- Installing desktop programs ---"
    PKGS=$(grep -v '^#' "$DOTFILES_DIR/programs/desktop.txt" | grep -v '^$' | tr '\n' ' ')
    paru -S --needed --noconfirm $PKGS

    # Flatpak
    if ! command -v flatpak &> /dev/null; then
        sudo pacman -S --needed --noconfirm flatpak
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
        echo "$FISH_PATH" | sudo tee -a /etc/shells
    fi
    chsh -s "$FISH_PATH"
    echo "  ✅ Default shell set to fish (re-login to apply)"
else
    echo "  ✅ fish is already the default shell"
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
