# Recipes

One recipe per kind of document this skill builds. A recipe fixes the role, the length band, the structure and the build size; everything else comes from `references/latex-house-style.md` (the look) and `references/voice.md` plus `references/teaching-communication.md` (the writing).

Pick the recipe before anything else. It decides how much pipeline runs: see "Build size" below and the scaled pipeline in `SKILL.md`.

| Recipe | Length | Role | Build size |
|---|---|---|---|
| `reference` | 7-8pp landscape | Method-per-row landscape reference, organised by the document's taxonomy. | large |
| `formula-sheet` | 7-8pp | The official exam sheet mirrored verbatim with a one-line annotation under each entry. No official sheet: a consolidated complexity / invariant sheet. | large |
| `visual-intuition` | 10-13pp | About fifteen mechanism figures, each with one caption saying what to picture. | large |
| `worked-examples` | 25-30pp | Past-exam problems worked one per page, with a clickable contents. | large |
| `course-notes` | 40-70pp | The narrative that teaches. The others drill or look up. | large |
| `companion` | 2-6pp | The printable of one lesson-builder lesson. | small |
| `cheat-sheet` | 1-2pp | One page a reader keeps beside the work: the decisions and the shapes, no derivations. | small |
| `technical-doc` | 5-40pp | A design note, report or write-up. Not teaching material. | small or large |

**Build size** is the only thing that changes the pipeline. `large` runs intake, extraction, the builder fan-out and the five-reviewer pass. `small` skips the extractors, because its source is already structured, and runs two reviewers instead of five. `SKILL.md` has the exact split.

**"Build the PDFs for `<course>`" means the first five**, in that order, as one coordinated set: the default manifest, not a fixed set. Drop one the course does not need, add a `cheat-sheet` if the reader wants one, and say which manifest you are building before you start.

## reference

Page 1 is the framework: the tools table and a decision tree that routes a problem to a method. Pages 2 to N are one page per category, each a `tabularx` of method / form / when to reach for it / key equation / watch-out, under a `\catbanner` in that category's colour. Landscape, 0.55in margins.

Build this first in a `large` build even though it is not the biggest: it forces the taxonomy and the colour map to be settled, and every later document cites its categories.

## formula-sheet

Mirror the official sheet verbatim, entry for entry, in its order, with an italic grey one-line annotation under each: when it applies, how to use it, the trap. Never silently correct the official sheet; where it is wrong or unconventional, annotate the difference.

With no official sheet, the recipe becomes a consolidated sheet of the load-bearing essentials (complexities, invariants, closed forms) in `fsheet` boxes, same annotation discipline.

When the course provides an official sheet, build this first instead of the reference: it is the most deterministic document in the set and it pins notation for everything after it.

## visual-intuition

About fifteen figures. matplotlib for quantitative dependence, into `viz_src/` with a `generate_all.py` that regenerates every PNG; inline TikZ for trees, structures and small staged diagrams. One `pictureit` caption per figure saying what the reader should picture, in domain.

A figure that only restates a sentence is deleted, not shrunk. Fifteen is a target, not a quota.

## worked-examples

One problem per page. `\probhead{source}{method}{cat-tag}` at the top, the statement verbatim, then the derivation in `step` boxes. Clickable contents, category banner per section.

Two rules that have cost real rework: cherry-pick from the practice exams and problem-set solutions rather than inventing problems, and re-derive every numerical answer from scratch. Extractors hallucinate numbers; the reviewer catches only some of them.

Fading is by ordering, per `references/voice.md`: full instances first, then partial ones, then statements whose answers sit in the appendix.

## course-notes

The only document that teaches. It carries the teaching arc: for each topic, a central question, an entry state, ordered moves, a declared example sequence, an exit model, and exit evidence. Plan it before writing it, per `references/teaching-communication.md`.

Structure: a preface (orientation, visual grammar, scope), one Part per taxonomy category, an appendix (cross-topic connections, decision tree, glossary, scope recap). Weak-area sections get 8-11pp, the rest 4-6pp.

This is the only recipe that needs the multi-file driver in `assets/driver-template.tex`, and the only one where the Part-numbering trap in `SKILL.md` applies.

