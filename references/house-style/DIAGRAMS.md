# Diagrams: a module of their own

Two skills share a figure. **diagram-maker**
([ihsan-sa/diagram-maker](https://github.com/ihsan-sa/diagram-maker)) owns the
picture. **This kit** owns the page the picture sits on. This file is the
contract between them. Keep to it and neither can break the other.

## Who owns what

| Part of a figure | Owner | Where it lives |
|---|---|---|
| Label (`Figure 2 / what it shows`), grey rules, legend sentence | the kit | `hsfigure` in `housestyle.sty` |
| Fail-path caption under the picture | the kit | `\hsfailnote` in `housestyle.sty` |
| Provenance footline | the kit | `\hsprovenance` |
| Everything inside the picture: boxes, colours, type, arrows, routing, edge labels | diagram-maker | its JSON spec, rendered to `figures/<name>.pdf` |
| The TikZ fallback picture | the kit's diagram module | `hsdiagrams.sty` |

`housestyle.sty` holds no picture code. The TikZ kit (`hsnode`, `hsrole`,
the role colours, `\hsnodetext`, ...) is in `hsdiagrams.sty`, which
`housestyle.sty` loads unless you pass `[nodiagramkit]`. A change to either
picture source cannot reach the page layout, and a change to the page cannot
reach into a picture.

## The socket

```latex
\begin{hsfigure}{Figure 2 / what a change goes through before it merges}%
{The legend: how to read the picture, what the dashed line is.}
\hsdiagram{figures/merge-gates}
\end{hsfigure}
```

`\hsdiagram[keys]{file}` places the PDF at its own size and scales it down
only if it is wider than the measure. It never scales up. That is the only
command a diagram-maker figure needs.

## Calling diagram-maker from a document build

1. Write the spec to `figures/<name>.json` next to the `.tex`. The figure's
   message (10 words or fewer) goes in the `hsfigure` label, after
   `Figure N /`, and in the spec's `alt`.
2. Render: `node <diagram-maker>/scripts/render.js figures/<name>.json`, and fix
   every `error` the report lists.
3. Export: `<diagram-maker>/scripts/export.sh figures/<name>.svg pdf`.
4. Place it with `\hsdiagram{figures/<name>}` inside `hsfigure`. Its caption
   becomes the `hsfigure` legend.
5. Keep the `.json` next to the `.pdf`, so the figure can be regenerated.

## Size

The page measure is 415 pt on A4 and 432 pt on Letter. diagram-maker draws in
px, and a PDF export maps 1 px to 0.75 pt. So:

- **Where the type accepts `canvas`, set it to the measure in px: 553 on A4,
  576 on Letter.** The figure then lands at 1:1, and its 14 px titles read at
  10.5 pt, the body size.
- Where the type does not accept `canvas` (the 720 default), the figure is
  scaled to 77%. Titles read at about 8 pt. That is acceptable, and it is the
  floor.
- **Never 960 on a portrait page.** Scaled to the measure it is 43%, and its
  text drops below 6 pt. Split the figure instead, as diagram-maker's own node
  limits already say.

## Rules that hold on both sides

- **The picture has no title and no caption.** Both belong to `hsfigure`, and
  diagram-maker already leaves them out.
- **Nothing in the document restyles the picture.** Don't write `\tikzset`
  over a diagram-maker figure, don't clip or recolour it, and don't hand-edit
  the SVG. To change a figure, change the spec and re-render.
- **One source per document.** Every figure comes from diagram-maker, or every
  figure is the TikZ kit. The two draw different boxes, type and colours, and a
  document that mixes them looks like two documents.
- **Inside a diagram-maker picture its `STYLE.md` governs**, the way the
  accent budget stops at a `tikzpicture`. That includes its sans-serif type
  and its role colours. The page's "no sans-serif" rule and the eight colour
  tokens stop at the picture's edge.
- **\hsfailnote is only for the TikZ kit.** diagram-maker's `gate` type labels
  its own fail path, so a diagram-maker figure never gets a second fail
  caption.

## When diagram-maker can't run

If `export.sh` exits 2 (no converter on the machine), draw the figure with the
TikZ kit in `hsdiagrams.sty` and use the kit for every other figure in the
document too. `page-composition.md` has the three kit patterns. Say in the
hand-off that you did.

## Word

Diagrams reach the Word template as images, never as shapes. Export the PNG
(`export.sh figure.svg png`, 2x). Place it in a **Figure** paragraph at the
text width, with its label above in **Label** and the caption under it in
**Caption**.

## Differences between the two styles (open)

These are the owner's call, and neither side should change without one:

- **Type.** diagram-maker sets Helvetica, and the page is Source Serif 4
  throughout.
- **Rust.** diagram-maker's gate rust is `#C96442`, and the kit accent is
  `#9C4221`. A figure's gate and the page's accent label are two different
  rusts.
- **Role colours** differ in hue. Kit slate `#4F6D8A` sits against io
  `#3E6C8F`, and kit sage `#5E7A5A` against work `#4F7A52`. diagram-maker also
  has actor ochre and store purple.
- **Canvas.** diagram-maker's `#FAF9F6` sits on the page's `#FAF8F3`, 1 apart
  in green and 3 in blue. That is invisible in print, but a screen can show a faint box. An
  export with a transparent background, or a canvas of `#FAF8F3`, would remove
  it.
