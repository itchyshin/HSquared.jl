# v0.7 D0F Retry-5 post-preseal tree-validation blocker

**Disposition: `UNADJUDICATED — POST-PRESEAL TREE-VALIDATION BLOCKER
(ADMISSION CONTRACT NOT PROVEN)`.**

Retry 5 is a permanently retired diagnostic root. It must not be resumed,
repaired, subsetted, pooled, or adjudicated. Its one successful fit is not D0F
recovery evidence. No D1, D2, public activation, capability-status promotion,
`public_covered_count` change, PR merge, release, or G10 is admitted.

## Locked execution identity

| Item | Value |
| --- | --- |
| Totoro root | `/home/snakagaw/hsq_work/v07-genomic-recovery-v3-d0f-retry-r5-fcfde69-06941997` |
| R deployed/recomputer head | `fcfde69dbc283aea66a6efb1134f5a468e4e655a` |
| Julia replay head | `069419977fff76e87eca45c4410b65bca1ca3592` |
| R ordinary-route candidate | `31befc036bc390cb8e7bff85c0a1bd753b198383` |
| Julia numerical candidate | `fc9d39df650b20aa09d769d9f9528eed1b606f1e` |
| Frozen doc-49 SHA-256 | `2f669d24d14d52cefc1d0d77d8d6c2f19b9edb4fafd8cc6ae681465cb7591c6a` |
| Stage-preseal SHA-256 | `e79666c27c3f99d00e0cfdd5c753eb8dd10d4a4b0c98544062e40363e25e3998` |
| Bootstrap-manifest SHA-256 | `9341b92e024066bed7429de31b6f3d57b69abe4c0bae80fe796fcc00d6cd0641` |
| Sole attempt SHA-256 | `2843fb6bf4fb09c97091756473f4f5caecffdd43c1eb695fcc97d25b1cb538d0` |
| Sorted tree digest | `f97d1c15600307238eef794c80bfc3644715421ee93f0812527f951727cc1b02` |
| Phenotype/bootstrap bases | `2038000000` / `2039000000`, complete spaces retired |

## What ran

- The schema-3 preseal was written at 06:15:48 MDT after exact-head R and
  Julia CI were green.
- The create-once bootstrap manifest was materialized at 06:17:35.
- The first phenotype, seed `2038101001`, was generated at 06:18:32 and
  produced one valid, successful, converged interior official fit.
- Before a second seed was selected or generated, `v3d_run_one()` called
  `v3d_validate_bound_stage()`. The deployed validator reapplied the
  pristine-tree predicate and rejected the legitimate first `attempts/` and
  `packets/` members as additional input.
- No corpus lock, base-R summary, Julia replay, Julia summary, or adjudication
  receipt exists. No D1 or D2 seed was consumed.

## Immutable-root verification

A read-only Totoro audit found 38 files and nine directories, all directories
mode `555`, all files mode `444`, zero writable members, zero links, and
zero special members. All 19 primary/sidecar pairs verify. The command

```sh
cd ROOT &&
find . -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum
```

returned the sorted tree digest above before and after the audit. Three process
probes found no Retry-5 process. Exactly one attempt TSV, one packet directory,
and one phenotype primary exist, all for `2038101001`.

## Post-run admission chronology audit

The exact-head evidence does **not** prove every preregistered admission gate:

| Gate | Verdict | Evidence |
| --- | --- | --- |
| Prospective endpoint amendment | PASS | R commit `190f0cf0` preceded implementation and RNG. |
| Exact Retry-4 identity pins | PASS | Julia `32d44fc3` corrected both hashes before deployed `06941997`. |
| Declared/component ratio contract | PASS | Both deployed heads preserve the declaration and check components at absolute `1e-12`. |
| Exact-head CI, clean deploy, preseal order | PASS | CI completed before preseal; deployed clones were clean and hash-matched; bootstrap and phenotype followed the preseal. |
| Five hash-bound CLEAN verdict receipts | PASS | Fisher, Noether, Hopper, Grace, and Rose receipts bind the exact doc and heads and existed before preseal. |
| Typed Julia infrastructure-error gate | **RED** | Deployed `06941997` used ordinary `ErrorException`; its generic mutation helper accepted any exception. `ReplayContractError` and typed assertions were added only afterward in the separate Retry-6 Julia head `d1914951`. |
| Mutation controls actually exercised | **RED/UNKNOWN** | The Julia do-block helper's argument order made labelled mutations pass by catching an unrelated `MethodError`; exact-head CI did not run the standalone replay selftest. |
| Fixed read-only 16-packet preflight | UNKNOWN | Design prose attests to a pass, but the command intentionally emitted no artifact and no stdout/check receipt survives. The deployed implementation also lacked full 576-row boundary-inventory equality and failure-path immutability. |
| Reviews executed in two batches | UNKNOWN | Five verdict files exist, but the receipt schema has no review time or batch and all files were materialized together. |

Therefore the first Retry-5 phenotype was spent without the required
admission proof. The later typed/mutation repair cannot cure that chronology
retroactively. This process breach is independent of the runtime-tree blocker:
both are reasons the root remains unadjudicable.

## Allowed and forbidden claims

Allowed:

- one official Retry-5 fit completed successfully;
- runtime-tree validation stopped before the second phenotype;
- the whole root and complete Retry-5 phenotype/bootstrap spaces are retired;
- the root is immutable diagnostic evidence;
- the admission chronology is not contract-clean.

Forbidden:

- D0F PASS/COMPLETE, recovery, bias, or convergence-rate evidence;
- a claim that all preregistered admission gates were proven before RNG;
- reuse of any unused Retry-5 seed;
- activation, promotion, count change, merge, release, or G10.

## Forward boundary

Prospective Retry 6 is separate work. It must retain pristine validation for
preseal/bootstrap creation, authenticate immutable inputs under a runtime
projection after compute begins, add a synthetic two-worker regression, keep
typed infrastructure failures and genuine disagreements red, persist
preflight/review-batch evidence, use disjoint bases `2040000000` /
`2041000000`, and pass every prospective gate before any RNG. Nothing in
Retry 6 may mutate or rehabilitate Retry 5.

Totoro at no more than 96 single-threaded workers, or DRAC via scheduled jobs;
never GitHub Actions for simulation evidence.