## companion

**The printable of one lesson-builder lesson: 2-6pp, built from that lesson's plan and prose, not re-derived.**

The lesson is the source of truth. Its plan already carries the objectives with their checks, the teaching arc, the equations, the key concepts and the practice problems with their sources; its prose is already written against that plan and already reviewed. Re-deriving any of it from the course materials produces a handout that disagrees with the screen the reader just left, which is worse than no handout.

Inputs, in this order:

1. `<lesson_root>/lesson_build.log.md` and the run record beside it (`lesson-run/1`): the plan artifact, whose format is `lesson-builder/references/phase-2-plan.md`. Objectives, `teaching_arc`, equations, key concepts, `practice_problems` with sources.
2. The lesson's `.jsx` prose. Condense it; do not rewrite it. The voice is already correct.
3. The course's other lessons, for the neighbour links.

Structure, in order:

- A header carrying the course code, the lesson title, and the lesson's URL.
- **Objectives**, verbatim from the plan. Not paraphrased: the reader is told the same thing the lesson told them.
- **The equations**, in `fsheet` boxes, each with the one sentence saying what the relation implies.
- **One worked example**, the highest-value practice problem from the plan, with its source attribution, worked in `step` boxes. One, not the set: this is a handout, not the worked-examples recipe.
- **The exit check**, from the arc's `exit_evidence`. It requires the compressed model and introduces nothing new.
- **Neighbours**: one line each for the lesson before and after in the course, with their titles and URLs, so a printed page is not a dead end.

`pictureit` at most twice; `connect` for the neighbour relation when it is structural rather than sequential. No teaching arc of its own, no new derivations, no new examples.

**Where it lands.** `<workspace_root>/<COURSE>/claude_lessons/<slug>/<course>_<slug>_companion.tex` and the compiled `.pdf` beside it, inside the lesson directory, so the handout travels with the lesson it belongs to.

**What the lessons repo must change to publish it.** Both of these are that repo's work, not this skill's; `docs/integration.md` carries them for a follow-up track there.

- `.gitignore`: the workspace ignores `*.pdf` and `*.tex` globally and un-ignores course-level documents one filename at a time. Lesson-level companions need a pattern that reaches into `claude_lessons/<slug>/`, and it has to sit before the trailing secret-exclusion block, which must stay last.
- `build-all.sh`: it publishes `<COURSE>/*.pdf` at the course level only, so a companion inside a lesson directory is invisible to it. It needs the same guarded copy (symlink resolution, hard-link refusal, member-tree sandboxing) for `<COURSE>/claude_lessons/<slug>/*.pdf`, landing at `dist/<prefix>/<slug>/`.

## cheat-sheet

One page, two at the outside. Decisions and shapes: the decision tree, the method-to-situation table, the handful of equations whose *form* must be recognised on sight. No derivations, no worked examples, no prose paragraphs.

The test is whether it works face-up beside the work. If the reader has to read it rather than glance at it, it is a `reference`, not a cheat sheet.

## technical-doc

**Not teaching material.** A design note, an incident write-up, a report, an evaluation. The reader is a colleague deciding something, not a student learning something.

What applies: the whole of `references/latex-house-style.md`, and from `references/teaching-communication.md` the optimization target, the representation rules, the exposition rules and the analogy policy. Those are about explaining clearly to a competent reader, which is exactly this job.

What does not apply, and must not be bolted on: the teaching arc, retrieval prompts, transfer items, exit checks, misconception repair, objectives, weak-area page budgets. A report with an exit check in it is a report nobody finished.

Boxes, remapped: `insight` for a conclusion or a decision, once each; `step` for a derivation or a measurement procedure; `connect` for a cross-reference to another system or document; `optional` for depth a first reader can skip; `fsheet` for a specification or invariant that other work must hold to. `pictureit` is usually wrong here, because a colleague reading a design note wants the structure diagram, not a mental image of it.

Structure follows the document, not a template: a design note leads with the decision and its constraints; an incident write-up with what happened and what changed. Length band is wide because the recipe is: 5pp for a design note, 40pp for a full evaluation with results.
