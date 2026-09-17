#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Secure developer account bootstrap
# Creates a locked-down local user with access to git and nano
# only, while removing sudo privileges and tightening home perms.
# ============================================================

if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

USERNAME="ephemeral"

if id "$USERNAME" >/dev/null 2>&1; then
    echo "User '$USERNAME' already exists. Reusing the account."
else
    useradd --create-home --shell /bin/rbash "$USERNAME"
    echo "Created user '$USERNAME'."
fi

passwd "$USERNAME"

# Remove privileged access and block sudo-style escalation.
for group in sudo wheel adm; do
    gpasswd -d "$USERNAME" "$group" 2>/dev/null || true
    deluser "$USERNAME" "$group" 2>/dev/null || true
done

if [[ -f "/etc/sudoers.d/$USERNAME" ]]; then
    rm -f "/etc/sudoers.d/$USERNAME"
fi

# Ensure permissions are tight.
HOME_DIR="/home/$USERNAME"
chmod 700 "$HOME_DIR"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR"

# Build a restricted PATH containing only the commands we want to allow.
mkdir -p "$HOME_DIR/bin"
chmod 700 "$HOME_DIR/bin"
chown "$USERNAME:$USERNAME" "$HOME_DIR/bin"

# Only allow git and nano for a constrained day-to-day workflow.
for cmd in git nano; do
    if command -v "$cmd" >/dev/null 2>&1; then
        ln -sf "$(command -v "$cmd")" "$HOME_DIR/bin/$cmd"
    else
        echo "Warning: '$cmd' was not found in PATH; skipping symlink creation." >&2
    fi
done

# Keep the user's shell restricted but still usable for git + nano.
cat > "$HOME_DIR/.bash_profile" <<EOF
export PATH="$HOME/bin"
export SHELL=/bin/rbash
umask 077
EOF
chmod 600 "$HOME_DIR/.bash_profile"
chown "$USERNAME:$USERNAME" "$HOME_DIR/.bash_profile"

# Lock editor config down in a minimal secure mode.
cat > "$HOME_DIR/.nanorc" <<'EOF'
set tabsize 4
set multibuffer
set nowrap
EOF
chmod 600 "$HOME_DIR/.nanorc"
chown "$USERNAME:$USERNAME" "$HOME_DIR/.nanorc"

# Pre-create a safe Git config that still allows work to be tracked.
cat > "$HOME_DIR/.gitconfig" <<'EOF'
[user]
    name = Empheral User
    email = ephemeral@ephemeral.ephemeral
[core]
    editor = nano
    autocrlf = input
[pull]
    rebase = false
EOF
chmod 600 "$HOME_DIR/.gitconfig"
chown "$USERNAME:$USERNAME" "$HOME_DIR/.gitconfig"

# Optional: disable password-based login if SSH is used by policy.
# This preserves the existing system policy and avoids locking the user out accidentally.

echo "------------------------------------------------------------"
echo "Created restricted user: $USERNAME"
echo "Allowed commands: git, nano"
echo "Sudo access: disabled"
echo "Shell: /bin/rbash"
echo "Home directory permissions: 700"
echo "Git config and nano config are installed in the user's home."
echo "------------------------------------------------------------"
