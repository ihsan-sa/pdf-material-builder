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
#      template's A4 line, uncommented, builds A4.
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
#   6 to 9 are SKIPPED, with the reason printed, when lualatex is absent;
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
TOPLEVEL = {'SKILL.md', 'README.md'}
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
# A tint of a token is clean; a hue that is not a token is not, tinted or plain.
selfcheck colour-tint a.tex '\\node[draw=teal!40,fill=accent!12] {x};\n' \
                      b.tex '\\node[draw=accent,fill=accent!12] {x};\n'
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
\begin{tabularx}{\linewidth}{L{3cm}YR{2cm}}\hstoprule \hshead{Key} & \hsaccenthead{New} & \hshead{N} \\ \hstoprule a & b & 1 \\ \hline c & d & 2 \\ \hstoprule\end{tabularx}
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
    fail "page-composition snippets: one of the $n patterns does not compile"
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

echo
if [ "$FAILED" -eq 0 ]; then echo 'check.sh: green'; else echo 'check.sh: RED'; fi
exit "$FAILED"
