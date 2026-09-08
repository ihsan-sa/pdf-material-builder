# Review pipeline

Five parallel reviewers, each catching a distinct class of issue. Which of them run is set by the recipe's build size in `references/recipes.md`, not by taste.

## Which reviewers run

**A `large` build runs all five.** 40-70pp course notes, a worked-examples set, a reference: the document is long, its content was re-derived from source materials, and nobody has read it before.

**A `small` build runs two: the math verification agent and the cold-edit reviewer.** A companion, a cheat sheet or a short technical doc is 2-6pp, and for a companion its content arrived already reviewed inside the lesson. The three reviewers a small build skips, and why:

- *Full-context content reviewer* -- for a companion, lesson-builder's `content-review-agent` already ran the accuracy and discourse passes over this exact content. Running it again reviews the lesson, not the handout.
- *Student-peer brutal review* -- it looks for coverage gaps against an exam. A handout is not supposed to have coverage; its scope is one lesson.
- *Cross-doc consistency reviewer* -- there is one document.

The two that stay are the two whose failure mode survives condensing: a number can be copied wrong, and a `.tex` file can fail to compile. For a small technical doc, swap the student-peer reviewer in as a third if the document makes a recommendation somebody will act on.

The filter phase below is mandatory at both sizes.

## The five reviewers

### 1. Full-context content reviewer (`content-review-agent`)

Knows the doc's purpose, the target student's learning preferences, the conventions doc, and recent fixes. Verifies:

- **Equation / algorithm correctness** -- every recurrence, complexity claim, pseudocode step
- **Convention fidelity** -- prof-specific naming, numbering, signs, notations
- **Scope alignment** -- banned-optional topics either absent or `\opt`-tagged
- **Pedagogy boxes** -- every major concept has a `pictureit`; derivations in `step`; cross-references via `connect`
- **Common traps** the specific prof is known to test (e.g., sign of ghost-point Neumann BC; last-cell pivot on sorted input; unit-weight Dijkstra-vs-BFS framing)

Output: structured findings grouped by file, each tagged CRITICAL / MAJOR / MINOR with location and proposed fix. Cap ~40 findings; surface the top 10 MINOR items only.

### 2. Student-peer brutal review (`general-purpose`)

Framed as a past student who took the course and got a B or C; brutal, not polite. Asks:

- **Coverage gaps**: what would appear on the final that the doc set doesn't cover? Check every verb in the review guide -- does each have a drilled worked example somewhere?
- **Undercovered weak areas**: does the doc cover "the definition" but not "the application"? Every weak area should have at least 4 distinct problem textures (standard / ugly forcing / edge case / non-standard BC).
- **Notation collisions**: where does a student flipping between docs get lost?
- **Pedagogy misses**: are known traps warned about? (Sign conventions; implementation-dependent counter-examples; "tightest upper bound" Theta-in-disguise.)
- **Coding prep**: if the final has coding questions, does the doc set give enough C++ / pseudocode to write the expected functions from scratch under time pressure?
- **Rubric alignment**: does pseudocode have enough structure to earn 60-80% partial credit?

Output: a **Scorecard** (A-F grades per axis), detailed findings, and a **grade-delta estimate** (if the student scored X before, what could the doc set lift them to?). End with "Top 5 changes I'd make if I had one day."

### 3. Cross-doc consistency reviewer (`general-purpose`)

Greps across ALL `.tex` in the set for inconsistencies. Build a canonical-equations table and verify each appears identically across every doc where it shows up.

Check:
- Notation letters (wave speed, diffusivity, damping coefficient, load factor)
- Shift theorem direction and letter
- Heap indexing (1-based vs 0-based) consistency per mention
- Height/depth conventions
- Invariant numbering (RB rules 1-4 vs CLRS 5)
- Probe-sequence formulas (linear / quadratic / double)
- Complexity bounds (e.g., Dijkstra `O((V+E) log V)`)
- Adjacency-list type (prof-specific `map<int, map<int, int>>` etc.)
- Pseudocode skeletons (agrees across reference, formula sheet, course notes, worked examples)

Output: numbered findings with file:line citations for each doc involved.

### 4. Math verification agent (`general-purpose` with Python / SymPy)

Independently re-derives every numerical claim. Report PASS / FAIL / UNVERIFIABLE per item.

