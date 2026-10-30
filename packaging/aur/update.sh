#!/usr/bin/env bash
# Bump PKGBUILD to an Empryo release: update.sh [version]. Without a version,
# reads the latest one from dl.empryo.com/latest.json. Must run as non-root.
set -euo pipefail
cd "$(dirname "$0")"

base=https://dl.empryo.com
new=${1:-$(curl -fsSL "$base/latest.json" | jq -r .version)}
[[ $new =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$ ]] || { echo "invalid version: '$new'" >&2; exit 1; }

cur=$(sed -n 's/^_ver=//p' PKGBUILD)
if [[ $new == "$cur" ]]; then
  echo "already at $cur"
  exit 0
fi
if (( $(vercmp "${new//-/}" "${cur//-/}") < 0 )); then
  echo "refusing to downgrade $cur -> $new" >&2
  exit 1
fi

sed -i -e "s/^_ver=.*/_ver=$new/" -e 's/^pkgrel=.*/pkgrel=1/' PKGBUILD
updpkgsums

sums=$(curl -fsSL "$base/v$new/SHA256SUMS.txt")
# shellcheck source=/dev/null
source PKGBUILD
for a in x64:x86_64 aarch64:aarch64; do
  file="Empryo-$new-linux-${a%%:*}.pkg.tar.zst"
  want=$(awk -v f="$file" '$2 == f || $2 == "*" f { print $1 }' <<<"$sums")
  declare -n got="sha256sums_${a#*:}"
  if [[ -z $want || $want != "${got[0]}" ]]; then
    echo "checksum mismatch for $file: PKGBUILD=${got[0]} SHA256SUMS=${want:-missing}" >&2
    exit 1
  fi
  unset -n got
done

makepkg --printsrcinfo > .SRCINFO
echo "bumped $cur -> $new"
