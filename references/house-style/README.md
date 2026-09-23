# House style for technical documents

A visual template and LaTeX implementation for the `pdf-material-builder` skill.
Drop this folder in as `references/house-style/` and point the recipes at it.

## What is here

| File | What it is |
|---|---|
| `house-style-template.html` | The reference document (v5). Seven pages, every block in the kit shown once at the size it is meant to be used. Open it in a browser; print it to see the page geometry. This is the target a reformatted document should match. |
| `style-spec.md` | The written spec: page geometry (letter and A4), the full type scale, six colour tokens, the 8 pt spacing step, and the rule for each of the twelve blocks. This is the file a skill reads. |
| `housestyle.sty` | A LaTeX class implementing the spec: the page, type and every block's frame. LuaLaTeX (it uses fontspec and finds its fonts with Lua). |
| `hsdiagrams.sty` | The TikZ diagram kit, a module of its own; `housestyle.sty` loads it. |
| `DIAGRAMS.md` | The contract between the page and the pictures in it: diagram-maker figures through `\hsdiagram`, or the TikZ kit. |
| `house-style-template-short.html` | The same reference in the short form: no title page, the title block opens page one. |
| `../../assets/short-template.tex` | The short form: no title page, the title block opens page one and the prose follows. Up to about twelve pages. |
| `../../assets/blank-template.tex` | The long form: title page, contents, Parts. |
| `../../assets/word-template/` | The Word half: `house-style.docx`, `house-style-short.docx` and `WORD-STYLES.md`, the style names that are its interface. Vendored as the kit sent it; nothing in the skill builds a PDF from it yet. |
| `CHANGES.md` | What v5 changed and why, as the designer wrote it. |
| `example.tex` | A compiling document that exercises the title block, flow diagram, stat row, claim, callout and provenance footline. |
| `CONFORMANCE.md` | The ten checks a built document must pass, and the seven defects from a real build that each one exists to stop. Read it before declaring a document done. |

## The short version

One family: **Source Serif 4** for everything read -- prose, headings, captions,
tables, statistics, and every label, running head and figure number, which are
set in its own small caps. **IBM Plex Mono** only for code, URLs and paths.

Five neutrals and one accent: ink `#15140F`, ink-70 `#4A4740`, ink-55
`#77716A`, paper `#FAF8F3`, fill `#F0EADE`, accent `#9C4221`.
The accent marks a deterministic check or a source numeral. It is never
decoration and never appears more than three times on a page.

Page: portrait, 90 pt sides, text block from 92 pt to 70 pt off the foot, one
measure (415 pt on A4) for prose and blocks alike. Prose ranged left, or
justified with `\hsjustified` for essays and write-ups. Running head
on every page but the first. One 8 pt spacing step used as 8 / 16 / 24 / 32 / 56.
Rules are 0.75 pt, ink for structure and grey for division.

Twelve blocks and no thirteenth: title block, flow diagram, stat row, comparison
table, data table, figure plate, provenance footline, numbered sources, claim,
callout, code listing, display equation. `style-spec.md` states the rule for
each.

## Reformatting an existing document

1. Keep the prose. The style is a page treatment, not a rewrite.
2. Map each existing element onto one of the twelve blocks. Anything that maps
   onto none of them is cut or turned into prose.
3. Draw each diagram for what it shows. The three node kinds -- a slate box for
   inputs and outputs, a sage box for work an agent does, an accent box for a
   deterministic check -- are the pattern for a flow, and a lane diagram is the
   pattern for a mechanism that crosses several actors.
   *Owner's decision, 22 September 2026: "dont force diagrams into the format in
   the template", and the lane diagrams of the old documents "stay". This
   replaces the earlier rule 3, which reduced every diagram to the three
   kinds.* One thing does not bend: the typography -- small-caps labels and eyebrows,
   the text serif for prose inside a node, the page's paper ground, no sans. The
   palette he settled twice. First the same day, 22 September 2026: the old
   diagrams' form comes across but not their colours, "they can still be
   redrawn in the new pallette which is prob better but i mean the form etc",
   so a role read apart by weight and never a hue of its own. Then on 23
   September, choosing shading over the filled-ink box -- "I prefer the lightly
   shaded or outlined boxes ... all consistent with shading but different
   colours. basically just the black is too different" -- he overruled that: a
   role now reads apart by one of four muted colours (slate, sage, ochre and
   the kit's own accent), each a thin outline on a fill at about 12% of itself,
   and no box is filled solid black.
4. Every page carrying a figure or a statistic gets a provenance footline naming
   the command, commit, file and date the number came from. A number with no
   source and no footline does not go in.
5. Move all footnotes into one numbered source list on the last page.
6. Pick one sentence as the claim, set at 27 pt between two ink rules. Exactly
   one per document.

## If a build looks wrong

It is almost always the kit being driven wrong rather than the spec. Check
`CONFORMANCE.md` first: the failures seen so far are too many statistics in a
row, the slug repeated in head and foot, over-tracked labels, missing provenance
footlines, and no claim or callout in a document that argues for something.

The palette is not negotiable and not a suggestion: warm paper, warm ink, rust
accent, painted on every page. A build in another palette has not matched this
package. Inside a diagram, rule 3 above governs instead.

Rev 05, 23 September 2026. Labels move from IBM Plex Mono capitals to the serif's
small caps; headings, title and statistics take Source Serif 4's Subhead and
Display cuts; ink-55 darkens to #77716A. Every command is unchanged. See
`CHANGES.md` beside this file. The diagram role colours and their tints (23
September) carry over unchanged, and still read only inside a tikzpicture.

Rev 03, September 2026. Rev 03 keeps the original palette and carries rev 02's
hardening: label tracking at 7%, the stat row capped at four, xurl, the sources
page heading itself, and CONFORMANCE.md.
