#!/usr/bin/env bash
# Usage:
#   ./install.sh                 # interactive mode selection
#   ./install.sh --mode desktop  # CachyOS/Arch + KDE
#   ./install.sh --mode server   # Ubuntu/Debian headless
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=""
MARKER="$HOME/.local/share/dotfiles/.installed"
APPLY_STOW=false

# Parse args first so MODE is known before any prompts
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

# Ask stow question BEFORE git update so we know whether to preserve kde configs.
# On server: always apply stow (no KDE writing files through symlinks).
# On desktop: first install applies automatically; repeat installs ask (default No).
if [[ ! -f "$MARKER" ]]; then
    APPLY_STOW=true
elif [[ "$MODE" == "desktop" ]]; then
    if NEWT_COLORS='
        root=black,black
        window=white,black
        border=blue,black
        title=cyan,black
        button=black,blue
        actbutton=brightwhite,blue
        textbox=white,black
    ' LANG=C whiptail --title "Apply configs?" \
        --defaultno \
        --yesno "Apply stow configs (dotfiles)?\n\nThis will overwrite your current settings\nwith the versions from the repo.\n\nSkip this on machines where you have\ncustom local changes." 14 55 2>/dev/null; then
        APPLY_STOW=true
    fi
else
    APPLY_STOW=true
fi

# Auto-update dotfiles repo if it has a remote
if git -C "$DOTFILES_DIR" remote get-url origin &>/dev/null; then
    echo "--- Updating dotfiles repo ---"
    OLD_HASH=$(git -C "$DOTFILES_DIR" rev-parse HEAD)
    BRANCH=$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref HEAD)

    # git reset --hard ignores skip-worktree, so manually save kde package when
    # user chose not to apply stow (KDE writes config changes through symlinks into it)
    if [[ "$MODE" == "desktop" ]] && [[ -f "$MARKER" ]] && ! $APPLY_STOW; then
        _kde_tmp=$(mktemp -d)
        cp -r "$DOTFILES_DIR/packages/kde/." "$_kde_tmp/"
    fi

    git -C "$DOTFILES_DIR" fetch origin && \
    git -C "$DOTFILES_DIR" reset --hard "origin/$BRANCH" || \
    { echo "  ⚠️  git fetch failed — continuing with local version"; }

    # Restore kde package if we saved it
    if [[ -n "${_kde_tmp:-}" ]]; then
        cp -r "$_kde_tmp/." "$DOTFILES_DIR/packages/kde/"
        rm -rf "$_kde_tmp"
    fi

    NEW_HASH=$(git -C "$DOTFILES_DIR" rev-parse HEAD)
    if [[ "$OLD_HASH" != "$NEW_HASH" ]]; then
        echo "  ✅ Updated — restarting script..."
        exec "$DOTFILES_DIR/install.sh" "$@"
    fi
    echo "  ✅ Up to date"
    echo ""
fi

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

SELECTIONS_FILE="$HOME/.local/share/dotfiles/selections.conf"

select_packages() {
    local file=$1 title=$2 key=$3
    local prev=""
    [[ -f "$SELECTIONS_FILE" ]] && prev=$(grep "^${key}=" "$SELECTIONS_FILE" 2>/dev/null | cut -d= -f2-)

    local items=()
    while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        local state="ON"
        if [[ -n "$prev" ]]; then
            echo "$prev" | grep -qw "$pkg" && state="ON" || state="OFF"
        fi
        items+=("$pkg" "" "$state")
    done < "$file"

    local colors='
        root=black,black
        window=white,black
        border=blue,black
        title=cyan,black
        listbox=white,black
        actlistbox=brightwhite,blue
        checkbox=cyan,black
        actcheckbox=brightwhite,blue
        button=black,blue
        actbutton=brightwhite,blue
        textbox=white,black
        acttextbox=white,black
        label=white,black
        scrollbar=black,black
        shadow=black,black
    '
    local result
    result=$(LANG=C NEWT_COLORS="$colors" whiptail --title "$title" --checklist \
        "Space = toggle, Enter = install selected:" 20 55 12 \
        "${items[@]}" 3>&1 1>&2 2>&3) || return 1

    # Save selections for next run
    local clean
    clean=$(echo "$result" | tr -d '"')
    mkdir -p "$(dirname "$SELECTIONS_FILE")"
    if grep -q "^${key}=" "$SELECTIONS_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${clean}|" "$SELECTIONS_FILE"
    else
        echo "${key}=${clean}" >> "$SELECTIONS_FILE"
    fi

    echo "$result"
}

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

