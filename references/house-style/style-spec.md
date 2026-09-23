# House style for technical documents

The visual spec behind `Documentation House Style.dc.html`. Every value here is
what that template renders; the LaTeX class `housestyle.sty` implements it.

## Page

| | Letter | A4 |
|---|---|---|
| Trim | 8.5 x 11 in | 210 x 297 mm |
| Top margin | 54 pt | 54 pt |
| Side margins | 72 pt | 72 pt |
| Foot margin | 44 pt | 44 pt |
| Measure | 34 em of body text (~420 pt) | same |

Portrait only. One geometry for every recipe; a landscape reference sheet is a
separate class, not a variant of this one.

Running head on every page but the first: document slug at the left, section name
at the right, mono 10.5 pt uppercase, +14% tracking, ink 55%, with a 0.75 pt grey
rule under it. Page number at the foot, same style, outer edge.

## Type

Two faces, both open-licensed and vendored in `assets/fonts/` for lualatex.

- **Source Serif 4** - all prose, headings, captions, tables, mathematics.
- **IBM Plex Mono** - labels, running heads, figure numbers, statistics, code,
  file paths, provenance lines.

| Role | Face | Size / leading | Notes |
|---|---|---|---|
| Document title | serif 400 | 52 / 56, -1.5% | title page only |
| Page heading | serif 400 | 28 / 34, -1% | one per page, at the top |
| Lead line | serif 400 | 17 / 26 | ink 70%, two lines max |
| Body | serif 400 | 16 / 26 | the default for prose |
| Claim (pull quote) | serif 400 | 27 / 35 | one per document |
| Caption, figure note | serif 400 | 13.5 / 20 | ink 70% |
| Table body | serif 400 | 14 / 20 | numerals tabular, right-aligned |
| Statistic | mono 500 | 38 / 38, -3% | four abreast, never five |
| Label, provenance | mono 400 | 10.5, +14% tracking | uppercase, ink 55% |
| Code | mono 400 | 12.5 / 21 | no syntax colour in print |

No bold in body text. Emphasis is italic. No small caps, no underline except on
links.

## Colour

| Token | Hex | Use |
|---|---|---|
| ink | #15140F | text, structural rules |
| ink-70 | #4A4740 | lead lines, captions, secondary table cells |
| ink-55 | #8A857A | labels, running heads, provenance, dividing rules |
| paper | #FAF8F3 | the sheet, painted on every page |
| fill | #F0EADE | callout ground; #F2EEE3 for code ground |
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

One 8 pt step, used as 8 / 16 / 24 / 32 / 56. Blocks are separated by 32, a new
section by 56. Rules are 0.75 pt: ink where they carry structure (above a table
head, under the title block), grey where they only divide.

## The twelve blocks

1. **Title block** - eyebrow (mono, accent), title, one-line lead, then content.
   Documents over twelve pages get a dedicated title page with a four-column
   metadata strip at the foot: built for / paper / type / scope.
2. **Diagram** - drawn for what it shows. *Owner's decision, 22 September 2026:
   "dont force diagrams into the format in the template". This replaces the
   earlier text of this block, which allowed three node kinds and no more.* The
   node row is one pattern: horizontal nodes, mono arrow glyphs, a slate box
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
   is the house's -- mono labels, the text serif for prose in a node, the page's
   paper ground, and no sans-serif anywhere.
3. **Stat row** - four measured figures, mono, with a caption under each. Rule
   above in ink, rule below in grey. Only for numbers that were measured.
4. **Comparison table** - one row per dimension, two or three columns, the new
   column headed in accent. No vertical rules.
5. **Data table** - mono keys, serif descriptions, tabular numerals right-aligned,
   ink rule above and below the head, grey rules between rows, `thead` repeated
   across pages.
6. **Figure plate** - full measure, no border, no shadow, no rounded corner. A
   mono spec line directly under it (name, then greyed facts, then status in
   accent), then a caption naming what the plate is evidence of. Half-measure
   plates come in pairs sharing a baseline.
7. **Provenance footline** - grey rule, then one or two mono lines at 10.5 pt
   saying what the page's numbers were read from: the command, the commit, the
   file, the date. Mandatory on any page with a figure or a statistic.
8. **Numbered sources** - one list on the last page, numbered in the order the
   superscripts appear, each with the date read. URLs in mono. No footnotes at the
   foot of the page.
9. **Claim** - the one sentence the document exists for, at 27 pt between two ink
   rules, with a mono line under it. Exactly one per document.
10. **Callout** - the objection a careful reader would raise, stated before they
    have to. Flat #F0EADE ground, accent mono label, no icon, no border, never two
    in a row.
11. **Code block** - #F2EEE3 ground, ink rule on top only, mono 12.5 pt, output
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
