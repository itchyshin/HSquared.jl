# 54 — Factor-analytic grammar freeze (S4-scoped)

> **STATUS: BOOLE-FROZEN 2026-09-03 — names + engine-control route only.**
> This is the 0.8 S7 / design-41 §3 item 6 artifact (auto-routing predicate +
> argument names) scoped to **what S4 actually fitted**. It is a
> **precondition** of any later `V4-FA` covered flip, not a follow-up and
> **not the flip**. Maintainer ratification is still required before any
> covered flip (R twin `docs/design/41-lane-goal-to-1.0.md` §5). Design-38 remains
> the freeze for **unstructured 2-trait** `cbind()` only; it does not cover
> FA.

## Purpose and scope

S4 on HSquared.jl PR [#292](https://github.com/itchyshin/HSquared.jl/pull/292)
banked a known-truth FA recovery PASS (`8/10 ok_recovery` vs the frozen 8/10
bar) at tip `d8148a3a` (fit SHA `3d1de490`, S2 freeze `eff57e3d`, cell
`d4-k1`). That run used the **Julia engine API**, not an R formula.

This freeze pins two things so a later flip cannot drift:

- **(A)** the auto-routing predicate for the **engine-control** FA path that
  S4 actually exercised;
- **(B)** the user-facing argument names for that path, plus the **planned**
  `cov = fa(K = …)` spelling so the name cannot wander.

It does **not** implement R parsing of `cov =`, does **not** activate the R
bridge for `"factor_analytic"`, and does **not** promote `V4-FA` or the R
capability row.

The **covered numeric claim**, if a later packet ever flips, is scoped to the
S4 cell: **`t = 4`, `K = 1`**, Ledermann slack `> 0`, uniqueness floor
`min(ψ̂) ≥ 1e-4`, rotation-invariant `G` / `R` / `ψ`. The grammar may
*name* other `(t, K)` pairs; those stay experimental.

---

## A. Auto-routing predicate (S4-supported)

### A.1 What S4 actually ran

S4 called the dense multivariate REML fitter with a constrained genetic
covariance and unstructured residual covariance:

```julia
fit_multivariate_reml(
    Y, X, Z, Ainv;
    method = :REML,                    # implied; ML is not implemented
    genetic_structure = :factor_analytic,
    rank = 1,                          # K
)
```

Reconstruction used by the fitter and by the pass objects:

```text
G0 = ΛΛ' + Ψ          # Ψ diagonal, min(ψ) ≥ 1e-4 after S3
R0 = unstructured PD
```

Pass objects were rotation-invariant functionals of `G`, `R`, and `ψ`
(`docs/dev-log/recovery-checkpoints/2026-09-03-v08-s2-fa-recovery-gate-predeclaration.md`).
Raw loadings `Λ` were **not** a pass object
(`docs/dev-log/decisions/2026-06-19-fa-rotation-convention.md`;
R twin `docs/design/29-structured-covariance-eigenbasis-bridge-contract.md`).

### A.2 Frozen engine-control dispatch key

The FA engine target is selected **iff** every clause holds:

```text
route → fit_multivariate_reml(...; genetic_structure = :factor_analytic, rank = K)   ⟺
    multivariate cbind response, ≥ 2 numeric bare columns     # (1)
  ∧ family = gaussian() / identity                            # (2)
  ∧ primary = pedigree animal(1 | id, pedigree = ped)         # (3)
  ∧ no second effect / iid / rr(...)                          # (4)
  ∧ genetic_structure ∈ {:factor_analytic, "factor_analytic"} # (5)
  ∧ rank = K is a single integer, 1 ≤ K < t                   # (6)
  ∧ ledermann_slack = (t − K)² − (t + K) > 0                  # (7)  covered-flip cell only
  ∧ residual structure is unstructured                        # (8)
```

Clauses (1)–(4) are the design-38 multivariate fence; FA does not widen them.
Clause (5)–(6) are the S4 argument names. Clause (7) is the S2/S3 covered-flip
cell guard (`require_fa_covered_flip_cell` refuses slack ≤ 0 as a
*promotion* cell; diagnostic fits on saturated cells may still run). Clause
(8) matches the engine: structured `G0` only; `R0` stays unstructured.

**R today:** `hs_validate_genetic_structure_control()` **rejects**
`"factor_analytic"` and `rank` (`R/julia-bridge.R`). This freeze **does not**
authorise removing that reject. A later S8 bridge slice may implement the
opt-in route under this predicate. Until then the only live FA path is the
Julia engine API.

### A.3 Formula auto-route — names frozen, implementation draft

The planned formula spelling (already reserved in
`docs/src/model-spec-grammar.md` and R `formula_status()`) is:

```r
hsquared(
  cbind(y1, y2, y3, y4) ~ animal(1 | id, pedigree = ped, cov = fa(K = 1)),
  data = dat,
  family = gaussian(),
  REML = TRUE
)
```

**Frozen as a name** so later slices cannot invent `fa(2)`, `FA()`,
`factor()`, or `rr()` for this structure.

**Not frozen as a dispatch:**

- The R `animal()` parser still errors: `cov` is planned, not implemented
  (`hs_stop_animal_covariance_arg()`).
- Default-path auto-route from `cov = fa(...)` is **not authorised**.
- Long-format `animal(trait | id, cov = fa(K))` stays planned (design-38
  already left it out of the 0.6 freeze).
- Residual `residual(..., cov = fa(...))` is out of scope (S4 did not fit
  residual FA).

When a later slice implements the parser, `cov = fa(K = k)` **must** map to
`genetic_structure = "factor_analytic"` and `rank = k`. That mapping is
frozen; the implementation date is not.

---

## B. Frozen argument names

### B.1 Engine / expert-control surface (S4-live)

| Surface | Frozen spelling | Notes |
| --- | --- | --- |
| Structure token | `factor_analytic` | Julia `Symbol`; R string `"factor_analytic"` when the bridge is later opened |
| Rank | `rank` | positive integer; required iff structure is `factor_analytic` or `lowrank` |
| Reconstruction | `G0 = ΛΛ' + Ψ` | `Ψ` diagonal uniqueness; S3 floor `ψ = 1e-4 + exp(θ)` |
| Residual | unstructured `R0` | no residual-structure argument on the S4 path |
| Method | REML | `REML = TRUE` / `method = :REML`; ML not implemented |
| Primary | `animal(1 \| id, pedigree = ped)` | pedigree `Ainv`; genomic / single-step FA not in S4 |

R expert-control shape (names frozen; **bridge still rejects**):

```r
engine_control = list(
  target = "multivariate",
  genetic_structure = "factor_analytic",
  rank = 1L
)
```

`genetic_structure` is the control name, not `cov`, because this path
constrains only additive-genetic `G0` (design-18).

### B.2 Planned formula surface (name freeze only)

| Surface | Frozen spelling | Status |
| --- | --- | --- |
| FA constructor | `fa(K = k)` | named argument `K` required; `k` is the integer rank |
| Term | `animal(..., cov = fa(K = k))` | parser still rejects `cov` |
| Not this structure | `lowrank(K = k)` → `G0 = ΛΛ'` | sibling name; **not** S4; not this freeze |
| Not this structure | `us()`, `diag()` | design-38 / diagonal experimental |

Do **not** name the FA form `rr()` — that is random regression.

### B.3 Extractor / payload names (already ratified; re-pinned)

Rotation-invariant only (design-29). This freeze does not add extractors.

| Frozen as identified | Not identified / not a covered claim |
| --- | --- |
| `genetic_covariance` / `G_matrix()` (`G0`) | raw `genetic_loadings` / `loadings()` as axes |
| `residual_covariance` / `R_matrix()` | SEs on any `Λ[i,k]` |
| `genetic_uniqueness` (`ψ`) | factor-interpretation claims |
| `genetic_structure`, `genetic_rank` (`K`) | default-path `cov = fa` fitting |
| `loglik`, `converged` | interval calibration |

Per-trait `h²` and `r_g` on an FA `G` are **derived**. They are not in the
S4 pass definition and are not frozen as a covered FA claim here.

---

## C. Frozen vs still draft

**Boole-frozen (this document):**

1. Engine argument names: `genetic_structure = :factor_analytic`, `rank`.
2. Reconstruction `G0 = ΛΛ' + Ψ`, unstructured `R0`.
3. Engine-control dispatch key §A.2 (clauses (1)–(8)).
4. Formula constructor spelling `fa(K = k)` and the map `K → rank`.
5. Covered-claim cell **if** a later flip happens: `t = 4`, `K = 1`,
   slack `> 0`, `min(ψ̂) ≥ 1e-4`. Other `(t, K)` stay experimental.
6. Rotation-invariant pass objects only (`G`, `R`, `ψ`).

**Still draft (may change without a deprecation cycle):**

- R parser for `cov =`.
- Default-path auto-route from `cov = fa(...)`.
- R bridge activation of `"factor_analytic"` / `rank` (currently errors).
- Long-format `animal(trait | id, cov = …)`.
- Residual FA / residual `cov =`.
- `lowrank` as a covered sibling (design-36 §3.4: if fa resists and
  low-rank passes, ship low-rank and hold fa — that fork is unused; S4
  passed fa).
- `K > 1`, `t ≠ 4`, Ledermann-saturated `t = 3 K = 1` as a covered cell
  (S2 forbids the last).
- Loadings+SE; production sparse FA; WOMBAT parity; interval coverage.
- Any `partial → covered` row, count 7→8, or experimental 0.8.0.

---

## D. What this freeze does NOT cover

- **It is not the implementation.** Removing the R `factor_analytic` reject
  and parsing `cov = fa(K)` are later slices under this contract.
- **It does not promote anything.** `V4-FA` stays **partial**. R FA stays
  **planned** until a twin pointer says otherwise. `public_covered_count`
  stays **7**. Experimental version stays **0.7.0**.
- **It does not replace design-38.** Unstructured 2-trait `cbind()` remains
  the 0.6 freeze. FA is an additive expert-control / planned-`cov` layer.
- **It does not sign Darwin, WOMBAT, or no-anchor.** Those are other Rose
  §3 items.
- **It does not authorise loadings as biological axes.**

---

## E. Verification (when a later slice implements under this freeze)

1. Julia `fit_multivariate_reml(...; genetic_structure = :factor_analytic,
   rank = K)` still uses the §B.1 names.
2. R `engine_control$genetic_structure = "factor_analytic"` with `rank`
   either still errors as planned, or — after S8 — maps to the same engine
   call. No third token (`"fa"`, `"FA"`, `"factor"`) is accepted.
3. `cov = fa(K = 1)` either still errors as planned, or maps `K → rank`.
   `cov = fa(1)` (positional) and `cov = rr(K = 1)` must not silently
   become FA.
4. A covered-flip packet that cites this freeze must keep the S4 cell
   (`t = 4`, `K = 1`, slack `> 0`) or write a new freeze.

---

## F. Open questions (not silently frozen)

1. **Default-path formula route.** When the parser exists, does
   `cov = fa(K)` on the default `engine = "fit"` path auto-select FA, or
   stay opt-in via `engine_control`? **Not frozen.** S4 never touched the
   default path. Proposal: keep opt-in until an R-public §3 packet.
2. **`K > 1` grammar.** Parseable-and-fittable-but-experimental (same
   posture as design-38 `k ≥ 3` traits), or gated until a `K > 1` recovery
   cell exists? **Not frozen.** S4 is `K = 1` only.
3. **Maintainer ratification.** Design-41 §5 requires a maintainer nod
   before this freeze can be cited as the flip gate. Boole has frozen the
   names; the nod is a later human step.

---

## Ratification

- **Boole (formula/API freeze):** **FROZEN 2026-09-03** — §A.2 engine-control
  predicate and §B names, scoped to the S4 cell. Formula `cov = fa(K = k)`
  is a **name** freeze only.
- **Maintainer:** **pending** — required before any covered flip
  (design-41 §5). This document may sit on #292 / R #160 without that nod.
- **Darwin / Rose CLEAN / WOMBAT-or-disclosure / no-anchor:** other
  packets. Not this file.

Cross-links: design-38 (unstructured MV); design-41 §3 item 6; design-42
(S1 diagnosis, not a grammar freeze); S2
`docs/dev-log/recovery-checkpoints/2026-09-03-v08-s2-fa-recovery-gate-predeclaration.md`;
S4 `docs/dev-log/recovery-checkpoints/2026-09-03-v08-s4-fa-d4-k1.md`;
R twin copy of this file when landed on #160.
