# Conventions — palette, macros, LaTeX traps

This file is consulted during the build to get the canonical preamble elements right the first time, and during the review pipeline to check style compliance.

## Palette

All courses share the gold / category-colour structure. Add or rename category colours per course.

```
gold         #B8943E   primary accent, section headers
muted        #555555   secondary text
softbg       #F7F4EC   warm cream fill for step / example boxes
tool (green) #5C8A5C   tool chips [T1]-[T7]

intuitrose   #D4708A   pink stripe (picture / insight boxes)
fsheetgreen  #5CB85C   green stripe (formula-sheet equations)
connectblue  #3E6FB8   blue stripe (cross-topic connections)
optorange    #C97A1E   orange stripe (optional / out-of-scope content)
```

Category colours — pick per course:

```
ECE 204 (A-D: numerical methods)
catA #2B8A8A teal   (approximating expressions)
catB #B8943E amber  (algebraic equations)
catC #C05A7A rose   (analytic: IVPs, BVPs, PDEs)
catD #7A5AC0 violet (optimization)

ECE 205 (A-D: ODEs + transforms)
catA #2B8A8A teal   (first-order ODEs)
catB #B8943E amber  (second-order + vibrations)
catC #C05A7A rose   (Laplace)
catD #7A5AC0 violet (Fourier / PDEs)

ECE 250 (A-G: data structures + algorithms)
catA #2B8A8A teal    (analysis and ADTs)
catB #B8943E amber   (linear structures)
catC #C05A7A rose    (trees and heaps)
catD #7A5AC0 violet  (hashing)
catE #3E6FB8 blue    (sorting)
catF #2E8B57 emerald (graphs)
catG #8B5A2B brown   (paradigms)
```

## Box styles (tcolorbox)

| Stripe | Env name | Purpose |
|---|---|---|
| Pink | `pictureit`, `insight` | Mental-image narrative, one-line takeaway. Read first on review. |
| Grey (filled) | `step` | Multi-line derivation. Work through once; skip on re-read. |
| Green | `fsheet` | Equation / fact that lives on (or should live on) the official formula sheet. Commit shape, not digits. |
| Blue | `connect` | Cross-topic link. Foreshadows later material or recalls earlier. |
| Orange | `optional` | Flagged as out of scope per course materials. Skip on first read. Inline `\opt` tag for brief mentions. |

**Naming gotcha.** Never define a tcolorbox env named `picture` — it collides with LaTeX's built-in `picture` environment and silently breaks `\@iiiparbox`. Use `pictureit`.

## Canonical macro kit

