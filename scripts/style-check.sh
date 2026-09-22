#!/usr/bin/env bash
# Style gate for pdf-material-builder.
#
# Fails on, per references/latex-house-style.md and
# references/house-style/style-spec.md:
#   - an em-dash, an emoji, or any other character above ASCII  (.tex .md .sh .sty)
#   - \lt or \gt, which are KaTeX and undefined in LaTeX        (.tex)
#   - a bare $O()$ where the \Oh macro belongs                  (.tex)
#   - a tcolorbox named `picture`, which collides with LaTeX's  (.tex)
#     built-in picture environment and breaks \@iiiparbox
#   - a \footnote: sources go in one numbered list on the last  (.tex)
#     page (spec, block 8)
#   - a second \hsclaim in one document: exactly one claim per  (.tex)
#     document (spec, block 9). A .tex with \begin{document} is
#     a document with every file it \input{}s or \include{}s,
#     followed recursively; any other .tex is counted on its own
#   - a colour outside the six tokens (spec, Colour): a hex    (.tex .sty)
#     value not in the token set, a \definecolor in a document,
#     or a colour name or `!` tint that is not a token name
#   - a pdflatex call (`pdflatex` then an option or a .tex    (all four)
#     file): housestyle.sty needs lualatex; use scripts/build.sh
#
# The .tex and .sty rules read the line with its LaTeX comment stripped: a rule
# written in a comment (the preamble documents \Oh by naming what it replaces)
# cannot break a build. The ASCII and pdflatex rules read the whole line.
#
# Usage:  scripts/style-check.sh [DIR]      (default: the repo root)
# Exit:   0 clean, 1 violations found, 2 bad usage.
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
[ -d "$ROOT" ] || { echo "style-check: not a directory: $ROOT" >&2; exit 2; }

python3 - "$ROOT" <<'PYEOF'
import os, re, sys, unicodedata

root = os.path.realpath(sys.argv[1])
# fonts/ holds third-party files vendored verbatim.
SKIP_DIRS = {'.git', '_extraction', 'course_materials', 'viz_src',
             'node_modules', 'claude_lessons', 'dist', '.venv',
             'fonts'}
EM_DASH = '\u2014'

files = []
for d, dirs, fs in os.walk(root):
    dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS)
    for f in sorted(fs):
        p = os.path.join(d, f)
        # Regular files only: a symlink could point at /dev/zero or outside the tree.
        if f.endswith(('.tex', '.md', '.sh', '.sty')) and os.path.isfile(p) and not os.path.islink(p):
            files.append(p)

# A bare O( inside math: not \Oh, not \Ohof, not part of a longer identifier.
BARE_O = re.compile(r'\$[^$]*?(?<![\\A-Za-z])O\s*\(')
LT_GT = re.compile(r'\\[lg]t(?![A-Za-z])')
TEX_COMMENT = re.compile(r'(?<!\\)%.*$')
PICTURE_BOX = re.compile(r'\\(?:new|renew)tcolorbox(?:\[[^\]]*\])?\{picture\}'
                         r'|\\DeclareTColorBox(?:\[[^\]]*\])?\{picture\}')

FOOTNOTE = re.compile(r'\\footnote(?![A-Za-z])')
CLAIM = re.compile(r'\\hsclaim(?![A-Za-z])')
BEGIN_DOC = re.compile(r'\\begin\s*\{document\}')
INPUT = re.compile(r'\\(input|include)\s*\{([^}]+)\}')
PDFLATEX = re.compile(r'(?<![\w-])pdflatex\s+(?:-|[^\s]*\.tex\b)')
# The six tokens of style-spec.md, the code ground and the grey rule the .sty
# defines, by hex and by the names housestyle.sty gives them.
TOKEN_HEX = {'15140F', '4A4740', '8A857A', 'FAF8F3', 'F0EADE', 'F2EEE3',
             '9C4221', 'DED8CA'}
TOKEN_NAMES = {'ink', 'inkseventy', 'inkfiftyfive', 'paper', 'fill',
               'codefill', 'accent', 'rulegrey', 'none'}
HEX = re.compile(r'(?:#|\{HTML\}\{)([0-9A-Fa-f]{6})\b')
DEFINECOLOR = re.compile(r'\\definecolor(?![A-Za-z])')
COLOR_USE = re.compile(
    r'\\(?:textcolor|color|colorbox|pagecolor|arrayrulecolor)\s*(?:\[[^\]]*\])?\{([^}]*)\}'
    r'|(?<![A-Za-z])(?:draw|fill|text|colback|colframe|rulecolor|bgcolor)\s*=\s*([^,\]}\s]+)')

def line_events(line, n):
    """The claims and \\input/\\include targets on one comment-stripped line,
    in the order they appear."""
    found = []
    if '\\newcommand' not in line:
        found += [(m.start(), ('claim', n)) for m in CLAIM.finditer(line)]
    found += [(m.start(), ('input', n, m.group(1), m.group(2).strip()))
              for m in INPUT.finditer(line)]
    return [e for _, e in sorted(found)]

