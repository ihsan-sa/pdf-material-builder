# Conformance: what a built document must satisfy

Checked against `style-spec.md`. Every rule here exists because a build broke
it. Run this list before declaring a document done.

Vendored into the pdf-material-builder skill from the owner's rev 03 package.
Items 1, 3, 4, 6, 7, 8 and 10 are partly mechanical and `scripts/style-check.sh`
greps what it can of them; the rest, and everything under "What the kit cannot
check for you", are the hand-off checklist in
`references/page-composition.md`.

## The defects that produced this file

From `pitch.pdf`, built 22 September 2026 (LuaTeX 1.22, 5pp):

| Seen | Rule | Now enforced by |
|---|---|---|
| Six statistics in one row, wrapped into a ragged grid with six-line captions | Four abreast, never five. Six measured figures are two rows or a data table. | `hsstatrow[n]` caps at four and raises a `\PackageError` on the fifth `\hsstat` |
| Document slug printed in the running head *and* the foot of every page | The slug appears once. Head: slug left, section right. Foot: page number right. | `\fancyfoot[L]` is empty by default |
| Every label set as separated capitals (`A U T O B O X`) | Labels are mono uppercase at 7% tracking, not 14% | `\labelfont` is `LetterSpace=7.0, WordSpace=1.25` |
| The sources page carrying the previous page's section name | The sources page is headed "Sources" | the `hssources` environment sets `\hsgsection{Sources}`, globally, so the value survives the list's group and reaches the output routine |
| A URL hyphenated mid-word across a line break | URLs break at any character and are never hyphenated | `xurl` loaded; `\hsurl{...}` for source entries |
| No provenance footline on any page, the figure note set as body prose instead | Every page carrying a figure or a statistic ends in a provenance footline | manual: see item 3 below |
| No claim, no callout anywhere in a five-page document making a strong claim | One claim per document; the limit of that claim stated in a callout on the same page | manual: see items 4 and 5 |

## The checklist

1. **Blocks only.** Every element on the page is one of the twelve in
   `style-spec.md`. No tcolorbox, no coloured boxes, no invented block, no
   footnotes, no fourth diagram node kind.
2. **Statistics.** Between two and four per row, each measured, each with a
   caption under it. A figure that was not measured is prose.
3. **Provenance.** Every page with a figure or a statistic ends in
   `\hsprovenance{...}` naming the command, file, commit or date the numbers
   came from. A number with neither a source superscript nor a footline is cut.
4. **Claim.** Exactly one `\hsclaim` per document, and it is the sentence the
   document exists for. Zero is as wrong as two.
5. **Limits.** Any page making a strong claim carries the `hscallout` that
   states what the claim does not mean.
6. **Sources.** One `hssources` list on the last page, numbered in the order the
   superscripts appear, each with the date read, URLs in `\hsurl`.
7. **Colour.** Only the six tokens. The accent appears at most three times on a
   page and only on a check, a source numeral or one table header cell. The warm
   paper tint is part of the style and `housestyle.sty` paints it on every page,
   so a document never calls `\pagecolor` itself; a build that comes out on plain
   white has lost the tint, and a document that sets its own page colour has
   overridden it. Inside a `tikzpicture` see item 9.
8. **Type.** Two faces. No bold in body text, no small caps, no underline except
   links, no size outside the scale in `style-spec.md`.
9. **Diagrams.** A diagram is drawn for what it shows, not poured into the
   template's node row. *Owner's decision, 22 September 2026: "dont force
   diagrams into the format in the template", and the lane diagrams of the old
   pitch and deeper-look documents "stay". It overrides the earlier wording of
   this item, of `style-spec.md` block 2 and of the README's rule 3.* What still
   binds every diagram is the typography and the ground: mono for labels and
   eyebrows, the text serif for prose inside a node, the page's paper tint, no
   sans-serif anywhere. The three node kinds (`hsnode`, `hswork`, `hsgate`) are
   one pattern among several; a lane diagram with an annotated arrow between
   lanes is another, and a role graph a third. The colour is the kit's: the
   owner settled the same day that the old diagrams' form comes across and their
   colours do not ("they can still be redrawn in the new pallette which is prob
   better but i mean the form etc"), so a picture differs its roles by weight --
   the five treatments `hsfilled`, `hsmarked`, `hsoutlined`, `hsground` and
   `hsquiet` -- and invents no hue. The three-appearance accent budget governs
   the prose of a page; inside a picture, spend the accent on one role.
   What every diagram still owes the reader: a filled figure label, a legend
   sentence in caption size naming the kinds it uses, an eyebrow in every node,
   boxes of one height in a row, and a fail path as one line with its caption
   under the picture rather than tangled into the arrows.
10. **Banned characters.** No em-dashes, no emoji, no `\lt` / `\gt`.

## What the kit cannot check for you

The page has to be *composed*. A document that satisfies every rule above and
still puts a running head, a heading, a lead, four paragraphs and a diagram on
every page in the same order is not in this style -- it is a template being
filled in. The reference document alternates: a page of prose, a page carrying
one figure, a page of statistics, a page of table. Read
`house-style-template.html` and match the rhythm, not just the macros.
`references/page-composition.md` is that rhythm written down: the eight page
shapes of the reference document, the rule against repeating one, and the
page-by-page comparison to run before hand-off.
