# Composing a page

`references/latex-house-style.md` says which macro draws which block. This file
says how to put them on a page, because the first real build of this kit called
every macro correctly and still did not look like the reference document.

Read it before writing the first page of any document, and again with the
rendered PDF open beside `references/house-style/house-style-template.html`.

## What went wrong the first time

The house style landed, a five-page document was built with it, and the owner's
verdict was that the files do not look as they should. Nothing in it broke a
rule. What it did instead:

- called `\begin{hsfigure}{}{}` with an empty label and an empty legend, so the
  figure arrived with no number, no name and nothing telling the reader what the
  boxes mean;
- wrote node bodies as `\textbf{Draft}\\structure first`, so the nodes had no
  eyebrow and each box took the height of its own text, leaving the row ragged;
- put the fail path's caption in among the arrows, where the dashed line, the
  arrowhead and two lines of prose overlapped each other;
- carried no provenance footline on a page full of measured numbers;
- ran three paragraphs, a heading and a diagram on every page in the same order,
  and left the bottom third of most pages empty.

`scripts/style-check.sh` now catches the first three. The last two are judgement,
and this file is that judgement written down.

## The reference document's eight shapes

The target is eight pages and no two of them are laid out alike. Read them as a
catalogue of shapes, not as a sequence to copy:

| Page | Shape | What it is for |
|---|---|---|
| 1 | Title block high on the page, a long fall of white, a four-column metadata strip on the foot rule | Says what the document is and then gets out of the way. The white is deliberate. |
| 2 | Heading, lead, two prose paragraphs, then one figure at full measure with its legend, then the provenance footline | One mechanism, explained once and drawn once. |
| 3 | Heading, two-line lead, a stat row of four, the claim between two rules with its mono line, a callout | The page that carries the numbers and the sentence the document exists for. |
| 4 | Two labelled tables, one comparison and one data, and nothing else | A page may be a single kind of thing all the way down. |
| 5 | A full-measure plate with its spec line and caption, then two half-measure plates side by side | Evidence. The pair below the single is what stops the page reading as one column. |
| 6 | A labelled listing, a caption, a labelled display equation between rules, a callout | Exactness: the page where the literal string and the literal formula matter. |
| 7 | A type ladder with a mono spec column down the right, then a swatch row | A reference page, built out of primitives rather than blocks. |
| 8 | A numbered source list, then two short asides side by side | The last page, and the only place sources appear. |

Three things to take from the catalogue. **A page can be one thing.** Page 4 is
two tables and no prose at all, and it is the calmest page in the document.
**A page can be mostly empty.** Page 1 gives half its height to nothing.
**A page can be two columns.** Pages 5 and 8 both split, and neither needs a
macro to do it: a pair of `minipage`s at `0.47\linewidth` with `\hfill` between.

## The rhythm rule

Before writing, list the document's pages and give each a shape. If two pages in
a row have the same shape, one of them is wrong: merge them, split them
differently, or move a block. A document whose every page is heading, lead, three
paragraphs, figure is not in this style even when every macro is correct. That
sentence is the owner's, in `references/house-style/CONFORMANCE.md`, under "What
the kit cannot check for you".

Two working rules that follow from it:

- **No page is only prose past the second page.** By page three the reader
  expects the document to show something: a figure, a table, a stat row, a
  listing, a plate, an equation.
- **A page that ends a third of the way up is not finished.** Either it has more
  to carry, or the block above it should have been given the room. The exception
  is the title page, where the fall of white is the design.

## Filling a block in rather than calling it

Every block below has an argument the first build left empty. None of them is
optional.

| Block | What has to be in it |
|---|---|
| `hsfigure` | A label of the form `Figure N / what it shows`, and a legend sentence in the second argument naming the kinds of box the picture uses. The legend is prose, not a caption of the label. |
| `hsnodetext` | An eyebrow that names the node's kind in one or two words, a title of two or three, and a detail line that is not a repeat of the title. |
| `hsstat` | A measured number and a caption saying what was measured and when. A figure nobody measured is prose. |
| `hsprovenance` | The command, file, commit or date. `\hsprovenance{}` on a page of numbers is worse than none, because it claims a source it does not name. |
| `hsclaim` | The sentence the document exists for, and a mono line under it saying what kind of sentence it is. Exactly one per document. |
| `hscallout` | The label states the objection, so `What this does not mean` rather than `Note`. |
| `hsplate` | The image, its name, the grey facts, the status, and a caption saying what the plate is evidence of. |
| `hslisting` | `Listing N / what it is`, and then output as it came back, trimmed but not edited. |

