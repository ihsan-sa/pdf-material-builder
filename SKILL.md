---
name: course-pdf-builder
description: Build a five-document LaTeX study pack for a university course: landscape reference, annotated formula sheet, visual intuition, worked examples, and 40-70pp course notes. Use this skill whenever the user asks to create, build, make, or generate a study pack, reference document, formula sheet, course notes, worked examples, or "document set" for any course (ECE, CS, MATH, PHYS, etc.), OR says something like "do for ECE X what we did for ECE Y", OR points at a folder with lecture PDFs and wants a pedagogical PDF pack out of it. Also trigger when the user says "build the PDFs for <course>" or "set up reference docs for <course>" or updates an existing pack.
---

# course-pdf-builder

Build and iterate on a five-document study pack for a university course. One coordinated set of deliverables, each with a distinct role, unified palette and macros, and deep content on the student's weak areas.

## The deliverable set

Every pack ships exactly these five documents, each with a fixed role:

| Doc | Length | Role |
|---|---|---|
| `<course>_reference.pdf` | 7-8pp landscape | Concise method-per-row reference. Organised by the course's taxonomy. Tools / brackets / order / when-to-reach-for-it columns. |
| `<course>_formula_sheet_annotated.pdf` | 7-8pp | Mirrors the official exam formula sheet, verbatim, with italic grey one-line annotations under each entry (when / how / trap). If the course provides no official formula sheet, this doc becomes a consolidated "complexity/invariant sheet" of the load-bearing essentials. |
| `<course>_visual_intuition.pdf` | ~10-13pp | 15-ish mechanism graphs via matplotlib and TikZ. One pink `pictureit` caption per figure. |
| `<course>_worked_examples.pdf` | 25-30pp | Past-exam problems step-by-step. One problem per page, clickable TOC, category banner, `\probhead{source}{method}{cat-tag}` macro. |
| `<course>_course_notes.pdf` | 40-70pp | Pedagogical narrative. The only doc that *teaches*; the others drill / reference. Heavy use of `pictureit`, `step`, `fsheet`, `connect`, `optional` boxes. |

Build order that works: **reference → formula sheet → visual intuition → worked examples → course notes**. Each prior doc is referenced from later ones. Exception: when the course provides an official formula sheet verbatim, build the formula sheet first (most deterministic).

## How the user learns (verbatim; every decision flows from this)

1. **Connections.** Cross-reference every method to others that share structure ("Simpson weights mirror RK4 weights"; "Floyd build-heap is the same amortised argument as array doubling"; "ghost points reappear in heat and Laplace"). Use a blue-stripe `connect` box. Don't bury connections in prose.
2. **Fundamentals up.** Derive. Never say "it can be shown". Always show the Taylor expansion / substitution / algebra. Grey `step` boxes are for these derivations.
3. **Visual / picture this.** Pink-stripe `pictureit` boxes are for mental-image narratives: tangent lines, shrinking brackets, stair-steps, pond ripples, BFS layers, hash-probe lanes. One per major idea is the floor, not the ceiling.
4. **Not plug-and-chug.** Emphasise *when* and *why* a method applies, not its mechanics. Decision tables and a method taxonomy are worth more than ten drilled examples.
5. **Concise.** Reference docs are mid single-digit pages. Course notes are 40-70pp even when the topic is deep. Don't pad. No filler ("it is important to note", "clearly", "obviously").
6. **Professional / equation-first.** Write like a well-calibrated textbook author.
7. **Weak areas get depth.** Ask the user; invest the page budget there.

## Seven-phase pipeline

### Phase 1 — Intake and extraction

**Step 1.1 — Ask four questions (minimum).** Use `AskUserQuestion` for these four; do not assume answers even in auto mode:

- **Taxonomy**: which category labels (A/B/C/...) organise the course? Propose a default from the lecture list.
- **Weak areas**: which 1-3 topics deserve extra depth in the course notes? (Multi-select.)
- **Past exams**: does a practice midterm / final / review guide exist? If yes, the user will point at the folder.
- **Banned-optional list**: anything the prof explicitly flags as out of scope? (Often surfaces from the review guide, but ask anyway.)

