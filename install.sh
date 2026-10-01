#!/usr/bin/env bash
set -euo pipefail

REPO="zarzorr69/ryoku-we"
BRANCH="${RYOKU_WE_BRANCH:-main}"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
TMP="$(mktemp -t Ryoku-WE.XXXXXX)"

cleanup() {
    rm -f "$TMP"
}
trap cleanup EXIT

echo "==> Downloading Ryoku-WE..."
curl -fsSL "${RAW}/Ryoku-WE" -o "$TMP"
chmod +x "$TMP"

echo "==> Installing / repairing Ryoku-WE..."
"$TMP" install

echo
echo "Ryoku-WE installed."
echo "Launch it with:"
echo "  Ryoku-WE"
echo "or:"
echo "  ryoku-we"
