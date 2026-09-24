#!/usr/bin/env bash
# page-break-check.sh -- report bad page breaks in a built house-style PDF.
#
#   scripts/page-break-check.sh [--strict] [--tex <file.tex>] <file.pdf>
#
# Reads each page's body with pdftotext -layout, cropped to the text block so
# the running head and the foot are left out, and warns, with page numbers:
#   widow    a page opens with the last line of a paragraph that began on the
#            page before: one short line, then a gap or the end of the page,
#            under a page that ended mid-sentence;
#   heading  a page ends with a heading (a \part, \section, \subsection or
#            \subsubsection title in the source) or with a listing caption;
#   listing  a listing breaks across pages with fewer than two of its lines on
#            one side of the break.
# The source is <file>.tex beside the PDF unless --tex names it; the files it
# \input{}s or \include{}s are read too. With no source the heading rule knows
# only "Listing N" captions and the listing rule does not run.
#
# These are heuristics on extracted text, so a warning is a page to look at,
# not a verdict. Exit 0 whatever it finds; with --strict, exit 1 when it finds
# anything. Exit 2 on a usage error or when pdftotext or pdfinfo is missing.
set -euo pipefail

strict=0; tex=""
while [ $# -gt 0 ]; do
  case "$1" in
    --strict) strict=1; shift ;;
    --tex) [ $# -ge 2 ] || { echo "usage: $0 [--strict] [--tex file.tex] <file.pdf>" >&2; exit 2; }
           tex="$2"; shift 2 ;;
    -*) echo "usage: $0 [--strict] [--tex file.tex] <file.pdf>" >&2; exit 2 ;;
    *) break ;;
  esac
