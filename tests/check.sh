#!/usr/bin/env bash
# The repo gate for pdf-material-builder. Hermetic, no network, about a
# minute with lualatex present. Run it before opening a PR; the landing check runs it too.
#
# Cases:
#   1  SKILL.md frontmatter parses and carries `name` and `description`,
#      and `name` is this skill's directory name.
#   2  Every relative path this skill's own docs mention exists.
#      references/teaching-communication.md is exempt and says so: it is a
#      verbatim vendored copy, and the paths in it are lesson-builder's.
#   3  scripts/style-check.sh passes on this repo.
#   4  scripts/style-check.sh selfcheck: each of its rules flags its own
#      fixture and stays quiet on the matching clean case. The claim rule is
#      also proved across files: a driver that \input{}s one file and
#      \include{}s another, one \hsclaim in each, fails; the same tree with
#      one claim passes. Both trees hold a cycle and a missing input.
#   5  scripts/voice-drift.sh reports no drift from the canonical spec.
#      SKIPPED, with the reason printed, when lesson-builder is not on disk.
#   6  assets/preamble-template.tex and assets/driver-template.tex build with
#      scripts/build.sh (lualatex, three passes) to a non-empty PDF in a temp
#      directory. With pdfinfo present, the default build is letter and the
#      template's A4 line, uncommented, builds A4. assets/short-template.tex
#      and assets/blank-template.tex build the same way, and so does
#      blank-template with \hsnumbersections on and with the A4 line on; the
#      contents page shows the Part in its small-caps column (and, numbered,
#      the section number), and the blank template embeds the Subhead,
#      Display and Semibold cuts. build.sh failing on an overfull box is
#      what makes each of these a check that nothing overruns the measure.
#   7  Every ```latex block in references/page-composition.md compiles against
#      housestyle.sty, each as its own page, and none of them logs an overfull
#      box: a writer copies these patterns out of the file, so a style the .sty
#      renamed or a picture wider than the measure fails in their document.
#   8  references/house-style/example.tex builds the same way, and pdffonts
#      shows Source Serif 4 and IBM Plex Mono embedded.
#   9  With housestyle.sty in the current directory, kpse returns it as
#      ./housestyle.sty (a bare lualatex run there); the .sty's font lookup
#      must still resolve to assets/fonts/. Then references/house-style/
#      example.tex builds in place with scripts/build.sh and embeds the
#      vendored Source Serif 4; the example.pdf it makes is removed.
#  10  scripts/build.sh exits 1 on a document with an Overfull \hbox and
#      names it, and 0 on the same document without one.
#  11  \hsprovenance keeps a typed "--state" as two hyphens, both with the
#      .sty's own provenance font and with that font swapped for one whose
#      TeX ligatures are on, so the guard does not rest on the font feature.
#  12  A label splits at " / " and not at a bare "/".
#  13  \hsdiagram places a diagram-maker PDF: build.sh renders two specs in
#      figures/ with the bundled diagram-maker's render.js and exports them
#      with its export.sh, one at canvas 576 (placed 1:1 on letter) and one at
#      its default width (scaled down to the measure), and the page carries the
#      figure's text with no overfull box. A spec render.js rejects fails the
#      build. SKIPPED, with the reason, when diagram-maker is not checked out,
#      node is absent, or export.sh has no converter (exit 2).
#  14  install.sh against scratch clones, all on local file URLs: a missing
#      directory, a plain one, a symlink and a clone of another origin are
#      left alone with exit 0; a clone of this origin is fast-forwarded and
#      its diagram-maker moved to diagram-maker's latest main, past the pin; a
#      second run changes nothing; a pin bump fast-forwards over a submodule
#      already ahead of it; a local commit in the way is exit 1 and moves
#      nothing. scripts/sync-diagram-maker.sh moves the submodule to the new
#      tip, is a silent exit 0 when the remote is unreachable, and does not
#      touch the enclosing repo of a vendored copy.
#  15  The document register, with a stub cc-docs that logs its calls. A
#      two-page document with a title page and a copyright foot builds with
#      no DOC_* variables and calls nothing; with DOC_PROJECT set but no
#      cc-docs on PATH it builds the same. With DOC_PROJECT, DOC_TITLE,
#      DOC_KIND and DOC_MEMBER it asks `number` before compiling and `file`
#      after, passing each flag and the source path, and every page carries
#      the number under the foot while the rest of each page's text, the
#      copyright line and page number included, is what the draft printed.
#      DOC_NO_STAMP=1 prints no number and files with --no-stamp; DOC_PROJECT
#      without DOC_TITLE exits 2 and calls nothing.
#  16  Page breaks. A fixture builds with the style and with \pbcold, which puts
#      back what the style did before (150 widow and club penalties, a caption
#      the code could break from, fvextra's breakable overlap glue) or might
#      have done (a subsection's room check run straight under a section
#      heading) and strands a heading at a page foot. The styled build has no
#      widow, moves a five-line listing whole onto the next page with its
#      caption, moves a section 420pt down a page onto p.6 with the subsection
#      under it, and page-break-check.sh --strict passes it. The old build
#      still exits 0 but build.sh reports the widow on p.2, the one-line listing
#      split on p.3, the heading on p.5 and the section left alone at the foot
#      of p.7; the check exits 0 on it, 1 under --strict, and 2 on a missing
#      PDF.
#  17  A workspace's own design system (apply-design-system/). The default
#      build is unchanged: with no token file, build.sh's PDF of the short
#      template is byte-for-byte the PDF of three bare lualatex passes, under a
#      fixed SOURCE_DATE_EPOCH, and names no design system. The same source in
#      a repo with .cc/design-tokens.json (the placeholder salari-test system)
#      names it, differs, and prints its title in capitals. `find` takes the
#      token file at the repo root, not one above the repo's .git, and none
#      with DESIGN_TOKENS=none; a DESIGN_TOKENS that names no file exits 2.
#      `import` reads a fixture Claude Design export (var() chains, an oklch
#      colour, a [data-brand] block it must ignore, one logo) into a valid
#      token file. `xlsx` writes the same bytes twice, carries the header fill
#      and the rows, and exits 1 where no design system applies.
#   6 to 13, 15, 16 and 17's builds are SKIPPED, with the reason printed, when lualatex is absent;
#   8's and 9's font checks are skipped the same way when pdffonts is absent.
#
# Exit: 0 all pass (skips are not failures), 1 any failure.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_NAME=pdf-material-builder
FAILED=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

