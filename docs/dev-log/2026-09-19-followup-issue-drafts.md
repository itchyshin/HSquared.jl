# Follow-up issue drafts — 2026-09-19 large-pedigree performance arc

Ready-to-file GitHub issue bodies for the follow-ups left open by the 2026-09-17 and
2026-09-19 check-log entries (`reliability()` memory fix; dense-clique selected inverse).

**Why this file exists:** the session that found these had no `gh` CLI available, so the
issues could not be opened directly. File them against `itchyshin/HSquared.jl` and replace
this file's entries with the resulting issue numbers (or delete it once all are filed).

Ordered by expected impact on the originating report (a standard animal model far slower
than ASReml-R, ~35 GB on a ~100,000-row pedigree).

---

## 1. `fitted_values` densifies `Z` — O(n²) blow-up on the standard animal model

**Labels:** bug, performance, phase-1

`src/likelihood.jl`, `fitted_values`:

```julia
fitted = Matrix{Float64}(spec.X) * result.beta
fitted = fitted + Matrix{Float64}(spec.Z) * result.animal_effects.values
```

`Matrix{Float64}(spec.Z)` densifies the animal incidence matrix. For the standard
single-response animal model where every animal is phenotyped, `Z` is `n_obs × n_animals`
— at 100,000 × 100,000 that is **74.5 GiB dense**, built from a matrix with exactly one
nonzero per row. `result_payload()` calls `fitted_values(fit)` unconditionally, so this is
on the same path as the `reliability` blow-up fixed in `6bb10c97`, and is of comparable
severity.

The sparse products are already correct; dropping the two `Matrix{Float64}` conversions
should be sufficient.

**Acceptance:** `fitted_values` allocates O(nnz(Z)), not O(n²); existing fitted-value tests
unchanged; a large-`n` smoke test (or an `@allocated` bound) pins it.

Found by the Gauss numerical review, 2026-09-17. Recorded in `V1-REML`
(`docs/design/validation-debt-register.md`).

---

## 2. `henderson_mme` solves the SPD mixed-model equations with UMFPACK LU, twice per payload

**Labels:** performance, phase-1

`src/likelihood.jl`, `henderson_mme`, does `solution = lhs \ rhs` on a bare
`SparseMatrixCSC`. Julia's sparse `\` performs no symmetry detection, so it takes an
unsymmetric UMFPACK LU of a matrix that is symmetric positive definite by construction.

Measured at n=4000 (nnz(lhs)=43,612), Karpinski review 2026-09-17:

| route | time | factor nonzeros |
|---|---|---|
| `lhs \ rhs` (UMFPACK LU) | 0.740 s | nnz(L)+nnz(U) = 719,784 |
| `cholesky(Symmetric(lhs)) \ rhs` | 0.012 s | nnz(L) = 498,155 |

**60x slower, 1.4x the factor fill, identical solutions to the bit** (maxdiff 0.00e+00).

`result_payload()` pays it **twice**: once via `breeding_values(fit)` and once via
`fitted_values(fit)`, each calling `henderson_mme` independently.

Two separable pieces of work:
1. switch to `cholesky(Symmetric(lhs))`;
2. compute the solve once and share it across `breeding_values` / `fitted_values` rather
   than re-solving per extractor.

**Acceptance:** identical β/EBVs (they were bit-identical in the probe above); one
factorization per `result_payload`; existing Henderson MME and Mrode fixtures unchanged.

Found by the Gauss numerical review, 2026-09-17. Recorded in `V1-REML`.

---

## 3. No dense-size guard on `prediction_error_variance` / `reliability` defaults

**Labels:** bug, usability, phase-1

Both extractors still default to `method = :dense`, and neither runs the
`_check_dense_validation_size` / `max_dense_cells` guard that every dense *fitter* in
`src/likelihood.jl` carries. A direct call at large `n` therefore attempts the O(n³)
inversion with no early, named error — the user sees an OOM or a hang rather than an
`ArgumentError` naming the lever to raise.

