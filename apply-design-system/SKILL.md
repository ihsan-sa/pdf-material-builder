---
name: apply-design-system
description: Give everything generated in one workspace that workspace's own design system instead of the house look. Use it when a workspace or repo carries .cc/design-tokens.json, when someone wants their PDFs or spreadsheets to wear their own brand, colours or fonts, when a Claude Design design-system export has to be dropped in, or when a new generator (xlsx, docx, slides) should pick up the workspace's look. pdf-material-builder's build.sh applies it on its own.
---

# apply-design-system

A workspace chooses its look with one committed file at its repo root,
`.cc/design-tokens.json`. Every generator run inside that repo reads it, and a
repo without it keeps the house look, unchanged to the byte. Selecting a
system is config, never an edit to a skill: the skills are read-only inside a
member workspace anyway.

`ds.py` beside this file does all of it with the Python standard library,
and fontTools when an export ships its own font files:

| Command | What it does |
|---|---|
| `ds.py find [dir]` | Prints the token file that applies to `dir`; exit 1 and nothing when none does. |
| `ds.py import [<export>] [-o out] [--logo file\|name] [--voice file]...` | Turns a Claude Design export into a token file; with no export, re-imports the one it came from. |
| `ds.py check <tokens.json>` | Validates a token file. |
| `ds.py voice <tokens.json>` | Prints the voice guides the token file points at. |
| `ds.py latex <tokens.json>` | Prints the LaTeX theme `scripts/build.sh` loads after `housestyle.sty`. |
| `ds.py xlsx <data.csv> -o out.xlsx [--title T] [--sheet S] [--tokens file]` | Writes the rows as a styled workbook. |

`find` walks up from the directory and stops at the first one holding `.git`,
so it never reads a file above the repo. `DESIGN_TOKENS=<path>` names a file
outright, and `DESIGN_TOKENS=none` turns the system off for one run.

## Dropping in a Claude Design export

1. Unzip the export into the workspace. It is a folder with `tokens/*.css`
   (`colors.css`, `typography.css`, `fonts.css` and so on), and often
   `fonts/`, `assets/logo/`, `assets/icons/` and `guidelines/`.
2. From the repo root, run
   `python3 ~/.claude/skills/pdf-material-builder/apply-design-system/ds.py import <export-folder> --logo <the-logo>`.
   `--logo` takes a file or a name in the export's `assets/logo/`
   (`--logo lockup-horizontal`). With exactly one logo in the export it can be
   left off; with several it takes none and lists them. Add `--voice <file>`
   for a voice guide that lives outside the export, such as the project's own
   design skill.