pass() { printf 'ok    %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAILED=1; }
skip() { printf 'skip  %s -- %s\n' "$1" "$2"; }

# --- 1. frontmatter ---------------------------------------------------------
if python3 - "$REPO/SKILL.md" "$SKILL_NAME" <<'PYEOF'
import re, sys
path, want = sys.argv[1], sys.argv[2]
text = open(path, encoding='utf-8').read()
m = re.match(r'---\n(.*?)\n---\n', text, re.S)
if not m:
    print('  no --- frontmatter block at the top of SKILL.md'); sys.exit(1)
block = m.group(1)
problems = []
name = re.search(r'^name:\s*(\S.*?)\s*$', block, re.M)
desc = re.search(r'^description:\s*(\S.*)$', block, re.M | re.S)
if not name:
    problems.append('frontmatter has no `name`')
elif name.group(1).strip('"\'') != want:
    problems.append(f'frontmatter name is {name.group(1)!r}, expected {want!r}')
if not desc:
    problems.append('frontmatter has no `description`')
elif len(desc.group(1)) < 80:
    problems.append('description is too short to trigger on anything useful')
for p in problems:
    print('  ' + p)
sys.exit(1 if problems else 0)
PYEOF
then pass "frontmatter: name=$SKILL_NAME and a description"
else fail "frontmatter"
fi

# --- 2. every relative path mentioned exists --------------------------------
if python3 - "$REPO" <<'PYEOF'
import os, re, sys

repo = sys.argv[1]
# Vendored: a verbatim copy of lesson-builder's spec, whose paths are that
# repo's. Editing it here would make scripts/voice-drift.sh report drift.
EXEMPT = {'references/teaching-communication.md'}

docs = ['SKILL.md', 'README.md', 'docs/integration.md']
docs += sorted('references/' + f for f in os.listdir(os.path.join(repo, 'references'))
               if f.endswith('.md'))
docs = [d for d in docs if d not in EXEMPT and os.path.exists(os.path.join(repo, d))]

# A path is checked only when its first segment is a directory this repo has,
# or it names a top-level file. Anything else (course_notes/, viz_src/,
# lesson-builder/..., <build_dir>/...) belongs to a build or another repo.
ROOTS = tuple(d + '/' for d in ('references', 'assets', 'scripts', 'tests', 'docs'))
TOPLEVEL = {'SKILL.md', 'README.md', 'install.sh'}
CANDIDATE = re.compile(r'`([^`\s]+)`|\]\(([^)\s]+)\)')

missing = []
checked = 0
for doc in docs:
    text = open(os.path.join(repo, doc), encoding='utf-8').read()
    for n, line in enumerate(text.splitlines(), 1):
        for a, b in CANDIDATE.findall(line):
            tok = (a or b).rstrip('.,;:')
            if '<' in tok or '>' in tok or '*' in tok:
                continue
            if not (tok.startswith(ROOTS) or tok in TOPLEVEL):
                continue
            checked += 1
            if not os.path.exists(os.path.join(repo, tok)):
                missing.append(f'  {doc}:{n}: {tok} does not exist')

for m in missing:
    print(m)
print(f'  {checked} path mentions across {len(docs)} docs'
      f'{"" if not EXEMPT else "; exempt: " + ", ".join(sorted(EXEMPT))}')
sys.exit(1 if missing else 0)
PYEOF
then pass "every relative path the docs mention exists"
else fail "referenced paths"
fi

# --- 3. style-check on the repo ---------------------------------------------
if out=$("$REPO/scripts/style-check.sh" "$REPO" 2>&1); then
  pass "style-check on the repo (${out##*$'\n'})"
else
  fail "style-check on the repo"; printf '%s\n' "$out" | sed 's/^/  /'
fi

# --- 4. style-check selfcheck ------------------------------------------------
# Each case builds its own fixture directory holding exactly two files: the one
# the rule must flag, and the one it must stay quiet on. Both are asserted, so a
# rule that fires on everything fails here just as a dead rule does.
selfcheck() {
  local name="$1" dirty_file="$2" dirty="$3" clean_file="$4" clean="$5"
  local d out rc
  d="$TMPROOT/sc-$name"; mkdir -p "$d/dirty" "$d/clean"
  printf '%b' "$dirty" > "$d/dirty/$dirty_file"
  printf '%b' "$clean" > "$d/clean/$clean_file"

  out=$("$REPO/scripts/style-check.sh" "$d/dirty" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then
    fail "selfcheck $name: the violating fixture was not flagged"; return
  fi
  out=$("$REPO/scripts/style-check.sh" "$d/clean" 2>&1); rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "selfcheck $name: the clean fixture was flagged"
    printf '%s\n' "$out" | sed 's/^/  /'; return
  fi
  pass "selfcheck $name: flags the violation, passes the clean case"
}

selfcheck em-dash    a.md  'A sentence \u2014 broken.\n'        b.md  'A sentence -- fine.\n'
selfcheck emoji      a.tex 'Ship it \U0001F680\n'              b.tex 'Ship it.\n'
selfcheck lt-gt      a.tex '$a \\lt b$\n'                      b.tex '$a < b$ % \\lt in a comment is inert\n'
selfcheck bare-big-o a.tex 'Runs in $O(n \\log n)$ time.\n'    b.tex 'Runs in $\\Ohof{n \\log n}$ time.\n'
selfcheck picture-box a.tex '\\newtcolorbox{picture}{colback=paper}\n' \
                      b.tex '\\newtcolorbox{pictureit}{colback=paper}\n'
selfcheck footnote   a.tex 'A number.\\footnote{From the log.}\n' \
                     b.tex 'A number.\\textsuperscript{1}\n'
selfcheck second-claim a.tex '\\hsclaim{One.}{x}\n\\hsclaim{Two.}{y}\n' \
                       b.tex '\\hsclaim{One.}{x}\n'
selfcheck colour-hex a.tex '\\textcolor[HTML]{1F6FEB}{x}\n' \
                     b.tex '% the accent is 9C4221, set by housestyle.sty\n\\textcolor{accent}{x}\n'
selfcheck definecolor a.tex '\\definecolor{gold}{HTML}{B8943E}\n' \
                      b.tex '\\textcolor{inkfiftyfive}{x} % a token the .sty defines\n'
selfcheck colour-name a.tex '\\textcolor{black!75}{x} \\colorbox{softbg}{y}\n' \
                      b.tex '\\textcolor{inkseventy}{x} \\colorbox{fill}{y}\n'
# A tint is a violation in itself: the style allows no gradients and no tints,
# only the named tokens, so `accent!12` is as wrong as a hue that is no token.
selfcheck colour-tint a.tex '\\node[draw=teal!40,fill=accent!12] {x};\n' \
                      b.tex '\\node[draw=accent,fill=fill] {x};\n'
# The four diagram role colours are tokens too, each with its own explicit
# tint (slatetint, and so on), so a bare role name in draw=/fill= passes and a
# document that tints one itself -- even a token it is otherwise allowed to
# name -- still fails, the same as any other colour. Both fixtures sit inside
# a tikzpicture, which is the only place a role colour is allowed at all.
selfcheck diagram-role-colour \
  a.tex '\\begin{tikzpicture}\\node[draw=slate,fill=slate!12] {x};\\end{tikzpicture}\n' \
  b.tex '\\begin{tikzpicture}\\node[draw=slate,fill=slatetint] {x};\\end{tikzpicture}\n'
# A role colour is a token, but only inside a tikzpicture: prose, headings,
# tables, callouts and the page keep the eight kit tokens. The same colour on
# a node inside a tikzpicture is exactly the diagram-role-colour case above.
selfcheck role-colour-outside-tikz \
  a.tex '\\textcolor{slate}{x}\n' \
  b.tex '\\begin{tikzpicture}\\node[draw=slate,fill=slatetint] {x};\\end{tikzpicture}\n'
# The role colours are defined in hsdiagrams.sty, the TikZ kit, and read
# anywhere in it; any other .sty -- housestyle.sty included, since v5.1 it
# holds no picture code -- keeps them inside a tikzpicture like a document.
selfcheck role-colour-in-page-sty \
  a.sty '\\newcommand{\\hsx}{\\color{slate}x}\n' \
  hsdiagrams.sty '\\newcommand{\\hsx}{\\color{slate}x}\n'
selfcheck pagecolor  a.tex '\\pagecolor{paper}\n' \
                     b.tex '% housestyle.sty paints the paper tint; a document never does\n'
selfcheck sans-face  a.tex '{\\sffamily A label}\n' \
                     b.tex '{\\labelfont A label}\n'
# The defects the reference rendering exposed in the first real build.
selfcheck empty-figure-label \
  a.tex '\\begin{hsfigure}{}{}\\end{hsfigure}\n' \
  b.tex '\\begin{hsfigure}{Figure 1 / the flow}{Filled boxes are inputs.}\\end{hsfigure}\n'
selfcheck empty-provenance \
  a.tex '\\hsprovenance{ }\n' \
  b.tex '\\hsprovenance{Read off the box on 21 September 2026.}\n'
selfcheck node-without-eyebrow \
  a.tex '\\node[hswork] (b) {\\textbf{Draft}\\\\then prose};\n' \
  b.tex '\\node[hswork] (b) {\\hsnodetext{Agent}{Draft}{then prose}};\n'
selfcheck fifth-stat \
  a.tex '\\begin{hsstatrow}\n\\hsstat{1}{a}\\hsstat{2}{b}\\hsstat{3}{c}\\hsstat{4}{d}\\hsstat{5}{e}\n\\end{hsstatrow}\n' \
  b.tex '\\begin{hsstatrow}[3]\n\\hsstat{1}{a}\\hsstat{2}{b}\\hsstat{3}{c}\n\\end{hsstatrow}\n\\begin{hsstatrow}\n\\hsstat{4}{d}\\hsstat{5}{e}\n\\end{hsstatrow}\n'
# The row's own [n] is the cap, not just four: a third stat in a row of two is
# the \PackageError the .sty raises at build time, so the gate has to catch it.
selfcheck stat-over-declared-cap \
  a.tex '\\begin{hsstatrow}[2]\n\\hsstat{1}{a}\\hsstat{2}{b}\\hsstat{3}{c}\n\\end{hsstatrow}\n' \
  b.tex '\\begin{hsstatrow}[2]\n\\hsstat{1}{a}\\hsstat{2}{b}\n\\end{hsstatrow}\n'
# One claim per document, not per file: a driver and the files it pulls in.
# The inputs sit in a subdirectory and name each other relative to themselves;
# ch2 inputs the driver back (a cycle) and a file that does not exist.
claim_tree() {
  local d="$1" second="$2"
  mkdir -p "$d/notes"
  printf '%s\n' '\documentclass{article}' '\begin{document}' '\input{notes/ch1}' \
    '\include{notes/ch2}' '\end{document}' > "$d/main.tex"
  printf '%s\n' '\section{One}' '\hsclaim{The claim.}{x}' > "$d/notes/ch1.tex"
  printf '%s\n' '\section{Two}' "$second" '\input{../main}' '\input{absent}' > "$d/notes/ch2.tex"
}
T="$TMPROOT/sc-claim-tree"
claim_tree "$T/dirty" '\hsclaim{Another claim.}{y}'
claim_tree "$T/clean" 'No claim here.'
out=$(timeout 30 "$REPO/scripts/style-check.sh" "$T/dirty" 2>&1); rc=$?
if [ "$rc" -ne 1 ] || ! printf '%s\n' "$out" | grep -q '^notes/ch2.tex:2: a second \\hsclaim'; then
  fail "selfcheck claim-tree: a claim in each of two input files was not flagged at notes/ch2.tex:2 (exit $rc)"
  printf '%s\n' "$out" | sed 's/^/  /'
elif ! out=$(timeout 30 "$REPO/scripts/style-check.sh" "$T/clean" 2>&1); then
  fail "selfcheck claim-tree: one claim across the document was flagged"; printf '%s\n' "$out" | sed 's/^/  /'
else
  pass "selfcheck claim-tree: counts claims across a driver's inputs, through a cycle and a missing file"
fi

# Split so this file does not itself read as a call.
PDFL='pdf''latex'
selfcheck pdflatex-call a.sh "$PDFL -interaction=nonstopmode notes.tex\n" \
                        b.sh "scripts/build.sh notes.tex  # $PDFL cannot load fontspec\n"

# --- 5. voice drift ----------------------------------------------------------
# Selfcheck first, so the drift detector is proved on every machine, not only
# where lesson-builder is on disk. The vendored copy is the canonical file put
# through an ASCII table under a six-line banner, so the copy minus its banner
# is a source the check must accept, and that plus one line is one it must not.
sc="$TMPROOT/sc-voice-drift"; mkdir -p "$sc/clean/references" "$sc/dirty/references"
tail -n +7 "$REPO/references/teaching-communication.md" > "$sc/clean/references/teaching-communication.md"
{ cat "$sc/clean/references/teaching-communication.md"; printf '\nA line the vendored copy does not have.\n'; } \
  > "$sc/dirty/references/teaching-communication.md"
out=$("$REPO/scripts/voice-drift.sh" --source "$sc/dirty" 2>&1); rc=$?
if [ "$rc" -ne 1 ]; then
  fail "selfcheck voice-drift: a mutated source exited $rc, expected 1"; printf '%s\n' "$out" | sed 's/^/  /'
else
  out=$("$REPO/scripts/voice-drift.sh" --source "$sc/clean" 2>&1); rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "selfcheck voice-drift: the matching source exited $rc, expected 0"; printf '%s\n' "$out" | sed 's/^/  /'
  else
    pass "selfcheck voice-drift: flags a mutated source, accepts a matching one"
  fi
fi

out=$("$REPO/scripts/voice-drift.sh" 2>&1); rc=$?
case "$rc" in
  0) pass "voice drift: vendored spec matches lesson-builder" ;;
  3) skip "voice drift" "${out#voice-drift: }" ;;
  *) fail "voice drift"; printf '%s\n' "$out" | sed 's/^/  /' ;;
