# House style for technical documents

The visual spec behind `house-style-template.html` (v5). Every value here is
what `housestyle.sty` renders, in points, and the HTML reference matches it.

## Page

| | Letter | A4 |
|---|---|---|
| Trim | 8.5 x 11 in | 210 x 297 mm |
| Top of text block | 92 pt | 92 pt |
| Running head baseline | 47 pt from the top edge | same |
| Side margins | 90 pt | 90 pt |
| Bottom of text block | 70 pt | 70 pt |
| Page number baseline | 38 pt from the bottom edge | same |
| Measure | 432 pt | 415 pt |

*v5.1, 23 September 2026 (owner, option 2a).* **One measure for everything.**
Prose, rules, figures, tables, stat rows and the running head all run the same
width, so both edges of the text block line up with the rules. Before, prose
stopped 48 pt short of the rules, and the page looked as if it ended early on
the right. The whole scale also came down one step, and the running head moved
off the top edge.

Portrait only. One geometry for every recipe; a landscape reference sheet is a
separate class, not a variant of this one.

Running head on every page but the first: document slug at the left, section
name at the right, serif small caps 8 pt, +9% tracking, ink 55%, with a 0.5 pt
grey rule 4 pt under it. Page number at the foot, same style, outer edge.

## Alignment

Prose is ranged left (the default) or justified (`\hsjustified`), chosen once
per document:

- **Justified** for an essay, a write-up, a letter or reading notes: pages
  that are mostly continuous paragraphs.
- **Ranged left** for a technical document (notes with maths and code, a
  reference, a spec), and for any document whose prose is broken up by a
  block on most pages. The pitch is one (the owner's pick, 2a).

Lead lines, captions, legends, labels, stat captions, callouts and sources
are ranged left in both.

## Type

One family in three optical sizes, and one mono for literal strings. All
open-licensed (OFL) and vendored in `assets/fonts/` for lualatex.

- **Source Serif 4** - everything a reader reads: prose, headings, captions,
  tables, labels, statistics, the text of mathematics. The Text cut for body
  and labels, Subhead for headings and the claim, Display for the title and
  the statistics.
- **IBM Plex Mono** - only what is literal: code listings, URLs, file paths
  and commands set inline with `\texttt`.

Labels are the serif's own small caps (OpenType `smcp` and `c2sc`, so
input case does not matter) at +5% tracking: running heads, eyebrows, figure,
table and listing numbers, table heads, the claim attribution, callout labels.
A label written `Figure 2 / what it shows` splits at the slash: the number in
small caps, the title in the text italic at ink 70%. *v5, 23 September 2026:
this replaces IBM Plex Mono capitals, which the owner found out of place and
machine-made.*

| Role | Face | Size / leading (pt) | Notes |
|---|---|---|---|
| Document title | Display 400 | 32 / 35; 40 / 44 on a title page | `\hstitle`, `\hstitleblock` |
| Part and section heading | Subhead 400 | 17 / 21 | 32 pt above, 8 below; unnumbered; `\hsnumbersections` adds "2" in ink 55%, 12 pt before the title |
| Subsection | Subhead 400 | 13 / 17 | numbered "2.1" when switched on |
| Sub-subsection | Text italic | 10.5 / 16 | |
| Lead line | Text 400 | 11.5 / 17 | ink 70%, two lines max |
| Body | Text 400 | 10.5 / 16 | paragraphs 8 pt apart |
| Claim (pull quote) | Subhead 400 | 17 / 23 | one per document |
| Legend, caption | Text 400 | 9 / 13 | ink 70% |
| Callout body | Text 400 | 10 / 15 | label hangs in a 96 pt column |
| Sources | Text 400 | 9.5 / 14 | |
| Statistic | Display 400 | 24 / 24 | lining tabular figures; four abreast, never five |
| Stat caption | Text 400 | 8.5 / 12 | ink 70% |
| Label | Text, all small caps | 8.5 / 12, +5% | ink 55%, or accent; a label's italic title is 9.5 |
| Running head, page number | Text, all small caps | 8 / 10, +9% | ink 55% |
| Node eyebrow | Semibold, all small caps | 7.5 / 8.5, +6% | the role colour (TikZ kit) |
| Node title, node detail | Text 400 | 10 / 12, 8 / 10.5 | TikZ kit |
| Fail note | Text italic | 8.5 / 11.5 | accent |
| Provenance | Text 400 | 7.5 / 11 | ink 55%, as typed (TeX ligatures off) |
| Code | Plex Mono 400 | 10 x 0.86 / 15 | no syntax colour in print |

No bold in body text. Emphasis is italic. Small caps only through the label
macros. No sans-serif on the page; inside a diagram-maker picture its own
`STYLE.md` governs (`DIAGRAMS.md`). No underline except on links.

## Colour

| Token | Hex | Use |
|---|---|---|
| ink | #15140F | text, structural rules |
| ink-70 | #4A4740 | lead lines, captions, secondary table cells |
| ink-55 | #77716A | labels, running heads, provenance, arrows (v5: was #8A857A) |
| paper | #FAF8F3 | the sheet, painted on every page |
| fill | #F0EADE | a lane step's ground; #F2EEE3 for code ground |
| accent | #9C4221 | deterministic checks, source numerals, one header cell |

