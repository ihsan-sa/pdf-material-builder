#!/usr/bin/env bash
# build.sh -- compile one house-style document with lualatex, three passes.
#
#   scripts/build.sh <file.tex>
#
# Run it from anywhere; it compiles in the .tex file's own directory, so
# \input and \includegraphics paths stay relative to the document. It puts
# the document's own directory first on TEXINPUTS and references/house-style/
# after it, so \usepackage{housestyle} resolves and a file beside the document
# is never shadowed by one of the same name in the style directory;
# housestyle.sty finds the vendored fonts in assets/fonts/ from its own
# location. texlive-luatex must be installed alongside lualatex: it carries
# the font loader fontspec needs, and without it no font loads.
#
# Each pass writes to the temp jobname _tmp_<name> so a PDF open in a viewer
# does not lock the build; the result is copied over <name>.pdf and the temp
# files removed. Exits 1 if any pass logs a "!" error, printing the lines.
# Exits 1 too if the last pass logs an Overfull \hbox: something prints past
# the right margin. The PDF is still written, so the page can be looked at,
# and the log's overfull lines are printed with the source lines they name.
#
# Figures (references/house-style/DIAGRAMS.md): when figures/*.json sits next
# to the document, build.sh first runs scripts/sync-diagram-maker.sh, which
# brings the bundled diagram-maker/ to its latest main (a quiet no-op offline),
# then renders each spec with diagram-maker's render.js and exports it to
# figures/<name>.pdf with its export.sh, so \hsdiagram{figures/<name>} places
# what the latest diagram-maker draws. A spec render.js reports an error in
# fails the build. With no node, or when export.sh exits 2 (no converter on
# the machine), a figure whose PDF is already there keeps it, with a note; one
# with no PDF fails the build and says to draw it with the TikZ kit instead.
#
# A workspace's own design system (apply-design-system/SKILL.md): when
# `apply-design-system/ds.py find` names a token file for the document's
# directory (.cc/design-tokens.json at the repo root, or $DESIGN_TOKENS),
# build.sh writes its LaTeX theme to _tmp_<name>.theme.tex and has lualatex
# load it right after housestyle.sty, and prints "design system: <file>".
# With no token file, or no python3, the lualatex command is exactly what it
# was before design systems existed, so the PDF is too.
#
# Page breaks: after a clean build, when pdftotext is on the machine, build.sh
# runs scripts/page-break-check.sh on the PDF and prints what it finds (a
# widow at a page top, a heading or listing caption at a page foot, a listing
# split with one line on a side). It only warns: the build's exit is the same.
#
# The document register: a finished build is numbered and filed when the
# environment carries DOC_PROJECT (a project name or number) and DOC_TITLE and
# cc-docs is on PATH. Before compiling, build.sh asks `cc-docs number --tex`
# for the number and defines it ahead of the document, so housestyle.sty
# prints it in the foot of every page; after a clean build it runs `cc-docs
# file` on the PDF and prints what the register did. DOC_KIND
# (work|course|member) and DOC_MEMBER pass on as --kind and --member;
# DOC_NO_STAMP=1 prints no number and files with --no-stamp. DOC_PROJECT
# without DOC_TITLE exits 2 before compiling, and a filing cc-docs refuses
# exits 1 with its reason. With DOC_PROJECT unset, or no cc-docs, nothing of
# this runs: a draft builds exactly as before.
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: $0 <file.tex>" >&2; exit 2; }
command -v lualatex >/dev/null || { echo "build.sh: lualatex is not installed" >&2; exit 2; }

skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
name="$(basename "$src" .tex)"
cd "$(dirname "$src")"

export TEXINPUTS=".:$skill/references/house-style//:${TEXINPUTS:-}"

