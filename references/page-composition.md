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

The owner's original reference was eight pages and no two of them were laid
out alike. (The v5 `house-style-template.html` shows every block once over
seven pages and uses five of these shapes; the catalogue still stands.) Read them as a
catalogue of shapes, not as a sequence to copy:

| Page | Shape | What it is for |
|---|---|---|
| 1 | Title block high on the page, then a long fall of white (long documents; a short one opens with `\hstitleblock` and goes straight into prose, see `assets/short-template.tex`) | Says what the document is and then gets out of the way. The white is deliberate. |
| 2 | Heading, lead, two prose paragraphs, then one figure at full measure with its legend, then the provenance footline | One mechanism, explained once and drawn once. |
| 3 | Heading, two-line lead, a stat row of four, the claim between two rules with its small-caps line, a callout | The page that carries the numbers and the sentence the document exists for. |
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
| `hsclaim` | The sentence the document exists for, and a small-caps line under it saying what kind of sentence it is. Exactly one per document. |
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

Figures come from diagram-maker first (`references/house-style/DIAGRAMS.md`).
This skill carries its own copy of diagram-maker in `diagram-maker/`, a
submodule that follows diagram-maker's main, and that copy is the one to use:

1. Write the spec to `figures/<name>.json` next to the `.tex`. Set `canvas` to
   the measure where the type takes one: 553 on A4, 576 on letter, so the
   figure lands at 1:1. The figure's message goes in the `hsfigure` label and
   in the spec's `alt`.
2. `scripts/build.sh doc.tex` does the rest. It syncs `diagram-maker/` to its
   latest main (quietly skipped offline), renders each spec with
   `diagram-maker/scripts/render.js`, exports it with
   `diagram-maker/scripts/export.sh <name>.svg pdf`, and fails on any error the
   render reports. Fix the spec, never the SVG.
3. Place it inside `hsfigure` with `\hsdiagram{figures/<name>}`, which sets it
   at its own size and only ever scales it down to the measure.

```tex
\begin{hsfigure}{Figure 2 / what a change goes through before it merges}%
{The legend: how to read the picture, what the dashed line is.}
\hsdiagram{figures/merge-gates}
\end{hsfigure}
```

The three patterns below are the TikZ kit in `hsdiagrams.sty`. They are the
fallback for when diagram-maker cannot run: when `export.sh` exits 2 (no
converter on the machine) or there is no node. One picture source per
document, so a fallback draws every figure in the document with the kit, and
the hand-off says so.

A diagram is drawn for what it shows. The owner decided this on 22 September
2026 -- "dont force diagrams into the format in the template" -- and it overrides
the earlier wording of `style-spec.md` block 2, `CONFORMANCE.md` item 9 and the
package README's rule 3, all three of which now say so.

What does not bend, in any of the three patterns below:

- **Typography is the house's.** Small caps for every label and eyebrow (v5; they
  were mono capitals), the text serif for prose inside a node, the page's paper as the ground. No sans-serif
  anywhere; the old documents these patterns come from were set in Helvetica and
  that part does not come with them.
