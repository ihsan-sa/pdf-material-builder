# pdf-material-builder goals

A Claude Code skill that builds teaching material and technical documentation as LaTeX PDFs, at any length, in one house style and one voice. A one-page cheat sheet, a short companion to a single lesson, a long set of course notes and a design note all share the same page and the same author.

## Proposed goals

Filed by runs. Each says what done looks like as something a run can check, and keeps its status (open, done, failed, dropped) with the pull requests that moved it. At most three are open at once.

### build.sh passes a revision note when it files a document

- **Status:** open
- **What:** With `DOC_PROJECT` and `DOC_TITLE` set, `scripts/build.sh` numbers the document before it compiles and files the finished PDF in the document register after. The filing call never passes `--note`, and build.sh reads no variable that could carry one, so a rebuilt document is filed as a new revision (B, C and so on) with nothing saying what changed. Read a `DOC_NOTE` variable and pass it to the filing call as `--note "$DOC_NOTE"`; with `DOC_NOTE` unset, call it exactly as today. Document `DOC_NOTE` in build.sh's header comment beside the other `DOC_*` variables, and in `SKILL.md` and `references/recipes.md` where the finished build is described.
- **Done when:** `tests/check.sh` passes, and its case 15 (the document register, with a stub that logs its calls) also builds with `DOC_NOTE` set and finds `--note` followed by the note's text in the logged `file` call, while the build without `DOC_NOTE` logs no `--note`.

## Later

Goals waiting for an open slot. When a proposed goal closes, the run that closed it moves the top one here up into Proposed goals as open.

None is waiting yet.

## Closed

What has landed, from the git history, one line per pull request in this repo, newest first.

- #18 Build PDFs in a project's own design system, fonts and voice
- #17 Print the copyright line in every house-style foot
- #16 Stop raggedbottom pages from breaking nearly empty
- #15 Make this repo's GitHub checks pass on main
- #14 This repo's checks run on GitHub Actions
- #13 Make each whole contents line a hidden link to its section
- #12 Each workspace's PDFs can wear their own theme
- #11 Stop stranded lines and split listings at page breaks
- #10 A finished build prints its document number under the foot of every page and is filed in the document register
- #9 Pass figure specs to diagram-maker's new export.sh
- #8 Adopt house style v5.1 and bundle diagram-maker for figures
- #7 Apply Claude Design's v5 fixes: spacing, labels, sources page
- #6 Adopt Claude Design's house style v5 templates
- #5 Draw diagram boxes in light role colours, not black
- #4 Make built documents look like the house-style template
- #3 Adopt the documentation house style as the one look
- #2 Refresh vendored voice spec to lesson-builder's attempt-first wording
- #1 Widen to PDF material builder; share voice with lesson-builder
