#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <32-byte-seed-hex> [output-dir]"
    echo ""
    echo "Creates an Ed25519 private key deterministically from a 32-byte seed."
    echo "The seed must be exactly 64 hexadecimal characters (32 bytes)."
    echo "The script writes:"
    echo "  - private_key.pem"
    echo "  - public_key.pem"
    echo "  - public_key.pub"
    exit 1
}

if [[ $# -lt 1 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

SEED_HEX="${1}"
OUTPUT_DIR="${2:-$(pwd)}"

if ! [[ "$SEED_HEX" =~ ^[0-9a-fA-F]{64}$ ]]; then
    echo "Error: seed must be exactly 64 hexadecimal characters (32 bytes)." >&2
    usage
fi

mkdir -p "$OUTPUT_DIR"

python3 - <<'PY' "$SEED_HEX" "$OUTPUT_DIR"
import pathlib
import sys

seed_hex = sys.argv[1]
output_dir = pathlib.Path(sys.argv[2])

try:
    import cryptography
except ModuleNotFoundError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", "cryptography"], stdout=subprocess.DEVNULL)
    import cryptography

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

seed_bytes = bytes.fromhex(seed_hex)
if len(seed_bytes) != 32:
    raise ValueError("Seed must be exactly 32 bytes.")

private_key = Ed25519PrivateKey.from_private_bytes(seed_bytes)
public_key = private_key.public_key()

private_pem = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption(),
)
public_pem = public_key.public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo,
)
public_ssh = public_key.public_bytes(
    encoding=serialization.Encoding.OpenSSH,
    format=serialization.PublicFormat.OpenSSH,
)

(output_dir / "private_key.pem").write_bytes(private_pem)
(output_dir / "public_key.pem").write_bytes(public_pem)
(output_dir / "public_key.pub").write_bytes(public_ssh + b"\n")

print(f"Generated keys in: {output_dir}")
print(f"Private key: {output_dir / 'private_key.pem'}")
print(f"Public key:  {output_dir / 'public_key.pub'}")
PY