esac

# --- 6. the templates compile ------------------------------------------------
if ! command -v lualatex >/dev/null; then
  skip "template compile" "no lualatex on this machine"
else
  D="$TMPROOT/tex"; mkdir -p "$D"
  cp "$REPO/assets/preamble-template.tex" "$D/"

  # The preamble is everything before \begin{document}, so a smoke document can
  # \input it and then exercise every box and macro the briefs promise writers.
  cat > "$D/preamble-smoke.tex" <<'TEXEOF'
\input{preamble-template.tex}
\begin{document}
\hstitleblock{Smoke}{Preamble smoke test}{One lead line.}
\section{First section}\label{sec:first}
\insight{One conclusion, once.}
Body with \cat{A} \tool{5} \tools{T4,T5}. Out of scope here.\opt
\opt An optional paragraph starts with the tag.
\begin{derivation}
\begin{equation} \Ohof{n \log n},\ X^\trans,\ \bx,\ \pderiv{u}{t},\ \ppderiv{u}{x},\ \pmderiv{u}{x}{y},\ \diff{x},\ \R,\ \RR{n},\ \grad f,\ \Hess,\ \bzero \label{eq:a}\end{equation}
where $X$ is a matrix.
\end{derivation}
Text before a sheet equation.
\onsheet
\begin{equation} e^{i\theta} = \cos\theta + i\sin\theta \end{equation}
See \eqref{eq:a} and \nameref{sec:first}.
\probhead{Final 2024 Q3}{method}{A}
\begin{hsblock}\begin{tabularx}{\linewidth}{L{3cm}YR{2cm}}\hstoprule \hshead{Key} & \hsaccenthead{New} & \hshead{N} \\ \hstoprule a & b & 1 \\ \hline c & d & 2 \\ \hstoprule\end{tabularx}\end{hsblock}
\begin{hscallout}{The objection} Not a box.\end{hscallout}
\hslisting{Listing 1 / code}
\begin{Verbatim}[bgcolor=codefill]
int main() { return 0; }
\end{Verbatim}
\catbanner{B}{Category title}\label{part:b}
\section{Next}
\begin{hsstatrow}\hsstat{1}{a}\hsstat{2}{b}\hsstat{3}{c}\hsstat{4}{d}\end{hsstatrow}
\hsclaim{The one claim.}{One per document}
\begin{hssources}\item A source, read 2026-09-22. \end{hssources}
\hsprovenance{built by smoke}
\end{document}
TEXEOF

  # The driver is a template: its preamble is a copy-here comment and its
  # section files do not exist yet. Supply the first, comment out the second,
  # give it one section of content. The substitution is asserted to have hit
  # something, so a driver that stopped using \input stubs fails here loudly
  # rather than compiling an empty document.
  if python3 - "$REPO/assets/driver-template.tex" "$D/driver-smoke.tex" <<'PYEOF'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding='utf-8').read()
text, n = re.subn(r'^(\\input\{course_notes/[^}]*\})', r'% (tests/check.sh) \1',
                  text, flags=re.M)
if n == 0:
    print('  driver-template.tex has no \\input{course_notes/...} stubs to stub out')
    sys.exit(1)
if '\\end{document}' not in text:
    print('  driver-template.tex has no \\end{document}')
    sys.exit(1)
text = text.replace('\\end{document}',
                    '\\section{Driver smoke test}\n'
                    'Body supplied by tests/check.sh in place of the %d section files.\n\n'
                    '\\end{document}' % n)
open(dst, 'w', encoding='utf-8').write('\\input{preamble-template.tex}\n' + text)
PYEOF
  then
    for job in preamble-smoke driver-smoke; do
      if ! out=$("$REPO/scripts/build.sh" "$D/$job.tex" 2>&1); then
        fail "$job: scripts/build.sh failed"; printf '%s\n' "$out" | head -8 | sed 's/^/  /'
      elif [ -s "$D/$job.pdf" ]; then
        pass "$job builds in three lualatex passes ($(wc -c < "$D/$job.pdf") bytes)"
      else
        fail "$job: scripts/build.sh exited 0 but the PDF is empty or missing"
      fi
    done
  else
    fail "driver-smoke: could not build the driver fixture"
  fi

  # Paper size: the default build is letter, and the template's A4 line, once
  # uncommented, gives A4 (pdfinfo: 612 x 792 pts letter, 595 x 842 pts A4).
  if ! command -v pdfinfo >/dev/null; then
    skip "paper size" "no pdfinfo on this machine"
  else
    sed 's/^% \\newcommand\\hspaper{a4paper}$/\\newcommand\\hspaper{a4paper}/' \
      "$D/preamble-template.tex" > "$D/preamble-a4.tex"
    sed 's/preamble-template\.tex/preamble-a4.tex/' "$D/preamble-smoke.tex" > "$D/a4-smoke.tex"
    # Rounded to whole points: pdfinfo prints A4 as 595.276 x 841.89 pts.
    size() { pdfinfo "$1" 2>/dev/null | awk '/^Page size:/ { printf "%.0f x %.0f pts", $3, $5 }'; }
    ls=$(size "$D/preamble-smoke.pdf")
    if [ "$ls" = "612 x 792 pts" ]; then pass "default paper is letter ($ls)"
    else fail "default paper: pdfinfo says '$ls', expected 612 x 792 pts"; fi
    if cmp -s "$D/preamble-template.tex" "$D/preamble-a4.tex"; then
      fail "paper size A4: the template has no '% \\newcommand\\hspaper{a4paper}' line to uncomment"
    elif ! out=$("$REPO/scripts/build.sh" "$D/a4-smoke.tex" 2>&1); then
      fail "a4-smoke: scripts/build.sh failed"; printf '%s\n' "$out" | head -8 | sed 's/^/  /'
    else
      as=$(size "$D/a4-smoke.pdf")
      if [ "$as" = "595 x 842 pts" ]; then pass "the template's A4 line gives A4 ($as)"
      else fail "paper size A4: pdfinfo says '$as', expected 595 x 842 pts"; fi
    fi
  fi
fi