Outside a diagram there is one accent, and it is the only hue on the page;
inside a tikzpicture, block 2 adds the four diagram role colours. The warm paper tint is part
of the style, not an artefact: the LaTeX class paints it on every page, and a
build that comes out on plain white has lost it.

Five values and one accent. The accent marks a check or a pointer, never
decoration, and never more than three appearances on a page. No gradients, no
tints of the accent, and no second hue outside a diagram (block 2). The budget of three is the budget of a
page's prose; inside a diagram, block 2 governs.

## Spacing

One 8 pt step, used as 8 / 16 / 24 / 32. Paragraphs are 8 apart, blocks 24,
a new section 32. Rules are 0.75 pt: ink where they carry structure (above a table
head, under the title block), grey where they only divide.

## The twelve blocks

1. **Title block** - eyebrow (small caps, accent), title, one-line lead, then content.
   Documents over twelve pages get a dedicated title page, framed by two ink
   rules: the slug and date above the top one, the copyright line under the
   bottom one, no page number. Between them, the eyebrow, the title at 44 / 48
   and the lead, a third of the way down, and white. Shorter documents open
   with the title block at the top of page one and go straight into prose.
2. **Diagram** - a module of its own (`DIAGRAMS.md`): the kit draws the frame
   (label, rules, legend), and the picture comes from diagram-maker through
   `\hsdiagram`, or from the TikZ kit in `hsdiagrams.sty`. Drawn for what it shows. *Owner's decision, 22 September 2026:
   "dont force diagrams into the format in the template". This replaces the
   earlier text of this block, which allowed three node kinds and no more.* The
   node row is one pattern: horizontal nodes joined by grey arrows, a slate box
   (input, output), a sage box (work an agent does), an accent box (a
   deterministic check). A lane diagram, and a role graph with annotated
   arrows, are equally house style. All three patterns draw a role in one of
   four muted colours -- slate `#4F6D8A`, sage `#5E7A5A`, ochre `#A07A2C` and
   the kit's own accent -- each a thin outline with a fill at about 12% of the
   same colour, so every box carries the same weight and a role reads apart by
   hue rather than by how loud the box is (owner, 23 September 2026, picking
   this over the filled-ink look: "I prefer the lightly shaded or outlined
   boxes ... all consistent with shading but different colours. basically just
   the black is too different"). These four colours exist only inside a
   `tikzpicture`; the rest of the page keeps the six above.
   What every diagram owes the reader, whatever its shape: a filled figure
   label, a legend sentence under it in caption size naming the kinds it uses,
   an eyebrow in every node, one height for every box in a row, and a fail path
   drawn as one accent line with its caption under the picture. The typography
   is the house's -- small-caps labels and eyebrows, the text serif for prose in a node, the page's
   paper ground, and no sans-serif anywhere.
3. **Stat row** - two to four measured figures in the Display cut, lining tabular, with a
   caption under each. Rule
   above in ink, rule below in grey. Only for numbers that were measured.
4. **Comparison table** - one row per dimension, two or three columns, the new
   column headed in accent. No vertical rules.
5. **Data table** - mono keys, serif descriptions, tabular numerals right-aligned,
   ink rule above and below the head, grey rules between rows, `thead` repeated
   across pages.
6. **Figure plate** - full measure, no border, no shadow, no rounded corner. A
   small-caps spec line directly under it (name, then greyed facts, then status in
   accent), then a caption naming what the plate is evidence of. Half-measure
   plates come in pairs sharing a baseline.
7. **Provenance footline** - grey rule, then one or two serif lines at 8.5 pt, ink 55%,
   saying what the page's numbers were read from: the command, the commit, the
   file, the date. Mandatory on any page with a figure or a statistic.
8. **Numbered sources** - one list on the last page, numbered in the order the
   superscripts appear, each with the date read. URLs in mono. No footnotes at the
   foot of the page.
9. **Claim** - the one sentence the document exists for, at 27 pt between two ink
   rules, with a small-caps line under it. Exactly one per document.
10. **Callout** - the objection a careful reader would raise, stated before they
    have to. A grey rule above and below, the accent small-caps label hanging in
    a 96 pt column at the left, the body at 10.5 / 16 beside it. No fill, no
    icon, never two in a row. *v5: this replaces the flat #F0EADE box, which
    read as pasted onto the page.*
11. **Code block** - #F2EEE3 ground, ink rule on top only, Plex Mono, output
    shown as it came back. A skipped check prints its reason.
12. **Display equation** - centred, serif, italic variables and upright
    operators, number at the right margin as (1). Every symbol named in the
    sentence after it, in order of appearance. Referred to as (1), never as "the
    equation above".

## Voice rules the layout assumes

- The opening paragraph is the only general one. Everything after it is a number,
  a mechanism, a table, or a check that passed.
- A number with no source gets a provenance footline. If neither a source nor a
  footline exists, the number does not go in.
- Say what a pass does not mean on the same page it is claimed.
- Nothing is illustrated twice. If a diagram carries it, the prose does not repeat
  it.
