# Cross-lane handoff + implementation spec: non-Gaussian per-record varying-trial Binomial activation (#44 gate 1)

Meta: 2026-06-22 · from the Julia-lane Claude session · **to the R-twin (`hsquared`) Claude session** · status: design approved by Shinichi, **not yet implemented**, **not committed**.

> **Why this file lives in `HSquared.jl`.** Shinichi confirmed a separate R-twin
> session owns `hsquared`, so the Julia-lane session must not edit `hsquared`.
> This implementation-ready spec is therefore authored in the Julia lane (which
> this session owns) as a cross-lane handoff. The R-twin session applies the
> changes in `hsquared`. **The Julia engine is unchanged by this slice.**

## Critical context

- Public issue: **HSquared.jl #44** ("Bridge activation: non-Gaussian Laplace/VA
  families + MarginalMethod dispatch"), label `cross-lane`. Two gates remain;
  this slice is **gate 1 only**.
- Gate 1 (this slice): *per-record varying-trial R formula/bridge activation for
  the general `cbind(successes, failures)` Binomial where row totals vary.*
- The default `hsquared()` path is the covered univariate Gaussian animal model.
  This widens an already-experimental **opt-in** route (`target =
  "nongaussian"`). **Status stays `partial`. No promotion, no public default
  change, no Rose-gated covered claim.**
- **Engine is already done.** `HSquared.fit_laplace_reml(...; family = :binomial,
  n_trials = <scalar OR vector>)` dispatches via `_resolve_single_family`
  (`src/nongaussian.jl:88-97`): a vector builds `BinomialVectorResponse`, a scalar
  builds `BinomialResponse`. Per-record kernels resolve through `_fam_record`
  (`:81-82`); `_check_counts(::BinomialVectorResponse, …)` (`:177-181`) enforces
  `length(n_trials) == length(y)` and `0 ≤ y[i] ≤ n_trials[i]`. **No engine edit.**
- The **result/normalizer side in R is already vector-ready**: the parity fixture
  case `binomial_vector_variational` carries `n_trials = 2;4;5;6;10;12` and
  `hs_normalize_nongaussian_result()` preserves the vector
  (`tests/testthat/test-nongaussian.R:143-175`, `:97-102`). **No change needed
  downstream of the fit.**

## Design decisions (approved by Shinichi)

1. **Syntax:** keep the existing `binomial(logit)` + `cbind(successes, failures)`
   route; simply allow `successes + failures` to differ per record. No new public
   argument (matches the `glm()` / `lme4` idiom).
2. **Encoding:** binomial-counts payloads **always** carry a per-record integer
   `n_trials` vector of length *n* (the equal-totals case becomes a repeated
   value). One bridge code path.
3. **Scope:** gate-1 activation **plus** a written gate-2 validation plan
   (executed later). Stays `partial`.
4. **All-ones edge case:** a `cbind` whose totals are **all 1** still reduces to
   **Bernoulli** (`family` label `"bernoulli"`, no `n_trials` marshalled),
   preserving the documented reduction and its tests. Rule:
   `max(n_trials) > 1 → binomial`, else `bernoulli`.
5. **Gate-2 comparator** is `MCMCglmm` (Bayesian *agreement*, **not** same-estimand
   REML parity). `gllvm` is not an animal model; BLUPF90 categorical executables
   are absent — recorded as a blocker, not evidence.

## The block being removed (one guard)

`hsquared/R/model-spec.R::hs_build_binomial_counts_response` (`:405-456`) computes
`n_trials <- unique(totals)` and **errors when `length != 1`** (`:437-446`),
storing a **scalar**. That single guard is the gate. Everything else is making
the scalar assumption into a per-record vector end to end.

A full `grep -rn n_trials R/ tests/` sweep confirms the change set below is
**complete**: the only scalar assumptions live in `model-spec.R` (the guard +
store), `julia-bridge.R` (symbol test + marshalling + comments), `bridge-payload.R`
(pass-through), and `test-binomial-counts.R` (assertions + comments). The
result-side normalizer (`julia-bridge.R:589-661`) and the parity fixture are
already vector-safe — confirmed, no change.

