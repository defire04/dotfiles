function fish_title
    set -l cwd (prompt_pwd --dir-length 3)
    if set -q SSH_CONNECTION
        echo "[$(hostname -s)] $cwd"
    else
        echo $cwd
    end
end
