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
#      fixture and stays quiet on the matching clean case.
#   5  scripts/voice-drift.sh reports no drift from the canonical spec.
#      SKIPPED, with the reason printed, when lesson-builder is not on disk.
#   6  assets/preamble-template.tex and assets/driver-template.tex build with
#      scripts/build.sh (lualatex, three passes) to a non-empty PDF in a temp
#      directory.
#   7  references/house-style/example.tex builds the same way, and pdffonts
#      shows Source Serif 4 and IBM Plex Mono embedded.
#   8  With housestyle.sty in the current directory, kpse returns it as
#      ./housestyle.sty (a bare lualatex run there); the .sty's font lookup
#      must still resolve to assets/fonts/. Then references/house-style/
#      example.tex builds in place with scripts/build.sh and embeds the
#      vendored Source Serif 4; the example.pdf it makes is removed.
#   6, 7 and 8 are SKIPPED, with the reason printed, when lualatex is absent;
#   7's and 8's font checks are skipped the same way when pdffonts is absent.
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
selfcheck colour-hex a.tex '\\definecolor{gold}{HTML}{B8943E}\n' \
                     b.tex '% the accent is 9C4221, set by housestyle.sty\n\\textcolor{accent}{x}\n'
selfcheck colour-name a.tex '\\textcolor{black!75}{x} \\colorbox{softbg}{y}\n' \
                      b.tex '\\textcolor{inkseventy}{x} \\colorbox{fill}{y}\n'
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
fi

# --- 7. the owner's example builds and embeds both faces ----------------------
if ! command -v lualatex >/dev/null; then
  skip "house-style example" "no lualatex on this machine"
else
  E="$TMPROOT/example"; mkdir -p "$E"
  cp "$REPO/references/house-style/example.tex" "$E/"
  if ! out=$("$REPO/scripts/build.sh" "$E/example.tex" 2>&1); then
    fail "house-style example: scripts/build.sh failed"; printf '%s\n' "$out" | head -8 | sed 's/^/  /'
  else
    pass "house-style example builds in three lualatex passes with no ! errors"
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

# --- 8. the font lookup and the example, in place ----------------------------
# Case 7 copies the example away from housestyle.sty. build.sh puts the .sty's
# absolute directory first on TEXINPUTS, so kpse only returns ./housestyle.sty
# when "." is searched first, as in a bare lualatex run in that directory. The
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
