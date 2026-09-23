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
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: $0 <file.tex>" >&2; exit 2; }
command -v lualatex >/dev/null || { echo "build.sh: lualatex is not installed" >&2; exit 2; }

skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
name="$(basename "$src" .tex)"
cd "$(dirname "$src")"

export TEXINPUTS=".:$skill/references/house-style//:${TEXINPUTS:-}"

for pass in 1 2 3; do
  lualatex -interaction=nonstopmode -halt-on-error -jobname="_tmp_$name" "$name.tex" >/dev/null 2>&1 || true
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
