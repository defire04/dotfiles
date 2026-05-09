if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
else
    set -gx LANG en_US.UTF-8
end

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# XDG Base Directories
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_STATE_HOME $HOME/.local/state
set -gx XDG_CACHE_HOME $HOME/.cache

# XDG cleanup
set -gx CARGO_HOME $XDG_DATA_HOME/cargo
set -gx CUDA_CACHE_PATH $XDG_CACHE_HOME/nv
set -gx GTK2_RC_FILES $XDG_CONFIG_HOME/gtk-2.0/gtkrc
set -gx NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/npmrc
set -gx WINEPREFIX $XDG_DATA_HOME/wine
set -gx DOCKER_CONFIG $XDG_CONFIG_HOME/docker
set -gx LESSHISTFILE $XDG_STATE_HOME/less/history
set -gx NODE_REPL_HISTORY $XDG_STATE_HOME/node/history
set -gx PYTHON_HISTORY $XDG_STATE_HOME/python/history

# Editor aliases
alias m='sudo -E micro'
set -gx EDITOR micro
set -gx VISUAL micro

# Other aliases
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'

# Better CLI tools
alias cat='bat --style=plain'
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'

fish_add_path $XDG_DATA_HOME/npm/bin
