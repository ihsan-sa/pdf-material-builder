# Integration: what the other repos must change

This skill builds companion handouts for lesson-builder lessons, but a handout is only useful once the lessons workspace tracks it and publishes it. **Nothing in this document is this repo's work.** It is the list a follow-up track in `~/dev/lesson-builder` and `~/dev/lessons` picks up; neither repo is edited from here.

Three groups, in the order they unblock each other.

## 1. lessons workspace: track and publish a companion

Today `~/dev/lessons` publishes course-level PDFs only. A companion lands *inside* a lesson directory, so it is invisible to both git and the publisher until these two change.

**`lessons/.gitignore`.** The workspace ignores `*.pdf` and `*.tex` globally and un-ignores course-level documents one filename at a time (`!ECE205/ece205_reference.pdf` and so on). A companion sits at `<COURSE>/claude_lessons/<slug>/`, which no current negation reaches. Add a pattern that does, for example:

```
!*/claude_lessons/*/*_companion.tex
!*/claude_lessons/*/*_companion.pdf
```

Two constraints that have already caught people in that file: git never looks inside an excluded directory, so every directory on the path has to be re-included before a `/**` rule can reach the contents; and the trailing block that re-ignores secrets dropped into a materials inbox **must stay last**, because a later rule wins. The new negations go above it.

Lesson-level `materials/`, `source/` and `notes/` stay private. A companion is a deliverable, not an input, and is named so a glob can tell them apart.

**`lessons/build-all.sh`.** It walks `<tree>/<COURSE>/*.pdf` and copies each into `dist/<prefix>/`. It needs the same walk one level deeper, over `<tree>/<COURSE>/claude_lessons/<slug>/*.pdf`, landing at `dist/<prefix>/<slug>/` beside the lesson's own build.

Reuse the existing copy path rather than writing a second one. Every guard it already carries applies unchanged to companions, and each exists because a security review demonstrated the hole: `resolves_inside` before the copy, because `cp` dereferences and a symlink named `notes.pdf` would otherwise publish its target's bytes; the hard-link refusal, because no path check can see a second name for the same bytes; and, for a member's tree, the `cc-sandbox member <handle>` boundary, because reading and building inside somebody else's tree runs their code.

The landing page (`lessons/bin/gen-index.mjs`) then needs the companion to appear under its lesson rather than in the course's PDF row. `lessons/bin/test-gen-index.sh` has the fixture pattern for that.

## 2. lessons workspace: vendor this skill

`.claude/skills/lesson-builder/` is a git subtree of the public lesson-builder repo, kept current by `lessons/bin/sync-skill` and the `follow-skill` timer. Vendor this skill the same way, at `.claude/skills/pdf-material-builder/`, so a session in any worktree of that workspace can build a companion without the skill being installed on the machine.

Do not edit the vendored copy in place, for the same reason as lesson-builder's: change this repo, then pull the subtree. If `follow-skill` grows a second source, it should run this repo's `tests/check.sh` on the result exactly as it runs lesson-builder's.

The alternative, for a machine rather than a workspace, is a clone into `~/.claude/skills/pdf-material-builder/`. The README says both.

## 3. lesson-builder: the plan hook

A companion is built from a lesson's plan and prose, not re-derived. Two changes make that a first-class output rather than something a session remembers to ask for.

**Phase 2 plan artifact.** Add one line to the Lesson Plan, beside `Deploy:`:

```
Companion PDF: yes (2-6pp) | no
```

It goes through the same human approval gate as the rest of the plan, so the answer is on the record before Phase 3 writes a word. The fields a companion consumes already exist in the artifact: `objectives` with their `checks`, `teaching_arc` (for `exit_evidence` and `exit_model`), `equations`, `key concepts`, and `practice_problems` with their sources. No new fields are needed, which is the point of hooking it here.

**Phase 5 deploy.** When the plan said yes, invoke this skill's `companion` recipe after the lesson builds and before the deploy step, so the PDF is in the tree when `build-all.sh` runs.

**A pointer in lesson-builder's SKILL.md.** One line saying that printable material is this skill's job, so a session asked for "a handout for this lesson" reaches for the right tool instead of hand-rolling LaTeX.

## 4. The voice contract, in both directions

`references/teaching-communication.md` in lesson-builder is canonical. This repo carries an ASCII transliteration of it and `scripts/voice-drift.sh` reports any divergence; `tests/check.sh` fails on drift, and skips with a printed reason when lesson-builder is not on disk.

What that asks of lesson-builder: nothing, until the spec changes. When it does, the change lands there first, and this repo catches up with `scripts/voice-drift.sh --refresh` plus a read of `references/voice.md` for any PDF-side rule the new text contradicts. A cheap way to notice is to run this repo's gate on a timer, the way `follow-skill` already runs lesson-builder's.

The reverse direction is not automated and should not be: `references/voice.md` holds three rules the spec has no row for (weak areas get the page budget, derive rather than "it can be shown", cross-reference methods that share structure). If they ever earn a place in the canonical spec, that is a decision for lesson-builder, made there.