---

## Implementation (R-twin applies in `hsquared`)

### Change 1 — `R/model-spec.R::hs_build_binomial_counts_response` (~`:400-456`)

- Delete the equal-totals error block (`:437-446`).
- Keep the existing validation: numeric, finite (no `NA`), non-negative integers,
  and `total ≥ 1` per record. (These already guarantee the engine's
  `0 ≤ successes ≤ total`, since `failures ≥ 0`.)
- Store the **per-record vector**: `n_trials = as.integer(totals)` (length *n*).
- Update the header comment (`:400-404`) to describe per-record trials and the
  `BinomialVectorResponse` engine path.

Resulting return list (only `n_trials` changes — now length *n*):

```r
  list(
    name = hs_deparse(lhs),
    values = as.numeric(successes),
    trait_names = if (length(trait_names) >= 1L) trait_names[[1L]] else NULL,
    multivariate = FALSE,
    binomial_counts = TRUE,
    n_trials = as.integer(totals)   # was: as.integer(unique(totals)) (scalar)
  )
```

### Change 2 — `R/bridge-payload.R` (~`:96-98`)

No logic change (pass-through `n_trials = spec$response$n_trials`). Update only the
comment, since `n_trials` is now a length-*n* vector for binomial counts and `NULL`
for Bernoulli/Poisson/Gaussian.

### Change 3 — `R/julia-bridge.R::hs_nongaussian_family_symbol` (`:438-455`)

Generalize the scalar `n_trials > 1L` test to tolerate a vector (scalar inputs
still work, so existing symbol tests pass unchanged):

```r
  if (identical(family$family, "binomial") && identical(family$link, "logit")) {
    if (!is.null(n_trials) && max(n_trials) > 1L) {   # was: n_trials > 1L
      return("binomial")
    }
    return("bernoulli")
  }
```

Update the function docstring to note `n_trials` may be a per-record vector.

### Change 4 — `R/julia-bridge.R::hs_fit_julia_nongaussian_payload` (`:538-545`)

Marshal the integer **vector** and stop scalarizing the keyword. The engine sees a
`Vector{Int}` and builds `BinomialVectorResponse`:

```r
  # A binomial-counts response carries a PER-RECORD trial-count vector; the
  # engine's _resolve_single_family builds a BinomialVectorResponse from a vector
  # (and a scalar BinomialResponse from a scalar). Bernoulli omits the keyword.
  n_trials_kw <- ""
  if (identical(family_symbol, "binomial")) {
    n_trials_int <- as.integer(n_trials)
    if (length(n_trials_int) != length(payload$y)) {
      stop(
        "Internal bridge error: binomial `n_trials` must have one entry per ",
        "record (length(n_trials) == length(y)).",
        call. = FALSE
      )
    }
    JuliaCall::julia_assign("hsq_n_trials", n_trials_int)
    n_trials_kw <- "n_trials = hsq_n_trials, "   # was: "n_trials = Int(hsq_n_trials), "
  }
```

(`JuliaCall::julia_assign` marshals an R integer vector to a Julia `Vector{Int}`;
the engine's `_resolve_single_family` then dispatches to `BinomialVectorResponse`.
A length-1 vector is still accepted — `_check_counts` requires only
`length(n_trials) == length(y)`.)

### Tests — `tests/testthat/test-binomial-counts.R`

- **Line 35** (equal-totals case): `expect_equal(spec$response$n_trials, 3)` →
  `expect_equal(spec$response$n_trials, c(3, 3, 3, 3))`.
- **Lines 40-57** (currently *"varying row totals errors clearly"*): **invert** to a
  success test:

