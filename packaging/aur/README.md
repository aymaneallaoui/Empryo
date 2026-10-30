# empryo-bin (AUR)

`PKGBUILD` repackages the official Empryo desktop builds from `dl.empryo.com` for x86_64 and aarch64.

## Automation

`.github/workflows/aur.yml` keeps this folder in sync with Empryo releases:

1. Every 6 hours (or on manual dispatch) it reads the current version from `https://dl.empryo.com/latest.json`. It exits without changes if `_ver` already matches.
2. On a new version, `update.sh` sets `_ver`, resets `pkgrel=1`, runs `updpkgsums` and checks both hashes against `https://dl.empryo.com/v<ver>/SHA256SUMS.txt`. It fails on a mismatch, then regenerates `.SRCINFO`.
3. The x86_64 package is built in an `archlinux:base-devel` container, then a pull request is opened on the `aur/empryo-bin-update` branch.
4. When a change to `PKGBUILD` or `.SRCINFO` lands on `main`, the workflow checks that `.SRCINFO` is current and pushes both files to `ssh://aur@aur.archlinux.org/empryo-bin.git` (master).

The bump PR step needs "Allow GitHub Actions to create and approve pull requests" enabled under Settings > Actions > General, otherwise it fails.

The bump PR is opened with `GITHUB_TOKEN`, so GitHub does not start other workflows on it. If required checks show "waiting for status", close and reopen the PR to trigger them.

## AUR_SSH_PRIVATE_KEY

Repository secret holding a private SSH key whose public half is registered on the AUR account that maintains `empryo-bin`. Without it, the AUR push is skipped with a notice and the rest of the workflow still runs.

## Running it manually

- GitHub: Actions → aur → Run workflow. Leave `version` empty for the latest release, or pin one such as `3.12.1-beta`.
- Locally, as a non-root user on Arch with `pacman-contrib` and `jq`: `packaging/aur/update.sh [version]`.
