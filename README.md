# ephemeral

A small repository of shell utilities for secure local system setup, hardened Git workflows, and encrypted storage on Linux systems.

This project is intended to help you bootstrap and manage a safer personal environment without depending on heavy infrastructure or a complex framework. It includes scripts for:

- setting up a minimal Linux developer environment
- hardening local git and SSH identity workflows
- creating restricted users for safe, low-privilege work
- configuring firewall defaults and health checks
- creating and mounting encrypted LUKS-backed files
- running security scans and quick operational checks

---

## Repository structure

- setup/
  - installation.sh: routine developer environment bootstrap
  - healthcheck.sh: live-system security and firmware health checks
  - nftables.sh: default-deny nftables firewall setup
  - secure_git_nano_user.sh: create a restricted user with Git and Nano access
  - add_aliases.sh: install helpful shell aliases for the repo

- sh/
  - git_identities/: scripts for multi-identity Git, restricted git users, and locked-down repo access
  - hardware_encryption/: scripts for creating encrypted .pac images and mounting them

- security/
  - security_scan.sh: ClamAV, rkhunter, and chkrootkit scan wrapper

- homeserver.md
  - reference doc for home server hardening and SSH/security configuration

---

## Quick start

From the repository root:

```bash
bash setup/add_aliases.sh
source ~/.bashrc
```

This installs useful aliases such as:

- dev-install
- dev-health
- dev-firewall
- dev-user
- git-identity
- git-clone
- git-user
- git-lock
- luks-create
- luks-open
- security-scan

You can then run commands like:

```bash
dev-install
dev-health
dev-firewall
dev-user
git-identity
luks-create
luks-open
security-scan
```

---

## Setup commands and when to use them

### Developer environment

```bash
bash setup/installation.sh
```

Installs the default base development tooling for a Linux workstation, including Git, Python, utilities, and common developer helpers.

### Health and firmware checks

```bash
bash setup/healthcheck.sh
```

Runs a live-system hygiene and firmware check for secure boot, EFI, TPM, firmware status, and active services.

### Firewall

```bash
bash setup/nftables.sh
```

Applies a default-deny nftables policy with selective outbound access for DNS, browser traffic, and SSH.

### Restricted user for Git and Nano

```bash
sudo bash setup/secure_git_nano_user.sh
```

Creates a new local user named ephemeral with a prompted password, restricted shell, Git identity configured to:

- Name: Empheral User
- Email: ephemeral@ephemeral.ephemeral

and allows access to Git and Nano only.

---

## Git identity workflows

The scripts under sh/git_identities are designed for managed identity separation and safer Git use.

Common examples:

```bash
bash sh/git_identities/ephemeral_git_identities.sh
bash sh/git_identities/git_clone_repositories_useraccount.sh
bash sh/git_identities/clean_and_safe_gituser.sh
bash sh/git_identities/locked_down_development_account.sh
bash sh/git_identities/ssh_locked_git_repository.sh
```

These cover:

- per-persona SSH keys and Git config isolation
- safe repo cloning patterns
- hardened local Git users
- restricted developer account setup
- locked-down Git-over-SSH repository handling

---

## Encrypted storage workflows

The scripts under sh/hardware_encryption create and mount encrypted filesystem images.

### Create a new encrypted image

```bash
sudo bash sh/hardware_encryption/create_luks_image.sh
```

This prompts for:

- target image path
- size in GB
- LUKS passphrase

It creates a local .pac image file, encrypts it with LUKS, formats it as ext4, and closes it when done.

### Open and mount an encrypted image

```bash
sudo bash sh/hardware_encryption/open_luks_image.sh
```

This prompts for:

- the .pac image location
- the desired mount path
- the LUKS passphrase

It opens the encrypted device and mounts the filesystem at the chosen directory.

---

## Security scanning

```bash
bash security/security_scan.sh
```

Runs a basic host scan using ClamAV, rkhunter, and chkrootkit, then emails the report to the configured recipient.

---

## Security model

The repository is intended for local security-focused automation and personal infrastructure setup. It assumes:

- you are managing a Linux machine you control
- you want strict local separation of identities and privileges
- you want operational scripts that are easy to audit and adjust

The scripts are intentionally lightweight and readable so they can be adapted to your own environment without needing a large deployment framework.

---

## Recommended usage order

For a new environment, the common flow is:

1. Run the base developer setup:
   ```bash
   bash setup/installation.sh
   ```
2. Add repo aliases:
   ```bash
   bash setup/add_aliases.sh
   source ~/.bashrc
   ```
3. Apply a firewall if needed:
   ```bash
   dev-firewall
   ```
4. Create a restricted Git/Nano user if desired:
   ```bash
   sudo dev-user
   ```
5. Run security checks as needed:
   ```bash
   security-scan
   ```

This gives you a small but practical hardened workstation workflow without overengineering the system.