```r
test_that("cbind(successes, failures) with varying row totals builds a per-record binomial-counts spec", {
  ped <- ped4()
  dat <- data.frame(
    succ = c(1, 2, 3, 0),
    fail = c(2, 1, 1, 3),          # totals 3, 3, 4, 3 -> per-record vector
    id = c("s", "d", "a", "b")
  )
  spec <- hsquared:::hs_build_model_spec(
    cbind(succ, fail) ~ animal(1 | id, pedigree = ped),
    data = dat, family = stats::binomial(), REML = TRUE,
    allow_families = c("gaussian", "poisson", "binomial")
  )
  expect_true(isTRUE(spec$response$binomial_counts))
  expect_equal(spec$response$n_trials, c(3L, 3L, 4L, 3L))
  expect_equal(as.numeric(spec$response$values), c(1, 2, 3, 0))

  payload <- hsquared:::hs_build_bridge_payload(spec)
  expect_equal(payload$n_trials, c(3L, 3L, 4L, 3L))   # always a per-record vector
  expect_equal(
    hsquared:::hs_nongaussian_family_symbol(stats::binomial(), payload$n_trials),
    "binomial"
  )
})
```

- **Symbol test (`:89-106`)**: add vector cases — `n_trials = c(2L, 4L, 5L)` →
  `"binomial"`; `n_trials = c(1L, 1L, 1L)` → `"bernoulli"` (all-ones reduction).
  The existing scalar cases (`1L`, `5L`) stay green under the `max()` rule.
- **Balanced live parity (`:144-146`)**: change the direct-engine eval keyword
  `n_trials = Int(hsq_n_trials)` → `n_trials = hsq_n_trials` (now a vector).
- **New skip-guarded live test** for genuinely varying trials (mirrors the
  balanced live test at `:108-148`): simulate per-record `trials <- sample(5:15, n,
  TRUE)`, `succ <- rbinom(n, trials, p)`, fit through `target = "nongaussian"`,
  and assert parity vs a direct `HSquared.fit_laplace_reml(...; family = :binomial,
  n_trials = hsq_n_trials, ids = hsq_ped.ids)` to `tolerance = 1e-6`. Guard with
  `skip_on_cran()` + `skip_if_not(hsquared:::hs_julia_bridge_available())`.

Result-side tests/fixtures (`test-nongaussian.R`, `fixtures/non_gaussian_parity/`)
are already vector-ready — **no change**.

### Docs / status wording

- `docs/design/21-nongaussian-la-va-method.md`: §0 (note `BinomialVectorResponse`
  alongside `BinomialResponse`), §2, §5; and the two "Update" notes (`:252-272`)
  that currently say per-record varying `n_trials` is *planned/restricted* → mark
  **activated (experimental)**.
- `R/formula-status.R:242-253`: the binomial-counts row explicitly says **"equal
  row totals"** (`:246`) — change it to reflect per-record varying totals now
  allowed (experimental).
- `R/validation-status.R` (~`:342`): review the non-Gaussian poisson/binomial
  fitting row for any "equal/common trial" wording.
- **Stale comments to fix** (from the `n_trials` sweep), all asserting "ONE common
  n_trials / equal row totals / varying totals error": `R/model-spec.R:400-404`,
  `R/julia-bridge.R:433-437` and `:538-540`, and the
  `tests/testthat/test-binomial-counts.R` header (`:1-6`) + inline comments
  (`:19`, `:143`, `:170`).
- README / capability language: keep `partial`; refresh the #44 status line.
- R-side capability-status / validation-debt rows: record gate-1 activation,
  still `partial`.

---

## Live-verification recipe (the toolchain IS on this machine)

`julia 1.10.0` is installed via juliaup but off the non-interactive `PATH`, so the
bridge's `Sys.which("julia")` returns empty. Wire it on, then run:

```sh
export PATH="$HOME/.juliaup/bin:$PATH"        # makes Sys.which("julia") resolve
cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
julia --project=. -e 'using Pkg; Pkg.instantiate()'   # once, if not already

cd "/Users/z3437171/Dropbox/Github Local/hsquared"
Rscript --vanilla -e 'devtools::test(filter = "binomial-counts")'   # incl. live legs
air format .
Rscript --vanilla -e 'devtools::test()'
_R_CHECK_FORCE_SUGGESTS_=false Rscript --vanilla -e \
  'rcmdcheck::rcmdcheck(args = c("--no-manual","--as-cran"), error_on = "error")'
```

