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

`ds.py` beside this file does all of it with the Python standard library:

| Command | What it does |
|---|---|
| `ds.py find [dir]` | Prints the token file that applies to `dir`; exit 1 and nothing when none does. |
| `ds.py import <export> [-o out] [--logo file]` | Turns a Claude Design export into a token file. |
| `ds.py check <tokens.json>` | Validates a token file. |
| `ds.py latex <tokens.json>` | Prints the LaTeX theme `scripts/build.sh` loads after `housestyle.sty`. |
| `ds.py xlsx <data.csv> -o out.xlsx [--title T] [--sheet S] [--tokens file]` | Writes the rows as a styled workbook. |

`find` walks up from the directory and stops at the first one holding `.git`,
so it never reads a file above the repo. `DESIGN_TOKENS=<path>` names a file
outright, and `DESIGN_TOKENS=none` turns the system off for one run.

## Dropping in a Claude Design export

1. Unzip the export into the workspace. It is a folder with `tokens/*.css`
   (`colors.css`, `typography.css` and so on) and usually `assets/logo/`.
2. From the repo root, run
   `python3 ~/.claude/skills/pdf-material-builder/apply-design-system/ds.py import <export-folder> --logo <export-folder>/assets/logo/<the-logo>.png`.
   It writes `.cc/design-tokens.json` and copies the logo beside it as
   `.cc/design-logo.png`. With exactly one logo in the export, `--logo` can be
   left off; with several it takes none and lists them.
3. Read the notes it prints: a token the export does not define keeps the
   house value, and it says which.
4. Commit `.cc/design-tokens.json` and the logo. From then on every PDF built
   in the repo, and every workbook `ds.py xlsx` writes there, wears the system.

The importer reads only `:root` blocks, so a sister brand's
`[data-brand="..."]` override is left out. It resolves `var()` chains and
converts `oklch()`, `rgb()` and short hex colours to `#RRGGBB`. Which CSS
variable fills which token is the `IMPORT_*` tables in `ds.py`: the semantic
names (`--text-primary`, `--surface-page`, `--brand-accent`,
`--border-default`, `--font-sans`, `--type-heading-case` and so on) first.
The token file is plain JSON, so a value the mapping got wrong is fixed by
editing it.

Fonts come by name. A family that is not installed on the machine falls
through the CSS stack to the next one, and a generic `sans-serif` ends on
FreeSans or DejaVu Sans. To get the brand's own face, install its font files
where fontconfig finds them; the token file does not change.

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
 "logo": "design-logo.png"}
```

Every key is optional, and a key left out keeps the house value.

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