problems = []
# Per .tex (by real path), in line order: ('claim', n) and ('input', n, kind, target).
tex_events = {}
drivers = []
for path in files:
    rel = os.path.relpath(path, root)
    text = open(path, encoding='utf-8').read()
    is_tex = path.endswith('.tex')
    is_sty = path.endswith('.sty')
    events = tex_events[os.path.realpath(path)] = [] if is_tex else None
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
        if PDFLATEX.search(line):
            problems.append(f'{rel}:{n}: pdflatex call; housestyle.sty needs '
                            'lualatex, build with scripts/build.sh')
        if not (is_tex or is_sty):
            continue
        line = TEX_COMMENT.sub('', line)
        for m in HEX.finditer(line):
            if m.group(1).upper() not in TOKEN_HEX:
                problems.append(f'{rel}:{n}: colour #{m.group(1)} is not one of '
                                'the house-style tokens')
        for m in COLOR_USE.finditer(line):
            name = (m.group(1) or m.group(2) or '').strip()
            # \color{#1} in a macro body, or text=\foo, is not a literal.
            if name.startswith(('#', '\\')) or not name:
                continue
            if name not in TOKEN_NAMES:
                problems.append(f'{rel}:{n}: colour `{name}` is not a house-style '
                                'token (ink, inkseventy, inkfiftyfive, paper, '
                                'fill, codefill, accent, rulegrey)')
        if not is_tex:
            continue
        if DEFINECOLOR.search(line):
            problems.append(rf'{rel}:{n}: \definecolor in a document; the colours '
                            'are the tokens housestyle.sty defines')
        if FOOTNOTE.search(line):
            problems.append(rf'{rel}:{n}: \footnote; put the source in the '
                            'numbered list on the last page (hssources)')
        if BEGIN_DOC.search(line) and path not in drivers:
            drivers.append(path)
        events.extend(line_events(line, n))
        if LT_GT.search(line):
            problems.append(rf'{rel}:{n}: \lt or \gt is KaTeX, undefined in LaTeX; use < or >')
        if BARE_O.search(line) and '\\newcommand' not in line:
            problems.append(rf'{rel}:{n}: bare $O()$; use \Oh or \Ohof')
        if PICTURE_BOX.search(line):
            problems.append(f'{rel}:{n}: tcolorbox named `picture` collides with '
                            'the built-in environment; name it pictureit')

def read_events(real):
    """Events of a file an \\input reaches that the walk above did not list
    (outside ROOT, a skipped dir, or not named .tex)."""
    if real not in tex_events:
        lines = open(real, encoding='utf-8', errors='replace').read().splitlines()
        tex_events[real] = [e for n, line in enumerate(lines, 1)
                            for e in line_events(TEX_COMMENT.sub('', line), n)]
    return tex_events[real]

def resolve(including, driver, kind, target):
    """The file an \\input or \\include names: relative to the including file,
    then to the driver's directory (where lualatex runs). None when missing."""
    names = [target + '.tex'] if kind == 'include' else [target, target + '.tex']
    for base in (os.path.dirname(including), os.path.dirname(driver)):
        for name in names:
            p = os.path.realpath(os.path.join(base, name))
            if os.path.isfile(p) and not os.path.islink(os.path.join(base, name)):
                return p
    return None

def claims_in_tree(driver):
    """Every \\hsclaim in a document, in reading order, as (path, line). A
    missing target is skipped; a file that inputs one of its own includers (a
    cycle) is not followed back up. A file input twice counts twice, as it
    prints twice."""
    out = []
    def walk(real, stack):
        for e in read_events(real):
            if e[0] == 'claim':
                out.append((real, e[1]))
                continue
            child = resolve(real, driver, e[2], e[3])
            if child is not None and child not in stack:
                walk(child, stack | {child})
    real = os.path.realpath(driver)
    walk(real, {real})
    return out

def where(path, n):
    return f'{os.path.relpath(path, root)}:{n}'

in_a_document = set()
for driver in drivers:
    claims = claims_in_tree(driver)
    in_a_document.update(p for p, _ in claims)
    for p, n in claims[1:]:
        problems.append(rf'{where(p, n)}: a second \hsclaim; one claim per document '
                        f'(the document is {os.path.relpath(driver, root)}, '
                        f'the first claim is {where(*claims[0])})')
# A .tex no document reaches is counted on its own.
for path in files:
    if not path.endswith('.tex') or os.path.realpath(path) in in_a_document:
        continue
    claims = [e[1] for e in tex_events[os.path.realpath(path)] if e[0] == 'claim']
    for n in claims[1:]:
        problems.append(rf'{where(path, n)}: a second \hsclaim; one claim per document '
                        f'(the first is on line {claims[0]})')
problems = list(dict.fromkeys(problems))

for p in problems:
    print(p)
print(f'style-check: {len(files)} files, {len(problems)} violations')
sys.exit(1 if problems else 0)
PYEOF