# ── Install whiptail if needed ───────────────────────────────────────────────
if ! command -v whiptail &> /dev/null; then
    [[ "$OS" == "arch" ]] && $SUDO pacman -S --needed --noconfirm libnewt || install_ubuntu_pkgs whiptail
fi

# ── Install terminal programs ────────────────────────────────────────────────
echo ""
echo "--- Selecting terminal programs ---"

if [[ "$OS" == "arch" ]]; then
    SELECTED=$(select_packages "$DOTFILES_DIR/programs/terminal.txt" "Terminal packages" "terminal") || { echo "Installation cancelled."; exit 0; }
    SELECTED=$(echo "$SELECTED" | tr -d '"')
    PKGS=$(echo "$SELECTED" | grep -v '^paru$' | tr '\n' ' ')
    [[ -n "$PKGS" ]] && paru -S --needed --noconfirm $PKGS

else
    INSTALLED=()
    FAILED=()

    _mark() { command -v "$1" &>/dev/null && INSTALLED+=("$1") || FAILED+=("$1"); }

    UBUNTU_SELECTED=$(select_packages "$DOTFILES_DIR/programs/terminal.txt" "Terminal packages" "terminal") || { echo "Installation cancelled."; exit 0; }
    UBUNTU_SELECTED=$(echo "$UBUNTU_SELECTED" | tr -d '"')
    _sel() { echo "$UBUNTU_SELECTED" | grep -qw "$1"; }

    # Locale (needed for btop and other UTF-8 tools)
    $SUDO locale-gen en_US.UTF-8 || true
    echo 'LANG=en_US.UTF-8' | $SUDO tee /etc/default/locale > /dev/null || true

    # Ubuntu — apt packages
    APT_PKGS=()
    _sel fish       && APT_PKGS+=(fish)
    _sel bat        && APT_PKGS+=(bat)
    _sel btop       && APT_PKGS+=(btop)
    _sel ripgrep    && APT_PKGS+=(ripgrep)
    _sel duf        && APT_PKGS+=(duf)
    _sel mc         && APT_PKGS+=(mc)
    _sel nmap       && APT_PKGS+=(nmap)
    _sel macchanger && APT_PKGS+=(macchanger)
    _sel wipe       && APT_PKGS+=(wipe)
    _sel glances    && APT_PKGS+=(glances)
    [[ ${#APT_PKGS[@]} -gt 0 ]] && install_ubuntu_pkgs "${APT_PKGS[@]}" || true

    # fish PPA fallback
    if _sel fish && ! command -v fish &> /dev/null; then
        $SUDO apt-add-repository -y ppa:fish-shell/release-3
        $SUDO apt-get update
        install_ubuntu_pkgs fish || true
    fi

    # micro — official binary installer
    if _sel micro && ! command -v micro &> /dev/null; then
        cd /tmp && curl -fsSL https://getmic.ro | bash && $SUDO mv micro /usr/local/bin/ || true
        cd "$DOTFILES_DIR"
    fi

    # GitHub CLI
    if _sel github-cli && ! command -v gh &> /dev/null; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        $SUDO apt-get update -q && install_ubuntu_pkgs gh || true
    fi

    # Docker
    if _sel docker && ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | $SUDO bash || true
        [[ -n "$USER" && "$USER" != "root" ]] && $SUDO usermod -aG docker "$USER" || true
    fi

    # eza
    if _sel eza && ! command -v eza &> /dev/null; then
        EZA_URL=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest \
            | grep "browser_download_url.*eza_x86_64-unknown-linux-musl.tar.gz" \
            | cut -d '"' -f 4)
        [[ -n "$EZA_URL" ]] && curl -fsSL "$EZA_URL" | tar xz -C /tmp && $SUDO mv /tmp/eza /usr/local/bin/ || true
    fi

    # lazygit
    if _sel lazygit && ! command -v lazygit &> /dev/null; then
        LG_VER=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')
        if [[ -n "$LG_VER" ]]; then
            curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz" | tar xz -C /tmp && $SUDO mv /tmp/lazygit /usr/local/bin/ || true
        fi
    fi

    # lazydocker
    if _sel lazydocker && ! command -v lazydocker &> /dev/null; then
        LD_URL=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest \
            | grep "browser_download_url.*Linux_x86_64.tar.gz" \
            | cut -d '"' -f 4)
        [[ -n "$LD_URL" ]] && curl -fsSL "$LD_URL" | tar xz -C /tmp && $SUDO mv /tmp/lazydocker /usr/local/bin/ || true
    fi

    # yazi
    if _sel yazi && ! command -v yazi &> /dev/null; then
        YAZI_URL=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest \
            | grep "browser_download_url.*yazi-x86_64-unknown-linux-musl.zip" \
            | cut -d '"' -f 4)
        if [[ -n "$YAZI_URL" ]]; then
            curl -fsSL "$YAZI_URL" -o /tmp/yazi.zip && unzip -q /tmp/yazi.zip -d /tmp/yazi_extract || true
            $SUDO mv /tmp/yazi_extract/*/yazi /usr/local/bin/ 2>/dev/null || true
        fi
    fi

    # fastfetch
    if _sel fastfetch && ! command -v fastfetch &> /dev/null; then
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
    echo "--- Selecting desktop programs ---"
    SELECTED=$(select_packages "$DOTFILES_DIR/programs/desktop.txt" "Desktop packages" "desktop") || { echo "Installation cancelled."; exit 0; }
    SELECTED=$(echo "$SELECTED" | tr -d '"')
    for pkg in $SELECTED; do
        paru -S --needed --noconfirm "$pkg" || echo "  ⚠️  $pkg (failed — install manually)"
    done

    # Brave extensions + visual policy
    if echo "$SELECTED" | grep -qw "brave-bin" || command -v brave &>/dev/null || command -v brave-browser &>/dev/null; then
        $SUDO mkdir -p /etc/brave/policies/managed
        $SUDO cp "$DOTFILES_DIR/programs/brave-extensions.json" /etc/brave/policies/managed/extensions.json
        $SUDO cp "$DOTFILES_DIR/programs/brave-policy.json" /etc/brave/policies/managed/policy.json
        echo "  ✅ Brave policy applied (extensions + visual settings)"
        echo "  ℹ️  NTP background and shortcuts — enable Brave Sync to transfer those"
    fi

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

if $APPLY_STOW; then
    echo "--- Applying stow packages ---"
    STOW_CMD="stow -d $DOTFILES_DIR/packages -t $HOME"

    # Remove files that fisher/tools create before stow can symlink them
    rm -f "$HOME/.config/fish/fish_variables"

    TERMINAL_PKGS="fish git micro bat mc scripts systemd"
    for pkg in $TERMINAL_PKGS; do
        $STOW_CMD "$pkg" && echo "  ✅ $pkg" || echo "  ⚠️  $pkg (conflict — resolve manually)"
    done

    if [[ "$MODE" == "desktop" ]]; then
        # Remove KDE default files that conflict with stow
        rm -f "$HOME/.config/autostart/remmina-applet.desktop" "$HOME/.config/dolphinrc"
        rm -rf "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
        rm -f "$HOME/.config/gtkrc" "$HOME/.config/gtkrc-2.0"
        rm -f "$HOME/.config/kactivitymanagerdrc" "$HOME/.config/kcminputrc"
        rm -rf "$HOME/.config/kdedefaults"
        rm -f "$HOME/.config/kdeglobals" "$HOME/.config/kglobalshortcutsrc" "$HOME/.config/konsolerc"
        rm -f "$HOME/.config/kscreenlockerrc" "$HOME/.config/kwinrc"
        rm -f "$HOME/.config/plasma-localerc"
        rm -f "$HOME/.config/plasmanotifyrc" "$HOME/.config/plasmashellrc" "$HOME/.config/powerdevilrc"
        rm -f "$HOME/.local/share/plasma-systemmonitor/overview.page" "$HOME/.local/share/plasma-systemmonitor/processes.page"

        DESKTOP_PKGS="kitty kde easyeffects openrgb color-schemes aurorae plasma-systemmonitor plasma-themes"
        for pkg in $DESKTOP_PKGS; do
            $STOW_CMD "$pkg" && echo "  ✅ $pkg" || echo "  ⚠️  $pkg (conflict — resolve manually)"
        done

        # Set kitty as default terminal
        if command -v kitty &> /dev/null; then
            kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty || true
            kwriteconfig6 --file kdeglobals --group General --key TerminalService kitty.desktop || true
            echo "  ✅ kitty set as default terminal"
        fi

    fi

    # Mark as installed
    mkdir -p "$(dirname "$MARKER")"
    touch "$MARKER"
else
    echo "  ⏭  Stow skipped — configs unchanged"
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
    chsh -s "$FISH_PATH" && echo "  ✅ Default shell set to fish (re-login to apply)" || echo "  ⚠️  chsh failed — run manually: chsh -s $FISH_PATH"
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
