---
name: pdf-material-builder
description: Build teaching material and technical documentation as LaTeX PDFs, at any length, in one house style and one voice. Use this skill whenever the user asks to create, build, make, generate or update a study pack, reference document, formula sheet, course notes, worked examples, visual intuition doc or "document set" for a course (ECE, CS, MATH, PHYS, etc.), OR a companion, handout or printable PDF for one lesson-builder lesson, OR a cheat sheet, OR a technical doc, design note, report or write-up as a LaTeX PDF, OR says "do for X what we did for Y", OR says "build the PDFs for <course>" or "set up reference docs for <course>", OR points at a folder of lecture PDFs and wants a pedagogical PDF out of it.
---

# PDF material builder

Present teaching material and technical documentation in LaTeX, at whatever length the job needs: a 1pp cheat sheet, a 2-6pp companion to one lesson, a 40-70pp set of course notes, a design note. Every document shares one look and one voice, so a reader moving between them is reading the same author.

Three things are settled before any writing starts, and each has its own reference:

- **Which document.** `references/recipes.md` -- role, length band, structure and build size per recipe.
- **How it looks.** `references/house-style/style-spec.md` is the look: one portrait page, two faces, five neutrals and one accent, twelve blocks. `references/latex-house-style.md` maps it onto macros and carries the build, the teaching affordances, the math kit, the traps and the style gate.
- **How a page is put together.** `references/page-composition.md`. Calling every macro correctly is not enough and the first real build proved it: read this before the first page and again with the rendered PDF open. `references/house-style/CONFORMANCE.md` is the owner's own ten checks and the defects each one exists to stop.
- **How it explains.** `references/teaching-communication.md` is the canonical voice, shared with the lesson-builder skill. `references/voice.md` says which LaTeX construct carries each of its representations, and holds the three page-level rules the spec has no row for.

## Pick the recipe first

`references/recipes.md` has the full table. In short: `reference`, `formula-sheet`, `visual-intuition`, `worked-examples`, `course-notes`, `companion`, `cheat-sheet`, `technical-doc`.

**"Build the PDFs for `<course>`" means the first five**, in that order, as one coordinated set. That is a default manifest, not a fixed set: drop what the course does not need, add a `cheat-sheet` if the reader wants one, and say which manifest you are building before you start.

The recipe sets the **build size**, and build size is the only thing that changes the pipeline.

## Small builds

`companion`, `cheat-sheet` and a short `technical-doc` are small. **No intake phase, no extractor fan-out, no five-reviewer pass** -- their source is already structured, and spawning eight extractors over a lesson that has already been planned and reviewed spends a fortune to reintroduce drift.

A small build is four steps, and the orchestrator does the first three itself:

1. **Read the source.** For a `companion`: the lesson's run record and `lesson_build.log.md` (the plan artifact; its format is `lesson-builder/references/phase-2-plan.md`) and the lesson's `.jsx` prose. For a `cheat-sheet`: the existing reference or course notes. For a `technical-doc`: whatever the user pointed at.
2. **Write the driver.** One file, preamble copy-adapted from `assets/preamble-template.tex`, no `\input` stubs.
3. **Write the body.** One agent, or none. Condense the source; do not re-derive it. Plan the page shapes first, per `references/page-composition.md`: list the pages, give each one a shape, and change any two in a row that came out the same.
4. **Review.** Two reviewers, not five: the math verification agent and the cold-edit reviewer. `references/review-pipeline.md` says which three are skipped and why.

Then build with `scripts/build.sh`, run `scripts/style-check.sh`, and hand over.

## Large builds

`reference`, `formula-sheet`, `visual-intuition`, `worked-examples` and `course-notes` are large: their content is re-derived from source materials nobody has read yet.

### Phase 1 -- Intake and extraction

**Step 1.1 -- Ask four questions (minimum).** Use `AskUserQuestion`; do not assume answers even in auto mode.

