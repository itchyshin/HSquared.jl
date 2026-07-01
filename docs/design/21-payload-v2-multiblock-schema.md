# 21 · Bridge payload v2 — multi-block random-effect schema (FREEZE-READY)

**Status: FREEZE-READY (Phase 0 / P0.1 + P0.2). Reconciled against the actual
bridge — awaiting the ratification handshake commit.** This is the Julia lane's
frozen extension of the R→Julia bridge contract to carry an ordered list of
random-effect blocks (independent effects, coefficient-covariance / random-slope
blocks, and a correlated 2×2 direct–maternal block). It is the single upfront
handshake (sync **S0**) the generality-gap programme depends on — see the
ultraplan and `docs/design/03-engine-contract.md` (the v0.1 contract this
extends). This revision reconciles the earlier DRAFT with the concrete shapes
that already exist in `hsquared/R/bridge-payload.R`, `hsquared/R/julia-bridge.R`,
and the engine functions in `HSquared.jl/src/likelihood.jl` /
`src/multivariate.jl`; where the draft contradicted the live bridge, the live
bridge wins and the contradiction is flagged in §9.

**Ratification rule (Shannon):** a field name, unit, or shape here is NOT ratified
until a mirrored-issue GitHub comment (Julia #5/#6 ↔ R #5) uses the keyword
**RATIFIED** and is cross-linked by the R lane. Neither lane builds the v2 parser
(P0.3, Julia) or the v2 emitter (P0.4, R) against these names until then. This
doc is the proposal text for that comment; §8 tracks the freeze checklist.

**Direction:** one-way **R → Julia** (JuliaCall; Julia never calls R). R builds
every `Z`, `Phi`, and pedigree-row table and all metadata; Julia builds only the
relationship inverses it is told to (`relmat_status = "build_in_julia"`). No Julia
object flows back into the request payload. This matches the current bridge:
`Ainv` is always `NULL` on the R side today (`bridge-payload.R:89`,
`bridge-payload.R:137` sets `metadata$ainv_status = "build_in_julia"`).

**Honesty:** this is a *contract only*. It ships no estimator, activates no R
formula, and makes no capability claim. `public_covered_count` stays 1.
Engine-covered ≠ R-public-covered.

---

## 1. Why v2

The v0.1 request payload (`03-engine-contract.md` §"Current R Bridge Handoff")
carries a **single** random effect: one `Z` (sparse `dgCMatrix`) + `Ainv = NULL`
(built in Julia from `pedigree`). That is exactly one pedigree animal effect
(`bridge-payload.R:29-35` builds the single `Z`; `:101-108` carries the pedigree
rows). The bridge already grew ONE ad-hoc second slot — `Z2` + `effect2`
(`bridge-payload.R:41-63`) — to feed the two-effect / maternal-genetic / common-
environment estimators, but that is a *hard-coded pair*, not a general list, and
it cannot express three effects, a coefficient covariance, or a correlated 2×2
`G`. v2 replaces the ad-hoc `Z`/`Z2` pair with an **ordered list of blocks**,
while preserving the v0.1 single-pedigree payload byte-for-byte via the alias in
§4. It does NOT invent a parallel scheme: the top-level scalar/vector fields
(`y`, `Y`, `X`, `method`, `family`, `n_trials`, `ids`, `pedigree`, `metadata`)
stay exactly as `bridge-payload.R` emits them today; only the random-effect
carrier changes.

**What already exists (build on, do not re-invent).**

| Concern | Already in the bridge | File:line |
| --- | --- | --- |
| Single pedigree `Z` (record→animal incidence) | built from `id_index` | `bridge-payload.R:29-35` |
| `Ainv = NULL`, built in Julia | `ainv_status="build_in_julia"` | `bridge-payload.R:89,137` |
| Pedigree rows for Julia `Ainv` | `id/sire/dam/*_index/original_order` | `bridge-payload.R:101-108` |
| A *second* effect (2-effect / maternal / common-env) | `Z2` + `effect2 = {type,group,levels,relationship}` | `bridge-payload.R:41-63` |
| Supplied relationship inverse (`Ginv`/`Hinv`) primary | separate builder | `bridge-payload.R:165-292` |
| Random-regression descriptor | `random_regression` + `metadata$random_regression` | `bridge-payload.R:70,88,119-128` |
| Sparse CSC marshalling into Julia | `hs_julia_assign_sparse_csc()` / `sparse_csc_matrix()` | `julia-bridge.R:535,892`; `03-engine-contract.md` §"Sparse CSC" |
| Per-target Julia dispatch (no generic caller yet) | `hs_fit_julia_*_payload()` | `julia-bridge.R:858` (two-effect), `:1011` (mv), etc. |

The v2 change is therefore: **generalize the `Z`/`Z2`/`effect2` trio into
`random_effects = [block, …]`**, and add the block fields the four estimators
need. The top-level shape is otherwise unchanged.

## 2. Request payload v2 (R → Julia)

Top-level fields are **unchanged** from what `bridge-payload.R` emits today:
`y` (or `Y` for multivariate), `X`, `method`, `family`, `n_trials`, `ids`,
`pedigree`, `metadata`, plus the `class = c("hs_bridge_payload","list")` wrapper.
The single structural change:

- The v0.1 top-level `Z` and the ad-hoc `Z2`/`effect2` become **elements of a new
  ordered list** `random_effects`.
- `Z` (and `Ainv = NULL`) are **retained as a back-compat alias** (§4), so an
  existing single-pedigree payload is byte-identical.
- A new top-level scalar `payload_version = 2L` tags v2 payloads; its absence (or
  `1L`) means the legacy flat shape.

```
payload_version = 2L
random_effects  = list(block_1, block_2, ...)   # ordered; block order is stable and result-labelling-significant
```

Each `block_i` is a plain named `list` (an R list → a Julia `Dict`/`NamedTuple`;
"boring payload only", `12-bridge-compatibility.md` §Discipline). Fields not
applicable to a block `type` are `NULL`/absent.

| Field | Type (R → Julia) | Applies to | Meaning |
| --- | --- | --- | --- |
| `name` | string | all | term name for result labelling (e.g. `"animal"`, `"litter"`, `"maternal"`). Replaces the draft's `label`; `name` matches the `effect2$group`/`type` vocabulary already in the bridge. |
| `type` | string | all | `"pedigree"` \| `"iid"` \| `"coefcov"` \| `"correlated"` (see §3). |
| `Z` | `dgCMatrix` (CSC) | all | `n × q_i` record→level incidence (base incidence for `coefcov`; the DIRECT incidence for `correlated`). Marshalled by `hs_julia_assign_sparse_csc()`. |
| `relmat_inverse` | `dgCMatrix` \| `NULL` | all | supplied precision, or `NULL` when Julia builds it. Mirrors the current always-`NULL`-for-pedigree convention. |
| `relmat_status` | string | all | `"build_in_julia"` \| `"identity"` \| `"supplied"`. |
| `pedigree` | rows \| `NULL` | `pedigree`, `correlated` | pedigree rows for Julia to build `Ainv`; SAME record shape as top-level `pedigree` (`id, sire, dam, sire_index, dam_index, original_order`). For v0.1 parity this stays at top level too (§4). |
| `ids` | character/int vector \| `NULL` | all | the `q_i` level ids for this block (the engine's per-effect `ids`/`ids1`/`ids2` argument). For a pedigree block these are the normalized `ped.ids`. |
| `basis` | string \| `NULL` | `coefcov` | `"raw"` (an `(x\|g)`-style raw slope) \| `"legendre"` (`rr()`). |
| `order` | int \| `NULL` | `coefcov` | `k` = number of basis columns (`k=2` = intercept+slope). |
| `Phi` | dense `n × k` matrix \| `NULL` | `coefcov` | per-record basis rows φ(sᵣ)ᵀ (R builds it, as `random_regression` does today). |
| `covariate` | string \| `NULL` | `coefcov` | source covariate name, for labelling/re-standardization (matches `metadata$random_regression$covariate`). |
| `covariate_bounds` | `c(lower, upper)` \| `NULL` | `coefcov` | recorded standardization bounds (matches `random_regression$lower/upper`). |
| `cov_structure` | string \| `NULL` | `coefcov` | `"unstructured"` \| `"diagonal"`. |
| `partner_incidence` | `dgCMatrix` \| `NULL` | `correlated` | the SECOND incidence `Z_m` (dam) sharing this block's relationship; the engine's `Zm`. |
| `partner_name` | string \| `NULL` | `correlated` | label for the partner sub-effect (e.g. `"maternal"`), so the result can label direct vs maternal. |

**Notes (each tied to the engine argument it feeds).**
- `type = "iid"` ⇒ `relmat_status = "identity"`; Julia uses `I` (never
  materializes the `q_i × q_i` identity). This is exactly how the current
  two-effect bridge synthesizes `Ainv2` for a common-env effect
  (`julia-bridge.R:903-908` builds a sparse identity in Julia). For v2, the
  emitter sends `relmat_status = "identity"` and lets the parser build `I`.
- `type = "pedigree"` ⇒ `relmat_status = "build_in_julia"` + `pedigree` rows +
  `ids = ped.ids` (the v0.1 mechanism; `julia-bridge.R:912-914` normalizes the
  pedigree and builds `Ainv` in Julia).
- `type = "coefcov"` (random slope / reaction norm) ⇒ genetic precision block is
  `kron(relmat_inverse_i, inv(K_i))` over the face-splitting design
  `W_i = _rr_random_design(Phi_i, Z_i)` (the existing RR path,
  `src/random_regression.jl:276`, arg order `(Phi, Z)`). `relmat_inverse_i` is
  `Ainv` (pedigree) or `I`.
  This is a v2 *slot*; the RR estimator is already partial, but no multi-block
  `coefcov` estimator is wired yet — see §6.
- `type = "correlated"` (direct–maternal) ⇒ feeds
  `fit_direct_maternal_reml(y, X, Zd, Zm, Ainv; …)` (`likelihood.jl:1072`):
  `Z` → `Zd`, `partner_incidence` → `Zm`, one relationship `A = relmat_inverse⁻¹`,
  a 2×2 `G_dm`; precision `kron(G_dm, A)` on `[a_d; a_m]`. Frozen here so the slot
  is stable; the estimator exists (`likelihood.jl:1136` returns `G_dm`,
  `genetic_correlation`, `direct_effects`, `maternal_effects`).

## 3. Grammar-term → block mapping

This table is the R-lane emitter contract. **Only the rows whose R term is
actually parsed today are live**; the rest are frozen slots (flagged). See §9 for
the drift note: the R parser does NOT accept a bare `(1|g)` / `(x|g)` / `(x||g)`;
its only second-effect vocabulary is `permanent()` / `common_env()` /
`maternal_genetic()` with an `animal()` primary (`model-spec.R:238-244`,
`:2117-2135`).

| R term (as parsed) | parsed today? | `type` | `Z` | `relmat_status` | partner / basis |
| --- | --- | --- | --- | --- | --- |
| `animal(1 \| id, pedigree=ped)` | yes | `pedigree` | id incidence | `build_in_julia` | — |
| `permanent(1 \| id)` | yes | `iid` | shares animal incidence | `identity` | — (repeatability = animal + permanent) |
| `common_env(1 \| group)` | yes | `iid` | group incidence | `identity` | — |
| `maternal_genetic(1 \| dam)` | yes | `pedigree` | dam-as-animal incidence | `build_in_julia` (shares the animal `Ainv`) | — (two INDEPENDENT pedigree effects via `fit_two_effect_reml`) |
| `genomic(1 \| id, Ginv=Ginv)` | yes (opt-in) | `pedigree`-like w/ supplied | id incidence | `supplied` | — (uses the separate relinv builder) |
| `animal(rr(t, k) \| id, pedigree=ped)` | yes (opt-in) | `coefcov` | id incidence | `build_in_julia` | `basis="legendre"`, `Phi`, `order=k` |
| `maternal_genetic(...)` as CORRELATED direct–maternal 2×2 `G` | **NO — frozen slot** | `correlated` | animal incidence | `build_in_julia` | `partner_incidence` = dam, 2×2 `G` |
| `(x \| g)` raw random slope | **NO — frozen slot** | `coefcov` | base incidence | `identity` | `basis="raw"`, `Phi=[1,x]`, `K` 2×2 |

Fixed-effect richness (`a:b`, `a*b`, `poly()`, `I()`) is **not** a payload change
— R's `model.matrix` expands it into `X` columns; the engine is formula-blind
(unchanged from v0.1: `model-spec.R:200` builds `X` via `model.matrix`).

**Important reconciliation:** today `maternal_genetic()` is dispatched as the
*independent* second effect of `fit_two_effect_reml` (two pedigree effects, no
`σ_dm` covariance; `julia-bridge.R:896-900` sets `Ainv2 = Ainv`, `bridge_target`
`fit_two_effect_reml`, `model-spec.R:243`). The `correlated` block (a true 2×2
`G_dm` via `fit_direct_maternal_reml`) is a DIFFERENT model and a DIFFERENT
estimator. v2 freezes both so the R lane can later choose which one
`maternal_genetic()` maps to (or add a `cov=` argument to distinguish), without a
second contract change. Do not conflate them.

## 4. Back-compat alias (mandatory)

A v0.1 request (single `animal(1|id)`) must remain **byte-identical** through v2:

- R may still send top-level `Z` / `Ainv`(=NULL, `ainv_status="build_in_julia"`)
  with NO `payload_version` (or `payload_version = 1L`) and NO `random_effects`.
  The Julia parser treats this as
  `random_effects = [{name:"animal", type:"pedigree", Z, relmat_status:"build_in_julia", pedigree, ids:ped.ids}]`.
- Equivalently, a `payload_version = 2L` payload whose `random_effects` list has
  exactly one `pedigree` block and nothing else must produce output identical to
  the v0.1 path (same estimator call, same `result_payload`).
- The current two-effect payload (`Z` + `Z2` + `effect2`) is ALSO honored during
  the transition: the parser MAY accept it and internally lift `{Z}` +
  `{Z2, effect2}` into a two-block list, so the R lane can migrate the emitter
  after the parser lands (no lockstep-flip requirement). This is a transition
  convenience, not a permanent second scheme; once the R emitter sends
  `random_effects`, the `Z2`/`effect2` slots are retired.
- **Parity test (P0.5 / P1.3):** the v0.1 fixture routed through the v2 parser
  yields byte-identical `result_payload` legacy fields (§5 fast path). A second
  parity test does the same for the current two-effect fixture.

## 5. Result payload v2 (Julia → R)

The v0.1 `result_payload` field names (`03-engine-contract.md` §"R Result Payload
Contract") stay stable for the single-pedigree-block case. Those names are
consumed by the R normalizer `hs_normalize_julia_result()` and the S3 extractors;
the multi-effect / multivariate normalizers already read a *different* shape
(`hs_normalize_two_effect_result()` `julia-bridge.R:955`,
`hs_normalize_multivariate_result()` `:1132`). v2 unifies these under one
block-structured result for genuinely multi-block fits.

```
variance_components = (
  residual = σ_e2,                       # ALWAYS present (matches every current estimator's sigma_e2)
  blocks = [
    (name="animal", type="pedigree",  variance=σ_1),
    (name="litter", type="iid",       variance=σ_2),
    (name="slope",  type="coefcov",   K=<k×k>, correlation=<k×k>, variances=diag(K)),
    (name="maternal", type="correlated", G=<2×2>, correlation=r_am,
                                        direct_variance=σ_ad, partner_variance=σ_am, covariance=σ_dm),
  ],
)
random_effects = [
  (name="animal", ids=[...], values=[...]),                          # scalar block → vector
  (name="slope",  ids=[...], values=<q×k matrix>, basis=("legendre",k)),  # coefcov → matrix
  (name="maternal", ids=[...], direct=[...], partner=[...]),         # correlated → two vectors
]
heritability = <scalar for single-pedigree; NA + curve pointer for coefcov; labelled direct-vs-total for correlated>
prediction_error_variance / reliability = (ids, values)             # pedigree block(s) first
loglik, df, nobs, converged, diagnostics                            # unchanged top-level scalars
```

Field-name reconciliation with the live estimators (so the parser can populate
`blocks` directly from the estimator's `NamedTuple`):

| Result block field | Source estimator field | File:line |
| --- | --- | --- |
| `blocks[i].variance` (independent) | `variance_components.sigmas[i]` / `.sigma1`/`.sigma2` | `likelihood.jl:1012`, `:799` |
| `residual` | `variance_components.sigma_e2` | every estimator |
| `blocks[correlated].G` / `.direct_variance` / `.partner_variance` / `.covariance` / `.correlation` | `variance_components.G_dm` / `.sigma_ad` / `.sigma_am` / `.sigma_dm` / `genetic_correlation` | `likelihood.jl:1137-1144` |
| `random_effects[i].values` (independent) | `effects[i].values` / `effect1`/`effect2` | `likelihood.jl:1015`, `:803-804` |
| `random_effects[correlated].direct`/`.partner` | `direct_effects.values` / `maternal_effects.values` | `likelihood.jl:1146-1147` |
| `converged` / `boundary` | `converged` / `boundary` | `likelihood.jl:1017-1018` |

**Single-pedigree-block fast path:** when there is exactly one pedigree block and
nothing else, populate the *legacy flat* fields (`variance_components.sigma_a2`,
`random_effects.animal.ids/values`, scalar `heritability`, `df`, `nobs`) exactly
as v0.1, so `hs_normalize_julia_result()` and all existing R S3 extractors return
byte-identical output. Only genuinely multi-block fits return the block-list
shape. (Naming note: the legacy flat field is `sigma_a2`; the block field is
`variance`. The fast path emits `sigma_a2`; the block list emits `variance`.
Keep both — do not rename the legacy field.)

**Interpretation fences (carried on the payload, per Kirkpatrick/Falconer; these
match the engine's own docstring fences):**
- `coefcov` h² is **covariate-indexed** (a curve), never a single scalar.
- `correlated` reports **labelled direct-vs-total** additive variance; a bare h²
  is never emitted for a direct–maternal fit (the engine docstring at
  `likelihood.jl:1064-1067` states this fence explicitly).
- Any variance at a boundary (`σ_i → 0`, `|r| → 1`) is flagged via `boundary` /
  `converged`; ratios refuse or flag rather than returning a misleading number.

## 6. Engine parser contract (P0.3, Julia side)

The v2 parser is a **thin normalizer + dispatcher**, not a new estimator. It maps
`random_effects` → the existing estimator call, then wraps the estimator's
`NamedTuple` into the §5 result shape. It adds NO fitting capability.

Dispatch rule (by the multiset of block `type`s):

| `random_effects` shape | Estimator called | Signature (already exists) |
| --- | --- | --- |
| one `pedigree` block, nothing else (or v0.1 alias) | `fit_animal_model` / `fit_ai_reml` | `(y, X, Z, Ainv; ids, method)` — v0.1 |
| two independent blocks (`pedigree`/`iid` × 2) | `fit_two_effect_reml` | `(y, X, Z1, Ainv1, Z2, Ainv2; initial, ids1, ids2)` `likelihood.jl:757` |
| `K ≥ 2` independent blocks | `fit_multi_effect_reml` | `(y, X, effects; initial, ids)`, `effects = [(Z_i, Ainv_i), …]` `likelihood.jl:952` |
| one `correlated` block (+ optional independent) | `fit_direct_maternal_reml` | `(y, X, Zd, Zm, Ainv; initial, ids)` `likelihood.jl:1072` (v1: correlated-only) |
| multivariate `Y` (one pedigree block) | `fit_multivariate_reml` | `(Y, X, Z, Ainv; …)` `multivariate.jl:778` |
| one `coefcov` block | `fit_random_regression_reml` | existing RR path (`bridge_target` `model-spec.R:234`) |

New Julia code to add for P0.3 (narrow, contract-only):
- **`src/bridge_payload_v2.jl`** (new file): `parse_payload_v2(payload)` →
  `(effects, dispatch, ids, meta)`; builds each block's relationship (`I` for
  `identity`, `pedigree_inverse(normalize_pedigree(...))` for `build_in_julia`,
  the supplied matrix for `supplied`); resolves the dispatch row above;
  `result_payload_v2(fit, dispatch)` → the §5 block-structured result with the
  §5 fast-path collapse.
- Export `parse_payload_v2` / `result_payload_v2` from `src/HSquared.jl`
  (add to the existing export block).
- The `fit_multi_effect_reml` path needs the `effects`-vector build from the block
  list (each block → `(Z_i, relmat_inverse_i)`); this reuses existing kernels, no
  new numerics.

No estimator, objective, or covariance kernel is added. The parser MUST reject a
block combination it cannot dispatch (e.g. two `correlated` blocks) with a clear
`ArgumentError`, never silently drop a block.

## 7. Emitter contract (P0.4, R side — later slice, NOT in this doc's scope)

Recorded here so the R lane knows the exact target; **do not edit the R repo as
part of freezing this doc**. `hs_build_bridge_payload()` (`bridge-payload.R:1`)
gains a `random_effects` assembler that lifts the current `Z` + `Z2`/`effect2`
construction into blocks and sets `payload_version = 2L`. The per-target callers
in `julia-bridge.R` (`hs_fit_julia_two_effect_payload()` etc.) either (a) keep
using their bespoke Julia commands during the transition (the alias in §4 lets
the parser accept the old shape), or (b) migrate to a single
`hs_fit_julia_payload_v2()` that assigns `random_effects` and calls
`HSquared.parse_payload_v2` + the dispatched estimator + `result_payload_v2`.
Option (b) is the eventual target; the alias means it need not be simultaneous
with P0.3.

## 8. Freeze checklist (RATIFICATION)

Mark each ✅ in the ratification GitHub comment; the maintainer performs the freeze
commit + handshake (not this session).

- [ ] R lane confirms `payload_version = 2L` tag + the alias contract (§4) means
  **zero** changes to existing v0.1 fits.
- [ ] R lane confirms block field names (`name`, `type`, `Z`, `relmat_inverse`,
  `relmat_status`, `pedigree`, `ids`, `basis`, `order`, `Phi`, `covariate`,
  `covariate_bounds`, `cov_structure`, `partner_incidence`, `partner_name`)
  against what its emitter can produce from the parsed spec.
- [ ] Both lanes agree on `blocks` as an ORDERED list-of-records (not a named list
  keyed by `name`) for the result payload — this matches how
  `hs_normalize_two_effect_result()` and the multivariate normalizer already index
  by position/known keys.
- [ ] Both lanes agree on `coefcov` `values` as a `q×k` matrix (matches the RR
  reaction-norm result already carried).
- [ ] `(x|g)` `K` reporting (raw covariance vs lme4 Std.Dev/Corr) is deferred to
  the Phase 3 `P3.0` convention lock and only REFERENCED here — not frozen in
  this doc, since no `coefcov` estimator consumes it yet.
- [ ] The `maternal_genetic()` → independent-vs-correlated ambiguity (§3) is noted
  as an R-lane decision, not blocked by this contract.

## 9. Drift found — draft schema vs the live bridge (each reconciled above)

Flagged during the P0.1/P0.2 reconciliation; every item is now consistent in the
text above.

1. **Bare `(1|g)` / `(x|g)` / `(x||g)` are NOT parsed by the R lane.** The old
   draft's §3 grammar table listed `(1|g)`, `(x|g)`, `(x||g)`, `rr(t,k)` as if
   they were live R terms. The R parser accepts a second random effect ONLY via
   `permanent()` / `common_env()` / `maternal_genetic()` with an `animal()`
   primary (`model-spec.R:238-244`, `:2117-2135`, `formula-status.R:57-61`); a
   bare `(1|g)` is not a term. Reconciled: §3 now marks `(x|g)` as a **frozen
   slot** (NOT parsed today), and uses the real term names for the live rows.
2. **`label` vs `name`.** The draft used `label`; the bridge's `effect2` uses
   `type`/`group` and the result normalizers key on component names like
   `"animal"`/`"common_env"`. Reconciled: the block field is `name` (§2), aligned
   with the existing result vocabulary.
3. **`maternal_genetic()` is currently INDEPENDENT, not correlated.** The draft's
   grammar row mapped `maternal_genetic` straight to `correlated`. In the live
   bridge it dispatches to `fit_two_effect_reml` as a second *independent*
   pedigree effect (`julia-bridge.R:896-900`, `model-spec.R:243`) — there is no
   `σ_dm` today. Reconciled: §3 lists BOTH the live independent row and the frozen
   `correlated` slot, and §2/§3 warn not to conflate them (they are different
   estimators: `fit_two_effect_reml` vs `fit_direct_maternal_reml`).
4. **Estimators take positional matrix args, not a `blocks` list.** The draft
   implied the engine consumes the block list directly. It does not:
   `fit_two_effect_reml(y,X,Z1,Ainv1,Z2,Ainv2)`,
   `fit_multi_effect_reml(y,X,effects)` (a vector of `(Z_i,Ainv_i)` pairs),
   `fit_direct_maternal_reml(y,X,Zd,Zm,Ainv)`. Reconciled: §6 adds an explicit
   parser layer (`parse_payload_v2`) that translates `random_effects` → these
   existing signatures; no estimator changes.
5. **`Ainv` is always `NULL` from R.** The draft's `relmat_inverse` field implied
   R sometimes sends a precision for a pedigree block. It never does for pedigree
   (`bridge-payload.R:89,137`); only the `Ginv`/`Hinv` relinv builder sends a
   supplied matrix (`bridge-payload.R:253-266`). Reconciled: §2 states
   `relmat_status = "supplied"` is the only case with a non-`NULL`
   `relmat_inverse`; `pedigree`/`iid` blocks leave it `NULL`.
6. **`iid` identity is synthesized in Julia today.** The draft said the identity
   "is never materialized". The current two-effect bridge DOES materialize a
   sparse identity, but *in Julia* (`julia-bridge.R:903-908`), from
   `relationship != "pedigree"`. Reconciled: §2 note keeps the intent (`I`, not a
   stored dense identity) and points at the existing mechanism.

## 10. What this doc does NOT do

- No estimator, no R formula activation, no covered claim (`public_covered_count`
  stays 1). The `coefcov` multi-block and `correlated`-via-`maternal_genetic()`
  paths are FROZEN SLOTS, not wired estimators.
- Does not edit the R repo (§7 is the emitter target for a later slice, P0.4).
- Supersedes nothing; extends `03-engine-contract.md`. The
  `12-bridge-compatibility.md` matrix gains a `payload_version` column when this is
  RATIFIED.
