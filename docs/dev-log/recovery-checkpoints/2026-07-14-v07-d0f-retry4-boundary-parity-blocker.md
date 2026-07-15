# v0.7 D0F retry-4 boundary-ratio replay blocker

**Disposition: `UNADJUDICATED — REPLAY_ENDPOINT_REPRESENTATION_BLOCKER`.**

Recovery-v3 retry 4 is a permanently retired diagnostic root, not recovery
evidence. It must not be repaired, resumed, subsetted, pooled, or adjudicated
post hoc. No D1, D2, activation, capability-status promotion, or
`public_covered_count` change is admitted from this root.

## Locked execution identity

| Item | Value |
| --- | --- |
| Totoro root | `/home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0f-retry-r4-83d19e8-e5d4a0aa` |
| R deployed head | `83d19e8c781292a551f9fcb2149c011a37299691` |
| Julia deployed head | `e5d4a0aac7473a82655032717399a465d1a6635e` |
| Julia candidate head | `fc9d39df650b20aa09d769d9f9528eed1b606f1e` |
| Frozen doc-49 SHA-256 | `0bbad8420812865d599d30af85ccf0d2fd039eada4c4914542f54dee8a9d54f0` |
| Stage-preseal SHA-256 | `3f49e658d94cb3aa64d0afdf3cafe695faac0246fb509411607bd916c317f649` |
| Manifest SHA-256 | `f80eb2dbe14b1eb5b2db3b41acbf31d2809cdebe5a5e4d4d791eb7bdc7ba4a8f` |
| Official-corpus lock SHA-256 | `0aceb685a657b415fc30b3876b8c1698ea4088551155b75f58d4cc72a48199ba` |
| Base-R summary SHA-256 | `2fd74065d2d8eec028eb2677293eed00609bacffb5faa66d3b7950994ac6fc07` |
| Phenotype/bootstrap bases | `2036000000` / `2037000000`, now retired |

All five prospective reviews (Hopper, Noether, Fisher, Grace, and Rose), the
clean deployment, preseal, zero-seed preflight, n-ladder, and 16-worker smoke
preceded the first official phenotype.

## What ran

- Official R route: **576/576** attempted, successful, and converged; no error
  rows and finite stored gradient diagnostics.
- Independent base-R recomputation: **576/576**, with its diagnostic summary
  complete.
- Exact Julia replay: **455/576** rows written before four strided batches
  stopped fail-closed at their first boundary representation discrepancy.
- Remaining Julia rows: **121 unattempted**, not 121 failures.
- Julia summary and adjudication receipt: **absent**.
- D1 and D2: **not opened; no seed consumed**.

The 455 admitted replay rows agree with their official rows to a maximum
numeric difference of `2.2453150450019166e-12`, inside the frozen `1e-10`
route-parity tolerance.

## Localized blocker

The replay tool rederived
`sigma_g2 / (sigma_g2 + sigma_e2)` and required exact floating-point equality
with the declared numerical boundary endpoint (`1e-7` or `1 - 1e-7`). Five of
the 13 locked official boundary rows differ by one ULP between that rederived
ratio and the engine-declared `boundary.numerical_ratio`:

| Seed | Boundary | Replay state |
| ---: | --- | --- |
| `2036103006` | lower | first fail-closed blocker |
| `2036113007` | lower | first fail-closed blocker |
| `2036119002` | lower | latent; not reached in the retired replay |
| `2036120002` | lower | first fail-closed blocker |
| `2036115002` | upper | first fail-closed blocker |

The observed differences are about `1.32e-23` at the lower endpoint and
`1.11e-16` at the upper endpoint. The validator then caught this contract
exception and mislabeled it as scientific `fit_error`. This is evidence of a
replay representation/diagnostic-classification defect. It is **not** evidence
of solver, KKT, gradient, or recovery failure.

## Frozen stopping consequence

The preseal binds the exact replay commit and tool hash, and the preregistration
requires the complete attempted-seed denominator. Therefore no current row may
be patched, skipped, replaced, or rerun into evidence. The root and every
observed retry-4 phenotype/bootstrap seed are permanently retired.

Allowed claims are limited to:

- the official and base-R routes completed their locked 576-row diagnostics;
- the replay machinery failed closed;
- a one-ULP boundary-ratio representation mismatch was localized; and
- public activation remains held while the supplied-`Ginv` estimator alone
  retains its existing covered status.

Forbidden claims include D0F PASS, recovery or bias evidence, general solver
invalidity, broad genomic activation, a capability/count move, or an assertion
that exactly five of all 576 rows would fail the retired replay.

## Next discriminating experiment

A fresh prospective repair must:

1. preserve the engine-declared `boundary.numerical_ratio` in replay;
2. compare the component-derived ratio separately under a frozen tolerance;
3. classify replay-contract violations as infrastructure errors, not
   scientific `fit_error`;
4. add lower/upper one-ULP regression tests plus a mutation that proves a
   genuine component/declaration disagreement still fails;
5. run a diagnostic-only mechanism preflight over all 13 retired boundary
   packets plus representative interior packets; and
6. receive fresh exact-head reviews, deployment, preseal, and disjoint seeds
   before any Retry-5 evidence root is created.

Totoro/DRAC only; never GitHub Actions.