- **Taxonomy**: which category labels (A/B/C/...) organise the material? Propose a default from the lecture list.
- **Weak areas**: which 1-3 topics deserve extra depth? (Multi-select.)
- **Past exams**: does a practice midterm / final / review guide exist? If yes, the user will point at the folder.
- **Banned-optional list**: anything the prof explicitly flags as out of scope? (Often surfaces from the review guide, but ask anyway.)

**Step 1.2 -- Parallel lecture extraction.** Spawn about 8 `general-purpose` agents in one message. Split the lecture PDFs into batches of 2-5 per agent. A single agent reading 5 dense PDFs can hit the context limit; **if PDFs are image-heavy or dense, use 2-3 per agent, not 5**.

Each extraction agent writes one markdown file per lecture to `<build_dir>/_extraction/<LN>_<slug>.md` with:

- Title, core definitions (verbatim), theorems / results, algorithms / procedures
- Complexity / error / accuracy claims
- Invariants and properties, notational conventions (flag anything prof-specific)
- Emphasis cues (what the prof repeats, colours, slogans)
- Worked examples shown in lecture (copy numbers verbatim)
- Cross-lecture links

Each batch also writes `_notation_L<range>.md` listing conventions worth propagating.

**Step 1.3 -- Exam and problem-set extraction.** In parallel with the lecture batches, spawn agents for the official formula sheet and reference tables, the practice midterms and finals (verbatim statements plus key numerical answers), and the problem-set solutions (one file per set, flagging which problems are high-value for `worked-examples`).

**Step 1.4 -- Consolidate conventions.** Read all the `_notation_*.md` files and write `<build_dir>/_extraction/_<PROF>_CONVENTIONS.md` as the single source of truth: function-letter conventions, equation normalisation choices, signed-letter conflicts (wave speed $a$ vs Fourier coefficient $a_n$), taxonomy, tools analogue, weak-area flags, banned-optional list, exam format.

**Every downstream builder prompt cites this conventions doc as critical reading item #1.** Without it every builder re-derives conventions and the set drifts.

### Phase 2 -- The anchor document

Build `reference` first: it forces the taxonomy to be nailed down, and every later document cites its categories. Exception, per `references/recipes.md`: when the course provides an official formula sheet verbatim, build `formula-sheet` first, because it is the most deterministic document in the set.

Spawn one `general-purpose` agent with the conventions doc, the extraction markdowns, and a sibling course's reference as a voice sample. Outputs: `<name>_reference_body.tex` (shared body with `\if*` toggles), `<name>_reference.tex` (driver, all flags false), and optionally `<name>_reference_examples.tex` and `<name>_reference_formulas.tex` variants that flip the flags.

### Phase 3-5 -- Parallel builders

Once the anchor exists, spawn the remaining short-form builders in one message: `worked-examples`, `formula-sheet`, `visual-intuition`. Each recipe's structure is in `references/recipes.md`.

### Phase 6 -- Course notes

**Step 6.1 -- Write the driver first.** The orchestrator, not a subagent, writes `<name>_course_notes.tex` from `assets/driver-template.tex`: full preamble, macros, title page, `\tableofcontents`, and `\input{course_notes/NN_name}` stubs. This settles Part ordering and label conventions before the writers run.

**Step 6.2 -- Spawn 8-10 parallel section writers in one message.** One `course_notes/NN_name.tex` each: `00_preface.tex`, one per taxonomy category, `99_appendix.tex`. Weak-area sections get 8-11pp and explicit instructions to go deep with full `derivation` runs and figures; the rest get 4-6pp.

**Step 6.3 -- Every writer brief carries these.** Do not economise; repeat them in each prompt.