Notes:
- The first JuliaCall call precompiles HSquared.jl deps (can take minutes).
- Without the `PATH` export, the live legs **skip** (they are
  `skip_if_not(hs_julia_bridge_available())`), and the Julia-free parse/payload
  tests still run and must pass.
- Verified available here: `JuliaCall`, `MCMCglmm`, `sommer`, `pedigreemm`,
  `nadiv` all installed; `julia --version` → 1.10.0 (exit 0).

---

## Gate-2 validation plan (written now; executed later)

Not part of gate 1; **does not gate the activation**. Execute after gate-1 lands.

1. **Binomial information gradient.** Reproducible study: `σ²a` recovery improving
   from single-trial Bernoulli (boundary-prone, the documented information effect)
   up through larger/varying `n_trials`. This is the headline justification for the
   path. Engine-side sim exists in spirit (`sim/phase6_binomial_recovery.jl`); the
   R-lane variant fits via the bridge across a denominator ladder and records
   recovery. Output → `docs/dev-log/recovery-checkpoints/`.
2. **External comparator — `MCMCglmm` agreement (NOT REML parity).** Same binomial
   animal model (`cbind(succ, fail)`), labelled Bayesian agreement: HSquared
   `σ²a`/EBVs inside MCMCglmm 95% HPD, EBV correlation. Carry the explicit caveat
   that this is cross-estimator agreement, not same-estimand REML parity. BLUPF90
   categorical (`thrgibbs1f90`) executables are **absent** → record as a blocker.
3. **Interval calibration.** Out of scope until a binomial interval exists in the
   engine (`laplace_reml_interval` is Poisson-only). Document the gate; do not
   claim coverage.

None of gate 2 promotes the row past `partial`.

---

## Coordination (#44) — DRAFT, not posted

Outward GitHub posting needs Shinichi's explicit OK (auto-mode blocks it). Draft
note for **HSquared.jl #44** once gate-1 lands and is green:

> Gate 1 done (R lane): `cbind(successes, failures)` now accepts per-record
> varying trial totals; the R bridge marshals a per-record `n_trials` vector to
> the engine's existing `BinomialVectorResponse` path (engine unchanged). Julia-free
> parse/payload tests + a skip-guarded live varying-trial parity test added.
> Remaining: gate 2 (information-gradient study, MCMCglmm agreement, interval
> calibration). Stays `status:partial`; no promotion.

Mirror to the R issue ledger per the twin convention. Tick the #44 "Remaining
gates" checkbox for per-record varying trials.

---

## Definition of Done (gate 1)

Implementation (changes 1-4) · tests (new + inverted, green; live legs green with
`PATH` wired) · docs + status-wording updates · R capability/validation rows ·
`docs/dev-log/check-log.md` evidence · after-task report · coordination-board entry
· Rose claim-vs-evidence audit · clean local R checks (`air format`,
`devtools::test`, `rcmdcheck`) · #44 gate-1 update. **Remains `partial`.**

## How to resume

1. R-twin session: apply changes 1-4 in `hsquared`, update tests/docs.
2. Run the live-verification recipe above (or run Julia-free only; live legs skip
   without the `PATH` export).
3. On green: update ledgers, write after-task report, Rose audit; leave `partial`.
4. Gate 2 is a separate slice.

### Open question for Shinichi
Since Codex is down and the toolchain is present here, Claude (Julia lane) can
**live-verify gate-1 without touching the R-twin's working tree** by implementing
in an isolated `git worktree` of `hsquared` on a throwaway branch, running the
recipe, and handing back the diff/branch for the R-twin (or Shinichi) to merge.
Awaiting Shinichi's decision: (a) R-twin implements + verifies from this spec, or
(b) Claude implements + verifies in an isolated worktree, or (c) leave as a
written handoff only.
