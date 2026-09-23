# House style v5: changes

23 September 2026. This replaces rev 03/v4. Every command, environment, colour
name and TikZ style in `HANDOFF.md` keeps its name and arguments. Only what
they draw has changed.

## What changed, and why

**Labels are serif small caps now, not mono capitals.** The owner said the
IBM Plex Mono labels in wide-tracked capitals looked out of place and
machine-made. Every label now uses Source Serif 4's own small caps (the
OpenType `smcp` and `c2sc` features, so the case the text is typed in makes
no difference) at +5% tracking. That covers running heads, eyebrows, figure,
table and listing numbers, table heads, the claim attribution, callout labels
and page numbers. Small caps are how books set labels, and they belong to the
same face as the body text. They also keep the owner's "no sans-serif
anywhere" rule.

**A label with a slash splits in two.** `\hslabel{Figure 2 / what a change goes
through before it merges}` sets "Figure 2" in small caps and the title in the
text italic at ink 70%. It splits at the first ` / `. A label with no slash is
all small caps, as before. Documents need no changes.

**One type family in three optical sizes.** Source Serif 4 ships Text, Subhead
and Display cuts for different sizes, and v5 uses each where it is meant to go:
- Display for the title and the statistics. A 28 pt serif figure replaces the
  26 pt Plex Mono Medium one.
- Subhead for part, section and subsection headings, and for the claim.
- Text for everything else.

Semibold replaces Bold as the bold weight. It is used only for the 8.5 pt node
eyebrows, where the Regular cut is too light to carry a role colour.

**Mono is kept for literal strings only.** Plex Mono now sets only code
listings, `\hsurl` and `\texttt`.

**Provenance and fail notes are serif.** Provenance is 8.5 pt, ink 55%, set
exactly as typed, with no forced lower case. TeX ligatures are off in that
font, so `--state` stays two hyphens. `\hsfailnote` is text italic in the
accent colour, as typed.

**ink-55 is darker: `#8A857A` changed to `#77716A`.** Small caps are lighter
on the page than mono capitals were, and the old grey fell to about 3.5:1 on
the paper. The new one is about 4.5:1. The token name is unchanged.

**The table of contents is styled.** Before, the article class's bold
contents page showed through. Now there is no bold and there are no dot
leaders. Part numbers are small caps in a 64 pt column, and page numbers are
ink 55% at the margin. `tocdepth` is 2.

**Bullets** are ink 55%.

**The title-page metadata strip is gone** (built for / paper / type / scope).
It was filled in by hand on every document and told a reader nothing they
needed. The title page is now the eyebrow, the title and the lead, then white.
It was template content, not a command, so nothing in the interface changes.

**The title page is framed.** Two ink rules: the slug and date sit above the
top one, the copyright line under the bottom one, and there is no page
number. The title is 44 pt, and the block sits a third of the way down. Every
field is one the document already sets, so nothing is left to fill in by hand.

**The callout is ruled, not filled.** A grey rule above and below, with the
accent label hanging in a 96 pt column beside the body. The #F0EADE box read
as pasted onto the page. `fill` stays as a token (lane steps use it).

**A short-form template.** `samples/short-template.tex` and
`word-template/house-style-short.docx`: no title page. The title block opens
page one and the document goes straight into prose.

**Diagrams: the owner's 23 September treatment is kept exactly.** Boxes have a
thin outline and a fill at about 12% of the same colour, in slate, sage, ochre
or rust, and none is filled black. Only the text inside the boxes changed:
eyebrows and role names are Semibold small caps in the role colour. The
geometry, colours and every `hs*` TikZ style are as they were.

## Added to the interface

- `\hstitle{title}`: the document title on its own, in the Display cut. The
  title pages in `blank-template.tex` and `driver-template.tex` now use it
  instead of a raw `\fontsize{36pt}`. `\hstitleblock` calls it too.
- `\hsnumbersections`: optional numbered sections and subsections (1, 1.1)
  for the rest of the document, with numbers in the contents too. Off by
  default; `\section*` stays unnumbered. The LaTeX side only. In Word, turn on
  heading numbering on Heading 1 and Heading 2 if you need it.