# --- 6b. the short and long templates build ------------------------------------
# Both \input the preamble, as a document started from them does. The long one
# is built three ways: as shipped, with its \hsnumbersections line uncommented,
# and on A4. An overfull box fails the build, so each also proves the page fits.
if command -v lualatex >/dev/null; then
  cp "$REPO/assets/short-template.tex" "$REPO/assets/blank-template.tex" "$D/"
  sed 's/^% \\hsnumbersections .*/\\hsnumbersections/' "$D/blank-template.tex" > "$D/blank-numbered.tex"
  sed 's/preamble-template\.tex/preamble-a4.tex/' "$D/blank-template.tex" > "$D/blank-a4.tex"
  sed 's/^% \\hsjustified .*/\\hsjustified/' "$D/blank-template.tex" > "$D/blank-justified.tex"
  [ -f "$D/preamble-a4.tex" ] || sed 's/^% \\newcommand\\hspaper{a4paper}$/\\newcommand\\hspaper{a4paper}/' \
    "$D/preamble-template.tex" > "$D/preamble-a4.tex"
  if cmp -s "$D/blank-template.tex" "$D/blank-numbered.tex"; then
    fail "blank-numbered: blank-template.tex has no '% \\hsnumbersections' line to uncomment"
  fi
  if cmp -s "$D/blank-template.tex" "$D/blank-justified.tex"; then
    fail "blank-justified: blank-template.tex has no '% \\hsjustified' line to uncomment"
  fi
  for job in short-template blank-template blank-numbered blank-a4 blank-justified; do
    if ! out=$("$REPO/scripts/build.sh" "$D/$job.tex" 2>&1); then
      fail "$job: scripts/build.sh failed"; printf '%s\n' "$out" | head -8 | sed 's/^/  /'
    else
      pass "$job builds in three lualatex passes with no overfull box"
    fi
  done
  if ! command -v pdftotext >/dev/null; then
    skip "contents page" "no pdftotext on this machine"
  else
    # Page 2 is the contents. The Part number is small caps, which pdftotext
    # reads back as capitals; without titlesec's newparttoc the line is a bare
    # "1" and there is no PART at all.
    toc=$(pdftotext -f 2 -l 2 "$D/blank-template.pdf" - 2>/dev/null)
    if printf '%s\n' "$toc" | grep -qx 'PART 1'; then
      pass "contents page sets the Part as a small-caps 'Part 1' column"
    else
      fail "contents page: no 'PART 1' line on page 2"; printf '%s\n' "$toc" | head -12 | sed 's/^/  /'
    fi
    # The prose setting is a glue assignment; written wrong ("\rightskip=
    # \hsprosegap plus 3em" with a skip register), it prints "plus 3em" on
    # the page instead of stretching the line.
    for job in short-template blank-template blank-justified; do
      if pdftotext "$D/$job.pdf" - 2>/dev/null | grep -Eq 'plus [0-9.]*(em|fil|pt)'; then
        fail "$job: a glue spec ('plus ...') is printed on the page"
      else
        pass "$job: no glue spec leaks onto the page"
      fi
    done
    toc=$(pdftotext -f 2 -l 2 "$D/blank-numbered.pdf" - 2>/dev/null)
    if printf '%s\n' "$toc" | grep -qx '1 First section'; then
      pass "numbered contents page carries the section number"
    else
      fail "numbered contents page: no '1 First section' line on page 2"; printf '%s\n' "$toc" | head -12 | sed 's/^/  /'
    fi
  fi
  if command -v pdfinfo >/dev/null; then
    as=$(pdfinfo "$D/blank-a4.pdf" 2>/dev/null | awk '/^Page size:/ { printf "%.0f x %.0f pts", $3, $5 }')
    if [ "$as" = "595 x 842 pts" ]; then pass "blank-template on A4 is A4 ($as)"
    else fail "blank-template on A4: pdfinfo says '$as', expected 595 x 842 pts"; fi
  fi
  if command -v pdffonts >/dev/null; then
    fonts=$(pdffonts "$D/blank-template.pdf" 2>&1)
    for face in SourceSerif4Subhead-Regular SourceSerif4Display-Regular SourceSerif4-Semibold; do
      if printf '%s\n' "$fonts" | grep -E "\+$face[ -]" | grep -q ' yes '; then
        pass "blank-template embeds $face"
      else
        fail "blank-template: $face is not embedded"; printf '%s\n' "$fonts" | sed 's/^/  /'
      fi
    done
  fi
fi

# --- 7. the diagram patterns in references/page-composition.md still compile ---
# A writer copies these three straight out of the file, so a style the .sty
# renamed and a snippet nobody recompiled is a pattern that fails in their
# document, not in ours. Each latex block is built as its own page; the run also
# fails on an Overfull box, because a picture wider than the measure prints past
# the right margin and that is what the reference is meant to be an answer to.
if ! command -v lualatex >/dev/null; then
  skip "page-composition snippets" "no lualatex on this machine"
else
  C="$TMPROOT/patterns"; mkdir -p "$C"
  python3 - "$REPO/references/page-composition.md" "$C/patterns.tex" <<'PYEOF'
import re, sys
md = open(sys.argv[1]).read()
blocks = re.findall(r'```latex\n(.*?)```', md, re.S)
if not blocks:
    sys.exit("no ```latex blocks in page-composition.md")
head = ('\\documentclass[11pt]{article}\n\\usepackage{housestyle}\n'
        '\\hsslug{Diagram patterns}\n\\hssection{Patterns}\n\\begin{document}\n')
open(sys.argv[2], 'w').write(head + '\n\n\\clearpage\n\n'.join(blocks) + '\n\\end{document}\n')
PYEOF
  n=$(python3 -c "import re,sys;print(len(re.findall(r'\`\`\`latex',open(sys.argv[1]).read())))" "$REPO/references/page-composition.md")
  if [ "$n" -lt 3 ]; then
    fail "page-composition snippets: found $n latex blocks, expected the three diagram patterns"
  elif ! out=$("$REPO/scripts/build.sh" "$C/patterns.tex" 2>&1); then
    fail "page-composition snippets: one of the $n patterns does not build cleanly"
    printf '%s\n' "$out" | head -8 | sed 's/^/  /'
  else
    pass "page-composition's $n diagram patterns compile against housestyle.sty"
    (cd "$C" && TEXINPUTS=".:$REPO/references/house-style//:" \
      lualatex -interaction=nonstopmode -jobname=ovf patterns.tex >/dev/null 2>&1) || true
    if [ ! -s "$C/ovf.log" ]; then
      skip "page-composition snippets fit the measure" "no log written"
    elif over=$(grep -c 'Overfull \\hbox' "$C/ovf.log") && [ "$over" -gt 0 ]; then
      fail "page-composition snippets: $over overfull hbox(es); a pattern is wider than the measure"
      grep -A1 'Overfull \\hbox' "$C/ovf.log" | head -6 | sed 's/^/  /'
    else
      pass "page-composition's diagram patterns fit the measure with no overfull box"
    fi
  fi
fi

# --- 8. the owner's example builds and embeds both faces ----------------------
if ! command -v lualatex >/dev/null; then
  skip "house-style example" "no lualatex on this machine"
else
  E="$TMPROOT/example"; mkdir -p "$E"
  cp "$REPO/references/house-style/example.tex" "$E/"
  # Mark the copy, so the build can be told from the repo's own example.tex.
  sed -i 's/^\\end{document}/\\clearpage\\noindent HSCOPY-7c3e\\par\n&/' "$E/example.tex"
  if ! out=$("$REPO/scripts/build.sh" "$E/example.tex" 2>&1); then
    fail "house-style example: scripts/build.sh failed"; printf '%s\n' "$out" | head -8 | sed 's/^/  /'
  else
    pass "house-style example builds in three lualatex passes with no ! errors"
    if ! command -v pdftotext >/dev/null; then
      skip "house-style example is the copy" "no pdftotext on this machine"
    elif pdftotext "$E/example.pdf" - 2>/dev/null | grep -q 'HSCOPY-7c3e'; then
      pass "house-style example builds the copy, not the repo's own example.tex"
    else
      fail "house-style example: the PDF lacks the copy's marker, so build.sh compiled another example.tex"
    fi
    if ! command -v pdffonts >/dev/null; then
      skip "house-style example fonts" "no pdffonts on this machine"
    else
      fonts=$(pdffonts "$E/example.pdf" 2>&1)
      for face in SourceSerif4-Regular IBMPlexMono; do
        if printf '%s\n' "$fonts" | grep -E "\+$face[ -]" | grep -q ' yes '; then
          pass "house-style example embeds $face"
        else
          fail "house-style example: $face is not embedded"; printf '%s\n' "$fonts" | sed 's/^/  /'
        fi
      done
    fi
  fi
fi

# --- 9. the font lookup and the example, in place ----------------------------
# Case 7 copies the example away from housestyle.sty, so kpse finds the .sty by
# its absolute path. Built in its own directory, "." is searched first (build.sh
# and a bare lualatex run alike) and kpse returns ./housestyle.sty instead. The
# probe forces that with TEXINPUTS=.: and runs only the .sty's \hsfontdir block.
if ! command -v lualatex >/dev/null; then
  skip "house-style font lookup in place" "no lualatex on this machine"
  skip "house-style example in place" "no lualatex on this machine"
else
  HS="$REPO/references/house-style"
  P="$TMPROOT/fontdir"; mkdir -p "$P"
  sed -n '/^\\ifdefined\\hsfontdir/,/^\\fi/p' "$HS/housestyle.sty" > "$P/block.tex"
  printf '%s\n' '\directlua{texio.write_nl("KPSE=" .. kpse.find_file("housestyle.sty", "tex") .. "|")}' \
    '\input{block.tex}' '\directlua{texio.write_nl("FONTDIR=" .. "\hsfontdir" .. "|")}' '\end' > "$P/probe.tex"
  (cd "$HS" && TEXINPUTS="$P:.:" max_print_line=10000 \
    lualatex -interaction=nonstopmode -output-directory="$P" "$P/probe.tex" >/dev/null 2>&1)
  kp=$(grep -o 'KPSE=[^|]*' "$P/probe.log" 2>/dev/null); fd=$(grep -o 'FONTDIR=[^|]*' "$P/probe.log" 2>/dev/null)
  if [ ! -s "$P/block.tex" ]; then
    fail "house-style font lookup in place: no \\hsfontdir block found in housestyle.sty"
  elif [ "$kp" != "KPSE=./housestyle.sty" ]; then
    fail "house-style font lookup in place: kpse returned '${kp#KPSE=}', not ./housestyle.sty"
  elif [ "$fd" != "FONTDIR=$REPO/assets/fonts/" ]; then
    fail "house-style font lookup in place: resolved '${fd#FONTDIR=}', expected $REPO/assets/fonts/"
  else
    pass "house-style font lookup resolves assets/fonts/ when kpse returns ./housestyle.sty"
  fi

  if [ -e "$HS/example.pdf" ]; then
    fail "house-style example in place: $HS/example.pdf already exists; remove it first"
  else
    if ! out=$("$REPO/scripts/build.sh" "$HS/example.tex" 2>&1); then
      fail "house-style example in place: scripts/build.sh failed"; printf '%s\n' "$out" | head -8 | sed 's/^/  /'
    elif ! command -v pdffonts >/dev/null; then
      pass "house-style example builds in place"
      skip "house-style example in place fonts" "no pdffonts on this machine"
    elif pdffonts "$HS/example.pdf" 2>&1 | grep -E '\+SourceSerif4-Regular[ -]' | grep -q ' yes '; then
      pass "house-style example builds in place and embeds the vendored SourceSerif4-Regular"
    else
      fail "house-style example in place: vendored SourceSerif4-Regular is not embedded"
      pdffonts "$HS/example.pdf" 2>&1 | sed 's/^/  /'
    fi
    rm -f "$HS/example.pdf"
  fi
