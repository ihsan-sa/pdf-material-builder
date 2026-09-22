# House style for technical documents

A visual template and LaTeX implementation for the `pdf-material-builder` skill.
Drop this folder in as `references/house-style/` and point the recipes at it.

## What is here

| File | What it is |
|---|---|
| `house-style-template.html` | The reference document. Eight pages, every block in the kit shown once at the size it is meant to be used. Open it in a browser; print it to see the page geometry. This is the target a reformatted document should match. |
| `style-spec.md` | The written spec: page geometry (letter and A4), the full type scale, six colour tokens, the 8 pt spacing step, and the rule for each of the twelve blocks. This is the file a skill reads. |
| `housestyle.sty` | A LaTeX class implementing the spec. LuaLaTeX (it uses fontspec and finds its fonts with Lua). |
| `example.tex` | A compiling document that exercises the title block, flow diagram, stat row, claim, callout and provenance footline. |
| `CONFORMANCE.md` | The ten checks a built document must pass, and the seven defects from a real build that each one exists to stop. Read it before declaring a document done. |

## The short version

Two faces: **Source Serif 4** for all prose, headings, captions, tables and
mathematics; **IBM Plex Mono** for every label, running head, figure number,
statistic, path and code listing.

Five neutrals and one accent: ink `#15140F`, ink-70 `#4A4740`, ink-55
`#8A857A`, paper `#FAF8F3`, callout fill `#F0EADE`, accent `#9C4221`.
The accent marks a deterministic check or a source numeral. It is never
decoration and never appears more than three times on a page.

Page: portrait, 54 pt top, 72 pt sides, 44 pt foot, measure 34 ems. Running head
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
3. Draw each diagram for what it shows. The three node kinds -- filled ink for
   inputs and outputs, outlined ink for work an agent does, accent-outlined on
   fill for a deterministic check -- are the pattern for a flow, and a lane
   diagram is the pattern for a mechanism that crosses several actors.
   *Owner's decision, 22 September 2026: "dont force diagrams into the format in
   the template", and the lane diagrams of the old documents "stay". This
   replaces the earlier rule 3, which reduced every diagram to the three
   kinds.* Two things do not bend. The typography: mono labels and eyebrows, the
   text serif for prose inside a node, the page's paper ground, no sans. And the
   palette, which he settled the same day -- the old diagrams' form comes across
   but not their colours, "they can still be redrawn in the new pallette which
   is prob better but i mean the form etc" -- so a diagram tells its roles apart
   by weight (filled ink, outlined ink, the fill ground, a faint rule, and the
   accent spent on one role) rather than by a hue of its own.
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

Rev 03, September 2026. Rev 03 keeps the original palette and carries rev 02's
hardening: label tracking at 7%, the stat row capped at four, xurl, the sources
page heading itself, and CONFORMANCE.md.