```latex
% Tool / category chips
\tool{5}                 % [T5] green
\tools{T4,T5}            % multi-tool
\cat{A}                  % category badge

% Structure
\catbanner{catC}{Part 5 \textperiodcentered\ Category C: BVPs}

% Category banner (filled strip at top of each Part)
\newcommand{\catbanner}[2]{%
  \begin{tcolorbox}[enhanced,colback=#1,colframe=#1,boxrule=0pt,
    arc=2pt,left=8pt,right=8pt,top=3pt,bottom=3pt,
    fontupper=\bfseries\color{white}\normalsize]
  #2
  \end{tcolorbox}%
}

% Vector shorthand (define ALL lowercase letters, agents reach for any)
\newcommand{\ba}{\mathbf{a}} \newcommand{\bb}{\mathbf{b}} \newcommand{\bc}{\mathbf{c}}
\newcommand{\bd}{\mathbf{d}} \newcommand{\be}{\mathbf{e}} \newcommand{\bff}{\mathbf{f}}
\newcommand{\bg}{\mathbf{g}} \newcommand{\bh}{\mathbf{h}} \newcommand{\bi}{\mathbf{i}}
\newcommand{\bj}{\mathbf{j}} \newcommand{\bk}{\mathbf{k}} \newcommand{\bl}{\mathbf{l}}
\newcommand{\bm}{\mathbf{m}} \newcommand{\bn}{\mathbf{n}} \newcommand{\bp}{\mathbf{p}}
\newcommand{\bq}{\mathbf{q}} \newcommand{\br}{\mathbf{r}} \newcommand{\bs}{\mathbf{s}}
\newcommand{\bt}{\mathbf{t}} \newcommand{\bu}{\mathbf{u}} \newcommand{\bv}{\mathbf{v}}
\newcommand{\bw}{\mathbf{w}} \newcommand{\bx}{\mathbf{x}} \newcommand{\by}{\mathbf{y}}
\newcommand{\bz}{\mathbf{z}} \newcommand{\bzero}{\mathbf{0}}

% Transpose (critical: NO `^`; so X^\trans -> X^{\!\top})
\newcommand{\trans}{{\!\top}}

% Partial derivatives
\newcommand{\pderiv}[2]{\dfrac{\partial #1}{\partial #2}}
\newcommand{\ppderiv}[2]{\dfrac{\partial^2 #1}{\partial #2^2}}
\newcommand{\pmderiv}[3]{\dfrac{\partial^2 #1}{\partial #2 \, \partial #3}}

% Big-O (defined as macro so it's consistent everywhere)
\newcommand{\Oh}{\mathcal{O}}
\newcommand{\Ohof}[1]{\mathcal{O}\!\left(#1\right)}

% Other common
\newcommand{\grad}{\nabla}
\newcommand{\Hess}{H_f}
\newcommand{\RR}[1]{\mathbb{R}^{#1}}
\newcommand{\diff}[1]{\mathop{}\!\mathrm{d}#1}

% Problem heading (for embedded worked examples)
\newcommand{\probhead}[3]{%
  \vspace{4pt}
  \noindent\colorbox{softbg}{\parbox{\dimexpr\linewidth-2\fboxsep}{%
    \small\color{muted}\textbf{#1} \quad\textperiodcentered\quad \textit{#2} \quad\textperiodcentered\quad \textbf{\color{gold}#3}}}%
  \vspace{2pt}
}

% Inline tag for brief optional mentions
\newcommand{\opt}{\hspace{2pt}\textcolor{optorange}{\textsf{\scriptsize\textbf{[optional]}}}}
```

See `assets/preamble-template.tex` for the complete preamble.

## Formatting conventions

- `10pt`, letterpaper, `0.65in` margins for body docs; `0.55in` for the compact landscape reference.
- `parskip` (no paragraph indents).
- Section titles:
  ```
  \titleformat{\section}{\normalfont\large\bfseries\color{gold}}{\thesection.}{0.5em}{}
  ```
- Hyperref with `colorlinks=true`, `linkcolor=black!75` for TOC; gold for URLs. When the category accent is used for TOC links instead, pick `linkcolor=catX` to match the course's primary cat colour.

## LaTeX traps hit in real builds

1. **KaTeX habit leaking.** Agents write `\lt` and `\gt` (KaTeX-only). In LaTeX these are undefined. After every agent write, grep for `\\lt` and `\\gt` and replace with literal `<`/`>`. Do NOT use `sed`; regex edge cases corrupt `\Delta` and friends. Use Python with a precise regex.

2. **`picture` env collision.** LaTeX has a built-in `picture` environment; redefining it via `\newtcolorbox{picture}` silently breaks `\@iiiparbox` later. Always name custom boxes something else (`pictureit`).

3. **`\trans` macro design.** `\newcommand{\trans}{^{\!\top}}` then `X^\trans` expands to `X^^{\!\top}` (double `^`). Correct form: `\newcommand{\trans}{{\!\top}}`, so `X^\trans` → `X^{\!\top}`.

4. **`\bX` vector macros missing.** Agents use `\ba, \bb, \bc, \bd, \be, \bh, \bn, \br, \bs` freely. Define every lowercase letter in the preamble; don't wait to discover missing macros at compile.

5. **MiKTeX hang on auto-install.** MiKTeX pops a modal GUI dialog for on-demand package install, which CLI sees as a hang. One-time fix per machine: `initexmf --set-config-value="[MPM]AutoInstall=1"`.

