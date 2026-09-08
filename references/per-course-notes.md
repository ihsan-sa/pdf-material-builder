# Per-course case studies

Distilled from building ECE 204 (Harder), ECE 205 (Kotecha), and ECE 250 (Huang) at University of Waterloo. Use as a pattern library when starting a new course.

## ECE 204 -- Numerical Methods (Prof Harder)

### Taxonomy
- **A** Approximating expressions (interpolation, LS, Horner, Simpson)
- **B** Algebraic equations (root finding: bisection, Newton, secant, IQI, Newton-nD)
- **C** Analytic equations (IVPs, BVPs, PDEs)
- **D** Optimization (1D: Newton on f', golden, SPI; nD: Newton-Hessian, GD)

### Seven tools
| | Tool | Used by |
|---|---|---|
| T1 | Weighted averages | Simpson, RK4, Heun avg, LS weights |
| T2 | Iteration | Newton, bisection, RK, shooting, GD |
| T3 | Linear algebra | LS, BVP FD, Laplace, Newton-nD |
| T4 | Interpolation | Derivative rules, secant, IQI |
| T5 | Taylor series | Newton derivation, error bounds, Euler |
| T6 | Bracketing | Bisection, golden-ratio |
| T7 | IVT | Bisection correctness |

### User weak areas (invest page budget here)
- nD Newton
- nD optimization
- Gradient-descent mechanics
- Higher-order -> first-order system conversion

### Banned-optional content (per Prof Harder's summary)
Brief mention OK with `[optional]` tag:
- Conditioning as its own topic
- Iterative linear solvers: Jacobi, Gauss-Seidel, SOR, condition number
- Advanced LS: jitter, growth models, Fourier
- Advanced root-finders: bracketed secant, Muller's, Brent-Dekker, implicit Newton
- Dormand-Prince specifics (general mention OK)
- Wave equation (out of scope)
- Brent's optimization, linear programming
- Hooke-Jeeves detailed algorithm (general idea OK)

### Course conventions worth preserving
- Tolerance criterion `E <= tol * h` (Harder-specific; scales error budget per step so total error over `[t_0, T]` is `tol * (T - t_0)`)
- Ghost-point accuracy is not uniform: BVP Neumann and heat-equation insulation use centered O(h^2); Laplace insulated uses first-order one-sided
- "Forward" one-sided stencil vs "backward" -- Harder uses "one-sided"

### Classic exam traps to warn about
- Richardson extrapolation sign: `z_{2n} - y(T) ~= (y_n - z_{2n})/(2^p - 1)` -- numerator is coarser minus finer
- Ghost-point Neumann: moving `p_0 * (-2h alpha)` across equals gives `+2h alpha p_0` on RHS. Mark the sign explicitly
- Local vs global order: "order-p method" means global `O(h^p)`, local `O(h^{p+1})`
- PSD vs PD: strict PD is sufficient for strict local min; PSD is necessary but not sufficient

## ECE 205 -- Advanced Calculus 1 (Prof Kotecha)

### Taxonomy
- **A** First-order ODEs (linear / VoP / integrating factor / separable / exact)
- **B** Second-order ODEs + vibrations (char roots, UC, VoP, damping cases)
- **C** Laplace (shift theorems, Heaviside, convolution, Dirac)
- **D** Fourier series, Fourier transform, heat and wave PDEs

### Six tools
| | Tool | Used by |
|---|---|---|
| T1 | Ansatz + char equation | Const-coeff ODEs, separation spatial ODE |
| T2 | Linearity + superposition | Transforms, sum of particulars for sum of forcings |
| T3 | Integration by parts | Laplace/FT derivative rules, Euler-Fourier |
| T4 | Orthogonality / eigenfns | Fourier series, PDE eigenmodes |
| T5 | Transform pairs | Table lookup, domain switching |
| T6 | Separation of variables | $u(x,t) = X(x) T(t)$ |

### Weak-area flags (ask)
Depends per student. Kotecha-specific likely candidates:
- Heaviside piecewise Laplace
- Non-homogeneous BCs in heat IBVP
- Wave with nonzero initial velocity
- Fourier-series convergence questions

### Conventions (Kotecha vs textbooks)
- **Damping coefficient**: plain $\gamma$ (not $2\gamma$ or $c$)
- **Shift theorem letter**: $b$ (Kotecha) or $c$ (Dawkins) -- pick per doc
- **Separation constant**: $-\lambda$ in $X''/X = -\lambda$
- **Wave speed letter**: $a$ (Kotecha) vs $c$ (most textbooks); pick one and enforce
- **Heat diffusivity**: $\alpha$ (to avoid clash with Kotecha's $a$ for wave speed)
- **FT prefactor**: asymmetric $1 / \frac{1}{2\pi}$ (engineering) vs symmetric $\frac{1}{\sqrt{2\pi}}$ (physics)
- **FS constant term**: $a_0/2$ (by the standard convention used in lecture)
- **IVP unknown under Laplace**: use $Y(s)$ for the transform of the IVP unknown; reserve $F(s)$ for the generic $\mathcal{L}\{f\}$ of the forcing

### Classic exam traps
- Gibbs value: cite `8.95%` (3 sig figs), not "about 9%"
- $F(s) \to Y(s)$ confusion is the #1 notation drift in Laplace worked examples

### Exam-provides-formula-sheet workflow
ECE 205's exam ships a Laplace + FT table. Build the **annotated formula sheet first** in this case (most deterministic doc); the other docs reference its entries.

## ECE 250 -- Data Structures and Algorithms (Prof Huang)

### Taxonomy
- **A** Analysis (Big-O, ADT framing)
- **B** Linear structures (lists, stacks, queues, arrays)
- **C** Trees and heaps (Tree, BST, AVL, RB, Heap/PQ)
- **D** Hashing
- **E** Sorting (7 comparison + 1 non-comparison)
- **F** Graphs (intro, BFS/DFS, Dijkstra, MST)
- **G** Paradigms (BF, Greedy, D&C, DP)

### Seven tools
| | Tool | Used by |
|---|---|---|
| T1 | Invariants | Every balanced tree, heap, Dijkstra, MST |
| T2 | Recursion / recursive descent | Tree ops, merge sort, quick sort, DFS, D&C |
| T3 | Iteration with auxiliary container | BFS queue, iterative DFS stack, Dijkstra PQ |
| T4 | Amortised reasoning | Dynamic array doubling, rehash, build-heap Floyd |
| T5 | Randomisation / average-case | Quicksort random pivot, hash uniformity |
| T6 | Rotation / local restructuring | AVL, RB, heap sift |
| T7 | Comparison / decision model | Sorting lower bound, comparison vs non-comparison |

### User weak areas
- Amortised / recurrence analysis
- Hashing (collisions, open addressing)
- Graph algorithms (Dijkstra / MST correctness)

### Huang-specific conventions (DIFFER from CLRS / STL)
- ADT method names: `numItems()` not `size()`; Queue uses `enqueue/dequeue` not `push/pop`
- `Height(leaf) = 0`, `Height(NULL) = -1`, `Depth(root) = 0`
- RB rules numbered **1-4** (not CLRS 5): the "every leaf NIL is Black" rule is folded into Rule 4 via virtual black
- Heap root at index **1** with sentinel at `data[0]`; 0-based given as alternative
- Graph adjacency type on final: **`map<int, map<int, int>>`** (outer = source, inner = dest -> weight). This is THE final-coding-question type
- Big-O only; $\Omega$ and $\Theta$ are ECE 406. **One admitted exception**: the comparison-sorting lower bound $\Omega(N \log N)$ is stated as a quoted result

### Banned-optional content
- RB deletion (L9 slide 47, explicit; cite Matt Might for the curious)
- Master Theorem (not taught; derive via recursion tree or substitution)
- Universal hashing + closed-form expected-probe counts (use `[optional]`)
- Dynamic programming *derivation* (memoization *definition* IS in scope)
- Decrease-and-conquer, transform-and-conquer, backtracking (not named as paradigms)
- AVL/RB *rotations* are midterm-only (final still tests invariant identification)
- Bellman-Ford, Floyd-Warshall, A* (out of scope)

### Classic exam traps
- Dijkstra negative-edge counter-example needs an extra edge (e.g., `B -> D:1`) to make the failure persist in final `d[]`; the simplest 3-edge graph self-corrects under lazy insertion
- Quicksort last-cell pivot is $\Oh(N^2)$ on sorted input (not in-place on adversarial data)
- BFS/DFS "path-storing" iterative variant is $\Oh(V(V+E))$ time, not $\Oh(V+E)$, because paths are copied per push and mark-on-dequeue allows multiple enqueues per vertex. To get the canonical $\Oh(V+E)$, switch to mark-on-enqueue + predecessor map
- Selection sort makes $N-1$ swaps = $3(N-1)$ element writes with a temp, not $N-1$ writes
- Primitive-op model: memory access is *slower* than addition (register adds are ~1 cycle, DRAM is ~100), not the reverse
- "Tightest upper bound in the worst case" is strictly Theta; warn students not to carry this to ECE 406 or textbooks

### Exam format note
Closed book, no formula sheet. The "formula sheet annotated" doc therefore becomes a consolidated complexity/invariant cheat sheet (role analog, not verbatim mirror).

## Pattern library for a new course

When starting a new course, use the pattern below. Answers come from the user via `AskUserQuestion` in Phase 1:

```
Course: <code>
Prof: <name>
Term: <year/stream>

Taxonomy (N categories):
  Cat A: <name> (lectures Lx-Ly)
  Cat B: <name> (...)
  ...

Seven (or N) tools:
  T1: <primitive technique>
  ...

User weak areas (get extra depth):
  - <weak area 1>
  - <weak area 2>

Prof-specific conventions (may differ from textbook):
  - <convention 1>: <value>
  - ...

Banned-optional content (treat with `\opt` or skip):
  - <topic 1>
  - ...

Exam format: <open/closed book; formula sheet y/n; coding y/n>

Classic traps (warn about these in course notes):
  - <trap 1>
  - ...
```

Fill this in at the end of Phase 1; every downstream builder prompt cites it as critical reading item #1.
