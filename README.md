# pdf-material-builder

A Claude Code skill that builds teaching material and technical documentation as LaTeX PDFs, at any length, in one house style and one voice. A 1pp cheat sheet, a 2-6pp companion to a single lesson, a 40-70pp set of course notes, a design note: same page, same two faces, same twelve blocks, same author. The look is `references/house-style/style-spec.md`.

`SKILL.md` is the entry point. Everything below it is a level of detail you can stop at.

## Install

Machine-wide, for every session on this box:

```bash
git clone https://github.com/ihsan-sa/pdf-material-builder ~/.claude/skills/pdf-material-builder
```

Or vendored into one workspace, so the skill travels with the repo and every worktree of it:

```bash
git subtree add --prefix .claude/skills/pdf-material-builder \
  https://github.com/ihsan-sa/pdf-material-builder main --squash
```

Update a vendored copy with `git subtree pull` on the same prefix. Do not edit it in place: change this repo and pull.

**What must be installed: lualatex, and texlive-luatex (luaotfload) alongside it.** The fonts (Source Serif 4, IBM Plex Mono) are vendored in `assets/fonts/`. Build any document with the skill's own script, from any repo:

```bash
scripts/build.sh path/to/doc.tex
```

## Recipes

`references/recipes.md` has the structure and the build procedure for each.

| Recipe | Length | Role | Build size |
|---|---|---|---|
| `reference` | 7-8pp | Method-per-row reference, organised by taxonomy. | large |
| `formula-sheet` | 7-8pp | The official exam sheet mirrored verbatim, one annotation per entry. | large |
| `visual-intuition` | 10-13pp | About fifteen mechanism figures, each with a caption saying what to picture. | large |
| `worked-examples` | 25-30pp | Past-exam problems worked one per page. | large |
| `course-notes` | 40-70pp | The narrative that teaches. | large |
| `companion` | 2-6pp | The printable of one lesson-builder lesson. | small |
| `cheat-sheet` | 1-2pp | One page kept beside the work: decisions and shapes, no derivations. | small |
| `technical-doc` | 5-40pp | A design note, report or write-up. Not teaching material. | small or large |

"Build the PDFs for `<course>`" means the first five as one coordinated set: a default manifest, not a fixed set.

Build size is the only thing that changes the pipeline. A `large` build runs intake, an extractor fan-out and five reviewers; a `small` build skips the extractors, because its source is already structured, and runs two reviewers.

## Voice

The [lesson-builder](https://github.com/ihsan-sa/lesson-builder) skill owns the discourse spec, `references/teaching-communication.md`, and this repo carries a copy so a lesson and its companion handout read as one author. `scripts/voice-drift.sh` reports any divergence from that canonical file and `--refresh` updates the copy; `tests/check.sh` fails on drift.

`references/voice.md` is this skill's own layer and holds only what LaTeX adds: which construct carries each of the spec's representations, and three page-level rules the spec has no row for.

## Gate

```bash
tests/check.sh
```

Hermetic, no network, under a minute. Frontmatter, every path the docs mention, the style gate and its selfcheck, voice drift, and a real lualatex build of both templates. Drift and compile cases skip with a printed reason when lesson-builder or lualatex is absent.

`docs/integration.md` lists what the lesson-builder and lessons repos must change before companions can be published.