Two page-level obligations no macro enforces:

- **Provenance follows numbers.** Any page carrying a figure or a measured
  statistic ends in `\hsprovenance{...}`, which sits at the foot above the
  running foot because it uses `\vfill`. One per page, last thing before the page
  break.
- **The accent is budgeted at three a page**, counted in the prose: a gate node,
  a source numeral, one table header cell. Inside a `tikzpicture` the budget does
  not apply (`CONFORMANCE.md`, item 9).

## Diagrams

A diagram is drawn for what it shows. The owner decided this on 22 September
2026 -- "dont force diagrams into the format in the template" -- and it overrides
the earlier wording of `style-spec.md` block 2, `CONFORMANCE.md` item 9 and the
package README's rule 3, all three of which now say so.

What does not bend, in any of the three patterns below:

- **Typography is the house's.** Mono for every label and eyebrow, the text serif
  for prose inside a node, the page's paper as the ground. No sans-serif
  anywhere; the old documents these patterns come from were set in Helvetica and
  that part does not come with them.
- **Every figure is labelled and legended.** `\begin{hsfigure}{Figure N / ...}`
  with a legend sentence naming the kinds the picture uses.
- **Boxes in a row are one height**, which is what `\hsnodetext` is for.
- **A fail path is one line**, and its caption goes under the picture with
  `\hsfailnote`, never in among the arrows.

### Pattern 1 -- the node row

A mechanism with three to five steps in one direction. This is the template's own
figure, and it is the right answer when the thing genuinely is a line of steps.

```latex
\begin{hsfigure}{Figure 1 / node-and-arrow flow}%
{Filled boxes are inputs and outputs. Outlined boxes are work an agent does.
Rust boxes are deterministic checks that pass or fail.}
\begin{tikzpicture}[node distance=14pt]
  \node[hsnode] (a) {\hsnodetext{Input}{A brief}{goal, boundaries, done-criteria}};
  \node[hswork,right=of a] (b) {\hsnodetext{Agent}{Draft}{structure first, then prose}};
  \node[hsgate,right=of b] (c) {\hsnodetext{Gate}{Style check}{pass, or back with reasons}};
  \node[hsnode,right=of c] (d) {\hsnodetext{Output}{A PDF}{with its sources attached}};
  \draw[hsarrow] (a) -- (b); \draw[hsarrow] (b) -- (c); \draw[hsarrow] (c) -- (d);
  \draw[hsfail] (c.south) -- ++(0,-12pt) -| (b.south);
\end{tikzpicture}
\hsfailnote{A failed gate returns to the draft step, twice, then to a person}
\end{hsfigure}
```

`\hsnodesize{width}{height}` changes both dimensions for the rest of the picture;
the default 88 pt by 54 pt fits four across the measure.

### Pattern 2 -- the lane diagram

Several actors, and the thing that matters is which of them does what and in
which order. Lane headers across the top, a lifeline down from each, steps
sitting in their own lane, and an annotated arrow whenever the work crosses from
one lane to the next. The grid is `x` per lane and a negative `y` so the page
reads downwards.

```latex
\begin{hsfigure}{Figure 2 / one request, end to end}%
{Each column is one actor and time runs down the page. A dashed arrow is a
return; the italic line on an arrow says what crosses.}
\begin{tikzpicture}[x=92pt,y=-15pt]
  \node[hslane,hshuman]  (O) at (0,0) {\hsrolename{A person}{phone or laptop}};
  \node[hslane,hssystem] (S) at (1,0) {\hsrolename{Slack}{the project's channel}};
  \node[hslane,hsagent]  (P) at (2,0) {\hsrolename{Planning seat}{the project's session}};
  \node[hslane,hsmachine](W) at (3,0) {\hsrolename{Worker}{one task}};
  \node[hslane,hsstore]  (L) at (4,0) {\hsrolename{Landing}{the queue, and GitHub}};
  \foreach \c in {O,S,P,W,L} \draw[hslife] (\c.south) -- (\c.south |- 0,16);
  \draw[hsarrow] (0,1.6) -- node[hsann] {a message} (1,1.6);
  \draw[hsarrow] (1,3.2) -- node[hsann] {typed into the session's window} (2,3.2);
  \node[hsstep] at (2,4.6) {adds a board row, writes a brief};
  \draw[hsarrow] (2,6.2) -- node[hsann] {one command starts the worker} (3,6.2);
  \node[hsstep] at (3,7.6) {its own worktree and branch; a hook commits};
  \draw[hsarrow] (3,9.6) -- node[hsann] {says done, opens the PR} (4,9.6);
  \node[hsstep] at (4,11) {gates, then one review read of the diff};
  \draw[hsreturn] (4,13) -- node[hsann] {landed, in the track's own thread} (1,13);
  \draw[hsreturn] (1,14.6) -- node[hsann] {a note back} (0,14.6);
\end{tikzpicture}
\end{hsfigure}
```