fi

# --- 10. build.sh fails on an overfull box ------------------------------------
if ! command -v lualatex >/dev/null; then
  skip "build.sh overfull selfcheck" "no lualatex on this machine"
else
  O="$TMPROOT/overfull"; mkdir -p "$O"
  printf '%s\n' '\documentclass{article}' '\begin{document}' '\noindent\hbox to 700pt{wide\hfil}' \
    '\end{document}' > "$O/wide.tex"
  printf '%s\n' '\documentclass{article}' '\begin{document}' '\noindent\hbox to 300pt{fits\hfil}' \
    '\end{document}' > "$O/fits.tex"
  out=$("$REPO/scripts/build.sh" "$O/wide.tex" 2>&1); rc=$?
  if [ "$rc" -ne 1 ] || ! printf '%s\n' "$out" | grep -q 'Overfull \\hbox'; then
    fail "selfcheck build.sh overfull: a 700 pt box exited $rc without naming the overfull box"
    printf '%s\n' "$out" | head -6 | sed 's/^/  /'
  elif ! out=$("$REPO/scripts/build.sh" "$O/fits.tex" 2>&1); then
    fail "selfcheck build.sh overfull: a box that fits was refused"; printf '%s\n' "$out" | head -6 | sed 's/^/  /'
  else
    pass "selfcheck build.sh: fails on an Overfull \\hbox, passes the same document that fits"
  fi
fi

# --- 11. provenance keeps a command's -- ---------------------------------------
if ! command -v lualatex >/dev/null; then
  skip "provenance keeps --" "no lualatex on this machine"
elif ! command -v pdftotext >/dev/null; then
  skip "provenance keeps --" "no pdftotext on this machine"
else
  V="$TMPROOT/provenance"; mkdir -p "$V"
  printf '%s\n' '\documentclass[11pt]{article}' '\usepackage{housestyle}' '%SWAP' '\begin{document}' \
    'Body.' '\hsprovenance{741 from gh pr list --state merged; a---b.}' '\end{document}' > "$V/own.tex"
  # The same document with the provenance font replaced by the body face,
  # whose TeX ligatures are on: only the .sty's own guard can keep the -- now.
  sed 's/^%SWAP$/\\makeatletter\\let\\hs@notefont\\rmfamily\\makeatother/' "$V/own.tex" > "$V/swapped.tex"
  for job in own swapped; do
    if ! out=$("$REPO/scripts/build.sh" "$V/$job.tex" 2>&1); then
      fail "provenance ($job font): scripts/build.sh failed"; printf '%s\n' "$out" | head -6 | sed 's/^/  /'
    elif txt=$(pdftotext "$V/$job.pdf" - 2>/dev/null) && printf '%s\n' "$txt" | grep -q -- 'list --state merged; a---b\.'; then
      pass "provenance ($job font) keeps --state and --- as typed"
    else
      fail "provenance ($job font): a typed -- came out as a dash"; printf '%s\n' "$txt" | sed 's/^/  /'
    fi
  done
fi

# --- 12. a label splits only at " / " -------------------------------------------
if ! command -v lualatex >/dev/null; then
  skip "label split" "no lualatex on this machine"
elif ! command -v pdftotext >/dev/null; then
  skip "label split" "no pdftotext on this machine"
else
  L="$TMPROOT/labelsplit"; mkdir -p "$L"
  printf '%s\n' '\documentclass[11pt]{article}' '\usepackage{housestyle}' '\begin{document}' \
    '\hslabel{Pass/fail}\par' '\hslabel{Figure 2 / what it shows}\par' '\end{document}' > "$L/l.tex"
  if ! out=$("$REPO/scripts/build.sh" "$L/l.tex" 2>&1); then
    fail "label split: scripts/build.sh failed"; printf '%s\n' "$out" | head -6 | sed 's/^/  /'
  elif txt=$(pdftotext "$L/l.pdf" - 2>/dev/null) && printf '%s\n' "$txt" | grep -qi 'pass/fail' \
       && printf '%s\n' "$txt" | grep -i 'figure 2' | grep -qv '/'; then
    pass "label split: Pass/fail stays whole, Figure 2 / title splits"
  else
    fail "label split: a bare / split a label, or \" / \" did not"; printf '%s\n' "$txt" | sed 's/^/  /'
  fi
fi

# --- 13. \hsdiagram places a diagram-maker PDF -----------------------------------
# The bundled diagram-maker draws two of its own examples: a flow at canvas 576,
# the letter measure in px, which lands at 1:1, and a gate at its default width,
# which \hsdiagram scales down. build.sh renders and exports both. PMB_SYNC=0
# keeps the case hermetic: it uses the diagram-maker already checked out.
DM="$REPO/diagram-maker"
if ! command -v lualatex >/dev/null; then
  skip "hsdiagram" "no lualatex on this machine"
elif [ ! -f "$DM/scripts/render.js" ] || [ ! -f "$DM/examples/flow.json" ]; then
  skip "hsdiagram" "diagram-maker is not checked out in $DM (git submodule update --init)"
elif ! command -v node >/dev/null; then
  skip "hsdiagram" "no node on this machine"
else
  G="$TMPROOT/hsdiagram"; mkdir -p "$G/figures"
  python3 - "$DM/examples" "$G/figures" <<'PYEOF'
import json, os, sys
src, dst = sys.argv[1], sys.argv[2]
flow = json.load(open(os.path.join(src, 'flow.json')))
flow['nodes'] = flow['nodes'][:2] + flow['nodes'][-1:]   # three boxes fit 576 px
flow['canvas'] = 576
json.dump(flow, open(os.path.join(dst, 'flow.json'), 'w'))
json.dump(json.load(open(os.path.join(src, 'gate.json'))), open(os.path.join(dst, 'gate.json'), 'w'))
PYEOF
  printf '%s\n' '\documentclass[11pt]{article}' '\usepackage{housestyle}' '\hsslug{Socket}' \
    '\begin{document}' 'Body.' \
    '\begin{hsfigure}{Figure 1 / at the measure}{Rendered at canvas 576.}' '\hsdiagram{figures/flow}' '\end{hsfigure}' \
    '\begin{hsfigure}{Figure 2 / scaled down}{Rendered at its default width.}' '\hsdiagram{figures/gate}' '\end{hsfigure}' \
    '\end{document}' > "$G/doc.tex"
  out=$(PMB_SYNC=0 "$REPO/scripts/build.sh" "$G/doc.tex" 2>&1); rc=$?
  if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'export.sh found no converter'; then
    skip "hsdiagram" "diagram-maker's export.sh has no converter here (no rsvg-convert, no Chrome)"
  elif [ "$rc" -ne 0 ]; then
    fail "hsdiagram: scripts/build.sh failed"; printf '%s\n' "$out" | head -8 | sed 's/^/  /'
  elif ! [ -s "$G/figures/flow.pdf" ] || ! [ -s "$G/figures/gate.pdf" ]; then
    fail "hsdiagram: build.sh exited 0 but did not export figures/flow.pdf and figures/gate.pdf"
  elif command -v pdftotext >/dev/null && ! pdftotext "$G/doc.pdf" - 2>/dev/null | grep -q 'Planning agent'; then
    fail "hsdiagram: the page does not carry the flow figure's text"
  else
    fw=$(pdfinfo "$G/figures/flow.pdf" 2>/dev/null | awk '/^Page size:/ { printf "%.0f", $3 }')
    pass "hsdiagram places two diagram-maker figures, ${fw:-?} pt and wider, with no overfull box"
  fi
  # A spec diagram-maker rejects stops the build before lualatex runs.
  printf '%s\n' '{"type": "flow", "alt": "too wide", "canvas": 300, "nodes": [' \
    '{"title": "One", "role": "io"}, {"title": "Two", "role": "work"}, {"title": "Three", "role": "io"}]}' \
    > "$G/figures/gate.json"
  out=$(PMB_SYNC=0 "$REPO/scripts/build.sh" "$G/doc.tex" 2>&1); rc=$?
  if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q 'could not render figures/gate.json'; then
    pass "hsdiagram: a spec diagram-maker rejects fails the build and names it"
  else
    fail "hsdiagram: a rejected spec exited $rc without naming it"; printf '%s\n' "$out" | head -6 | sed 's/^/  /'
  fi
fi

# --- 14. install.sh and the diagram-maker sync, on scratch clones -----------------
# Everything is a local bare repo: $I/origin.git plays this repo's GitHub,
# $I/dm.git diagram-maker's. A "dev" clone carries install.sh as cc-land runs it,
# from a checkout; $I/skill is the installed clone it updates.
I="$TMPROOT/install"; mkdir -p "$I"
export GIT_CONFIG_COUNT=3 GIT_CONFIG_KEY_0=protocol.file.allow GIT_CONFIG_VALUE_0=always \
  GIT_CONFIG_KEY_1=user.name GIT_CONFIG_VALUE_1=check GIT_CONFIG_KEY_2=user.email GIT_CONFIG_VALUE_2=check@localhost