specs=()
for f in figures/*.json; do [ -f "$f" ] && specs+=("$f"); done
if [ ${#specs[@]} -gt 0 ]; then
  "$skill/scripts/sync-diagram-maker.sh"
  dm="$skill/diagram-maker"
  why=""
  if [ ! -f "$dm/scripts/render.js" ]; then
    why="diagram-maker is not checked out at $dm (git submodule update --init there)"
  elif ! command -v node >/dev/null; then
    why="node is not installed"
  fi
  for spec in "${specs[@]}"; do
    fig="${spec%.json}"
    if [ -z "$why" ]; then
      if ! out=$(node "$dm/scripts/render.js" "$spec" 2>&1); then
        echo "build.sh: diagram-maker could not render $spec:" >&2
        printf '%s\n' "$out" >&2
        exit 1
      fi
      rc=0; out=$("$dm/scripts/export.sh" "$spec" "$skill/assets/fonts" 2>&1) || rc=$?
      [ "$rc" -eq 0 ] && continue
      if [ "$rc" -ne 2 ]; then
        echo "build.sh: exporting $spec failed: $out" >&2
        exit 1
      fi
      note="export.sh found no converter"
    else
      note="$why"
    fi
    if [ -s "$fig.pdf" ]; then
      echo "build.sh: $note; using the $fig.pdf already there" >&2
    else
      echo "build.sh: $note, and there is no $fig.pdf; draw the figures with the TikZ kit instead (DIAGRAMS.md, \"When diagram-maker can't run\")" >&2
      exit 1
    fi
  done
fi

docargs=()
input="$name.tex"
if [ -n "${DOC_PROJECT:-}" ] && command -v cc-docs >/dev/null; then
  [ -n "${DOC_TITLE:-}" ] || { echo "build.sh: DOC_PROJECT is set but DOC_TITLE is not; a finished build needs both" >&2; exit 2; }
  docargs=(--project "$DOC_PROJECT" --title "$DOC_TITLE" --source "$src")
  [ -n "${DOC_KIND:-}" ] && docargs+=(--kind "$DOC_KIND")
  [ -n "${DOC_MEMBER:-}" ] && docargs+=(--member "$DOC_MEMBER")
  if [ "${DOC_NO_STAMP:-}" != 1 ]; then
    defs=$(cc-docs number "${docargs[@]}" --tex) || { echo "build.sh: cc-docs could not number $name.tex" >&2; exit 1; }
    input="$defs\\input{$name.tex}"
  fi
fi

ds="$skill/apply-design-system/ds.py"
if command -v python3 >/dev/null; then
  rc=0; tokens=$(python3 "$ds" find .) || rc=$?
  if [ "$rc" -eq 0 ]; then
    python3 "$ds" latex "$tokens" > "_tmp_$name.theme.tex" || { echo "build.sh: the design system at $tokens could not be applied" >&2; exit 1; }
    [ "$input" = "$name.tex" ] && input="\\input{$name.tex}"
    input="\\AddToHook{package/housestyle/after}{\\input{_tmp_$name.theme.tex}}$input"
    echo "design system: $tokens"
  elif [ "$rc" -ne 1 ]; then
    exit 1
  fi
fi

for pass in 1 2 3; do
  lualatex -interaction=nonstopmode -halt-on-error -jobname="_tmp_$name" "$input" >/dev/null 2>&1 || true
  if grep -q '^!' "_tmp_$name.log" 2>/dev/null || [ ! -s "_tmp_$name.pdf" ]; then
    echo "build.sh: pass $pass of $name.tex failed:" >&2
    grep -A3 '^!' "_tmp_$name.log" >&2 || echo "(no log written)" >&2
    exit 1
  fi
done
cp "_tmp_$name.pdf" "$name.pdf"
over=$(grep -A1 '^Overfull \\hbox' "_tmp_$name.log" || true)
rm -f _tmp_"$name".*
if [ -n "$over" ]; then
  echo "build.sh: $name.tex has overfull boxes; something is wider than the measure:" >&2
  printf '%s\n' "$over" >&2
  echo "build.sh: wrote $(pwd)/$name.pdf, but the build is not clean" >&2
  exit 1
fi
echo "built $(pwd)/$name.pdf"
if command -v pdftotext >/dev/null && command -v pdfinfo >/dev/null; then
  "$skill/scripts/page-break-check.sh" --tex "$src" "$name.pdf" || true
fi
if [ ${#docargs[@]} -gt 0 ]; then
  [ "${DOC_NO_STAMP:-}" = 1 ] && docargs+=(--no-stamp)
  filed=$(cc-docs file "$(pwd)/$name.pdf" "${docargs[@]}") || { echo "build.sh: cc-docs did not file $name.pdf" >&2; exit 1; }
  echo "register: $filed"
fi
