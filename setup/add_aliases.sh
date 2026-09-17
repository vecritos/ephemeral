#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TARGET_RC="${1:-$HOME/.bashrc}"

usage() {
    echo "Usage: $0 [bashrc-file]"
    echo "Adds helpful aliases for the ephemeral repository scripts to your shell config."
    echo "Example: $0 ~/.bashrc"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ ! -f "$TARGET_RC" ]]; then
    touch "$TARGET_RC"
fi

declare -A ALIASES=(
    [dev-install]="$REPO_ROOT/setup/installation.sh"
    [dev-health]="$REPO_ROOT/setup/healthcheck.sh"
    [dev-firewall]="$REPO_ROOT/setup/nftables.sh"
    [dev-user]="$REPO_ROOT/setup/secure_git_nano_user.sh"
    [seed-key]="$REPO_ROOT/setup/seed_to_private_key.sh"
    [git-identity]="$REPO_ROOT/sh/git_identities/ephemeral_git_identities.sh"
    [git-clone]="$REPO_ROOT/sh/git_identities/git_clone_repositories_useraccount.sh"
    [git-user]="$REPO_ROOT/sh/git_identities/clean_and_safe_gituser.sh"
    [git-lock]="$REPO_ROOT/sh/git_identities/locked_down_development_account.sh"
    [git-lock-repo]="$REPO_ROOT/sh/git_identities/ssh_locked_git_repository.sh"
    [luks-create]="$REPO_ROOT/sh/hardware_encryption/create_luks_image.sh"
    [luks-open]="$REPO_ROOT/sh/hardware_encryption/open_luks_image.sh"
    [luks-demo]="$REPO_ROOT/sh/hardware_encryption/encrypted_partitions.sh"
    [security-scan]="$REPO_ROOT/security/security_scan.sh"
    [repo-aliases]="$REPO_ROOT/setup/add_aliases.sh"
)

ALIAS_BLOCK="# ephemeral repo aliases"
for alias_name in "${!ALIASES[@]}"; do
    script_path="${ALIASES[$alias_name]}"
    if [[ -f "$script_path" ]]; then
        ALIAS_BLOCK+=$'\n'
        ALIAS_BLOCK+="alias ${alias_name}='bash \"${script_path}\"'"
    fi
done

if grep -Fq '# ephemeral repo aliases' "$TARGET_RC"; then
    echo "Aliases already exist in $TARGET_RC"
    exit 0
fi

printf '\n%s\n' "$ALIAS_BLOCK" >> "$TARGET_RC"

echo "Aliases added to $TARGET_RC"
echo "Reload your shell with: source $TARGET_RC"