q() { git "$@" >/dev/null 2>&1; }
dmtip() { git -C "$I/dm.git" rev-parse main; }
dmcommit() {   # one more commit on diagram-maker's main
  q -C "$I/dmwork" commit --allow-empty -m "$1" && q -C "$I/dmwork" push -q origin main
}
q init -q --bare -b main "$I/dm.git" && q clone -q "$I/dm.git" "$I/dmwork" \
  && q -C "$I/dmwork" checkout -q -b main && echo one > "$I/dmwork/f" && q -C "$I/dmwork" add f \
  && q -C "$I/dmwork" commit -q -m one && q -C "$I/dmwork" push -q origin main
q init -q --bare -b main "$I/origin.git" && q clone -q "$I/origin.git" "$I/dev" && q -C "$I/dev" checkout -q -b main
mkdir -p "$I/dev/scripts"
cp "$REPO/install.sh" "$I/dev/"; cp "$REPO/scripts/sync-diagram-maker.sh" "$I/dev/scripts/"
q -C "$I/dev" submodule add -q -b main "$I/dm.git" diagram-maker
q -C "$I/dev" add -A && q -C "$I/dev" commit -q -m first && q -C "$I/dev" push -q origin main
q clone -q --recurse-submodules "$I/origin.git" "$I/skill"
pin1=$(git -C "$I/dev" rev-parse HEAD:diagram-maker 2>/dev/null)

inst() { PMB_SKILL_DIR="$1" "$I/dev/install.sh" 2>&1; }
state() { git -C "$I/skill" rev-parse HEAD 2>/dev/null; git -C "$I/skill/diagram-maker" rev-parse HEAD 2>/dev/null; git -C "$I/skill" status --porcelain 2>/dev/null; }

if [ -z "$pin1" ] || [ ! -f "$I/skill/diagram-maker/f" ]; then
  fail "install.sh: could not build the scratch repositories"
else
  # Left alone, exit 0: missing, a plain directory, a symlink, a foreign clone.
  mkdir -p "$I/plain"; ln -s "$I/dev" "$I/link"; q clone -q "$I/dm.git" "$I/foreign"
  devhead=$(git -C "$I/dev" rev-parse HEAD); ok=1
  for d in "$I/missing" "$I/plain" "$I/link" "$I/foreign"; do
    out=$(inst "$d"); rc=$?
    if [ "$rc" -ne 0 ] || [ -z "$out" ]; then
      ok=0; fail "install.sh on $(basename "$d"): exit $rc, expected 0 with a reason"; printf '%s\n' "$out" | sed 's/^/  /'
    fi
  done
  if [ -e "$I/missing" ] || [ -n "$(ls -A "$I/plain")" ] || [ "$(git -C "$I/dev" rev-parse HEAD)" != "$devhead" ] \
     || [ "$(git -C "$I/foreign" rev-parse HEAD)" != "$(git -C "$I/dm.git" rev-parse main)" ]; then
    ok=0; fail "install.sh touched a directory it should have left alone"
  fi
  [ "$ok" = 1 ] && pass "install.sh leaves a missing, plain, symlinked or foreign directory alone, exit 0"

  # Behind by one commit, and diagram-maker has moved past the pin.
  echo two > "$I/dev/x" && q -C "$I/dev" add x && q -C "$I/dev" commit -q -m second && q -C "$I/dev" push -q origin main
  dmcommit "dm two"
  out=$(inst "$I/skill"); rc=$?
  if [ "$rc" -ne 0 ]; then
    fail "install.sh: exit $rc on a clone one commit behind"; printf '%s\n' "$out" | sed 's/^/  /'
  elif [ "$(git -C "$I/skill" rev-parse HEAD)" != "$(git -C "$I/origin.git" rev-parse main)" ]; then
    fail "install.sh: the clone was not fast-forwarded to origin/main"
  elif [ "$(git -C "$I/skill/diagram-maker" rev-parse HEAD)" != "$(dmtip)" ]; then
    fail "install.sh: diagram-maker is not at its latest main (the pin is behind it)"
  elif [ -L "$I/skill" ]; then
    fail "install.sh: the installed skill became a symlink"
  else
    pass "install.sh fast-forwards the clone and moves diagram-maker past the pin to its main"
    before=$(state); out=$(inst "$I/skill"); rc=$?
    if [ "$rc" -eq 0 ] && [ "$(state)" = "$before" ]; then
      pass "install.sh run again changes nothing"
    else
      fail "install.sh run again: exit $rc, or the clone changed"; printf '%s\n' "$out" | sed 's/^/  /'
    fi
  fi

  # A pin bump lands while the installed submodule is already ahead of it.
  q -C "$I/dev/diagram-maker" fetch -q origin && q -C "$I/dev/diagram-maker" checkout -q origin/main \
    && q -C "$I/dev" add diagram-maker && q -C "$I/dev" commit -q -m bump && q -C "$I/dev" push -q origin main
  dmcommit "dm three"
  out=$(inst "$I/skill"); rc=$?
  if [ "$rc" -eq 0 ] && [ "$(git -C "$I/skill" rev-parse HEAD)" = "$(git -C "$I/origin.git" rev-parse main)" ] \
     && [ "$(git -C "$I/skill/diagram-maker" rev-parse HEAD)" = "$(dmtip)" ]; then
    pass "install.sh fast-forwards over a pin bump with the submodule already ahead"
  else
    fail "install.sh over a pin bump: exit $rc, or the clone or diagram-maker is behind"; printf '%s\n' "$out" | sed 's/^/  /'
  fi

  # The sync: a new diagram-maker commit reaches the skill with no landing here.
  dmcommit "dm four"
  out=$("$I/skill/scripts/sync-diagram-maker.sh" 2>&1); rc=$?
  if [ "$rc" -eq 0 ] && [ -z "$out" ] && [ "$(git -C "$I/skill/diagram-maker" rev-parse HEAD)" = "$(dmtip)" ]; then
    pass "sync-diagram-maker moves the bundled diagram-maker to its new main, silently"
  else
    fail "sync-diagram-maker: exit $rc, or diagram-maker is not at its new main"; printf '%s\n' "$out" | sed 's/^/  /'
  fi
  # Unreachable: the submodule's remote points nowhere. Exit 0, nothing printed.
  have=$(git -C "$I/skill/diagram-maker" rev-parse HEAD)
  q -C "$I/skill/diagram-maker" remote set-url origin "$I/nowhere.git"
  out=$("$I/skill/scripts/sync-diagram-maker.sh" 2>&1); rc=$?
  if [ "$rc" -eq 0 ] && [ -z "$out" ] && [ "$(git -C "$I/skill/diagram-maker" rev-parse HEAD)" = "$have" ]; then
    pass "sync-diagram-maker with the remote unreachable: exit 0, silent, copy kept"
  else
    fail "sync-diagram-maker unreachable: exit $rc, or it printed or moved something"; printf '%s\n' "$out" | sed 's/^/  /'
  fi
  q -C "$I/skill/diagram-maker" remote set-url origin "$I/dm.git"
  # Vendored inside another repo: the enclosing repo's submodules are not its own.
  q init -q -b main "$I/host" && mkdir -p "$I/host/.claude/skills/pmb/scripts" \
    && cp "$I/skill/scripts/sync-diagram-maker.sh" "$I/host/.claude/skills/pmb/scripts/" \
    && cp "$I/skill/.gitmodules" "$I/host/.claude/skills/pmb/" && q -C "$I/host" add -A && q -C "$I/host" commit -q -m host
  out=$("$I/host/.claude/skills/pmb/scripts/sync-diagram-maker.sh" 2>&1); rc=$?
  if [ "$rc" -eq 0 ] && [ -z "$out" ] && [ -z "$(git -C "$I/host" status --porcelain)" ] && [ ! -e "$I/host/.claude/skills/pmb/diagram-maker/f" ]; then
    pass "sync-diagram-maker in a vendored copy is a no-op"
  else
    fail "sync-diagram-maker in a vendored copy touched the enclosing repo (exit $rc)"; git -C "$I/host" status --porcelain | sed 's/^/  /'
  fi

  # A local commit in the installed clone: exit 1, nothing moved.
  q -C "$I/skill" commit -q --allow-empty -m local
  echo three > "$I/dev/y" && q -C "$I/dev" add y && q -C "$I/dev" commit -q -m third && q -C "$I/dev" push -q origin main
  mine=$(git -C "$I/skill" rev-parse HEAD)
  out=$(inst "$I/skill"); rc=$?
  if [ "$rc" -eq 1 ] && [ "$(git -C "$I/skill" rev-parse HEAD)" = "$mine" ] && printf '%s\n' "$out" | grep -q 'cannot fast-forward'; then
    pass "install.sh refuses, exit 1, when a local commit is in the way, and moves nothing"
  else
    fail "install.sh with a local commit: exit $rc, expected 1 with main left where it was"; printf '%s\n' "$out" | sed 's/^/  /'
  fi
fi
unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0 GIT_CONFIG_KEY_1 GIT_CONFIG_VALUE_1 GIT_CONFIG_KEY_2 GIT_CONFIG_VALUE_2

# --- 15. the document register: number in the foot, filed after a clean build --
if ! command -v lualatex >/dev/null || ! command -v pdftotext >/dev/null; then
  skip "document register" "no lualatex or pdftotext on this machine"
else
  N="$TMPROOT/docreg"; mkdir -p "$N/bin"
  cat > "$N/bin/cc-docs" <<'SHEOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOCLOG"
case "$1" in
  number) printf '\\def\\docnumber{123-0045-B}\\def\\docstamp{123-0045-B \xc2\xb7 24 Sep 2026}\n' ;;
  file) printf '123-0045-B\t/filed.pdf\tfiled\n' ;;