- **A role reads apart by colour, and every box carries the same weight.** The
  owner tried weight first (22 September 2026, "they can still be redrawn in
  the new pallette which is prob better but i mean the form etc") and then
  overruled it (23 September 2026): "I prefer the lightly shaded or outlined
  boxes. preferably all consistent with shading but different colours.
  basically just the black is too different." So every box in a diagram is a
  thin outline with a fill at about 12% of the same colour, and the four
  colours -- `hsslate`, `hssage`, `hsochre`, `hsaccentrole` -- exist only
  inside a `tikzpicture`; nothing outside one takes a hue that is not one of
  the eight kit tokens. No box is filled solid black. *How a writer picks a
  colour* below is how.
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
{Slate boxes are inputs and outputs. Sage boxes are work an agent does.
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
the default 81 pt by 46 pt fits four across the A4 measure (415 pt).

### Pattern 2 -- the lane diagram

Several actors, and the thing that matters is which of them does what and in
which order. Lane headers across the top, a lifeline down from each, steps
sitting in their own lane, and an annotated arrow whenever the work crosses from
one lane to the next. The grid is `x` per lane and a negative `y` so the page
reads downwards.

```latex
\begin{hsfigure}{Figure 2 / one request, end to end}%
{Each column is one actor and time runs down the page. The ochre lane decides
and the rust one is where work becomes public; a dashed arrow is a return, and
the italic line on an arrow says what crosses.}
\begin{tikzpicture}[x=82pt,y=-15pt]
  \node[hslane,hsslate]      (O) at (0,0) {\hsrolename{A person}{phone or laptop}};
  \node[hslane,hsquiet]      (S) at (1,0) {\hsrolename{Slack}{the project's channel}};
  \node[hslane,hsochre]      (P) at (2,0) {\hsrolename{Planning seat}{the project's session}};
  \node[hslane,hssage]       (W) at (3,0) {\hsrolename{Worker}{one task}};
  \node[hslane,hsaccentrole] (L) at (4,0) {\hsrolename{Landing}{the queue, and GitHub}};
  \foreach \c in {O,S,P,W,L} \draw[hslife] (\c.south) -- (\c.south |- 0,16);
  \draw[hsarrow] (0,1.6) -- node[hsann,above=0pt] {a message} (1,1.6);
  \draw[hsarrow] (1,3.2) -- node[hsann,above=0pt] {typed into the session's window} (2,3.2);
  \node[hsstep] at (2,4.6) {adds a board row, writes a brief};
  \draw[hsarrow] (2,6.2) -- node[hsann,above=0pt] {one command starts the worker} (3,6.2);
  \node[hsstep] at (3,7.6) {its own worktree and branch; a hook commits};
  \draw[hsarrow] (3,9.6) -- node[hsann,above=0pt] {says done, opens the PR} (4,9.6);
  \node[hsstep] at (4,11) {gates, then one review read of the diff};
  \draw[hsreturn] (4,13) -- node[hsann,above=0pt] {landed, in the track's own thread} (1,13);
  \draw[hsreturn] (1,14.6) -- node[hsann,above=0pt] {a note back} (0,14.6);
\end{tikzpicture}
\end{hsfigure}
```

A node takes one shape style and one treatment, shape first: `hslane` for a lane
header, `hsrole` for a box anywhere else. An arrow's annotation is filled in the
paper colour and masks the line under it, which is what keeps it readable. Two
rules follow from that. On a free arrow, leave at least 40 pt beyond the label so
the arrowhead is not covered, and break a long annotation over two lines with
`\\` rather than let it run under the box at either end. In a lane diagram the
span between two lanes is usually shorter than the sentence, so put the
annotation `above=0pt` instead: the arrow stays whole under it and the reader
still sees which way the work went.

### Pattern 3 -- the role graph

Parts of a system that do not form a line: each box is a part, its colour says
what kind of part it is, and the arrow between two of them carries the thing that
passes. Place boxes on a coordinate grid rather than with `right=of`, so the
picture can breathe where it needs to.

```latex
\begin{hsfigure}{Figure 3 / what runs with nobody there}%
{Slate boxes are doors into the box, the rust one is what every event goes
through, the sage one is where a model runs and the grey one is a record. An
italic line on an arrow says what passes between two parts.}
\begin{tikzpicture}[x=1pt,y=1pt]
  \node[hsrole,hsslate]      (d) at (0,72)    {\hsrolename{Slack daemon}{the box's one connection}};
  \node[hsrole,hsslate]      (m) at (0,0)     {\hsrolename{Mail receiver}{loopback, behind a tunnel}};
  \node[hsrole,hsaccentrole] (b) at (158,36)  {\hsrolename{Broker}{every 60 s: the event door}};
  \node[hsrole,hssage]       (s) at (316,72)  {\hsrolename{Sessions}{the tmux windows}};
  \node[hsrole,hsquiet]      (r) at (158,-52) {\hsrolename{The board}{one row per task}};
  \draw[hsarrow] (d) -- node[hsann] {stored,\\then handed on} (b);
  \draw[hsarrow] (m) -- (b);
  \draw[hsarrow] (b) -- node[hsann] {one message,\\not six} (s);
  \draw[hsarrow] (b) -- (r);
\end{tikzpicture}
\end{hsfigure}
```

### How a writer picks a colour

There are four, and every one of them is drawn the same way -- a thin outline
and a fill at about 12% of itself -- so a reader tells the roles apart by hue,
not by how loud the box is. A fifth, `hsquiet`, carries no hue at all and is
for anything that is not a role.

| Style | Colour | Give it to |
| --- | --- | --- |
| `hsslate` | `#4F6D8A` | a person, or the door a thing comes in through |
| `hssage` | `#5E7A5A` | work getting done: an agent, a worker, wherever a model runs |
| `hsochre` | `#A07A2C` | the part that decides |
| `hsaccentrole` | `#9C4221`, the kit accent | the single role the mechanism turns on -- a gate, a landing, a broker every event passes through. One per picture |
| `hsquiet` | none: grey rule on paper | ambient things with no part to play -- a store, a record, a timer |

A colour carries no fixed meaning across pictures the way `hsmarked` once did
by being spent once; name in the legend what each one stands for in *this*
picture. Use three or four of the five in one picture, and each style names a
colour only, so it goes on a node beside `hsrole` or `hslane`, never alone.

## Three traps the first composed build hit

None of these is caught by the gate, and each of them cost a rebuild.

- **A block that is not prose needs `hsblock`.** A `tabular`, a pair of
  asides side by side: all of them are set as boxes, not
  prose, so they range left at the full measure whatever the prose alignment.
  Without the environment a table under `\hsjustified` gets its cells
  stretched.
- **`\hsprovenance` needs about 35 pt of room left.** It sits at the foot
  through `\vfill`, so on a page that is already full it does not compress: it
  goes alone to the next page, which then has a single grey line at the top and
  nothing else. When that happens, cut prose from the page above rather than
  move the footline.
- **In a lane diagram, leave about two grid rows between a step box and the next
  arrow.** A step is wider than its lane, so an arrow too close to it has its
  annotation land on the box. If the picture then runs past the page, drop an
  arrow rather than shrink the gaps: a diagram with one fewer annotated step
  still reads, and one with overlapping labels does not.

## What the second pitch build got wrong

`pitch (3).pdf`, built on the v5 templates on 23 September 2026, called every
macro and still drifted in five places. Each is now either fixed in the kit
or a rule here.

- **It drew its own boxes.** The document defined `who`, `ai`, `chk` and
  `stop` styles with `\tikzset`, so the nodes had no eyebrows, their heights
  followed their text (the Review box stood taller than its row), and a
  "Sent back" box sat where the fail path belonged. **A document never writes
  `\tikzset` for a box.** A node row is `hsnode` / `hswork` / `hsgate` with
  `\hsnodetext`. To give a node-row box another colour, add the treatment
  after the shape: `\node[hswork,hsochre]`. Anything else is `hsrole` or
  `hslane` with a treatment. `assets/blank-template.tex` shows the node row
  and the role graph drawn this way.
- **Stat captions ran to eight lines.** Four abreast, a caption has about
  100 pt of width. **Keep a stat caption to three lines, about fifteen words**:
  what was counted, over what, and when. The rest of the sentence belongs in
  the lead or in the provenance footline, which is where the command goes
  anyway. If every caption in a row needs more, use `hsstatrow[2]` or a
  data table.
- **The sources page had no heading.** It opened on "All sources opened on
  21 September 2026." under a running head that said Sources. **Open the last
  page with `\hssourcespage`**, which starts the page and heads it. A dating
  sentence goes under the heading, before the list.
- **Page one ended at 40%.** The title block, two paragraphs and one figure,
  then a forced `\newpage` and white down to the footline. The footline's
  `\vfill` does not fill a page, it only moves the footline down. Either let
  the next section follow on the same page or give page one more to carry.
  Don't `\newpage` after a page that is short of half full.
- **Spacing the kit got wrong, now fixed in `housestyle.sty`:** a heading at
  the top of a page sat 8 pt under the head rule (`headsep` is now 26 pt).
  The claim had 44 pt between its label and its closing rule (`\parskip` is
  now 0 inside the claim and the callout). The callout's label sat half a
  line below its body's first line (labels now start with `\leavevmode`).

## What the third pitch build showed

`pitch (4).pdf` (A4, 6 pp) used the kit's boxes everywhere and headed its
sources page. The remaining faults were in the kit or in the sample it copied:

- **Air inside every figure and stat row.** `\parskip` (11 pt) was added at
  every `\par` inside `hsfigure` and `hsstatrow`. That put about 70 pt of
  white in each figure and 140 pt between two stat rows. Fixed: both set
  `\parskip` to 0 inside, as the claim and the callout already did.
- **Stat captions still ran to eight lines**, because the kit's `samples/pitch.tex`
  itself had them and the build copied it. The sample now keeps each caption
  under ten words and moves the rest into a sentence under the row. The same
  applies to any document: **the caption names what was counted; the prose
  under the row says what it means.**
- **Two stat rows never touch.** Back to back, the first row's grey closing
  rule and the second's ink opening rule make a double rule with a band of
  white between them. Put a sentence between the rows, or make it one row.
- **A URL split inside a word** ("git / hub"). URLs now prefer to break after
  `/ . - _`. **An entry that cites several URLs puts each on its own line**
  with `\\`, as the sample's product-pages entry now does.
- **The callout's two-line label drifted from the body** by 2 pt a line. The
  label now uses the body's 16 pt leading.

**How much white above a footline is fine.** A one-figure page (shape 2) may
leave white between its last block and the provenance footline, up to about a
third of the page. More than that, and the next section should start on the
same page, or the page should carry more. Pages 4 and 5 of the build each left
about 40%; page 5's prose could have joined page 4 under the callout.

## Justified or ranged left

Pick once per document, in the preamble, before writing:

- **`\hsjustified`** for an essay, a write-up, a letter, reading notes:
  anything whose pages are mostly continuous paragraphs. Both edges of the text
  block are hard and line up with the rules.
- **Ranged left** (the default) for a technical document: course notes with
  maths and code, a reference, a runbook, a spec. Also for any document whose
  prose is broken up by a block on most pages, like the pitch (the owner picked
  ranged left for it, 23 September 2026). Short paragraphs between blocks
  justify badly, and paths, commands and URLs in the text stretch the spaces
  around them.

If in doubt, range left. Never mix the two in one document.

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
8. **Labels read as words.** They are serif small caps; a figure label shows its
   number in small caps and its title in italic. A label in mono capitals means
   an old `housestyle.sty` was loaded.
9. **The paper is warm.** A page that renders pure white has lost the tint, which
   means `housestyle.sty` did not load.
10. **The sources are one numbered list on the last page**, opened with
    `\hssourcespage` so the page heads itself `Sources`, and no footnote exists
    anywhere.
11. **No box is drawn with the document's own `\tikzset`.** Every node carries
    an `hs*` shape style, and every node in a row has an eyebrow.
12. **No stat caption runs past three lines**, and no two stat rows sit back to back.
13. **No URL breaks inside a word.** Several URLs in one source go one per line.

Say in the hand-off which pages you compared and what you changed after looking.