3. It writes `.cc/design-tokens.json` and, beside it, what LaTeX needs:
   `design-logo.pdf` (an SVG logo, converted), `design-icons.pdf` (every SVG
   in `assets/icons/`, a page each, drawn in the system's ink) and
   `design-fonts/` (the font files below).
4. Read the notes it prints: a token the export does not define keeps the
   house value, and a family it ships no file for comes by name, and it says
   which.
5. Commit `.cc/`. From then on every PDF built in the repo, and every
   workbook `ds.py xlsx` writes there, wears the system.

After the design changes, re-import with no arguments from anywhere in the
repo: `ds.py import`. The token file's `source` remembers the export folder
and the logo taken, and the re-import keeps the copyright holder and the
voice guides already there.

SVGs are converted with `rsvg-convert`, or headless Chrome when that is not
installed. With neither, the import keeps no logo or icons and says so.

The importer reads only `:root` blocks, so a sister brand's
`[data-brand="..."]` override is left out. It resolves `var()` chains and
converts `oklch()`, `rgb()` and short hex colours to `#RRGGBB`. Which CSS
variable fills which token is the `IMPORT_*` tables in `ds.py`, which know
two naming schemes: `--text-primary`, `--surface-page`, `--brand-accent`,
`--border-default` and the numbered `--fg-1`, `--bg-page`, `--fg-accent`,
`--border-1`. Headings take `--font-heading`, then `--font-display`, then
`--font-sans`. An export with other names gets rows in those tables. A
re-import overwrites the colours and faces, so a value the mapping got wrong
is fixed in the tables, or by editing the JSON and not re-importing.

## Fonts

A design system can ship its own fonts. When the export's `@font-face` rules
point at files for a family its type stacks name, the import writes them to
`.cc/design-fonts/` as static TrueType or OpenType files: woff2 and woff are
unpacked, and a variable font is cut at each weight the CSS asks for. The
regular face is the weight nearest 400, bold the heavier weight nearest 700,
and italic likewise. `fontspec` loads them by path, so nothing is installed
on the machine, and a family with files wins over the rest of its stack.
This needs fontTools and brotli (`pip install fonttools brotli`); without
them the import says so and the families come by name.

A family with no files still comes by name. One that is not installed falls
through the CSS stack to the next, and a generic `sans-serif` ends on
FreeSans or DejaVu Sans.

## Icons

When the export has `assets/icons/*.svg`, a document can place one inline
with `\dsicon{name}` (the file name without `.svg`), a cap high, or
`\dsicon[1em]{name}` at a given height. An unknown name stops the build and
lists the icons. `\dsicon` exists only when the design system has icons, so
a document that uses it builds only in that repo.

## Voice

When the export has a voice guide (`guidelines/*voice*`), or `--voice` named
one, the token file points at it and `build.sh` names it on its
`design system:` line. The writer follows that guide over
`references/voice.md` where the two disagree, and the house voice everywhere
the guide is silent. The guide is read where it is, never copied.

## The token file

```json
{"name": "salari-test placeholder",
 "color": {"ink": "#1B1F24", "ink-secondary": "#3D444D", "ink-muted": "#5F6873",
           "paper": "#FFFFFF", "fill": "#F3F5F7", "code-fill": "#EEF1F4",
           "accent": "#2B5C8A", "rule": "#D5DAE0"},
 "type":  {"body": ["Helvetica Neue", "Arial", "sans-serif"],
           "heading": ["Helvetica Neue", "Arial", "sans-serif"],
           "mono": ["Menlo", "monospace"], "heading-case": "uppercase"},
 "table": {"header-fill": "#1B1F24", "header-text": "#FFFFFF",
           "rule": "#1B1F24", "stripe": "#F3F5F7"},
 "logo": "design-logo.png",
 "copyright": {"holder": "A Member"},
 "fonts": {"IBM Plex Sans": {"regular": "design-fonts/ibm-plex-sans-400.ttf",
                             "bold": "design-fonts/ibm-plex-sans-600.ttf"}},
 "icons": {"file": "design-icons.pdf", "names": ["check", "sigma"]},
 "voice": ["../design/guidelines/brand-voice.html"],
 "source": {"path": "../design", "logo": "../design/assets/logo/lockup.svg"}}
```

Every key is optional, and a key left out keeps the house value. Every path
is relative to the token file.

| Token | In a PDF | In a workbook |
|---|---|---|
| `color.ink`, `ink-secondary`, `ink-muted` | `ink`, `inkseventy`, `inkfiftyfive` | cell text |
| `color.paper`, `fill`, `code-fill` | the page, `fill`, `codefill` | |
| `color.accent`, `rule` | `accent`, `rulegrey` | row rules |
| `type.body` | prose, labels, running head | body cells |
| `type.heading` | headings, title, stat figures | the title |
| `type.mono` | code, URLs, paths | number cells |
| `type.heading-case: uppercase` | headings, title, labels, running head in capitals | title and header row in capitals |
| `table.*` | | the header row, its rule, alternate-row stripe |
| `logo` | right of the first page's head | |
| `copyright.holder` | the holder the foot's copyright line names; a document's own `\hscopyrightholder` wins. A member's workspace sets it: a member's build prints no copyright line until something names the holder | |
| `fonts.<family>` | the face loaded by path for a type stack that names the family | |
| `icons` | what `\dsicon{name}` places | |
| `voice` | named on build.sh's line; the writer follows it over `references/voice.md` | |
| `source` | the export and logo `ds.py import` re-reads | |

The page geometry, sizes and spacing stay the house style's in a PDF, so the
measure, the page-break rules and every figure still fit. The TikZ kit's node
fills (`hsdiagrams.sty`) keep their slate, sage and rust.

## A new generator

A generator gets the workspace's look by calling `ds.py find` on the directory
it writes into. When it prints a path, the generator loads that file (`ds.py
check` validates it) and maps the tokens onto its own styles, as `latex()` and
`xlsx_styles()` in `ds.py` do. When it prints nothing, the generator does what
it did before.

`examples/salari-test/` is a placeholder system with a sample PDF and
workbook built from it; `examples/salari-test/design-tokens.json` is what
a workspace commits as `.cc/design-tokens.json`.