done
[ $# -eq 1 ] && [ -f "$1" ] || { echo "usage: $0 [--strict] [--tex file.tex] <file.pdf>" >&2; exit 2; }
for t in pdftotext pdfinfo python3; do
  command -v "$t" >/dev/null || { echo "page-break-check: $t is not installed" >&2; exit 2; }
done
pdf="$1"
[ -n "$tex" ] || tex="${pdf%.pdf}.tex"

python3 - "$pdf" "$tex" "$strict" <<'PYEOF'
import os, re, subprocess, sys

pdf, tex, strict = sys.argv[1], sys.argv[2], sys.argv[3] == '1'

# The text block of housestyle.sty: top=92pt, bottom=70pt. Crop a little
# outside it so the first and last lines' ascenders and descenders are in.
TOP, BOTTOM = 86, 66

info = subprocess.run(['pdfinfo', '-f', '1', '-l', '100000', pdf],
                      capture_output=True, text=True, check=True).stdout
sizes = {int(m.group(1)): (float(m.group(2)), float(m.group(3)))
         for m in re.finditer(r'^Page\s+(\d+) size:\s+([\d.]+) x ([\d.]+)', info, re.M)}
if not sizes:
    n = int(re.search(r'^Pages:\s+(\d+)', info, re.M).group(1))
    w, h = map(float, re.search(r'^Page size:\s+([\d.]+) x ([\d.]+)', info, re.M).groups())
    sizes = {i: (w, h) for i in range(1, n + 1)}

def body(page):
    w, h = sizes[page]
    out = subprocess.run(['pdftotext', '-f', str(page), '-l', str(page), '-layout', '-r', '72',
                          '-x', '0', '-y', str(TOP), '-W', str(int(w)), '-H', str(int(h - TOP - BOTTOM)),
                          pdf, '-'], capture_output=True, text=True, check=True).stdout
    lines = [l.rstrip() for l in out.replace('\f', '').split('\n')]
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    return lines

pages = {p: body(p) for p in sorted(sizes)}

def norm(s):
    return re.sub(r'[^0-9a-z]', '', s.lower())

# ---- the source: heading titles and listings --------------------------------
def read_tree(path, seen):
    path = os.path.abspath(path)
    if path in seen or not os.path.isfile(path):
        return ''
    seen.add(path)
    src = re.sub(r'(?<!\\)%.*', '', open(path, encoding='utf-8', errors='replace').read())
    def sub(m):
        name = m.group(1).strip()
        if not name.endswith('.tex'):
            name += '.tex'
        return read_tree(os.path.join(os.path.dirname(path), name), seen)
    return re.sub(r'\\(?:input|include)\{([^}]*)\}', sub, src)

src = read_tree(tex, set()) if os.path.isfile(tex) else ''

def detex(s):
    s = re.sub(r'\\[a-zA-Z@]+\*?(\[[^]]*\])?', ' ', s)
    return s.replace('{', '').replace('}', '').replace('~', ' ')

headings = set()
for m in re.finditer(r'\\(?:part|section|subsection|subsubsection|catbanner\{[^}]*\})\*?(?:\[[^]]*\])?\{((?:[^{}]|\{[^{}]*\})*)\}', src):
    t = norm(detex(m.group(1)))
    if len(t) >= 3:
        headings.add(t)

listings = []  # (caption or None, [normalised code lines])
for m in re.finditer(r'(?:\\hslisting\{((?:[^{}]|\{[^{}]*\})*)\}\s*)?\\begin\{Verbatim\}(?:\[[^]]*\])?\n(.*?)\\end\{Verbatim\}', src, re.S):
    code = [norm(l)[:40] for l in m.group(2).split('\n')]
    listings.append((m.group(1), [c for c in code if c]))

CAPTION = re.compile(r'^\s*listing\s*\d+\b', re.I)

def is_heading(line):
    n = norm(line)
    if not n:
        return False
    if CAPTION.match(line):
        return True
    return any(n == h or (len(n) >= 12 and h.startswith(n)) for h in headings)

found = []
def warn(page, kind, text):
    found.append((page, kind, text.strip()[:70]))

# ---- widow: a page that opens with a paragraph's last line ------------------
width = max((len(l) for ls in pages.values() for l in ls), default=0)
code_lines = {c for _, cs in listings for c in cs}
for p in sorted(pages):
    prev, cur = pages.get(p - 1), pages[p]
    if not prev or not cur:
        continue
    first, last = cur[0], prev[-1]
    alone = len(cur) == 1 or not cur[1].strip()
    short = len(first) < 0.75 * width
    open_end = not re.search(r'[.!?:;)\]"\u201d]\s*$', last)
    prose = len(last) >= 0.6 * width and norm(last)[:40] not in code_lines
    if alone and short and open_end and prose and not is_heading(first) and norm(first):
        warn(p, 'widow', first)

# ---- heading or caption at the foot of a page --------------------------------
for p in sorted(pages):
    if p == max(pages) or not pages[p]:
        continue
    if is_heading(pages[p][-1]):
        warn(p, 'heading', pages[p][-1])

# ---- a listing split with fewer than two lines on one side -------------------
seq = [(p, norm(l)) for p in sorted(pages) for l in pages[p]]
pos = 0
for caption, code in listings:
    if not code:
        continue
    at, hits = pos, []
    for c in code:
        for i in range(at, len(seq)):
            if seq[i][1] and (seq[i][1].startswith(c) or c.startswith(seq[i][1])) and len(seq[i][1]) >= min(len(c), 3):
                hits.append(seq[i][0]); at = i + 1
                break
    if len(hits) < len(code):
        continue  # not every line was found in the text: say nothing
    pos = at
    split = sorted(set(hits))
    if len(split) > 1:
        head, tail = hits.count(split[0]), hits.count(split[-1])
        if head < 2 or tail < 2:
            label = detex(caption).strip() if caption else 'a listing'
            warn(split[0] if head < 2 else split[-1], 'listing',
                 f'{label}: {head} line(s) on p.{split[0]}, {tail} on p.{split[-1]}')

for page, kind, text in sorted(found):
    print(f'page-break-check: p.{page}: {kind}: {text}')
if found:
    print(f'page-break-check: {len(found)} bad break(s) in {os.path.basename(pdf)}; '
          'reword, add \\needspace or move a figure, then rebuild')
sys.exit(1 if found and strict else 0)
PYEOF