- The conventions doc path (mandatory critical reading)
- The driver file path, which shows the macros available (`\insight`, `derivation`, `\onsheet`, `\opt`, `\tool`, `\tools`, `\cat`, `\catbanner`, `\probhead`, `\Oh`, and the house-style blocks: `hsfigure` with `\hsnodetext` and `\hsfailnote`, `\hsplate`, `hscallout`, `\hslisting` with `Verbatim`, tables with `\hstoprule` and `\hshead` inside `hsblock`), and the rule that nothing else is drawn: no boxes, no colour outside the tokens, no footnotes
- `references/page-composition.md`, which is what stops a writer filling the form instead of composing the page: the shape catalogue, the arguments that must not be empty, and the three diagram patterns with tikz to copy
- `references/voice.md` and `references/teaching-communication.md`, plus a sibling section as a voice sample
- The relevant extraction files, the target page count, and whether this is a weak-area section
- Hard rules: no emojis, no em-dashes, no `\footnote`, no colour but the tokens, at most one `\hsclaim` per document, no `\lt` / `\gt` (LaTeX is not KaTeX), `\Oh{...}` not bare `$O()$`
- Cross-references to expect ("foreshadows Part 5", "cites Part 1's recurrence-tree method via `\ref{sec:...}`")
- Banned-optional items to `\opt`-tag or skip

**Step 6.4 -- The Part-numbering trap.** Parallel writers each independently claim `\part{}` labels, so two writers both opening a Part both get Part 1. Fix it one of two ways and be explicit in every brief: either only certain section files open new Parts with `\catbanner` (`01_`, `02_`, `04_`, `07_` do; `03_`, `05_`, `06_` continue theirs), or the driver pre-declares every Part and section files use only `\section` and `\subsection`.

### Phase 7 -- Review

Read `references/review-pipeline.md` before launching. Five parallel reviewers: full-context content, student-peer brutal, cross-doc consistency, math verification, cold-edit.

**The filter phase is mandatory.** Reviewers hallucinate, and 20-40% of findings are false positives. Re-derive every math claim from scratch rather than trusting the reviewer's algebra; grep the file to confirm every quoted string exists verbatim; require two independent reviewers to agree before acting on a subjective claim. Apply only verified fixes, then rebuild.

## Traps that have cost real rework

`references/latex-house-style.md` has the full list with fixes. The ones that have bitten more than once:

- **`\lt` and `\gt` leak from KaTeX into LaTeX** and fail with "Undefined control sequence". Grep after every agent write. Replace with Python, not `sed`: regex edge cases corrupt `\Delta`.
- **Old macros in a writer's head.** `step`, `pictureit`, `fsheet`, `connect` and the coloured boxes are gone, and no tcolorbox is loaded. Map each onto the affordance table in `references/latex-house-style.md`; never define them again.
- **`\trans` must be `{\!\top}`, not `^{\!\top}`**, so `X^\trans` expands to `X^{\!\top}` and not a double `^`.
- **Three compile passes for a multi-page TOC.** Two is not enough: pass 1 writes an empty TOC, pass 2 writes a populated one that shifts every page number, pass 3 re-resolves the cross-references against the shifted layout. `scripts/build.sh` runs three, and compiles to a `_tmp_<name>` jobname so an open PDF does not lock the build.
- **The luaotfload font cache keeps the first path it saw.** A font first loaded through a relative path breaks later builds from another directory with "cannot find file ''" at shipout. The `.sty` uses an absolute path; if it happens, `touch assets/fonts/*.otf` forces a reload.
- **Em-dashes and emojis are banned.** `scripts/style-check.sh` is the gate; run it after every agent-authored write, not only at the end.

## Agent orchestration

- **About 8 agents per message** rather than serialising. Bulk similar work (parallel extractors, section writers, reviewers) into one call.
- **Brief agents like smart colleagues.** They have not seen the conversation: self-contained prompts, file paths, target lengths, hard rules, banned items, cross-reference expectations.
- **Do not trust agent summaries.** Agents describe what they intended to do. Read the files before marking a phase done.

## Directory layout

A large course build:

```
<build_dir>/
  <name>_course_notes.tex          # driver: preamble + \input stubs
  course_notes/00_preface.tex ... 99_appendix.tex
  <name>_reference.tex             # driver: preamble + flags
  <name>_reference_body.tex        # shared body with if-toggles
  <name>_formula_sheet_annotated.tex
  <name>_visual_intuition.tex
  <name>_worked_examples.tex       # driver with TOC
  worked_examples/problem_01_<slug>.tex ...
  viz_src/generate_all.py  _style.py  fig_<name>.py  viz_<name>.png
  _extraction/                     # local-only
    L1_<topic>.md ...  _notation_L<range>.md  _pset_NN_<slug>.md
    _practice_midterm.md  _practice_final.md  _exam_format.md
    _<PROF>_CONVENTIONS.md         # single source of truth
```

A companion lands inside its lesson instead: `<COURSE>/claude_lessons/<slug>/<course>_<slug>_companion.tex` and its `.pdf`. `references/recipes.md` says what the lessons repo must change to publish it, and `docs/integration.md` carries that as work for a follow-up track there.

## Quality bar before declaring done

**Compile.** `scripts/build.sh` (lualatex, three passes) exits 0; no `! Undefined control sequence`, no `! LaTeX Error`, no broken `\ref`; TOC populated (check by extracting the text of pages 2-3); page count inside the recipe's band.

**Style.** `scripts/style-check.sh` exits 0 over the build directory.

**Look.** Render it and look at it: `pdftoppm -png -r 80 <name>.pdf /tmp/<name>`, then read the images page by page against `references/house-style/house-style-template.html` (its diagram still shows the old filled-ink boxes; diagrams follow `style-spec.md` block 2 instead), and work the ten-point list at the end of `references/page-composition.md`. A document that passes the gate and lays out every page the same way has not passed this. Say in the hand-off which pages you compared.

**Content.** Every banned-optional topic absent or `\opt`-tagged; every math-heavy section re-derived by the verification agent; the reviewers the recipe calls for have all run and every critical and major finding is resolved; weak areas visibly deeper.

**Hand-off.** No `_tmp_*` files, no helper scripts left behind, filenames canonical rather than temp jobnames, copyright line on every page in the kit's foot treatment (`\fancyfoot[L]{\hslabel{\textcopyright{} YYYY <Name>. All rights reserved.}}`), and the user told the page counts, the emphases and the follow-ups.

## Files

- `references/recipes.md` -- the document types, their length bands, structures and build sizes.
- `references/house-style/` -- the look: `style-spec.md` (the spec), `housestyle.sty` (its LaTeX), `CONFORMANCE.md` (the ten checks), `example.tex`, and the rendered HTML target. Vendored from the owner's package at rev 03; edit only to carry a decision of his, and say so in the file.
- `references/latex-house-style.md` -- the spec mapped onto macros, the build, teaching affordances, math kit, traps, style gate.
- `references/page-composition.md` -- how to put the blocks on a page: the reference document's eight shapes, the rhythm rule, what each block's arguments must carry, the three diagram patterns with tikz, and the render-and-look checklist.
- `references/teaching-communication.md` -- the canonical voice, vendored from lesson-builder. Do not edit here.
- `references/voice.md` -- representation to LaTeX construct, and the three page-level rules.
- `references/review-pipeline.md` -- the five reviewers, which run at which build size, the filter protocol, the false-positive catalogue.
- `references/per-course-notes.md` -- case studies from ECE 204, ECE 205 and ECE 250: taxonomies, weak areas, banned-optional lists, scope quirks. A pattern library for a new course.
- `assets/preamble-template.tex` -- the canonical preamble. Copy and adapt per document.
- `assets/driver-template.tex` -- the multi-file `course-notes` driver.
- `assets/fonts/` -- Source Serif 4 and IBM Plex Mono, vendored with their OFL licences.
- `scripts/build.sh` -- the build: three lualatex passes, temp jobname, fails on any `!` error.
- `scripts/style-check.sh` -- the style gate.
- `scripts/voice-drift.sh` -- reports drift of the vendored voice spec from lesson-builder; `--refresh` updates it.
- `tests/check.sh` -- this repo's gate.
- `docs/integration.md` -- what the lesson-builder and lessons repos must change for companions.
