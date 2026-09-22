# LaTeX house style

The look and the build discipline every document in this skill shares, whatever its recipe: where the look is specified, how to build, the twelve blocks and their macros, the teaching affordances, the math kit, the traps, and the style gate. Read it before writing the first `.tex` line, and again during review.

It stands alone. Nothing here is about teaching or voice -- for those see `references/voice.md` and `references/teaching-communication.md`; for which document to build, `references/recipes.md`; and for how to put the blocks on a page rather than merely call them, `references/page-composition.md`, which is the other half of this file and not optional.

## The look

`references/house-style/style-spec.md` is the look, in the owner's words, and `references/house-style/housestyle.sty` implements it. Read the spec; this file does not copy its tables. In a few lines:

- **Two faces.** Source Serif 4 for prose, headings, captions, tables and mathematics; IBM Plex Mono for every label, running head, statistic, path and code listing.
- **Five neutrals and one accent**, as colour tokens: `ink`, `inkseventy`, `inkfiftyfive`, `paper`, `fill`, `codefill`, `rulegrey`, and `accent`. The accent marks a deterministic check or a pointer, never decoration, and appears at most three times on a page. No other colour exists in the prose of a page: no category colours, no tints, no second hue. **A diagram uses these same tokens**: it takes its form from the owner's old lane diagrams and its palette from this kit (owner's decision, 22 September 2026; `references/house-style/CONFORMANCE.md`, item 9), so it tells its roles apart by weight -- `hsfilled`, `hsmarked`, `hsoutlined`, `hsground`, `hsquiet` -- and never by a hue of its own. Inside a picture the three-appearance budget does not apply, but the accent still goes to one role only.
- **The paper tint is part of the style.** `housestyle.sty` paints `#FAF8F3` on every page; a document never calls `\pagecolor` itself, and a build that comes out on plain white did not load the class.
- **One portrait geometry for every recipe**, letter or A4. No landscape variant.
- **No bold in body text**, emphasis is italic, and there are no footnotes: sources go in one numbered list on the last page.
- **Twelve blocks and no thirteenth.** Anything that maps onto none of them is cut or turned into prose.
- **Prose sits on a 34 em measure and is left-ranged**, while rules, figures, tables and stat rows run the full 468 pt text width. The class does this with `\rightskip`, so `\linewidth` stays the full measure; `\hsfull` inside a box of your own resets it.

`references/house-style/README.md` says how to reformat an existing document, and `house-style-template.html` is the rendered target.

## Build

```bash
scripts/build.sh path/to/doc.tex
```

It runs three lualatex passes in the document's own directory under the temp jobname `_tmp_<name>`, copies the result to `<name>.pdf`, removes the temp files, and exits 1 with the `!` lines if any pass errors. Run it from anywhere.

**lualatex and texlive-luatex (luaotfload) must be installed.** The engine is lualatex: the `.sty` loads its faces with fontspec and finds them with Lua, and pdflatex cannot do either. fontspec needs luaotfload, which Debian ships in `texlive-luatex`, so install it alongside lualatex. The faces are vendored in the skill, as `.otf` files in `assets/fonts/` with their OFL licences.

**How another repo finds the style.** `build.sh` puts `references/house-style/` on `TEXINPUTS`, so `\usepackage{housestyle}` resolves from any repo, and `housestyle.sty` finds `assets/fonts/` from its own location (two directories up). In a repo that vendors the skill at `.claude/skills/pdf-material-builder/`, build with `.claude/skills/pdf-material-builder/scripts/build.sh path/to/doc.tex`. To load the faces from somewhere else, `\def\hsfontdir{/abs/path/}` (trailing slash) before `\usepackage{housestyle}`.

## The preamble

`assets/preamble-template.tex` is the canonical preamble: `\documentclass[11pt]{article}`, then `\usepackage{housestyle}` (for A4, `\newcommand\hspaper{a4paper}` before it), then the affordances and math kit below. The `.sty` already loads geometry, fontspec, xcolor, fancyhdr, titlesec, booktabs, array, colortbl, graphicx, caption, enumitem, tikz, amsmath, microtype, fvextra and hyperref with `hidelinks`. Do not load tcolorbox, listings, parskip or a second geometry, and do not define a colour.

