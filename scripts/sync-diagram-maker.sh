#!/usr/bin/env bash
# sync-diagram-maker.sh -- bring the bundled diagram-maker up to its main, best-effort.
#
#   scripts/sync-diagram-maker.sh
#
# Runs `git submodule update --init --remote diagram-maker` in this skill's own
# checkout, so the next figure is drawn by diagram-maker's latest main even when
# this repo's pin lags behind it. scripts/build.sh calls it before it renders a
# document's figures.
#
# Best-effort by design, and quiet: offline, a git error, a fetch slower than
# PMB_SYNC_TIMEOUT seconds (default 30), or a skill that is not a git checkout
# of its own (a copy vendored inside another repo, whose submodules are not this
# script's to move) is a no-op, and the copy on disk is used. PMB_SYNC=0 skips
# it. Always exits 0: a sync never fails a build.
set -u

[ "${PMB_SYNC:-1}" = 0 ] && exit 0
command -v git >/dev/null 2>&1 || exit 0

skill="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)" || exit 0
top="$(git -C "$skill" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ "$top" = "$skill" ] || exit 0
[ -f "$skill/.gitmodules" ] || exit 0

GIT_TERMINAL_PROMPT=0 timeout "${PMB_SYNC_TIMEOUT:-30}" \
  git -C "$skill" submodule update --init --remote --quiet diagram-maker >/dev/null 2>&1 || true
exit 0