**Step 1.2 — Parallel lecture extraction.** Spawn ~8 `general-purpose` agents in one message (per the user's preference for aggressive parallelism). Split the lecture PDFs into batches of 2-5 per agent. Per DOCUMENT_BUILD_GUIDE lessons, a single agent reading 5 dense PDFs can hit the 32MB context limit; **if PDFs are image-heavy or dense, use 2-3 per agent, not 5**.

Each extraction agent writes one markdown file per lecture to `<course_dir>/_extraction/<LN>_<slug>.md` with the following sections:

- Title, Core definitions (verbatim), Theorems / results, Algorithms / procedures
- Complexity / error / accuracy claims
- Invariants and properties, Notational conventions (flag anything prof-specific)
- Emphasis cues (what the prof repeats, colours, slogans)
- Worked examples shown in lecture (copy numbers verbatim)
- Cross-lecture links

Each batch also writes `_notation_L<range>.md` listing any conventions worth propagating.

**Step 1.3 — Exam and problem-set extraction.** In parallel with the lecture batches, spawn agents for:

- Official formula sheet / reference tables (if provided)
- Practice midterms and finals (verbatim statements + key numerical answers)
- Problem-set solutions (one file per pset, flagging which problems are high-value for the worked-examples doc)

**Step 1.4 — Consolidate conventions.** Read all the `_notation_*.md` files and write `<course_dir>/_extraction/_<PROF>_CONVENTIONS.md` as the single source of truth for every downstream builder agent. Include: function-letter conventions, equation normalisation choices, signed-letter conflicts (e.g., wave speed $a$ vs Fourier coefficient $a_n$), taxonomy colour map, 7-tools analogue, weak-area flags, banned-optional list, exam format.

**Every downstream builder agent prompt includes this conventions doc as its first critical-reading item.** Without this, every builder re-derives conventions and drifts.

### Phase 2 — Reference doc (taxonomy anchor)

Build the landscape reference first because it forces the taxonomy to be nailed down. Every later doc references its categories.

Spawn one `general-purpose` agent with:
- Load-bearing context: `DOCUMENT_BUILD_GUIDE.md`, the conventions doc, a sibling course's reference (ECE 204 or ECE 205 as voice template), the extraction markdowns.
- Outputs: `<course>_reference_body.tex` (shared body with `\if*` toggles), `<course>_reference.tex` (driver, all flags false), plus optional `<course>_reference_examples.tex` and `<course>_reference_formulas.tex` variants that flip flags.

Layout: Page 1 framework (tools table, decision tree). Pages 2-N: one page per category with a method-per-row table (method / form / when / key equation / watch-out). Reuse the palette and `\catbanner`, `\tool`, `\cat`, `\probhead` macros.

### Phase 3-5 — Worked examples, formula sheet, visual intuition (parallel)

Once the reference exists (taxonomy + colours settled), spawn three builders in the same message:

- **Worked examples** — 15-ish problems, one per page, with clickable TOC. Cherry-pick from the practice exams and pset solutions; require the builder to re-derive every numerical answer from scratch (extractors hallucinate; see the filter phase below).
- **Formula sheet annotated** — if official sheet exists, mirror verbatim and annotate; if not, build a consolidated complexity/invariant cheat sheet with italic one-line annotations.
- **Visual intuition** — 15 figures (mix of matplotlib PNGs in a `viz_src/` subdir with a `generate_all.py`, plus inline TikZ for trees and small diagrams). Each figure gets a `pictureit` caption.

### Phase 6 — Course notes

The longest document. 40-70pp pedagogical narrative. Build using parallel section writers (one per category plus preface and appendix).

**Step 6.1 — Write the driver first.** The orchestrator (you, not a subagent) writes `<course>_course_notes.tex` with the full preamble, palette, all macros, the title page, `\tableofcontents`, and `\input{course_notes/NN_name}` stubs. This forces the Part ordering and label conventions to be settled before the writers run.

**Step 6.2 — Spawn 8-10 parallel section writers in one message.** Each writer produces one `course_notes/NN_name.tex` file. Standard split:

- `00_preface.tex` — orienting + visual grammar + scope reminders
- `01_<cat-A>.tex`, `02_<cat-B>.tex`, ...  — one per taxonomy category
- `99_appendix.tex` — cross-topic connections, decision tree, glossary, exam scope recap

Weak-area sections get a longer target page count (8-11pp) and explicit instructions to go deep with `step` and `pictureit` boxes. Non-weak-area sections get 4-6pp.

**Step 6.3 — Critical brief elements for every writer** (keep repeating these across agent prompts; do not economise):

- The conventions doc path (mandatory critical reading)
- The driver file path (shows preamble macros available: `step`, `insight`, `pictureit`, `fsheet`, `connect`, `optional`, `\opt`, `\tool`, `\tools`, `\cat`, `\catbanner`, `\probhead`, `\Oh`, lstlisting cpp style)
- A voice-reference file path (a sibling course's similar-category section)
- A list of relevant extraction files
- Target page count and whether this is a weak-area section
- Hard rules: no emojis, no em-dashes, no `\lt`/`\gt` (LaTeX is not KaTeX), use `\Oh{...}` not bare `$O()$`
- Cross-references to expect ("will foreshadow Part 5", "references Part 1's recurrence-tree method via `\ref{sec:...}`")
- Banned-optional items that should be `\opt`-tagged or skipped

**Step 6.4 — Part numbering trap.** Parallel writers each independently claim `\part{}` labels. If two writers both write `\part{Analysis}` and `\part{Foundations}`, they get Parts 1 and 1. Solve by: (a) only having certain section files open new Parts (e.g., `01_`, `02_`, `04_`, `07_`, but not `03_`, `05_`, `06_` which continue their Part); or (b) having the driver pre-declare Parts and sections use only `\section` and `\subsection`. Pick one and be explicit in the briefs. When in doubt, the content reviewer will catch drift.

### Phase 7 — Review pipeline

Read `references/review-pipeline.md` before launching. This is the step that turns a "first draft that compiles" into a "production deliverable".

Five parallel reviewers, scaled to scope:

1. **Full-context content reviewer** (`content-review-agent`) — knows the doc's purpose, user's learning preferences, conventions. Verifies equations, Huang-convention fidelity, scope alignment, pedagogy boxes.
2. **Student-peer brutal review** (`general-purpose`, framed as a past-student who struggled) — identifies coverage gaps, notation collisions, exam-rubric misalignment. Expects a Scorecard and a grade-delta estimate.
3. **Cross-doc consistency reviewer** (`general-purpose`) — greps across all five docs' `.tex` for inconsistent notation, complexity claims, worked traces.
4. **Math verification agent** (`general-purpose` with Python / SymPy) — independently re-derives every numerical claim (recurrences, traces, counter-examples, closed-form formulas).
5. **Cold-edit reviewer** (`general-purpose`, minimal context) — catches typos, LaTeX glitches, column-count mismatches, missing references, unmatched braces.

**Filter phase is mandatory.** Reviewers hallucinate. After collecting all findings, reject 20-40% as false positives. For math claims, re-derive from scratch — don't trust the reviewer's algebra. For quote claims, grep the file and confirm the quoted text exists verbatim. For subjective claims, require two independent reviewers to agree.

Apply only verified fixes. Recompile. Done.

## Critical lessons from prior builds

### LaTeX / tooling gotchas

These are real traps hit during ECE 204 / 205 / 250 builds. Read `references/conventions.md` for the full list; the most load-bearing ones:

- **`\lt` and `\gt` leak from KaTeX into LaTeX** and fail with "Undefined control sequence". Grep after every agent write. Use Python to replace (not `sed`; regex edge cases corrupt `\Delta`).
- **`picture` tcolorbox name collides with LaTeX's built-in `picture` environment** and silently breaks `\@iiiparbox`. Name custom boxes `pictureit`.
- **`\trans` macro must be `{\!\top}` not `^{\!\top}`** so `X^\trans` expands to `X^{\!\top}` (no double `^`).
- **MiKTeX auto-install modal hang** — fix once: `initexmf --set-config-value="[MPM]AutoInstall=1"`.
- **PDF file-lock during compile** — compile to `-jobname=_tmp_<round>`, then swap via `cp`.
- **Three compile passes for multi-page TOC.** Two passes is not enough: pass 1 writes empty TOC, pass 2 writes populated TOC that shifts every page number, pass 3 re-resolves cross-refs against the shifted layout. If the TOC is single-page this converges in 2, but course notes with a 3-page TOC need 3 passes. Always run 3 to be safe.
- **Em-dashes** (`—`, U+2014) break some setups and the user forbids them. Use `--` or commas or semicolons.
- **Zero emojis.** High-unicode grep after every build.

### Convention discipline

The single-source-of-truth conventions doc is load-bearing. Without it, every builder re-derives conventions and the doc set drifts. Every builder prompt cites it as critical reading item #1. Flag anywhere a doc says "this is the prof's choice vs the classical textbook result" (e.g., AVL height bound, RB rules 1-4 vs CLRS 5, Huang's `map<int, map<int, int>>` adjacency type).

### The filter phase rejects 20-40% of review findings

Reviewers regularly flag:
- Sign errors from their own re-derivation (they inverted, not the doc)
- "Quote claims" that never appeared in the doc
- Subjective style preferences dressed as defects
- Section convention misreads (e.g., `n` = nodes vs `n` = polynomial degree)

Apply only fixes that survive independent verification.

### Rhetorical traps

- **"iff" for sufficient conditions** ("gradient descent converges iff `s < 2/L`" is `if`, not `iff`).
- **Θ-in-disguise.** "Tightest upper bound" is strictly a Θ characterisation. Warn the student that outside this course, `n = O(n²)` is correct (if loose).
- **"Formally equivalent"** for methods that mirror but don't literally equal (Simpson and RK4; Prim and Dijkstra). Prefer "mirrors" or "corresponds to".
- **"Dijkstra generalises BFS" via "extract-min reduces to FIFO"** — mechanism is still priority-based; the *order* happens to match on unit weights.

### Agent orchestration notes (user preference)

- **~8 agents per message** rather than serialising. Bulk similar tasks (parallel section writers, parallel extractors, parallel reviewers) should fire in one call.
- **Brief agents like smart colleagues** — they haven't seen the conversation. Self-contained prompts with file paths, target lengths, hard rules, banned items, cross-reference expectations.
- **Don't trust agent summaries** — agents describe what they *intended* to do. Check actual file contents before marking a phase done.

### Landing-page integration (if a deploy pipeline exists)

After the build, wire into the site:
1. `build-all.sh` — add a `mkdir -p "$OUT/<code>"` block and `cp` each PDF.
2. Landing-page HTML (inside the same script) — add a `<div class="pdf-banner">` under the course card with links to the PDFs.
3. `.gitignore` — add un-ignore rules for the tracked `.tex` and `.pdf` files and the `course_notes/` `worked_examples/` `viz_src/` subdirs.
4. Push. Verify the deploy picks up the commit.

### Copyright footer

All shipped PDFs get `\fancyfoot[L]{\footnotesize\color{muted}\textcopyright{} YYYY <Name>. All rights reserved.}`.

## Directory layout

```
<course_dir>/
  <course>_course_notes.tex              # driver (preamble + \input stubs)
  <course>_course_notes.pdf              # compiled
  course_notes/
    00_preface.tex
    01_<cat-A>.tex
    ...
    99_appendix.tex
  <course>_reference.tex                 # 1-line driver
  <course>_reference_body.tex            # shared body with if-toggles
  <course>_reference_examples.tex        # optional +examples variant
  <course>_reference_formulas.tex        # optional +formulas variant
  <course>_reference.pdf
  <course>_formula_sheet_annotated.tex
  <course>_formula_sheet_annotated.pdf
  <course>_visual_intuition.tex
  <course>_visual_intuition.pdf
  <course>_worked_examples.tex           # driver with TOC
  <course>_worked_examples.pdf
  worked_examples/
    problem_01_<slug>.tex
    ...
    problem_15_<slug>.tex
  viz_src/
    generate_all.py
    _style.py
    fig_<name>.py
    viz_<name>.png
  _extraction/                           # local-only
    L1_<topic>.md ... LN_<topic>.md
    _notation_L<range>.md
    _pset_NN_<slug>.md
    _practice_midterm.md
    _practice_final.md
    _exam_format.md
    _review_guide_summary.md
    _<PROF>_CONVENTIONS.md               # single source of truth
```

## Reference files

- **`references/conventions.md`** — the full palette, tcolorbox definitions, vector macros, `\trans` design, spacing recipe, common LaTeX traps, style-check script template.
- **`references/review-pipeline.md`** — five-reviewer details, agent-specific prompts, filter-phase protocol, common false-positives catalogue.
- **`references/per-course-notes.md`** — case studies from ECE 204 (Harder), ECE 205 (Kotecha), ECE 250 (Huang): taxonomy choices, weak areas, banned-optional lists, scope quirks. Use as a pattern library when building a new course.

## Assets

- **`assets/preamble-template.tex`** — canonical preamble (colours, spacing, titles, boxes, macros). Copy and adapt per course.
- **`assets/driver-template.tex`** — multi-file course-notes driver with `\input{course_notes/NN_name}` stubs.

## Quality bar before declaring done

Compile:
- `pdflatex` exits 0 on three passes.
- No `! Undefined control sequence`, no `! LaTeX Error`, no broken `\ref`.
- TOC populated (verify by extracting page 2-3 text).
- Page count within target.

Style:
- Zero em-dashes (`—`, U+2014).
- Zero `\lt` / `\gt`.
- Zero emojis / high-unicode.
- Every formula-sheet equation in a green `fsheet` box.
- Every major method has a pink `pictureit` box.

Content:
- Every banned-optional topic either absent or `\opt`-tagged.
- Every math-heavy section re-derived by the math-verification agent.
- Three+ review passes, all critical and major findings resolved.
- User's weak areas have visible extra depth.

Hand-off:
- No `_tmp_*` files in the directory.
- No helper scripts (`_fix_lt_gt.py`, `_sc.py`) left behind.
- PDF filenames match canonical names, not temp jobnames.
- Copyright footer present on every PDF.
- User informed of page counts, key emphases, and follow-ups.
