#!/usr/bin/env bash
set -Eeuo pipefail

REPO="zarzorr69/ryoku-we"
BRANCH="${RYOKU_WE_BRANCH:-main}"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
TMP="$(mktemp -t ryoku-we-bootstrap.XXXXXX)"

cleanup() {
    rm -f "$TMP"
}
trap cleanup EXIT

echo "==> Downloading Ryoku-WE bootstrap..."
curl -fL --retry 3 --retry-delay 1 \
    "${RAW}/bootstrap.sh" \
    -o "$TMP"

echo "==> Verifying bootstrap syntax..."
bash -n "$TMP"

echo "==> Starting Ryoku-WE dependency bootstrap..."
bash "$TMP"