`breeding_values_plot_data` calls `prediction_error_variance(fit)` at the dense default, so
that public function is on the same footing.

Note the scope boundary from `6bb10c97`: `result_payload` opts into `:selinv` explicitly and
`accuracy()` can now be asked for it, but the *defaults* were deliberately left alone as a
wider behavior change than that fix's scope.

**Acceptance:** a large-`n` dense-default call raises the standard guard error naming
`max_dense_cells` / `method = :selinv`; small-fixture behavior unchanged.

Found by the Gauss and Karpinski reviews, 2026-09-17. Recorded in `V1-SELINV-PEV`.

---

## 4. Reconcile the q=300,000 / 2.3 s DRAC figure with the per-iteration profile

**Labels:** validation, performance, docs

`docs/design/validation-debt-register.md` (`V1-REML`, F3 entry) records a DRAC run where
`fit_ai_reml` converged at **q=300,000 in 2.3 s**. The 2026-09-17 profile measured
`selinv_trace_against` alone at **~42.9 s per iteration at n=100,000**. Both are recorded;
they are not reconciled.

Most likely explanation: this cost tracks pedigree **fill-in**, not animal count, and the
DRAC benchmark pedigree has far lower fill than the synthetic ones profiled (the same
review measured 485 s at only n=20,000 on an adversarial fully-random-mating pedigree
versus 142 s at n=100,000 on a generation-structured one). Unverified.

**Acceptance:** report `nnz(L)` and `nnz(L)/col` for the factor in the DRAC q=300,000 setup,
alongside a re-timed per-iteration breakdown, and reconcile (or correct) the two entries.
Until then neither number should be cited as representative of the other's pedigree
structure.

---

## 5. Measure on a real pedigree, and against an external comparator

**Labels:** validation, performance

Every number in the 2026-09-17/19 arc is from **synthetic** pedigrees on one developer
machine. Specifically not evidenced:

- any ASReml-R (or BLUPF90 / sommer) comparison — none was run, so the originating
  "slower than ASReml-R" report is **narrowed, not closed**;
- any real production pedigree;
- end-to-end `fit_ai_reml` timing beyond n=8,000; selected-inverse timing beyond n=30,000;
- the exact "~35 GB" figure from the original report (the mechanism is demonstrated at the
  same scale, but no allocation trace of the failing run exists, and 35 GB does not
  arithmetically match a completed 80 GB allocation — an OOM kill partway through is the
  plausible reconciliation, unverified).

**Acceptance:** a pre-declared scaling run on a real or realistically structured pedigree
reporting wall time **and** peak RSS at n ∈ {10k, 30k, 100k}, with a per-component
breakdown (assemble / cholesky / solve / selinv / project), plus one same-estimand external
comparator at a size both engines handle.

---

## 6. Blocked/supernodal selected inverse (further constant-factor headroom)

**Labels:** performance, enhancement

`6bb10c97` cut `_selinv_zvals` by 6.65x-9.97x by removing per-pair binary searches, but the
recursion remains `Θ(Σⱼ|L[:,j]|²)` and is still the largest single term in an AI-REML
iteration. The next step is a blocked/supernodal formulation operating over CHOLMOD's
supernodes with small dense GEMMs — the structure production sparse-inverse routines use.

Karpinski's framing: the binary-search removal was the "contained change"; this is the
"bigger job".

Related, deliberately deferred as a ~0.28%-of-iteration item until the above lands: reusing
the CHOLMOD **symbolic** factorization across REML iterations (`cholesky!` with a fixed
pattern, measured 0.184 s → 0.062 s at n=100,000). If taken, make the pattern fixed *by
construction* rather than trusting `cholesky!` to detect a mismatch — it was verified NOT to
throw when handed a deliberately altered pattern.

**Acceptance:** bit-identical or documented-tolerance output against the current kernel
(the existing `V1-SELINV-PEV` equality tests plus the dense-block/fallback bitwise pin are
the gate), with a measured speedup on the same benchmark set.