esac
SHEOF
  chmod +x "$N/bin/cc-docs"
  # PATH with every real cc-docs taken out, so no case can reach a live register.
  bare=""; IFS=: read -ra dirs <<< "$PATH"
  for p in "${dirs[@]}"; do [ -x "$p/cc-docs" ] || bare="$bare${bare:+:}$p"; done
  # mk <case>: a fresh two-page document, title page first, in its own directory.
  mk() {
    mkdir -p "$N/$1"
    printf '%s\n' '\documentclass{article}' '\usepackage{housestyle}' \
      '\fancyfoot[L]{\hsrunlabel{\textcopyright{} 2026 Copyright Holder}}' '\begin{document}' \
      '\thispagestyle{hstitlepage}' 'Title page.' '\newpage' 'Body page.' '\end{document}' > "$N/$1/doc.tex"
    : > "$N/$1.log"
  }
  # page <case> <n>: page n's text, blank lines dropped and spaces squeezed.
  page() { pdftotext -layout -f "$2" -l "$2" "$N/$1/doc.pdf" - | tr -s ' ' | grep -v '^ *$'; }
  run() { local c="$1" path="$2"; shift 2; env PATH="$path" DOCLOG="$N/$c.log" "$@" "$REPO/scripts/build.sh" "$N/$c/doc.tex" 2>&1; }

  mk draft; out=$(run draft "$N/bin:$bare"); rc=$?
  if [ "$rc" -ne 0 ] || [ -s "$N/draft.log" ] || pdftotext "$N/draft/doc.pdf" - | grep -q '123-0045'; then
    fail "register: a build with no DOC_* variables called cc-docs or printed a number (exit $rc)"; printf '%s\n' "$out" | head -6 | sed 's/^/  /'
  else
    pass "register: a draft build calls no cc-docs and prints no number"
  fi

  mk nodocs; out=$(run nodocs "$bare" DOC_PROJECT=P DOC_TITLE=T); rc=$?
  if [ "$rc" -ne 0 ] || pdftotext "$N/nodocs/doc.pdf" - | grep -q '123-0045'; then
    fail "register: DOC_PROJECT with no cc-docs on PATH did not build as a draft (exit $rc)"; printf '%s\n' "$out" | head -6 | sed 's/^/  /'
  else
    pass "register: with no cc-docs on PATH the variables change nothing"
  fi

  mk final; out=$(run final "$N/bin:$bare" DOC_PROJECT=P DOC_TITLE="A title" DOC_KIND=work DOC_MEMBER=m); rc=$?
  want_n="number --project P --title A title --source $N/final/doc.tex --kind work --member m --tex"
  want_f="file $N/final/doc.pdf --project P --title A title --source $N/final/doc.tex --kind work --member m"
  bad=""
  [ "$rc" -eq 0 ] || bad="exit $rc"
  [ "$(cat "$N/final.log")" = "$(printf '%s\n%s' "$want_n" "$want_f")" ] || bad="$bad; calls were: $(cat "$N/final.log")"
  printf '%s\n' "$out" | grep -q 'register: 123-0045-B' || bad="$bad; the filing result was not printed"
  mk plain; run plain "$bare" >/dev/null
  for i in 1 2; do
    page final "$i" | grep -qx ' *123-0045-B .* 24 Sep 2026' || bad="$bad; page $i has no number line"
    [ "$(page final "$i" | grep -v '123-0045-B')" = "$(page plain "$i")" ] || bad="$bad; page $i's other text moved"
  done
  page final 1 | grep -q 'COPYRIGHT HOLDER' && page final 2 | grep -q 'COPYRIGHT HOLDER *2$' || bad="$bad; copyright or page number missing"
  if [ -n "$bad" ]; then
    fail "register: the finished build: ${bad#; }"; printf '%s\n' "$out" | head -6 | sed 's/^/  /'
  else
    pass "register: a finished build is numbered first, stamped under the foot on every page, filed after"
  fi

  mk nostamp; out=$(run nostamp "$N/bin:$bare" DOC_PROJECT=P DOC_TITLE=T DOC_NO_STAMP=1); rc=$?
  if [ "$rc" -ne 0 ] || [ "$(cat "$N/nostamp.log")" != "file $N/nostamp/doc.pdf --project P --title T --source $N/nostamp/doc.tex --no-stamp" ] \
     || pdftotext "$N/nostamp/doc.pdf" - | grep -q '123-0045'; then
    fail "register: DOC_NO_STAMP=1 (exit $rc), calls: $(cat "$N/nostamp.log")"; printf '%s\n' "$out" | head -6 | sed 's/^/  /'
  else
    pass "register: DOC_NO_STAMP=1 prints no number and files with --no-stamp"
  fi

  mk notitle; out=$(run notitle "$N/bin:$bare" DOC_PROJECT=P); rc=$?
  if [ "$rc" -ne 2 ] || [ -s "$N/notitle.log" ] || [ -e "$N/notitle/doc.pdf" ]; then
    fail "register: DOC_PROJECT without DOC_TITLE exited $rc, expected 2 with nothing called or built"
  else
    pass "register: DOC_PROJECT without DOC_TITLE exits 2 before anything runs"
  fi
fi

# --- 16. page breaks: the style keeps them clean, the check catches bad ones ---
if ! command -v lualatex >/dev/null || ! command -v pdftotext >/dev/null || ! command -v pdfinfo >/dev/null; then
  skip "page breaks" "no lualatex, pdftotext or pdfinfo on this machine"
else
  P="$TMPROOT/breaks"; mkdir -p "$P"
  cp "$REPO/assets/preamble-template.tex" "$P/"
  python3 - "$P" <<'PYEOF'
import sys
d = sys.argv[1]
lorem = ("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut "
         "labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris "
         "nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit "
         "esse cillum dolore.")
# \pbcold puts back what the style did before: LaTeX's 150 widow and club
# penalties, a caption the code could break away from, fvextra's breakable
# overlap glue, no short-listing rule, a subsection's room check that runs
# straight under a section heading; and it strands a heading at a foot.
doc = r"""\input{preamble-template}
\makeatletter\ifdefined\pbcold
  \widowpenalty=150 \clubpenalty=150 \@clubpenalty=150 \def\hs@lstshort{0}
  \renewcommand{\hslisting}[1]{\par\vspace{24pt}{\hsfull\hslabel{#1}\par}\vspace{8pt}}
  \def\FV@bgcoloroverlap{\vspace{-\FV@backgroundcolorboxoverlap}}
  \pretocmd{\subsection}{\needspace{5\baselineskip}}{}{}
\fi\makeatother
\begin{document}
\section{One}
""" + "\n\n".join([lorem] * 8) + r"""

\vspace*{20pt}
Widow paragraph """ + "word " * 60 + r"""final words end here.

Next paragraph.
\newpage
\section{Two}
""" + "\n\n".join([lorem] * 7) + r"""

\hslisting{Listing 1 / the gate}
\begin{Verbatim}[bgcolor=codefill]
alpha line one
beta line two
gamma line three
delta line four
epsilon line five
\end{Verbatim}
After text.
\ifdefined\pbcold\newpage Filler.\section{A stranded heading}\newpage Text.\fi
\newpage
\section{Gap}
Text.\par\vspace*{420pt}
Filler line.

\section{Results}
\subsection{Setup}
""" + lorem + r"""

""" + lorem + r"""
\end{document}
"""
open(f"{d}/breaks.tex", "w").write(doc)
open(f"{d}/old.tex", "w").write("\\def\\pbcold{}\\input{breaks}\n")
PYEOF
  "$REPO/scripts/build.sh" "$P/old.tex" > "$P/old.out" 2>&1 & oldpid=$!
  new=$("$REPO/scripts/build.sh" "$P/breaks.tex" 2>&1); newrc=$?
  wait "$oldpid"; oldrc=$?; old=$(cat "$P/old.out")
  chk="$REPO/scripts/page-break-check.sh"
  bad=""
  [ "$newrc" -eq 0 ] || bad="$bad; the fixed build exited $newrc"
  printf '%s\n' "$new" | grep -q 'page-break-check' && bad="$bad; the fixed build reported a bad break"
  "$chk" --strict "$P/breaks.pdf" >/dev/null || bad="$bad; --strict failed the fixed build"
  pdftotext -f 4 -l 4 "$P/breaks.pdf" - | grep -q 'alpha line one' \
    && pdftotext -f 4 -l 4 "$P/breaks.pdf" - | grep -qi 'listing 1' || bad="$bad; the short listing and its caption are not together on page 4"
  pdftotext -f 6 -l 6 "$P/breaks.pdf" - | grep -q '^Results' \
    && pdftotext -f 6 -l 6 "$P/breaks.pdf" - | grep -q '^Setup' || bad="$bad; the section and the subsection under it are not together on page 6"
  if [ -n "$bad" ]; then
    fail "page breaks: the style: ${bad#; }"; printf '%s\n' "$new" | head -8 | sed 's/^/  /'
  else
    pass "page breaks: no widow, a short listing moves whole with its caption, a section moves with the subsection under it, the check stays quiet"
  fi
  bad=""
  [ "$oldrc" -eq 0 ] || bad="$bad; build.sh exited $oldrc on bad breaks, but they only warn"
  for want in 'p.2: widow: voluptate velit' 'p.3: listing: Listing 1 / the gate: 1 line(s) on p.3, 4 on p.4' \
              'p.5: heading: A stranded heading' 'p.7: heading: Results'; do
    printf '%s\n' "$old" | grep -qF "page-break-check: $want" || bad="$bad; build.sh did not report \"$want\""
  done
  "$chk" "$P/old.pdf" >/dev/null || bad="$bad; the check without --strict exited non-zero"
  "$chk" --strict "$P/old.pdf" >/dev/null && bad="$bad; --strict exited 0 on bad breaks"
  "$chk" "$P/missing.pdf" >/dev/null 2>&1; [ $? -eq 2 ] || bad="$bad; a missing PDF did not exit 2"
  if [ -n "$bad" ]; then
    fail "page breaks: the check: ${bad#; }"; printf '%s\n' "$old" | head -8 | sed 's/^/  /'
  else
    pass "page breaks: the check names the widow, the one-line listing split and the stranded heading by page; --strict exits 1"
  fi
