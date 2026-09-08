#!/usr/bin/env bash
# Style gate for pdf-material-builder.
#
# Fails on, per references/latex-house-style.md:
#   - an em-dash, an emoji, or any other character above ASCII  (.tex .md .sh)
#   - \lt or \gt, which are KaTeX and undefined in LaTeX        (.tex)
#   - a bare $O()$ where the \Oh macro belongs                  (.tex)
#   - a tcolorbox named `picture`, which collides with LaTeX's  (.tex)
#     built-in picture environment and breaks \@iiiparbox
#
# The three .tex rules read the line with its LaTeX comment stripped: a rule
# written in a comment (the preamble documents \Oh by naming what it replaces)
# cannot break a build. The ASCII rule reads the whole line, comments included.
#
# Usage:  scripts/style-check.sh [DIR]      (default: the repo root)
# Exit:   0 clean, 1 violations found, 2 bad usage.
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
[ -d "$ROOT" ] || { echo "style-check: not a directory: $ROOT" >&2; exit 2; }

python3 - "$ROOT" <<'PYEOF'
import os, re, sys, unicodedata

root = sys.argv[1]
SKIP_DIRS = {'.git', '_extraction', 'course_materials', 'viz_src',
             'node_modules', 'claude_lessons', 'dist', '.venv'}
EM_DASH = '\u2014'

files = []
for d, dirs, fs in os.walk(root):
    dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS)
    for f in sorted(fs):
        p = os.path.join(d, f)
        # Regular files only: a symlink could point at /dev/zero or outside the tree.
        if f.endswith(('.tex', '.md', '.sh')) and os.path.isfile(p) and not os.path.islink(p):
            files.append(p)

# A bare O( inside math: not \Oh, not \Ohof, not part of a longer identifier.
BARE_O = re.compile(r'\$[^$]*?(?<![\\A-Za-z])O\s*\(')
LT_GT = re.compile(r'\\[lg]t(?![A-Za-z])')
TEX_COMMENT = re.compile(r'(?<!\\)%.*$')
PICTURE_BOX = re.compile(r'\\(?:new|renew)tcolorbox(?:\[[^\]]*\])?\{picture\}'
                         r'|\\DeclareTColorBox(?:\[[^\]]*\])?\{picture\}')

problems = []
for path in files:
    rel = os.path.relpath(path, root)
    text = open(path, encoding='utf-8').read()
    is_tex = path.endswith('.tex')
    for n, line in enumerate(text.splitlines(), 1):
        for ch in line:
            if ord(ch) > 0x7e:
                if ch == EM_DASH:
                    what = 'em-dash (use -- or a comma)'
                elif unicodedata.category(ch) == 'So':
                    what = 'emoji or symbol'
                else:
                    what = 'non-ASCII'
                problems.append(f'{rel}:{n}: {what}: U+{ord(ch):04X}')
                break
        if not is_tex:
            continue
        line = TEX_COMMENT.sub('', line)
        if LT_GT.search(line):
            problems.append(rf'{rel}:{n}: \lt or \gt is KaTeX, undefined in LaTeX; use < or >')
        if BARE_O.search(line) and '\\newcommand' not in line:
            problems.append(rf'{rel}:{n}: bare $O()$; use \Oh or \Ohof')
        if PICTURE_BOX.search(line):
            problems.append(f'{rel}:{n}: tcolorbox named `picture` collides with '
                            'the built-in environment; name it pictureit')

for p in problems:
    print(p)
print(f'style-check: {len(files)} files, {len(problems)} violations')
sys.exit(1 if problems else 0)
PYEOF