- `\hssourcespage`: starts the last page and heads it Sources.
- `\hstitle` takes an optional size: `\hstitle[44pt]{...}` on a title page.
- `\hsdate{...}` (defaults to the build's month and year) and the page style
  `hstitlepage`, used as `\thispagestyle{hstitlepage}` inside `titlepage`.
- Font commands `\hsdisplayfont`, `\hssubheadfont` and `\statfont` (the last
  already existed; it is now the Display cut).
- New fonts in `assets/fonts/`: `SourceSerif4-Semibold.otf`,
  `SourceSerif4-SemiboldIt.otf`, `SourceSerif4Subhead-Regular.otf` and
  `SourceSerif4Display-Regular.otf`. They come from Adobe's source-serif
  release and use the same OFL licence as the existing Source Serif 4 files.
  The `.sty` checks for the Semibold file. If it is missing, the `.sty` falls
  back to system-installed faces.
- The package now also loads `titletoc`.

## Files

| Path | Status |
|---|---|
| `references/house-style/housestyle.sty` | rewritten (v5) |
| `references/house-style/preamble-template.tex` | headings use `\hssubheadfont` |
| `references/house-style/driver-template.tex` | title uses `\hstitle`; type cell updated |
| `references/house-style/house-style-template.html` | new v5 reference: seven pages, every block, self-contained |
| `references/house-style/style-spec.md`, `CONFORMANCE.md`, `page-composition.md`, `README.md` | type rules updated to match |
| `references/house-style/example.tex` | unchanged |
| `samples/short-template.tex` | new: the short form |
| `samples/blank-template.tex` | uses `\hstitle`; adds the two diagram patterns and a provenance line; numbered equation; `bgcolor=codefill` on the listing |
| `samples/pitch.tex` | unchanged (see below) |
| `word-template/house-style.docx` | new: long form; styles, header and footer, sample pages |
| `word-template/house-style-short.docx` | new: short form, same styles |
| `word-template/WORD-STYLES.md` | the Word interface: every style name and its job |
| `word-template/figure-1.png` | the Figure 1 drawing used in the Word sample, rendered from the HTML reference |

## After the second pitch build (`pitch (3).pdf`)

I reviewed the six pages built on these templates. Fixed in the kit:
- `headsep` went from 14 to 26 pt, so a heading at the top of a page clears
  the head rule.
- The claim and the callout set `\parskip` to 0 inside, which removes 11 pt
  of stray space at every `\par`.
- Labels start with `\leavevmode`, so the callout's label lines up with the
  first line of its body.
- New `\hssourcespage`: a new page headed "Sources".

Fixed in the sample: `samples/pitch.tex` no longer defines its own box styles.
All three figures now use `hsnode`/`hswork`/`hsgate` with `\hsnodetext`
and `hsrole` with treatments. That gives eyebrows, rows of one height and a
real fail path, and nothing is filled black. Its sources page uses
`\hssourcespage`. The copy is unchanged.

Now rules in `page-composition.md` and `CONFORMANCE.md`: no `\tikzset` box
styles in a document, stat captions of three lines at most, and no
`\newpage` after a page that is less than half full.

## What I could not test

I could not run LuaLaTeX or LibreOffice where I built this, so **none of it
has been compiled or converted.** The rendered PDFs the handoff asks for
(`blank-template.pdf` and the Word sample exported to PDF) are not in this zip.
The HTML reference is rendered and reviewed. It shows the intended result,
with the same fonts, sizes and colours, in points.

Please build as `HANDOFF.md` describes and send me the page images. Check
these first:

1. **The label split (`\hslabel`, expl3).** It uses `\tl_if_in:nnTF` and a
   macro delimited by `/`. A slash inside braces, such as `\texttt{a/b}`, is
   deliberately ignored. Check `Figure 1 / ...` on the diagram page and in
   `Table 1 / ...`.
2. **Small-caps features.** fontspec should report no "feature not available"
   warnings for `SourceSerif4-Regular` or `-Semibold`. I checked that both
   files contain `smcp` and `c2sc`.
3. **Contents page.** `titletoc` together with the preamble's
   `\titleclass{\part}{top}`: the Part entries should show "Part 1" in small
   caps in the left column.
4. **Section numbering.** Uncomment `\hsnumbersections` in
   `blank-template.tex` and rebuild. Check the heading numbers and the hanging
   numbers in the contents.
5. **Overfull boxes.** `grep Overfull blank-template.log`. The TOC is wrapped
   in `\hsfull`, so page numbers reach the margin.
6. **`pitch.tex`.** It defines its own node styles, `who`/`ai`/`chk`/`stop`.
   `who` is still filled solid ink, which goes against the owner's 23
   September decision. I left it alone because it is a document, not the
   template. It will build with the new labels and fonts. Redrawing its three
   figures with `hsrole` + `hsslate`/`hssage`/`hsaccentrole` would bring it
   into line.
7. **A4.** Set `\newcommand\hspaper{a4paper}` and rebuild `blank-template.tex`.

For the Word template, check these under LibreOffice:

- **Page background.** Word's document background (`w:background`) has
  sometimes been dropped at PDF export. If the pages come out white, the
  fallback is a page-sized shape in the header, and I would rather see it
  fail first.
- **Small caps are synthesised.** LibreOffice fakes small caps from scaled
  capitals, which is lighter than the LaTeX version's true small caps. If
  that reads badly, LibreOffice accepts the font name
  `Source Serif 4:smcp&c2sc` for true small caps. Word would not understand
  it, so I have not made it the default.
- **Header field.** `STYLEREF "heading 1"` supplies the running section name,
  and LibreOffice's support for it varies by version. The skill's code can
  instead write the section name into each section's header as text.
- **Table styles.** Data Table borders and the header-row format come from
  the table style. LibreOffice imports them as direct formatting, which should
  look the same. Check the rules above and below the header row.

## Things I would change next, with your say-so

- Maths is still set in Computer Modern next to Source Serif. Switching to
  `unicode-math` with a matching math font would finish the look, but it
  touches how `\mathbf` and `amssymb` behave. It needs a compile to prove,
  so I have not done it.
- Redraw `pitch.tex`'s figures with the kit's role styles (item 6 above).
