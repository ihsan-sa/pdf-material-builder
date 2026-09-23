# Word template: style names

> **In this skill:** vendored as Claude Design sent it with house style v5.
> Nothing here converts a .docx to PDF yet: LibreOffice and python-docx are not
> installed on the box, and installing them waits on the owner. Until then a
> PDF comes from the LaTeX side. `CHANGES.md` below means
> `references/house-style/CHANGES.md`, which lists what to check under
> LibreOffice once there is one.

`house-style.docx` is the Word half of house style v5. The skill fills it from
code and converts it to PDF with LibreOffice, so the whole look lives in the
named styles below. Apply a style by name; add no local formatting.

**These names are the interface.** Once shipped they do not change, the same
rule as the LaTeX command names. New styles may be added; none is renamed or
removed.

## Page

- Letter, 8.5 x 11 in. Margins match `housestyle.sty`: top 54 pt, sides 72 pt,
  bottom 44 pt; header 28 pt from the top edge, footer 18 pt from the bottom.
- **A4:** change only the page size, to 11906 x 16838 twips (`w:pgSz` in the
  section properties, or Layout > Size). Margins stay.
- Page colour `#FAF8F3` is set as the document background. If a LibreOffice
  build exports white pages, the background did not carry: see CHANGES.md.
- Different first page. Long form: the title page is framed by two ink rules,
  slug and date above, copyright below, no page number. Short form: the first
  page has no running head and keeps the foot.
- Header: slug, a right tab, then a `STYLEREF "heading 1"` field for the
  section name. Footer: copyright line, a right tab, a `PAGE` field. Code can
  also write the section name into the header as plain text, which is safer
  than the field (see CHANGES.md).

## Labels and small caps

Every label style uses Word's small-caps attribute. Word and LibreOffice set
lower-case letters as small caps and leave capitals full height, so **write
label text in lower case** ("figure 1", "what this does not mean") to get the
all-small-caps look of the LaTeX version. This applies to Eyebrow, Label,
Callout Label, Claim Attribution, Table Head, Plate Spec, Inline Label, Header
and Footer.

A figure, table or listing label is two runs in one **Label** paragraph: the
number ("figure 1") in the paragraph's own style, two spaces, then the title
in the **Label Title** character style.

## Paragraph styles

| Style | Block | What it is for |
|---|---|---|
| Normal | | The base. 11.5 / 18.5 pt Source Serif 4, ink. Not applied directly. |
| Body | | Prose, on the 34-em measure (48 pt short of the right margin). |
| Eyebrow | 1 | The accent small-caps line over a title or a Part heading. |
| Title | 1 | The document title. Source Serif 4 Display, 36 / 40 pt. |
| Title Page Eyebrow | 1 | The Eyebrow on a dedicated title page; drops the title block to about a third of the page. |
| Title Page Title | 1 | The title on a dedicated title page. Display, 44 / 48 pt. |
| Lead | 1 | The lead under a title or a section heading. 12.5 pt, ink 70%. |
| Heading 1 | | A section heading. Subhead cut, 20 / 24 pt. Start a new page with page-break-before, not an empty paragraph. |
| Heading 2 | | A subsection. Subhead cut, 14 / 19 pt. |
| Heading 3 | | A sub-subsection. Text italic. |
| List Bullet | | A bulleted item; the bullet is ink 55%. |
| Equation | 12 | A display equation: tab, the equation, tab, the number "(1)". Maths-heavy material stays LaTeX-first. |
| Label | 2, 4, 5, 11 | The label over a figure, table or listing. |
| Figure | 2, 6 | The paragraph holding a diagram image, centred between two grey rules. |
| Fail Note | 2 | The fail path's caption, directly under the Figure paragraph, inside the same rules. Italic, accent. |
| Caption | 2 | The legend sentence under a figure, naming the kinds of box it uses. |
| Stat Figure | 3 | The number in a stat-row cell. Display cut, 28 pt. |
| Stat Caption | 3 | What was measured and when, under the Stat Figure in the same cell. |
| Table Head | 4, 5 | A header cell in a Data Table. |
| Table Body | 4, 5 | A body cell. |
| Plate Spec | 6 | The spec line under a plate: name, then Label Muted facts, then Label Accent status. |
| Plate Caption | 6 | What the plate is evidence of. |
| Provenance | 7 | The footline: grey rule, 8.5 pt ink 55%. The last paragraph on any page with a figure or a statistic. |
| Sources List | 8 | One numbered source. Accent numerals. |
| Claim | 9 | The one sentence the document exists for. Subhead cut, 19 pt, ink rule above. |
| Claim Attribution | 9 | The small-caps line under the claim, ink rule below. |
| Callout Label | 10 | The callout's accent small-caps label, which states the objection. Left cell of a Callout Table. |
| Callout | 10 | The callout's body. Right cell of a Callout Table. |
| Code | 11 | One line of a listing, in IBM Plex Mono on #F2EEE3, ink rule on top. Consecutive Code paragraphs merge into one block. |
| header, footer | | The running head and foot. Built-in names. |
| Title Page Header, Title Page Footer | 1 | The long form's first-page header (slug, tab, date) and footer (copyright), each on an ink rule, so the title page is framed. |
| toc 1, toc 2 | | Table of contents entries, if a TOC field is used. Built-in names. |

## Character styles

| Style | What it is for |
|---|---|
| Label Title | The italic title half of a figure, table or listing label. |
| Label Muted | Grey facts in a Plate Spec line. |
| Label Accent | The accent header cell of a comparison table (one per table); a plate's status. |
| Inline Label | A small-caps label inside a paragraph: [optional], [T5]. |
| URL | A URL in a source entry. Plex Mono, ink 70%. |
| Code Inline | A command, key or path inside prose or a table cell. Plex Mono. |
| Emphasis | Italic. The only emphasis there is. |

## Table styles

| Style | Block | What it is for |
|---|---|---|
| Data Table | 4, 5 | Comparison and data tables. Ink rule on top, grey rules between rows, small-caps header row. Mark the header row as a repeating header row. |
| Stat Row | 3 | A one-row table of two to four cells, one Stat Figure and one Stat Caption in each. Ink rule on top, grey below. Never five cells. |

| Callout Table | 10 | A one-row, two-cell table: Callout Label in a 112 pt left cell, Callout in the right. Grey rule above and below, no fill. |

## Two starting documents

- `house-style.docx`: the long form. Title page, then the body from page two, with every style shown once.
- `house-style-short.docx`: the short form. Eyebrow, Title and Lead open page one and the prose follows on the same page. Same styles; use it for anything up to about twelve pages.

## Fonts

Install these on the machine that converts, from `assets/fonts/` (all OFL):
Source Serif 4 (Regular, Italic, Semibold, Semibold Italic, Bold), Source
Serif 4 Subhead, Source Serif 4 Display, IBM Plex Mono (Regular, Medium). On
Linux, copy them to `~/.fonts/` and run `fc-cache -f` before calling
`soffice --headless --convert-to pdf`.
