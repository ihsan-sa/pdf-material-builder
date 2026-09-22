# Voice on the page

`references/teaching-communication.md` is the voice. It is a vendored copy of lesson-builder's canonical spec and it governs how anything in this skill explains: the optimization target, representation matching, the exposition rules, the analogy policy, the teaching arc. A lesson and its companion handout should read as one author, so there is one spec, not two.

This file holds only what that spec cannot say, because it does not know about LaTeX: which construct on a printed page carries each representation, the three rules the owner keeps that the spec has no row for, and the places where this skill's older wording lost to the spec.

Read the spec first. Read this second. If the two disagree, the spec wins and this file is wrong and should be fixed.

## Representation to LaTeX

The spec says to choose the representation that matches the semantic relationship, and never to format for visual variety. Here is what each of its rows becomes in a document built by this skill. The right column is the only permitted carrier; reaching for a frame or a label because the page looks plain is exactly the failure the spec's redundancy rule names.

| Spec relationship | Representation | On the page |
|---|---|---|
| A causes B because C; an argument | Prose | Body text. No box, no bullets. Prose is the medium for causal reasoning; framing it adds nothing and costs the reader a stop. |
| Formal relationship | Equation + a sentence saying what it implies | A display equation (block 12), numbered, with every symbol named in the sentence after it and that sentence saying what it implies. `\onsheet` before it only when it is also a formula-sheet fact worth committing. |
| Several independent properties sharing a stem | Bullets | `itemize`. The spec's bullet lint applies unchanged: if the items need "because", "therefore" or "whereas", write prose. |
| Ordered procedure | Numbered list | `enumerate`. A multi-line derivation is not a procedure: that is a `derivation` run of display equations. |
| Comparison across repeated dimensions | Table | A comparison or data table (blocks 4 and 5): `tabularx` with `\hstoprule`, `\hshead` and the `Y`, `L` and `R` columns. One row per method, one column per dimension. This is the reference document's whole grammar. |
| Spatial / geometric structure | Diagram | Inline TikZ in an `hsfigure`, using the three node kinds. Keep it in the `.tex`; a structure diagram that lives in a PNG cannot be edited in review. |
| Continuous quantitative dependence | Graph | matplotlib into `viz_src/`, set as a figure plate (`\hsplate`). Regenerable from `generate_all.py`, never a pasted image. |
| A process with stages; a before/after; a varying parameter | Figure: staged diagram or before/after pair | A multi-panel TikZ figure or a pair of half-measure plates sharing a baseline. One figure, one caption. Print has no slider, so the parameter sweep becomes three panels with the parameter labelled on each. |
| Problem-solving method | Worked example, then faded | `\probhead{source}{method}{cat}` and the derivation under it. Print cannot collapse a solution, so fading is done by ordering: a full worked instance, then a partial one whose last steps are left to the reader, then a statement whose answer sits in the appendix. |
| Critical conclusion or decision rule | Stated once | The section's lead line, `\insight{...}`, once. It stores the conclusion; it never replaces the explanation that earned it, and it never repeats a sentence already on the page. |
| Definition | Short prose | An italic lead-in in body text (no bold in body). A `derivation` only when the definition needs unpacking to be usable. |

Three affordances have no row in the spec because they are print-only, and none of them is a box:

- **A mental image is in-domain, never an analogy.** Tangent lines, shrinking brackets, stair-steps, BFS layers, hash-probe lanes: the reader pictures the object under study, in its own domain, in prose, or in a figure plate if it is a figure. The moment it maps to a different domain it is an analogy and the spec's analogy policy takes over, which means default none, and when genuinely needed, the bridging pattern with the mapping stated relation by relation and where it breaks stated beside it. An unmapped one-liner ("think of voltage like water pressure") is deleted, not shortened.
- **The callout** (`hscallout`) carries the objection a careful reader would raise, stated before they have to. Never two in a row.
- **`\opt`** is print's progressive disclosure. It marks genuinely optional depth, per the spec's rule 11: never the mechanism, never a required definition, never the equation-to-application reasoning.

## The three rules the spec has no row for

The owner has held these across every build. They sit beside the spec, not against it.

1. **Weak areas get the page budget.** Ask which one to three topics the reader is weakest on, and spend the pages there: eight to eleven for a weak-area section against four to six for the rest. The spec calibrates density to `audience_level`; this says where to spend length once density is set.
2. **Derive; never write "it can be shown".** Show the Taylor expansion, the substitution, the algebra, in a `derivation`. This is the spec's rule 5 (state inference links) taken to its end: a skipped derivation is a conceptual step the reader is asked to invent, and the document exists to teach it.
3. **Cross-reference methods that share structure.** Simpson weights mirror RK4 weights; Floyd build-heap is the same amortised argument as array doubling; ghost points reappear in heat and in Laplace. Say it in its own sentence with a `\ref` or `\nameref` to the other place, not buried mid-paragraph. A printed document is read out of order and the reader needs the link visible from wherever they land.

## Where this skill's older wording lost

Both of these were in the "how the user learns" list this skill used to carry. The spec is canonical; these are the conflicts, and the spec's answer.

- **"Professional / equation-first" loses to representation matching.** "Prefer equations over prose" is not a rule anywhere in this skill: prose is the correct medium for causal reasoning, and an equation is correct only when the relationship is formal.
- **"One mental-image box per major idea is the floor, not the ceiling" loses to the redundancy rule.** A mental image that restates a sentence already on the page is deleted, not shrunk, and media never repair weak prose.
