#!/usr/bin/env bash
# build.sh -- compile one house-style document with lualatex, three passes.
#
#   scripts/build.sh <file.tex>
#
# Run it from anywhere; it compiles in the .tex file's own directory, so
# \input and \includegraphics paths stay relative to the document. It puts
# references/house-style/ on TEXINPUTS so \usepackage{housestyle} resolves,
# and housestyle.sty finds the vendored fonts in assets/fonts/ from its own
# location. When the system lualatex has no luaotfload (Debian without
# texlive-luatex, as on iiks1), it also puts the vendored copy in
# assets/luaotfload/ on LUAINPUTS; without one, fontspec cannot load a font.
#
# Each pass writes to the temp jobname _tmp_<name> so a PDF open in a viewer
# does not lock the build; the result is copied over <name>.pdf and the temp
# files removed. Exits 1 if any pass logs a "!" error, printing the lines.
set -euo pipefail

[ $# -eq 1 ] || { echo "usage: $0 <file.tex>" >&2; exit 2; }
command -v lualatex >/dev/null || { echo "build.sh: lualatex is not installed" >&2; exit 2; }

skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
name="$(basename "$src" .tex)"
cd "$(dirname "$src")"

export TEXINPUTS="$skill/references/house-style//:${TEXINPUTS:-}"
if ! kpsewhich luaotfload-main.lua >/dev/null 2>&1; then
  export LUAINPUTS="$skill/assets/luaotfload//:${LUAINPUTS:-}"
  export TEXINPUTS="$skill/assets/luaotfload//:$TEXINPUTS"
fi

for pass in 1 2 3; do
  lualatex -interaction=nonstopmode -halt-on-error -jobname="_tmp_$name" "$name.tex" >/dev/null 2>&1 || true
  if grep -q '^!' "_tmp_$name.log" 2>/dev/null || [ ! -s "_tmp_$name.pdf" ]; then
    echo "build.sh: pass $pass of $name.tex failed:" >&2
    grep -A3 '^!' "_tmp_$name.log" >&2 || echo "(no log written)" >&2
    exit 1
  fi
done
cp "_tmp_$name.pdf" "$name.pdf"
rm -f _tmp_"$name".*
echo "built $(pwd)/$name.pdf"
