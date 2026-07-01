# 21 · Bridge payload v2 — multi-block random-effect schema (DRAFT)

**Status: DRAFT proposal (Phase 0 / P0.1). Not yet RATIFIED.** This is the Julia
lane's *proposed* extension of the R→Julia bridge contract to carry an arbitrary
number of random-effect blocks (and, later, correlated blocks and random slopes).
It is the single upfront handshake (sync **S0**) that the generality-gap
programme depends on — see the ultraplan and `docs/design/03-engine-contract.md`
(the v0.1 contract this extends).

**Ratification rule (Shannon):** a field name, unit, or shape here is NOT
ratified until a mirrored-issue GitHub comment (Julia #5/#6 ↔ R #5) uses the
keyword **RATIFIED** and is cross-linked by the R lane. Neither lane builds a
parser/normalizer against v2 until then. This doc is the proposal text for that
comment.

**Direction:** one-way **R → Julia** (JuliaCall; Julia never calls R). R builds
`Z`, `Phi`, pedigree rows, and all metadata; Julia builds only the relationship
inverses it is told to (`ainv_status = "build_in_julia"`). No Julia object flows
back into the request payload.

**Honesty:** this is a *contract only*. It ships no estimator, activates no R
formula, and makes no capability claim. `public_covered_count` stays 1.
Engine-covered ≠ R-public-covered.

---

## 1. Why v2

The v0.1 request payload (`03-engine-contract.md` §"Current R Bridge Handoff")
carries a **single** random effect: one `Z` (sparse `dgCMatrix`) + one `Ainv`
(built in Julia from `pedigree`). That is exactly one pedigree animal effect.
Every generality-gap capability — multiple random intercepts, permanent
environment, common environment, random slopes, direct–maternal — needs **more
than one** random-effect block, and some need a *coefficient covariance* (a `k×k`
`K`) or a *correlated* block (a 2×2 `G`). v2 replaces the single `(Z, Ainv)` with
an **ordered list of blocks**, while preserving v0.1 byte-for-byte via an alias.

## 2. Request payload v2 (R → Julia)

Top-level fields `y`, `X`, `method`, `family`, `ids`, `metadata` are **unchanged**
from v0.1. The single change is: the v0.1 top-level `Z` / `Ainv` become the
**first element** of a new ordered list `random_effects`, and the top-level
`Z`/`Ainv` are retained as a **back-compat alias** (see §4).

```
random_effects = [ block_1, block_2, ... ]   # ordered; block order is stable
```

Each `block_i` is a record with these fields (fields not applicable to a block
`type` are `NULL`/absent):

| Field | Type | Applies to | Meaning |
| --- | --- | --- | --- |
| `label` | string | all | term name for result labelling (e.g. `"animal"`, `"litter"`, `"x\|herd"`) |
| `type` | string | all | `"pedigree"` \| `"iid"` \| `"coefcov"` \| `"correlated"` (see §3) |
| `Z` | `dgCMatrix` | all | `n × q_i` record→level incidence (base incidence for `coefcov`/`correlated`) |
| `relmat_inverse` | `dgCMatrix` \| NULL | all | supplied precision, or NULL when Julia builds it |
| `relmat_status` | string | all | `"build_in_julia"` \| `"identity"` \| `"supplied"` |
| `pedigree` | rows \| NULL | `pedigree`/`correlated` | pedigree rows for Julia to build `Ainv` (as v0.1) |
| `basis` | string \| NULL | `coefcov` | `"raw"` (lme4 `(x\|g)`) \| `"legendre"` (`rr()`) |
| `order` | int \| NULL | `coefcov` | `k` = number of basis columns (k=2 = intercept+slope) |
| `Phi` | dense `n × k` \| NULL | `coefcov` | per-record basis rows φ(sᵣ)ᵀ (R builds it) |
| `covariate_name` | string \| NULL | `coefcov` | source covariate, for labelling |
| `standardize` | bool \| NULL | `coefcov` | raw vs standardized covariate (lme4 raw = FALSE) |
| `cov_structure` | string \| NULL | `coefcov`/`correlated` | `"unstructured"` \| `"diagonal"` (`(x\|\|g)` = diagonal) |
| `partner_incidence` | `dgCMatrix` \| NULL | `correlated` | second incidence `Z_m` (e.g. dam) sharing the block's `relmat_inverse` |

**Notes.**
- `type = "iid"` ⇒ `relmat_status = "identity"`; the `q_i × q_i` identity is never
  materialized (Julia uses `I`).
- `type = "pedigree"` ⇒ `relmat_status = "build_in_julia"` + `pedigree` rows (the
  v0.1 mechanism).
- `type = "coefcov"` (random slope / reaction norm) ⇒ genetic precision block is
  `kron(relmat_inverse_i, inv(K_i))` over the face-splitting design
  `W_i = _rr_random_design(Z_i, Phi_i)` (the existing RR path,
  `src/random_regression.jl:276`). `relmat_inverse_i` is `Ainv` (pedigree) or `I`.
- `type = "correlated"` (direct–maternal) ⇒ one relationship `A`, two incidences
  (`Z` = direct/animal, `partner_incidence` = maternal/dam), a 2×2 `G`; precision
  `kron(inv(G), Ainv)` on `[a_d; a_m]`. Phase 4 only; drafted here so the slot is
  frozen once.

## 3. Grammar-term → block mapping

| R term | `type` | `Z` | `relmat` | `Phi`/`K`/partner |
| --- | --- | --- | --- | --- |
| `animal(1 \| id, pedigree=ped)` | `pedigree` | id incidence | build `Ainv` | — |
| `(1 \| g)` | `iid` | group incidence | `I` | — |
| `permanent(id)` | `iid` | id incidence | `I` | — (repeatability = animal+permanent) |
| `common_env(group)` | `iid` | group incidence | `I` | — |
| `(x \| g)` | `coefcov` | base incidence | `I` | `Phi=[1,x]` raw, `K` 2×2 unstructured |
| `(x \|\| g)` | `coefcov` | base incidence | `I` | `K` 2×2 diagonal |
| `rr(t, k)` | `coefcov` | id incidence | `Ainv` or `I` | `Phi`=Legendre(t,k), `K` k×k |
| `animal(x \| id)` (genetic slope) | `coefcov` | id incidence | build `Ainv` | `Phi=[1,x]`, `K` 2×2 |
| `maternal_genetic(dam, pedigree=ped)` | `correlated` | animal incidence | build `Ainv` | `partner_incidence` = dam, `G` 2×2 |

Fixed-effect richness (`a:b`, `a*b`, `poly()`, `I()`) is **not** a payload change —
R's `model.matrix` expands it into `X` columns; the engine is formula-blind.

## 4. Back-compat alias (mandatory)

A v0.1 request (single `animal(1|id)`) must remain **byte-identical** through v2:

- R may still send top-level `Z` / `Ainv`(=NULL, `ainv_status="build_in_julia"`).
  Julia treats this as `random_effects = [{label:"animal", type:"pedigree",
  Z, relmat_status:"build_in_julia", pedigree}]`.
- Equivalently, a `random_effects` list with exactly one `pedigree` block and no
  others must produce output identical to the v0.1 path.
- **Parity test (P0.5 / P1.3):** the v0.1 fixture routed through the v2 parser
  yields byte-identical `result_payload` legacy fields.

## 5. Result payload v2 (Julia → R)

The v0.1 `result_payload` field names (`03-engine-contract.md` §"R Result Payload
Contract") stay stable for the single-pedigree-block case. For multi-block fits,
`variance_components` and `random_effects` become block-structured:

```
variance_components = (
  residual = σ_e2,
  blocks = [
    (label="animal", type="pedigree",  variance=σ_1),
    (label="litter", type="iid",       variance=σ_2),
    (label="x|herd", type="coefcov",   K=<k×k>, correlation=<k×k>, variances=diag(K)),
    (label="dam",    type="correlated", G=<2×2>, correlation=r_am,
                                        direct_variance=σ_ad, maternal_variance=σ_am),
  ],
)
random_effects = [
  (label="animal", ids=[...], values=[...]),               # scalar block → vector
  (label="x|herd", ids=[...], values=<q×k matrix>, basis=("raw",k)),  # coefcov → matrix
]
heritability = <scalar for single-pedigree; NA + curve pointer for coefcov blocks>
prediction_error_variance / reliability = (ids, values)    # pedigree block(s) first
```

**Single-pedigree-block fast path:** when there is exactly one pedigree block and
nothing else, populate the *legacy flat* fields (`variance_components.sigma_a2`,
`random_effects.animal.ids/values`, scalar `heritability`) exactly as v0.1, so all
existing R S3 extractors return byte-identical output. Only genuinely multi-block
fits return the block-list shape.

**Interpretation fences (carried on the payload, per Kirkpatrick/Falconer):**
- `coefcov` h² is **covariate-indexed** (a curve), never a single scalar.
- `correlated` reports **labelled direct-vs-total** additive variance; a bare h²
  is never emitted for a direct–maternal fit.
- Any variance at a boundary (`σ_i → 0`, `|r| → 1`) is flagged; ratios refuse or
  flag rather than returning a misleading number.

## 6. What this doc does NOT do

- No estimator, no R formula activation, no covered claim (`public_covered_count`
  stays 1).
- Does not freeze the `correlated` internals beyond the slot (Phase 4 refines).
- Supersedes nothing; extends `03-engine-contract.md`. The
  `12-bridge-compatibility.md` matrix gains a `payload_version` column when this
  is RATIFIED.

## 7. Open ratification questions for the R lane

1. `variance_components.blocks` as a list-of-records vs a named list keyed by
   `label` — which does the R normalizer prefer for `VarCorr()`/`ranef()`?
2. `coefcov` `values` as a `q×k` matrix vs a list of `k` vectors for `ranef()`.
3. `(x|g)` `K` reporting: raw covariance vs lme4 Std.Dev/Corr (ties to the Phase 3
   `P3.0` convention lock — should be decided jointly there, referenced here).
4. Confirm the back-compat alias contract (§4) is sufficient for zero R-side
   changes on existing v0.1 fits.