fi

# --- 17. a workspace's own design system -------------------------------------
DSPY="$REPO/apply-design-system/ds.py"
DS="$TMPROOT/ds"; mkdir -p "$DS/repo/.git" "$DS/repo/.cc" "$DS/repo/sub" "$DS/outer/.cc" "$DS/outer/repo/.git"
TOK="$REPO/apply-design-system/examples/salari-test/.cc/design-tokens.json"
cp "$TOK" "$DS/repo/.cc/design-tokens.json"; cp "$TOK" "$DS/outer/.cc/design-tokens.json"
bad=""
got=$(env -u DESIGN_TOKENS python3 "$DSPY" find "$DS/repo/sub") || bad="$bad; find exited non-zero in a repo with a token file"
[ "$got" = "$DS/repo/.cc/design-tokens.json" ] || bad="$bad; find printed '$got', not the repo's token file"
env -u DESIGN_TOKENS python3 "$DSPY" find "$DS/outer/repo" >/dev/null && bad="$bad; find read a token file above the repo's .git"
DESIGN_TOKENS=none python3 "$DSPY" find "$DS/repo" >/dev/null && bad="$bad; DESIGN_TOKENS=none still found one"
DESIGN_TOKENS="$DS/nothing.json" python3 "$DSPY" find "$DS/repo" >/dev/null 2>&1; [ $? -eq 2 ] || bad="$bad; a DESIGN_TOKENS naming no file did not exit 2"
[ -n "$bad" ] && fail "design system: find: ${bad#; }" || pass "design system: find takes the repo's token file, never one above .git, none with DESIGN_TOKENS=none"

# import: a fixture export shaped like Claude Design's
EX="$DS/export"; mkdir -p "$EX/tokens" "$EX/assets/logo"
cat > "$EX/tokens/colors.css" <<'CSSEOF'
:root {
  /* comment */
  --ink-900: #1a1a1a;
  --paper-0: #fff;
  --text-primary: var(--ink-900);
  --surface-page: var(--paper-0);
  --brand-accent: oklch(0.42 0.08 250);
  --border-default: var(--missing, #e2e0db);
}
[data-brand="other"] { --brand-accent: #ff0000; }
CSSEOF
printf ':root {\n  --font-sans: "Overpass", Helvetica, sans-serif;\n  --type-heading-case: uppercase;\n}\n' > "$EX/tokens/typography.css"
printf 'PNG' > "$EX/assets/logo/brand-black.png"
bad=""
python3 "$DSPY" import "$EX" -o "$DS/imp/.cc/design-tokens.json" >/dev/null 2>&1 || bad="$bad; import exited non-zero"
python3 "$DSPY" check "$DS/imp/.cc/design-tokens.json" >/dev/null 2>&1 || bad="$bad; the imported file does not pass check"
[ -f "$DS/imp/.cc/design-logo.png" ] || bad="$bad; the one logo was not copied beside the token file"
python3 - "$DS/imp/.cc/design-tokens.json" <<'PYEOF2' || bad="$bad; the imported values are wrong"
import json, sys
t = json.load(open(sys.argv[1]))
want = {('color', 'ink'): '#1A1A1A', ('color', 'paper'): '#FFFFFF',
        ('color', 'accent'): '#285077', ('color', 'rule'): '#E2E0DB'}
ok = all(t[g][k] == v for (g, k), v in want.items())
ok = ok and t['type']['body'] == ['Overpass', 'Helvetica', 'sans-serif']
ok = ok and t['type']['heading-case'] == 'uppercase' and t['logo'] == 'design-logo.png'
if not ok:
    print('  imported:', json.dumps(t)); sys.exit(1)
PYEOF2
[ -n "$bad" ] && fail "design system: import: ${bad#; }" || pass "design system: import reads a Claude Design export's :root tokens, resolves var() and oklch, ignores a [data-brand] block"

# xlsx
printf 'Item,Count,Price\nA,3,4.50\nB & C,12,10\n' > "$DS/repo/sub/rows.csv"
bad=""
( cd "$DS/repo/sub" && env -u DESIGN_TOKENS python3 "$DSPY" xlsx rows.csv -o a.xlsx --title "Rows" >/dev/null && env -u DESIGN_TOKENS python3 "$DSPY" xlsx rows.csv -o b.xlsx --title "Rows" >/dev/null ) || bad="$bad; xlsx exited non-zero"
cmp -s "$DS/repo/sub/a.xlsx" "$DS/repo/sub/b.xlsx" || bad="$bad; the same rows made different bytes"
python3 - "$DS/repo/sub/a.xlsx" <<'PYEOF2' || bad="$bad; the workbook does not carry the rows and the header fill"
import sys, zipfile
import xml.etree.ElementTree as ET
z = zipfile.ZipFile(sys.argv[1])
for n in z.namelist():
    if n.endswith('.xml') or n.endswith('.rels'):
        ET.fromstring(z.read(n))
sheet, styles = z.read('xl/worksheets/sheet1.xml').decode(), z.read('xl/styles.xml').decode()
ok = 'B &amp; C' in sheet and '<v>12</v>' in sheet and 'ROWS' in sheet
ok = ok and 'FF1B1F24' in styles
sys.exit(0 if ok else 1)
PYEOF2
mkdir -p "$DS/bare/.git"; cp "$DS/repo/sub/rows.csv" "$DS/bare/"
env -u DESIGN_TOKENS python3 "$DSPY" xlsx "$DS/bare/rows.csv" -o "$DS/bare/x.xlsx" >/dev/null 2>&1; [ $? -eq 1 ] || bad="$bad; xlsx without a design system did not exit 1"
[ -n "$bad" ] && fail "design system: xlsx: ${bad#; }" || pass "design system: xlsx writes a styled workbook, the same bytes twice, and refuses where no system applies"

if ! command -v lualatex >/dev/null; then
  skip "design system: builds" "no lualatex on this machine"
else
  bad=""
  for d in plain themed; do
    mkdir -p "$DS/$d/.git"
    cp "$REPO/assets/short-template.tex" "$REPO/assets/preamble-template.tex" "$DS/$d/"
  done
  mkdir -p "$DS/themed/.cc"; cp "$TOK" "$DS/themed/.cc/design-tokens.json"
  export SOURCE_DATE_EPOCH=1790000000 FORCE_SOURCE_DATE=1
  plainout=$(env -u DESIGN_TOKENS "$REPO/scripts/build.sh" "$DS/plain/short-template.tex" 2>&1) || bad="$bad; the plain build failed"
  mv "$DS/plain/short-template.pdf" "$DS/plain/via-build.pdf"
  # What build.sh ran before design systems existed: three bare passes, in the
  # same directory, because the PDF's /ID is made from the path it is built at.
  ( cd "$DS/plain" && export TEXINPUTS=".:$REPO/references/house-style//:${TEXINPUTS:-}" \
    && for pass in 1 2 3; do lualatex -interaction=nonstopmode -halt-on-error -jobname=_tmp_short-template short-template.tex >/dev/null 2>&1; done \
    && cp _tmp_short-template.pdf bare.pdf && rm -f _tmp_short-template.* ) || bad="$bad; the bare lualatex build failed"
  themedout=$(env -u DESIGN_TOKENS "$REPO/scripts/build.sh" "$DS/themed/short-template.tex" 2>&1) || bad="$bad; the themed build failed: $themedout"
  unset SOURCE_DATE_EPOCH FORCE_SOURCE_DATE
  cmp -s "$DS/plain/via-build.pdf" "$DS/plain/bare.pdf" || bad="$bad; with no design system the PDF is not byte-identical to the bare build"
  printf '%s\n' "$plainout" | grep -q '^design system:' && bad="$bad; the plain build named a design system"
  printf '%s\n' "$themedout" | grep -qF "design system: $DS/themed/.cc/design-tokens.json" || bad="$bad; the themed build did not name its token file"
  cmp -s "$DS/plain/via-build.pdf" "$DS/themed/short-template.pdf" && bad="$bad; the themed PDF is the same as the plain one"
  if command -v pdftotext >/dev/null; then
    pdftotext -l 1 "$DS/plain/via-build.pdf" - | grep -qF '<Document title>' || bad="$bad; the plain title is not as written"
    pdftotext -l 1 "$DS/themed/short-template.pdf" - | grep -qF '<DOCUMENT TITLE>' || bad="$bad; the themed title is not in capitals"
  fi
  [ -n "$bad" ] && fail "design system: builds: ${bad#; }" || pass "design system: no token file builds byte-identical to bare lualatex; a token file restyles the same source"
fi

echo
if [ "$FAILED" -eq 0 ]; then echo 'check.sh: green'; else echo 'check.sh: RED'; fi
exit "$FAILED"