- `\hsslug{<Course> <Doc>}` -- the running head's left side.
- `\hssection{...}` -- its right side. The preamble sets it from each `\section` automatically; call it to override.
- `\catbanner{A}{Title}` -- opens a Part on a new page: accent eyebrow `Part N . Category A`, then the page heading at 20/24 (the .sty's `\section`), no bold.
- Section headings are unnumbered on the page, so cross-reference a section by name (`\nameref{sec:...}`), a Part as `Part~\ref{part:...}`, and an equation as `\eqref{eq:...}`, which prints (1).

## The twelve blocks, as macros

| # | Block | Macro |
|---|---|---|
| 1 | Title block | `\hstitleblock{eyebrow}{title}{lead}`. Over twelve pages, a dedicated title page with the four-column strip (built for / paper / type / scope): `assets/driver-template.tex` has one. |
| 2 | Diagram | `\begin{hsfigure}{Figure 1 / label}{legend sentence}` around a `tikzpicture`. Neither argument is ever empty. Node row: `hsnode` (filled ink: input, output), `hswork` (outlined ink: work), `hsgate` (accent on fill: a deterministic check), edges `hsarrow` / `hsfail`, and every node's body is `\hsnodetext{eyebrow}{title}{detail}`, which gives it its eyebrow and holds the row to one height (`\hsnodesize{w}{h}` changes both). The fail path's caption goes under the picture in `\hsfailnote`. The lane and role-graph patterns, the five role treatments and how a writer picks one are in `references/page-composition.md`. |
| 3 | Stat row | `\begin{hsstatrow}[n] \hsstat{741}{caption} ... \end{hsstatrow}`, where `n` is 2, 3 or 4 and defaults to 4. Measured numbers only, and a fifth `\hsstat` is a `\PackageError` rather than a ragged second line. |
| 4 | Comparison table | `tabular` or `tabularx` inside `hsblock`, with `\hstoprule` above and below the head, `\hshead{...}` for header cells and `\hsaccenthead{...}` for the one new column. No vertical rules. |
| 5 | Data table | Same rules, grey `\hline` between rows; column types `L{w}` and `R{w}` (ragged, right-aligned numerals) from the `.sty`, `Y` for a tabularx column from the preamble. |
| 6 | Figure plate | `\hsplate{file}{name}{grey facts}{status}{caption}`: full measure, no border. |
| 7 | Provenance footline | `\hsprovenance{command, commit, file, date}`, at the foot of any page with a figure or a statistic. |
| 8 | Numbered sources | `\begin{hssources} \item ... \end{hssources}` on the last page; the list heads its own page with `Sources`. A URL in an entry goes in `\hsurl{...}`, which breaks anywhere and never hyphenates. No `\footnote`. |
| 9 | Claim | `\hsclaim{the sentence}{mono line}`. Exactly one per document. |
| 10 | Callout | `\begin{hscallout}{label} ... \end{hscallout}`: the objection a careful reader would raise. Never two in a row. |
| 11 | Code block | `\hslisting{Listing 1 / label}` then `\begin{Verbatim}[bgcolor=codefill] ... \end{Verbatim}`. No syntax colour. |
| 12 | Display equation | Plain `equation` / `align`, numbered at the right margin; every symbol named in the sentence after it. |

Primitives for anything built on top: `\hslabel{...}` (mono uppercase, ink-55 at 7% tracking), `\hsaccentlabel{...}`, `\hslead{...}`, `\hsrule` (ink), `\hsthinrule` (grey), `\hsrolename{name}{detail}` for a role or lane box, `\hsfull` to reset the prose measure inside a box, and `hsblock` around anything that is a block rather than prose.

**`hsblock` is not optional around a table or a row of minipages.** Prose sits on a 34 em measure, which the class sets with a 48 pt `\rightskip`; a `tabular`, a metadata strip or a pair of side-by-side `minipage`s is a block and wants the whole 468 pt. Without `hsblock` the row is 48 pt too wide for the line it is on, so the last `minipage` wraps underneath the others and the table logs an overfull box that then hides the warning from a table that really is too wide. The blocks that carry their own full measure already are the rules, the callout, the plate, the stat row and the figure.

## Teaching affordances

The old coloured boxes are gone. Each teaching need maps onto one of the twelve blocks or becomes prose, per the house-style README's rule 2, and the macros are built only from the primitives above.

| Need | On the page | Macro |
|---|---|---|
| The one thing to read first on review | The section's lead line, right under the heading. | `\insight{...}` (= `\hslead`) |
| A derivation to skip on re-read | Block 12's labelled form: a grey label opens the run of display equations, a grey rule closes it. | `\begin{derivation} ... \end{derivation}` |
| A fact that lives on the formula sheet | A grey label on its own line before the display equation. Grey, not accent: the accent budget is three a page. | `\onsheet` then `\begin{equation}` |
| Out of scope | A small grey tag after the mention, or first thing in an optional paragraph. No box. | `\opt` |
| A cross-topic connection | A sentence with a `\ref` or `\nameref`. No box. | -- |
| A mental image | Prose; a figure plate if it is a figure. No box. | -- |
| Category and tool tags | Grey mono tags; the category is also the Part's eyebrow and running head. | `\cat{A}`, `\tool{5}`, `\tools{T4,T5}`, `\catbanner{A}{Title}` |
| A worked problem's heading | One mono label line: source, method, category. | `\probhead{source}{method}{cat}` |

## Math kit

Math, not look, so it is the same as it always was. All of it is in `assets/preamble-template.tex`:

```latex
\ba ... \bz, \bff, \bzero       % bold vectors: every lowercase letter is defined
\trans                          % {\!\top}, so X^\trans -> X^{\!\top}
\pderiv{u}{t} \ppderiv{u}{x} \pmderiv{u}{x}{y}
\Oh  \Ohof{n \log n}            % never bare $O()$
\grad  \Hess  \RR{n}  \R \N \Z  \diff{x}
```

## Copyright foot

Every shipped PDF carries the copyright line in the kit's foot treatment, on every page:

```latex
\fancyfoot[L]{\hslabel{\textcopyright{} 2026 <Name>. All rights reserved.}}
```

The foot's left slot is empty by default, which is why the copyright line can have it: the slug prints in the running head, and printing it in both was a defect of the first build. The page number stays at the foot's right. The first page has no running head, per the spec, but keeps the foot.

## LaTeX traps hit in real builds

1. **KaTeX habit leaking.** Agents write `\lt` and `\gt` (KaTeX-only), undefined in LaTeX. After every agent write, grep for `\\lt` and `\\gt` and replace with literal `<` / `>`. Do NOT use `sed`; regex edge cases corrupt `\Delta` and friends. Use Python with a precise regex.

2. **`\trans` macro design.** `\newcommand{\trans}{^{\!\top}}` makes `X^\trans` expand to a double `^`. Correct form: `\newcommand{\trans}{{\!\top}}`.

3. **`\bX` vector macros missing.** Agents use `\ba, \bb, \bc, \bd, \be, \bh, \bn, \br, \bs` freely. Define every lowercase letter in the preamble.

4. **Old macros in a writer's head.** An agent that has seen an older build reaches for `step`, `pictureit`, `fsheet`, `connect` or a coloured `\catbanner`. None exists now; map them per the table above rather than defining them again.

5. **PDF file-lock during compile.** An open PDF cannot be overwritten. `build.sh` compiles to `_tmp_<name>` and copies over `<name>.pdf`, so do not hand-roll a compile loop.

6. **Three passes for a multi-page TOC.** Pass 1 writes no TOC, pass 2 writes one that shifts every page number, pass 3 re-resolves the references against the shifted layout. `build.sh` always runs three.

7. **The luaotfload font cache.** luaotfload caches each font by file basename in `~/.texlive2025/texmf-var/luatex-cache` and keeps the path from the first load, so a relative `Path=` poisons later builds from another directory ("cannot find file ''" at shipout). The `.sty` uses an absolute path; if it happens anyway, `touch assets/fonts/*.otf` forces a reload.

8. **TOC entries for starred sections.** Use `\phantomsection` + `\addcontentsline{toc}{section}{<title>}` before a `\section*`. For counter-driven entries (like `Problem N`), `\refstepcounter{probnum}` before the `\addcontentsline`.

9. **Em-dashes and unicode.** The em-dash character (U+2014) is a style ban. `scripts/style-check.sh` catches it; write `--` or recast with commas.

10. **No emojis.** Zero tolerance. The gate rejects any character above ASCII.

11. **Line endings.** On Windows, git's `autocrlf` may convert LF to CRLF. Agents that read files should handle both; when re-writing, preserve local line endings.

12. **Hyperref "Token not allowed in PDF string" warnings.** Math in a `\section` title warns when bookmarks are built. Cosmetic. Either wrap it in `\texorpdfstring{<math>}{<plain>}` or leave it with a one-line comment in the driver; the second is usually right.

## Style gate

`scripts/style-check.sh` is the gate. It fails on an em-dash, an emoji or any other character above ASCII; a `\lt` or `\gt`; a bare `$O()$` where `\Oh` belongs; a `\footnote`; a second `\hsclaim` in one document (a driver and every file it `\input`s or `\include`s); a colour outside the token set, inside a diagram as much as outside one (a hex literal, a `\definecolor` in a `.tex`, a colour name that is not a token, or a `!` tint whose named parts are not tokens); a `\pagecolor` in a document; a `\sffamily` or `\textsf`; and a pdflatex invocation.

It also reads the composition defects the reference rendering exposed: an empty mandatory argument to `hsfigure`, `hstitleblock`, `hsclaim`, `hsprovenance`, `hslisting`, `hsnodetext`, `hsplate` or `hscallout`; an `hsnode` / `hswork` / `hsgate` whose body is not `\hsnodetext`; and a fifth `\hsstat` in one row. What no script can judge is the ten-point list at the end of `references/page-composition.md`. Run it after every agent-authored write, not only at the end -- a batch of parallel writers can plant fifty `\lt`s in one round.

```bash
scripts/style-check.sh                # this repo
scripts/style-check.sh <course_dir>   # a build directory
```

It skips `_extraction/`, `course_materials/`, `viz_src/`, `node_modules/`, `claude_lessons/` and the vendored `assets/fonts/`, and exits non-zero with one line per offending file. `tests/check.sh` runs it against this repo, so the skill's own text obeys the rules it hands out.
