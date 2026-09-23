#!/usr/bin/env bash
# install.sh -- bring the installed skill up to main, with diagram-maker at its
# latest main.
#
#   ./install.sh
#
# cc-land runs it from ~/dev/pdf-material-builder after every landing and on
# catch-up. The installed skill is a clone of its own at
# ~/.claude/skills/pdf-material-builder (PMB_SKILL_DIR overrides it, for tests),
# never a symlink into a checkout, and this script never makes it one. In that
# clone it:
#   1. fetches origin and fast-forwards main to origin/main;
#   2. runs `git submodule sync` and `git submodule update --init --remote`, so
#      the installed copy carries diagram-maker's latest main even when this
#      repo's pin lags behind it.
# Running it again with nothing new changes nothing.
#
# Exit 0  installed, or nothing to install into: the directory is missing, is a
#         symlink, or is not a clone of this repo's origin. It says which, and
#         touches nothing.
# Exit 1  the clone is there but could not be brought up to date: the fetch
#         failed, it is not on main, a local commit or change is in the way, or
#         the submodule update failed. It says which; main is left where it was.
set -uo pipefail

src="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
dst="${PMB_SKILL_DIR:-$HOME/.claude/skills/pdf-material-builder}"
branch=main
export GIT_TERMINAL_PROMPT=0

say() { printf 'install.sh: %s\n' "$1"; }
die() { printf 'install.sh: %s\n' "$1" >&2; exit 1; }

# One spelling per repository: scheme, user, trailing .git and / dropped, so
# git@github.com:o/r.git and https://github.com/o/r are the same origin.
norm() {
  local u="${1%/}"; u="${u%.git}"
  u="${u#https://}"; u="${u#http://}"; u="${u#ssh://}"; u="${u#git://}"
  u="${u#*@}"
  printf '%s\n' "${u/://}"
}

if [ -L "$dst" ]; then
  say "$dst is a symlink, not a clone; left alone (the installed skill is a clone of its own, never a link into a checkout)"
  exit 0
fi
if [ ! -e "$dst" ]; then
  say "no installed skill at $dst; nothing to update (clone it there to install)"
  exit 0
fi
dst="$(cd -P "$dst" && pwd -P)" || die "cannot enter $dst"
top="$(git -C "$dst" rev-parse --show-toplevel 2>/dev/null || true)"
if [ "$top" != "$dst" ]; then
  say "$dst is not a git clone of its own; left alone"
  exit 0
fi
want="$(git -C "$src" remote get-url origin 2>/dev/null || true)"
have="$(git -C "$dst" remote get-url origin 2>/dev/null || true)"
if [ -z "$want" ] || [ -z "$have" ] || [ "$(norm "$want")" != "$(norm "$have")" ]; then
  say "$dst is a clone of '${have:-no origin}', not of this repo's origin '${want:-none}'; left alone"
  exit 0
fi

cur="$(git -C "$dst" symbolic-ref --short -q HEAD || true)"
[ "$cur" = "$branch" ] || die "$dst is on '${cur:-a detached HEAD}', not $branch; switch it back to $branch and run again"
out=$(timeout 300 git -C "$dst" fetch --quiet origin "$branch" 2>&1) \
  || die "fetching origin in $dst failed: ${out:-timed out}"
out=$(git -C "$dst" merge --ff-only --quiet "origin/$branch" 2>&1) \
  || die "cannot fast-forward $dst to origin/$branch (a local commit or change is in the way): $(printf '%s' "$out" | tail -1)"

if [ -f "$dst/.gitmodules" ]; then
  out=$(git -C "$dst" submodule sync --quiet 2>&1) || die "git submodule sync in $dst failed: $out"
  out=$(timeout 600 git -C "$dst" submodule update --init --remote --quiet 2>&1) \
    || die "git submodule update --init --remote in $dst failed: $(printf '%s' "$out" | tail -1)"
fi

head="$(git -C "$dst" rev-parse --short HEAD)"
dm="$(git -C "$dst/diagram-maker" rev-parse --short HEAD 2>/dev/null || echo none)"
say "installed $head at $dst; diagram-maker at $dm"
