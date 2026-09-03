# 56 — Single-step `single_step()` grammar freeze (n≫6 ordinary defaults)

> **STATUS: BOOLE-FROZEN 2026-09-03 — names + ordinary-default engine route only.**
> This is the 0.8 / design-41 §3 item 6 artifact (auto-routing predicate +
> argument names) scoped to **what the n≫6 recovery gate actually fitted**.
> It is a **precondition** of any later `V2-SSHINV` covered flip, not a
> follow-up and **not the flip**. Maintainer ratification is still required
> before any covered flip (R twin `docs/design/41-lane-goal-to-1.0.md` §5).
> Design-51 already fences `single_step(...)` out of the 0.7 GREML claim.
> Design-54 is the FA sibling; this file does not cover FA.

## Purpose and scope

The n≫6 gate on HSquared.jl PR [#295](https://github.com/itchyshin/HSquared.jl/pull/295)
banked a known-truth single-step REML recovery PASS at freeze SHA `8e6e038b`
(result recorded after the run; 48/48 converged; σ²a and σ²e `|bias| ≤ 2·MCSE`).
That run used the **Julia engine API**, not an R formula.

This freeze pins two things so a later flip cannot drift:

- **(A)** the engine-route predicate for the ordinary-default construction
  the gate actually exercised;
- **(B)** the user-facing argument names for that path, plus the reserved
  `single_step()` spellings so the name cannot wander.

It does **not** implement a new R parser, does **not** activate a default-path
`single_step()` fit, and does **not** promote `V2-SSHINV` or the R capability
row.

The **covered numeric claim**, if a later packet ever flips, is scoped to the
n≫6 cell: univariate Gaussian REML, `τ = ω = 1`, `blend_weight = ridge = 0`,
`G = A₂₂ + 0.05 I` (the A₂₂-plus-shift form the gate and the AGHmatrix
Hmatrix packet used — **not** VanRaden). The grammar may *name* other knobs
and marker-built `G`; those stay experimental.

---

## A. Auto-routing predicate (n≫6-supported)

### A.1 What the n≫6 gate actually ran

The gate called the dense single-step REML fitter with caller-supplied
pedigree relationship, pedigree inverse, and a genotyped-block `G` that is
a shifted copy of `A₂₂`:

```julia
G = A[g, g] + 0.05 I          # A₂₂ + shift; NOT VanRaden; NOT G = A₂₂
Hinv = single_step_inverse(Ainv, A, G, g;
                           tau = 1.0, omega = 1.0,
                           blend_weight = 0.0, ridge = 0.0)
fit_single_step_reml(y, X, Z, Ainv, A, G, g;
                     tau = 1.0, omega = 1.0,
                     blend_weight = 0.0, ridge = 0.0)
```

Construction identity (Aguilar et al. 2010; Christensen & Lund 2009):

```text
H⁻¹ = A⁻¹ + scatter(τ G_w⁻¹ − ω A₂₂⁻¹)    over genotyped rows g
G_w = (1 − blend_weight)·G + blend_weight·A₂₂ + ridge·I
```

At the frozen ordinary defaults (`τ = ω = 1`, `blend_weight = ridge = 0`)
this is `G_w = G` and `H⁻¹ = A⁻¹ + scatter(G⁻¹ − A₂₂⁻¹)`.
`A₂₂⁻¹` is `inv(A[g, g])`, **not** `(A⁻¹)[g, g]`.

Pass objects were σ²a and σ²e (`docs/dev-log/recovery-checkpoints/2026-09-03-v08-ss-n-recovery-gate-predeclaration.md`).
Derived h² = σ²a / (σ²a+σ²e) was **reported, not gated**.

### A.2 Frozen engine dispatch key

The ordinary-default single-step engine target is selected **iff** every
clause holds:

```text
route → fit_single_step_reml(...; tau=1, omega=1, blend_weight=0, ridge=0)   ⟺
    univariate numeric response                              # (1)
  ∧ family = gaussian() / identity                           # (2)
  ∧ primary = single_step construction from (Ainv, A, G, g)  # (3)
  ∧ no second effect / iid / rr(...) / metafounder Γ         # (4)
  ∧ tau = 1 ∧ omega = 1                                      # (5)
  ∧ blend_weight = 0 ∧ ridge = 0                             # (6)
  ∧ G is the genotyped-block relationship (same order as g)  # (7)
  ∧ G form for a covered-claim cell = A₂₂ + 0.05 I           # (8)
```

Clauses (1)–(4) fence the gate’s univariate pedigree+genotyped construction.
Clauses (5)–(6) are the ordinary defaults the gate and the AGHmatrix
Martini `τ=ω=1` packet actually used. Clause (7) is the engine argument
`G` — a supplied genotyped-block relationship, **not** a marker matrix.
Clause (8) is the covered-flip cell guard: the gate’s `G = A₂₂ + 0.05 I`
is the same estimand as the AGHmatrix Hmatrix packet. Other `G` recipes
(VanRaden markers, raw `G = A₂₂`, APY, blended/ridged `G_w`) may still
run as experimental.

**R today:** `single_step(1 | id, Hinv = Hinv)` is opt-in supplied
precision (`target = "single_step"`). `single_step(1 | id, pedigree = ped,
markers = M)` is opt-in construction (`target = "single_step_construct"`)
that builds **VanRaden** `G` — a different estimand from clause (8).
This freeze **does not** authorise default-path auto-route of either
spelling, and it **does not** treat `markers = M` as the covered-claim
grammar.

### A.3 Formula auto-route — names frozen, default path not authorised

The reserved / already-parsed spellings are:

```r
# supplied precision (name frozen; gate did not use this path)
single_step(1 | id, Hinv = Hinv)

# construction (name frozen; R currently builds VanRaden G from markers)
single_step(1 | id, pedigree = ped, markers = M)
```

**Frozen as names** so later slices cannot invent `ssgblup()`, `ss()`,
`hinv()`, `Hmatrix()`, or `relmat(..., H = )` for this structure.

**Not frozen as a dispatch:**

- Default-path auto-route from `single_step(...)` is **not authorised**.
  Design-51 already keeps the term fenced off the 0.7 default genomic
  route. Stay opt-in (`engine = "julia"` + the matching target) until an
  R-public §3 packet.
- Julia `single_step()` remains a planned-not-implemented marker
  (`src/planned_terms.jl`); it does not construct `H⁻¹`.
- `markers = M` construction stays a **name**. It is **not** the n≫6
  covered-claim cell (VanRaden mixes `V2-GRM`).
- Metafounder `group =` / `Gamma =` stays out (the gate rejected `H^Γ`).
- `hs_data()` pedigree/genotype shorthand is a deferred ergonomic default,
  not a new engine term.

When a later slice implements a formula that matches the gated estimand,
the ordinary-default knobs **must** map to `tau = 1`, `omega = 1`,
`blend_weight = 0`, `ridge = 0`, and a covered-claim `G` **must** be the
A₂₂-plus-shift form (or a new freeze must be written). That mapping is
frozen; the implementation date is not.

---

## B. Frozen argument names

### B.1 Engine surface (n≫6-live)

| Surface | Frozen spelling | Notes |
| --- | --- | --- |
| Constructor | `single_step_inverse` | `H⁻¹`; public wrapper over `_single_step_Hinv` |
| Supplied-variance fit | `fit_single_step` | Henderson MME at given (σ²a, σ²e) |
| REML fit | `fit_single_step_reml` | the n≫6 gate fitter |
| Pedigree inverse | `Ainv` | dense/validation-scale `A⁻¹` |
| Pedigree relationship | `A` | dense `A`; `A₂₂ = A[g, g]` |
| Genomic block | `G` | square of `length(genotyped_rows)`; **not** a marker matrix |
| Genotyped index | `genotyped_rows` | pedigree-row positions `g` |
| Scaling | `tau`, `omega` | ordinary defaults **1**, **1** |
| Blend / ridge knobs | `blend_weight`, `ridge` | ordinary defaults **0**, **0** |
| Method | REML | `REML = TRUE` / `method = :REML` for the claim cell |
| Family | Gaussian identity | univariate |

R expert-control shape (names frozen; **default path still rejects**):

```r
engine_control = list(target = "single_step")            # supplied Hinv
engine_control = list(target = "single_step_construct")  # pedigree + markers
```

Knob names on the construction payload are `tau`, `omega`,
`blend_weight`, `ridge` — not `τ`/`ω`/`c`/`λ`, not `alpha`/`beta`.

### B.2 Planned / reserved formula surface (name freeze)

| Surface | Frozen spelling | Status |
| --- | --- | --- |
| Term | `single_step(...)` | reserved in Julia; parsed opt-in in R |
| Supplied precision | `Hinv = Hinv` | also accepts `H` as an alias in R; name is `Hinv` |
| Construction pedigree | `pedigree = ped` | required on the construct path (bundle shorthand deferred) |
| Construction markers | `markers = M` | **name only**; VanRaden `G` is **not** the n≫6 cell |
| Ordinary knobs | `tau = 1`, `omega = 1`, `blend_weight = 0`, `ridge = 0` | defaults the gate covered |
| Not this structure | `metafounder(..., Gamma =)` / `group =` | sibling; out of this freeze |
| Not this structure | `genomic(1 \| id, ...)` | design-51 GREML freeze |

Do **not** name the single-step term `relmat()` or `precision()` — those
are custom-kernel markers.

### B.3 Extractor / payload names (re-pinned, not new)

| Frozen as identified | Not identified / not a covered claim |
| --- | --- |
| `variance_components` (`σ²a`, `σ²e`) | h² as a gated object (reported only) |
| `breeding_values` / `EBV` labelled by pedigree ids | marker-effect SNP-BLUP |
| `converged` | interval calibration |
| construction knobs `tau`, `omega`, `blend_weight`, `ridge` | non-default τ/ω/blend/ridge recovery |

---

## C. Frozen vs still draft

**Boole-frozen (this document):**

1. Engine names: `single_step_inverse`, `fit_single_step`,
   `fit_single_step_reml`.
2. Knob names and ordinary defaults: `tau = 1`, `omega = 1`,
   `blend_weight = 0`, `ridge = 0`.
3. Engine dispatch key §A.2 (clauses (1)–(8)).
4. Formula term `single_step` and the reserved `Hinv` / `pedigree`+`markers`
   spellings (names only).
5. Covered-claim cell **if** a later flip happens: univariate Gaussian
   REML, `G = A₂₂ + 0.05 I`, those ordinary knobs. Other `G` recipes and
   non-default knobs stay experimental.
6. Pass objects σ²a and σ²e only. h² is derived (design-41 §3.3).

**Still draft (may change without a deprecation cycle):**

- Default-path auto-route from `single_step(...)`.
- Julia `single_step()` becoming a live constructor.
- `markers = M` → VanRaden `G` as a covered single-step claim.
- A formula spelling that takes supplied `G =` (not yet a parsed argument;
  do not invent it here as a required name).
- Metafounder `H^Γ`, APY, sparse production `H⁻¹`.
- Non-default `τ`/`ω`/`blend`/`ridge` (G7 retained debt).
- R catch-up / element-wise parity for the n≫6 cell.
- Interval coverage prereg.
- Any `partial → covered` row, count 7→8, or experimental 0.8.0.

---

## D. What this freeze does NOT cover

- **It is not the implementation.** Activating Julia `single_step()` or a
  default-path R route are later slices under this contract.
- **It does not promote anything.** `V2-SSHINV` stays **partial**.
  `public_covered_count` stays **7**. Experimental version stays **0.7.0**.
- **It does not replace design-51.** GREML `genomic()` remains the 0.7
  freeze. `single_step(...)` stays fenced off that claim.
- **It does not replace design-54.** FA is a sibling lane.
- **It does not sign Darwin, a second fit-level comparator, or no-anchor.**
  Those are other Rose §3 items. Construction AGREE vs AGHmatrix
  (`max|Hinv Δ| = 4.24e-12`, τ=ω=1) is G3, not this freeze.
- **It does not treat n=6 construction smoke as a gate.**

---

## E. Verification (when a later slice implements under this freeze)

1. Julia `single_step_inverse` / `fit_single_step_reml` still use the
   §B.1 names and ordinary defaults `tau = 1`, `omega = 1`,
   `blend_weight = 0`, `ridge = 0`.
2. R `target = "single_step"` / `"single_step_construct"` either still
   require opt-in, or — after a later §3 packet — map to the same engine
   call. No third token (`"ssgblup"`, `"hinv"`, `"ss"`) is accepted.
3. A covered-flip packet that cites this freeze must keep the n≫6 cell
   (`G = A₂₂ + 0.05 I`, ordinary knobs) or write a new freeze.
4. `markers = M` must not silently become the covered-claim `G` form.

---

## F. Open questions (not silently frozen)

1. **Default-path formula route.** When an R-public packet exists, does
   `single_step(...)` on `engine = "fit"` auto-select the construct
   target, or stay opt-in? **Not frozen.** The n≫6 gate never touched
   the default path. Proposal: keep opt-in until that packet.
2. **Supplied-`G` formula argument.** R construction today takes
   `markers`, not `G`. A later name for caller-supplied `G` (the gate’s
   actual input) is **not frozen** here — inventing it would outrun the
   parser. The engine argument remains `G`.
3. **Maintainer ratification.** Design-41 §5 requires a maintainer nod
   before this freeze can be cited as the flip gate. Boole has frozen
   the names; the nod is a later human step.

---

## Ratification

- **Boole (formula/API freeze):** **FROZEN 2026-09-03** — §A.2 engine
  predicate and §B names, scoped to the n≫6 ordinary-default cell.
  Formula `single_step()` spellings are a **name** freeze only.
- **Maintainer:** **RATIFIED 2026-09-03 — Shinichi** (`nod SS Boole` /
  `nod both Boole`). Owner authorization: *"please go ahead and merge
  what you need to do - and I approve to keep going"*. Freeze SHA
  **`17cd2e1b`**. Grammar ink only. Parser / default-path auto-route /
  R activation stay **draft**. **Not** a covered flip. Count stays **7**.
  Experimental stays **0.7.0**.
- **Darwin / Rose CLEAN / second fit-level comparator / no-anchor:**
  other packets. Not this file.

Cross-links: design-38 (unstructured MV); design-51 (GREML; fences
`single_step`); design-54 (FA sibling); design-41 §3 item 6; n≫6
predeclaration
`docs/dev-log/recovery-checkpoints/2026-09-03-v08-ss-n-recovery-gate-predeclaration.md`;
AGHmatrix construction packet `comparator/aghmatrix_hmatrix/`.
R twin copy of this file when a later R-lane slice lands it.
