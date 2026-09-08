#!/usr/bin/env bash
# Voice drift check.
#
# lesson-builder's references/teaching-communication.md is the CANONICAL
# discourse spec. This repo carries a copy so the skill works standalone; the
# copy must stay faithful to the original.
#
# The copy is not byte-identical: this repo is ASCII-only (see
# scripts/style-check.sh), so the copy is the source put through one fixed
# transliteration table plus a provenance banner. Drift therefore means
# "transliterated source != copy", and the same table produces the copy on
# --refresh, so check and refresh can never disagree.
#
# Usage:
#   scripts/voice-drift.sh [--source DIR] [--refresh]
#   PMB_LESSON_BUILDER=/path/to/lesson-builder scripts/voice-drift.sh
#
# Source resolution: --source, else $PMB_LESSON_BUILDER, else ../lesson-builder
# relative to this repo.
#
# Exit: 0 in sync (or refreshed), 1 drift, 2 bad usage, 3 source not found.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="${PMB_LESSON_BUILDER:-$REPO/../lesson-builder}"
MODE=check

while [ $# -gt 0 ]; do
  case "$1" in
    --source) SOURCE_DIR="${2:?--source needs a path}"; shift 2 ;;
    --refresh) MODE=refresh; shift ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "voice-drift: unknown argument: $1" >&2; exit 2 ;;
  esac
done

SRC="$SOURCE_DIR/references/teaching-communication.md"
if [ ! -f "$SRC" ]; then
  echo "voice-drift: canonical spec not found at $SRC"
  exit 3
fi

python3 - "$SRC" "$REPO/references/teaching-communication.md" "$MODE" <<'PYEOF'
import sys, difflib, unicodedata

src_path, copy_path, mode = sys.argv[1], sys.argv[2], sys.argv[3]

# The one transliteration table. Every non-ASCII character the canonical spec
# uses must appear here; an unmapped one stops a refresh rather than writing a
# copy that scripts/style-check.sh would then reject.
TABLE = {
    '\u2014': '--',   '\u2013': '-',    '\u2018': "'",   '\u2019': "'",
    '\u201c': '"',    '\u201d': '"',    '\u2026': '...', '\u00a0': ' ',
    '\u2011': '-',    '\u2192': '->',   '\u2190': '<-',  '\u00d7': 'x',
    '\u2265': '>=',   '\u2264': '<=',   '\u2248': '~=',  '\u2260': '!=',
    '\u2212': '-',    '\u00b7': '.',    '\u2022': '-',   '\u00b2': '^2',
    '\u03a9': 'Ohm',  '\u03c3': 'sigma','\u0394': 'Delta','\u03b1': 'alpha',
    '\u0398': 'Theta','\u00b0': ' deg', '\u2032': "'",   '\u226a': '<<',
    '\u226b': '>>',   '\u2261': '==',   '\u00b1': '+/-',
    '\u00a7': 'Sec.',
}

BANNER = """<!-- VENDORED COPY. DO NOT EDIT HERE.
Canonical source: lesson-builder references/teaching-communication.md.
This copy is that file transliterated to ASCII by scripts/voice-drift.sh.
Change the canonical file, then run `scripts/voice-drift.sh --refresh`.
tests/check.sh fails if this copy has drifted from the canonical source. -->

"""
raw = open(src_path, encoding='utf-8').read()
out = []
unmapped = {}
for ch in raw:
    if ord(ch) <= 0x7e:
        out.append(ch)
    elif ch in TABLE:
        out.append(TABLE[ch])
    else:
        unmapped.setdefault(ch, 0)
        unmapped[ch] += 1
        out.append(ch)
expected = BANNER + ''.join(out)

if unmapped:
    for ch, n in sorted(unmapped.items()):
        print(f'voice-drift: canonical spec uses U+{ord(ch):04X} '
              f'({unicodedata.name(ch, "?")}) x{n}, which the table does not map. '
              f'Add it to TABLE in scripts/voice-drift.sh.')
    sys.exit(1)

try:
    have = open(copy_path, encoding='utf-8').read()
except FileNotFoundError:
    have = None

if mode == 'refresh':
    if have == expected:
        print('voice-drift: copy already matches the canonical spec.')
    else:
        open(copy_path, 'w', encoding='utf-8').write(expected)
        print(f'voice-drift: refreshed {copy_path} from {src_path}.')
    sys.exit(0)

if have is None:
    print(f'voice-drift: no vendored copy at {copy_path}. '
          'Run scripts/voice-drift.sh --refresh.')
    sys.exit(1)

if have == expected:
    print('voice-drift: vendored copy is in sync with the canonical spec.')
    sys.exit(0)

diff = list(difflib.unified_diff(
    have.splitlines(), expected.splitlines(),
    fromfile='vendored copy', tofile='canonical (transliterated)', lineterm='', n=1))
print(f'voice-drift: DRIFT -- {sum(1 for d in diff if d[:1] in "+-" and d[:3] not in ("+++", "---"))} '
      'changed lines. The canonical spec wins; run --refresh and re-read voice.md '
      'for anything the PDF-side rules now contradict.')
for line in diff[:60]:
    print('  ' + line)
if len(diff) > 60:
    print(f'  ... {len(diff) - 60} more diff lines')
sys.exit(1)
PYEOF
