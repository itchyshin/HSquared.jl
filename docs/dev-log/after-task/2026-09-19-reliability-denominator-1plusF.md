# After-task — 2026-09-19 reliability denominator from `1 + F`

Handover #360 item 3; my own suggestion on #350 ("your suggested fix is better than mine for
the pedigree case"), split out as its own change as asked. Lane: Julia engine (Szymek, with
Claude). Branch `feat/relationship-diag-1pF`, stacked on the #355 review branch.

## 1. Goal

`reliability` standardises by the animal self-relationships `diag(A) = diag(inv(Ainv))`.
#350/#355 reads them through a Takahashi selected inverse of `Ainv`, which costs
`Θ(Σⱼ|L[:,j]|²)` over the factor of `Ainv`. For a pedigree `Ainv` that diagonal is `1 + F`,
and `pedigree_inverse` already computes `F` (Henderson's rules need `d_i = 0.5 −
0.25(F_sire + F_dam)`), so it is free at the point `Ainv` is built. The obstacle named on
#350 was that `AnimalModelSpec` carries `Ainv`, not a pedigree.

## 2. Implemented

- `_pedigree_inverse_and_inbreeding(ped) -> (Ainv, F)`; `pedigree_inverse` delegates to it and
  its `Ainv` is byte-identical (pinned).
- `AnimalModelSpec.relationship_diag::Union{Nothing,Vector{Float64}}`; the 7-argument
  constructor still works. `animal_model_spec(...; relationship_diag)` and the 4-matrix
  `fit_animal_model(...; relationship_diag)` accept it, checking length, finiteness and
  positivity. Consistency with `Ainv` is NOT checked and cannot be cheaply; the docstring
  states it is the caller's contract and that the bridge attaches it from the same pedigree
  that built `Ainv`.
- `_relationship_diag(spec, :auto)` returns the carried diagonal; explicit `:selinv` and
  `:dense` keep their literal paths, so the parity oracles still test what they name.
- Bridge payload v2: `build_in_julia` pedigree blocks carry `1 .+ F` in `Ainv`'s own
  (normalized) row order — the same `normalize_pedigree` call that orders `Ainv`, so
  alignment holds even when the payload's pedigree rows are not sorted. The `:animal`
  dispatch forwards it; `supplied` and `identity` relmats carry `nothing`. The bootstrap
  refit carries the spec's diagonal through.

Public R-facing contract unchanged: no payload field added or renamed, no result-payload
shape change, no new user-facing model syntax. `relationship_diag` is an optional Julia-side
spec input (documented, not exported); the R twin gets the benefit without changing anything.
Not public yet in the R lane sense — no R-side syntax refers to it.

## 3. Tests

`test/test_relationship_diag_1pF.jl`, 21 assertions, included in `runtests.jl`:
`Ainv` byte-identical and `F == inbreeding_coefficients`; on an inbred 240-animal pedigree
(6 generations, matings within an 8-sire/24-dam pool, `F > 0`) `:auto` takes the carried
diagonal by identity (`===`) and equals the `:selinv` and `:dense` reliabilities to 1e-10;
a fit without the diagonal is unchanged; short, zero and NaN diagonals are refused; the
payload-v2 `build_in_julia` path attaches `1 + F`, its payload reliability equals the
selected-inverse one to 1e-10, and a `supplied` `Ainv` keeps the selected inverse.

## 4. Measured

Generation-structured pedigree, 50 generations x 2,000 = 100,000 animals, parents drawn at
random from the previous generation (100 sires), fill of `L_Ainv` 170.8; Mac Studio M1 Ultra,
one thread, Julia 1.13.0:

| quantity | time |
|---|---|
| `pedigree_inverse(ped)` (includes the Meuwissen & Luo pass) | 39.3 s |
| `inbreeding_coefficients(ped)` alone, separate call | 39.9 s |
| selected-inverse diagonal of the same `Ainv` (kernel on `main`) | 878.4 s |
| `max|selinv − (1 + F)|` | 6.2e-14 |

So the denominator goes from ~15 minutes to free at q = 100,000, with the same numbers. At
validation scale the two are indistinguishable.

## 5. Rose claim-vs-evidence audit

- "free": true only where Julia builds `Ainv` from pedigree rows; a supplied `Ainv` (R-built,
  genomic `Ginv`, metafounder `A^Γ`) keeps the selected inverse, and the tests pin that.
- "equals the selected inverse": tested to 1e-10 at 240 animals and 6.2e-14 at 100,000.
- The 878.4 s figure is one machine, one synthetic pedigree, one thread. No real pedigree and
  no external comparator (#359 stands).
- `1 + F` is a pedigree identity; it is NOT the genomic case (`diag(G) + ridge`), which is why
  the diagonal is attached only on the pedigree path.
- No capability status flips; `public_covered_count` stays 7.

## 6. Checks

Check-log entry of the same date: full `Pkg.test()` passed (170 test summaries),
`preamble_cap.sh` CAP OK. CI pending the push.

## 7. Residuals

1. A supplied (R-built) `Ainv` cannot benefit; if the R twin ever ships `Ainv` with the
   pedigree alongside, the bridge could attach the diagonal there too.
2. `metafounder_animal_model` builds `inv(A^Γ)`, whose diagonal is not `1 + F`; deliberately
   left on the selected-inverse path.
3. The identity is exact, so no validation-debt row moves; `V1-SELINV-PEV` gains the
   mechanism sentence only.