A node takes one shape style and one role style: `hslane` for a lane header,
`hsrole` for a box anywhere else, and one of the five colours beside it. An arrow's annotation is filled in the paper colour and masks the
line under it, which is what keeps it readable; leave at least 40 pt of arrow
beyond the label so the arrowhead is not covered too.

### Pattern 3 -- the role graph

Parts of a system that do not form a line: each box is a part, its colour says
what kind of part it is, and the arrow between two of them carries the thing that
passes. Place boxes on a coordinate grid rather than with `right=of`, so the
picture can breathe where it needs to.

```latex
\begin{hsfigure}{Figure 3 / what runs with nobody there}%
{Blue is a door into the box, green a session, grey an automatic timer, rust a
store. An italic line on an arrow says what passes between two parts.}
\begin{tikzpicture}[x=1pt,y=1pt]
  \node[hsrole,hssystem]  (d) at (0,72)    {\hsrolename{Slack daemon}{the box's one connection}};
  \node[hsrole,hssystem]  (m) at (0,0)     {\hsrolename{Mail receiver}{loopback, behind a tunnel}};
  \node[hsrole,hsmachine] (b) at (190,36)  {\hsrolename{Broker}{every 60 s: the event door}};
  \node[hsrole,hsagent]   (s) at (380,72)  {\hsrolename{Sessions}{the tmux windows}};
  \node[hsrole,hsstore]   (r) at (190,-52) {\hsrolename{The board}{one row per task}};
  \draw[hsarrow] (d) -- node[hsann] {stored, then handed over} (b);
  \draw[hsarrow] (m) -- (b);
  \draw[hsarrow] (b) -- node[hsann] {one message, not six} (s);
  \draw[hsarrow] (b) -- (r);
\end{tikzpicture}
\end{hsfigure}
```

The five role styles are `hshuman` (gold, a person), `hssystem` (blue, a door or
an outside service), `hsagent` (green, something that runs a model),
`hsmachine` (grey, something automatic), `hsstore` (rust, a store or a record),
plus `hsstop` for a heavier rust box where something is refused. Each names a
colour only, so it goes on a node beside `hsrole` or `hslane`, never alone. Use three or
four of them in one picture, not all five, and name every one you use in the
legend. The role colours exist for the inside of a `tikzpicture`; nothing in the
prose of a page is set in them.

## Before hand-off: render it and look at it

The style gate is mechanical and this part is not. Build the document, then:

```bash
pdftoppm -png -r 80 <name>.pdf /tmp/<name>
```

and read the images, page by page, beside the reference rendering. Check:

1. **Shapes vary.** No two consecutive pages lay their blocks out the same way.
2. **No page dies early.** Nothing but the title page ends in the bottom third.
3. **Every figure has its number, its name and its legend sentence**, and the
   legend names the kinds the picture actually uses.
4. **Every node has an eyebrow**, and every box in a row is the same height.
5. **Every fail path is one line**, with its caption clear of the arrows.
6. **Every page with a figure or a measured number ends in a provenance
   footline**, and that footline names a command, a file, a commit or a date.
7. **The claim appears once**, and the callout stating its limit is on the same
   page.
8. **Labels read as words, not as spaced capitals.** If `HOUSE STYLE` has come
   out as `H O U S E  S T Y L E`, the label tracking is wrong.
9. **The paper is warm.** A page that renders pure white has lost the tint, which
   means `housestyle.sty` did not load.
10. **The sources are one numbered list on the last page**, which heads itself
    `Sources`, and no footnote exists anywhere.

Say in the hand-off which pages you compared and what you changed after looking.