6. **PDF file-lock during compile.** If the PDF is open in a viewer, `pdflatex` fails with "I can't write on file". Compile to a temp jobname (`pdflatex -jobname=_tmp_<round> ...`), then swap via `cp _tmp_<round>.pdf <final>.pdf`. Delete `_tmp_*` after.

7. **Two compile passes for cross-refs is not always enough.** With a multi-page TOC, the first pass writes no TOC entries, the second pass writes them but shifts every subsequent page number, and `\ref`s to page numbers miss. **Run three passes for any doc with a TOC of more than one page.** Course notes essentially always need three; reference docs and formula sheets usually converge in two.

8. **TOC entries for starred sections.** Use `\phantomsection` + `\addcontentsline{toc}{section}{<title>}` before a `\section*`. For counter-driven custom entries (like `Problem N`), use `\refstepcounter{probnum}` before the `\addcontentsline`.

9. **Em-dashes and unicode.** `—` (U+2014) breaks some setups and is a user style preference. Grep for them post-build; replace with `--` or commas/semicolons.

10. **No emojis.** Zero tolerance. Grep high-unicode code points after every build.

11. **Line endings.** On Windows, git's `autocrlf` may convert LF to CRLF in the working tree. Agents that read files should handle both; when re-writing, preserve local line endings.

12. **Hyperref "Token not allowed in PDF string" warnings.** Math in `\section` titles generates benign warnings when building PDF bookmarks. Cosmetic only. Options: (a) wrap each with `\texorpdfstring{<math>}{<plain>}` (mechanical, ~1 hour of edits); (b) live with the warnings and add a one-line comment in the driver explaining they're benign. Option (b) is usually the right call.

## Style-check script

Run after every agent-authored write. Expected final totals: all zero.

```python
import os, re
skip_dirs = {'_extraction', 'course_materials', 'viz_src',
             'node_modules', 'claude_lessons'}
files = []
for root, dirs, fs in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in skip_dirs]
    for f in fs:
        if f.endswith('.tex'):
            files.append(os.path.join(root, f))

lt_re = re.compile(r'\\lt(?=[\s$}\\])')
gt_re = re.compile(r'\\gt(?=[\s$}\\])')
t_em = t_lt = t_hi = 0
for f in files:
    with open(f, 'r', encoding='utf-8') as fh:
        s = fh.read()
    em = s.count('\u2014')
    lt = len(lt_re.findall(s))
    gt = len(gt_re.findall(s))
    hi = sum(1 for c in s if ord(c) > 0x2000 and
             ord(c) not in (0x2014, 0x2013, 0x2019, 0x201c, 0x201d))
    if em or lt or gt or hi:
        print(f'{f}: em={em}, lt/gt={lt+gt}, hi={hi}')
    t_em += em; t_lt += lt + gt; t_hi += hi

print(f'TOTAL: em={t_em}, lt/gt={t_lt}, hi={t_hi}, files={len(files)}')
```

## Compile recipe (idempotent; safe to re-run)

```bash
cd <course_dir>

# Three passes; use temp jobname so an open PDF in a viewer doesn't lock
for i in 1 2 3; do
  pdflatex -interaction=nonstopmode -jobname=_tmp_cn <course>_course_notes.tex > /dev/null 2>&1
done
cp _tmp_cn.pdf <course>_course_notes.pdf
rm _tmp_cn.*

# Repeat for each of the 5 PDFs
```

For the formula sheet / reference / visual-intuition docs, two passes usually suffice (single-page TOCs), but three costs nothing and guarantees convergence.

## Copyright footer

Every shipped PDF uses this footer:

```latex
\fancyfoot[L]{\footnotesize\color{muted}\textcopyright{} 2026 <Name>. All rights reserved.}
\fancyfoot[C]{\footnotesize\color{muted}<Course> <Doc Name>\ifdef{\leftmark}{ \textperiodcentered\ \leftmark}{}}
\fancyfoot[R]{\footnotesize\color{muted}\thepage}
```

For the course notes specifically, `\leftmark` adds the current section title, which is valuable for a 40-70pp doc.