Typical verification list for a numerical-methods or data-structures pack:
- Recurrence solutions (merge sort, build-heap, doubling)
- Series sums (Floyd's `sum h/2^h = 2` via SymPy)
- Worked algorithm traces (Dijkstra, Prim, Kruskal, quicksort partition)
- Hash probe sequences (modular arithmetic)
- Classical bounds (AVL Fibonacci argument; RB `2 log_2(n+1)`)
- Counter-example correctness (greedy 0/1 knapsack; Dijkstra on negative edges)
- Closed-form identities (Knuth linear-probe formulas; Stirling applied to `log(N!)`)

Give the agent Python/SymPy via Bash. Demand derivation summaries, not just "looks right". For graph-algo traces, have the agent simulate the trace by hand; for numerical closed forms, use SymPy symbolically and check a few alpha values.

### 5. Cold-edit reviewer (`general-purpose`, minimal context)

Told only "this is a study document, standard is textbook-quality clarity, no emojis, no em-dashes". Catches:

- Typos in prose (doubled words, missing plurals)
- LaTeX glitches: unbalanced `\begin`/`\end`, `\ref` without `\label`, missing `\phantomsection` before `\addcontentsline` for starred sections
- Column-count mismatches in `tabularx`
- Mixed style: tool chips `[T1]` vs `[T1,T2]`, raw `$O()$` vs `\Oh{}`
- Figure reference issues: `\includegraphics{viz_foo.png}` where file is missing
- Silent defects in code snippets (e.g., `LinkedList::addSorted` that's missing `template<>` and `<T>::`)

Minimal context = catches issues insiders overlook.

## Filter phase

**Mandatory after every review round. Reject 20-40% of findings as false positives.**

Reviewers hallucinate in predictable ways:

- **Sign errors from re-derivation** -- the reviewer inverted, not the doc. Re-derive from scratch; if the doc is correct, reject.
- **Quote claims for text that doesn't exist** -- "the doc says X" where X never appears. Grep the file; if absent, reject.
- **Stylistic preferences as defects** -- reviewer disagrees with word choice but it's not wrong. Reject unless two reviewers independently agree.
- **Section-convention misreads** -- e.g., confusing `n` = nodes with `n` = polynomial degree in a problem that uses both. Reject; the doc is self-consistent within its own convention.
- **Cascading cross-refs** -- one finding's "fix" introduces breaks in 3 other places. Evaluate the blast radius before accepting.

### Filter protocol

For each flagged finding:

1. **Math claim?** Re-derive from scratch. If the doc's algebra is right, reject.
2. **Quote claim?** Grep the file verbatim. If the quoted text is absent, reject.
3. **Subjective claim?** Reject unless two independent reviewers flag it.
4. **Cross-reference claim?** Check all affected files. If the "fix" creates breaks elsewhere, re-scope.
5. **Convention claim?** Check the conventions doc. If the doc follows the agreed convention, reject.

Apply only fixes that survive independent verification. Expect 20-40% rejection rate. On heavy-math sections this can be higher.

### Apply-fixes discipline

- Apply CRITICAL fixes first; recompile; re-run math verification on just that section.
- Apply MAJOR fixes in priority order; recompile once at the end of the batch.
- Apply MINOR fixes opportunistically; only recompile at the end.
- Don't apply all findings from one reviewer in one pass -- interleave across reviewers so you notice when two reviewers disagree (often: the student-peer says "add this" and the full-context says "this is fine as-is"; the cross-doc reviewer arbitrates).

## Iteration cadence

Typical cycle for a 40-70pp doc set:

1. Build (phases 1-6).
2. Compile all five docs (three passes each for TOC).
3. Review round 1 (all five reviewers in parallel).
4. Filter false positives (~20-40% rejection).
5. Apply consensus CRITICAL and MAJOR fixes.
6. Math-verification re-check on sections that changed.
7. Round 2 sanity review (full-context only, unless round 1 was ugly).
8. Apply residual polish.
9. Final compile, final style-check script.

Expect 2-5 review rounds before stable. Each round catches 5-15 real issues.

## Common false positives seen across courses

Build a running list for your course. Initial seeds from ECE 204 / 205 / 250:

**ECE 204 (numerical methods)**
- Reviewers inverting Richardson extrapolation sign ("`z_{2n} - y(T)` should be `y(T) - z_{2n}`").
- Reviewers flagging correct content as wrong because they misread the file.
- Reviewers saying "RK4 = Simpson" is wrong (weight vectors are different lengths). The doc said "mirrors", not `=`; false positive on the reviewer.

**ECE 205 (ODEs / transforms)**
- Reviewers flagging `y_c` vs `y_h` naming as wrong. Both are acceptable; the doc uses one convention consistently.
- Reviewers claiming Gibbs value should be `9%` not `8.95%`. `8.95%` is the canonical value; the `9%` in lecture is a rounded approximation. Reject.

**ECE 250 (data structures)**
- Reviewers inventing "Part 5" cross-references when a section was actually Part 3. The reviewer misread; grep confirmed the labels. The `\ref` resolves correctly.
- Reviewers claiming amortised bound of `3` was wrong. Close reading confirmed `3(N-1)` was correct for a specific definition of "element writes"; the reviewer assumed 2-write swaps. Accepted partially -- clarify "three writes per temp-based swap".

Track your course's recurring false positives; over time the list becomes a quick filter.

## Reviewer agent briefs

Brief every reviewer with:
- The doc's purpose (reference vs course notes vs worked examples)
- Target student (course code, prof name, their learning style)
- Hard rules: no emojis, no em-dashes, no `\lt`/`\gt`
- Conventions doc path as critical reading
- Scope flags (banned-optional list)
- Cap on finding count and severity classification

Don't under-specify; reviewers drift without scaffolding.
