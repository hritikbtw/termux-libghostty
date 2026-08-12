#!/usr/bin/env bash
# Preflight: verify every source tarball/git repo needed by the bootstrap
# dependency closure is reachable, BEFORE the expensive multi-arch builds.
# Fails fast (a few minutes) instead of after an hour of building.
set -euo pipefail
cd "$(dirname "$0")/.."

pkgdir() {
  for d in packages root-packages x11-packages; do
    if [ -f "$d/$1/build.sh" ]; then
      printf '%s' "$d/$1"
      return 0
    fi
  done
  return 1
}

# Bootstrap package set (must mirror scripts/build-bootstraps.sh).
queue=(apt bash libbz2 command-not-found proot coreutils dash diffutils findutils \
       gawk grep gzip less procps psmisc sed tar termux-core termux-exec \
       termux-keyring termux-tools util-linux ed debianutils dos2unix inetutils \
       lsof nano net-tools patch unzip)

declare -A seen
urls=()
unresolved=0
while [ ${#queue[@]} -gt 0 ]; do
  p="${queue[0]}"
  queue=("${queue[@]:1}")
  [ -n "${seen[$p]:-}" ] && continue
  seen[$p]=1
  dir="$(pkgdir "$p")" || continue
  deps="$(sed -n 's/^TERMUX_PKG_DEPENDS="\([^"]*\)"/\1/p' "$dir/build.sh" | head -1)"
  for d in $deps; do
    d="${d%%:*}"
    [ -z "${seen[$d]:-}" ] && queue+=("$d")
  done
  ver="$(sed -n 's/^TERMUX_PKG_VERSION="\([^"]*\)"/\1/p' "$dir/build.sh" | head -1)"
  srcs="$(sed -n 's/^TERMUX_PKG_SRCURL="\([^"]*\)"/\1/p' "$dir/build.sh" | head -1)"
  for u in $srcs; do
    [ -z "$u" ] && continue
    u="${u//\$\{TERMUX_PKG_VERSION\}/$ver}"
    u="${u//\$TERMUX_PKG_VERSION/$ver}"
    if [[ "$u" == *'${'* ]]; then
      echo "  (skip, unresolved var: $u)"
      unresolved=$((unresolved + 1))
      continue
    fi
    urls+=("$u")
  done
done

echo "Checking ${#urls[@]} sources across ${#seen[@]} bootstrap dependency packages (${unresolved} unresolved skipped)"
fail=0
for u in "${urls[@]}"; do
  if [[ "$u" == git+* ]]; then
    repo="${u:4}"
    printf '  git  %s\n' "$repo"
    if ! timeout 60 git ls-remote --heads "$repo" >/dev/null 2>&1; then
      echo "  FAILED to reach $repo"
      fail=1
    fi
    continue
  fi
  printf '  %s\n' "$u"
  if ! curl --fail --location --retry 5 --retry-all-errors --no-progress-meter \
       --connect-timeout 20 --max-time 120 --output /dev/null "$u"; then
    echo "  FAILED to download $u"
    fail=1
  fi
done
echo "Preflight $([ $fail -eq 0 ] && echo PASSED || echo FAILED)"
exit "$fail"
