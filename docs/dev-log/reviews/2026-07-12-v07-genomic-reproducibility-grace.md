# Grace audit — v0.7 genomic activation reproducibility

**Date:** 2026-07-12  
**Reviewed Julia commit:** `1f91763d518a5c943817f714d3ab55b8d5b3f022`  
**Reviewed R commit:** `2f8ed52` plus the uncommitted P6 recomputation files  
**Verdict:** **CLEAN after hardening recheck**  
**Initial verdict:** `CHANGES_REQUIRED` (retained below as audit history)

## Recheck after hardening

**Rechecked:** 2026-07-12, against the shared uncommitted Julia hardening above
`1f91763d` and R hardening above `1973d31`  
**Final recheck verdict:** **CLEAN**

The Julia repairs close original findings 1--4 and 7: campaign creation now
requires an empty external output directory and clean git tree; the exact commit,
driver, `Project.toml`, resolved `Manifest.toml`, pilot manifest, environment
manifest, and confirmation manifest are checksum-validated; immutable files use
create-once writes; resumed rows are rebound to the manifest and independently
recomputed provenance; explicit worker counts cannot exceed the RAM-derived cap;
and an in-repository `OUTDIR` is rejected. `bash -n`, `git diff --check`, and the
new Julia `--mode=selftest` all passed. The self-test includes the preregistered
pilot-SD upper-bound numeric anchor and mutation controls.

The R recomputation schema now includes per-row ridge and `pilot_sd_upper`, uses
the preregistered one-sided 95% SD upper bound, binds raw keys exactly to manifest
keys, and exercises all declared mutations. Its focused suite passed **31/31**
with zero failures, warnings, or skips on the first recheck. A follow-up repair
then added separate create-once pilot and confirmation seals, exact sealed-file-set
comparison, overwrite refusal, and tier-isolation controls; the expanded suite
passed **38/38**.

The final live-gate repair replaces the bare `SKIP` match with
`SKIP[[:space:]]+[1-9][0-9]*` plus the actual `══ Skipped` section marker.
`bash tools/run-v07-genomic-live-gate.sh --selftest` proves the two directions:
`SKIP 0` is accepted and `SKIP 1` is rejected. `bash -n` and `git diff --check`
also pass. The script otherwise retains exact twin-commit checks, clean-tree
checks, a committed fixture-tree identity, a separate R process, and no GitHub
Actions path.

All seven original findings are resolved in the shared trees. From Grace's
reproducibility lens, the repaired harness is ready for a **fresh**, external,
16-worker smoke/pilot after the changes are committed and both repositories are
clean. This is launch readiness only, not recovery evidence, an activation
verdict, a capability/count move, or maintainer G10.

## Post-clean false-positive discovery and final recheck

**Rechecked again:** 2026-07-12

**Pinned R commit:** `d4cefe10c155f87625bd5304d77e388a657c4eca`

**Pinned Julia commit:** `fade1d02cb2a9b404ec5d2d97da73fa291ac1237`

**Final verdict:** **CLEAN**

The first live execution after the preceding CLEAN exposed one more gate that
could not fail: `devtools::test()` printed a failed test but returned status zero,
while the shell gate inspected only skips and therefore printed PASS. This was a
real false-positive gate, so the preceding CLEAN was withdrawn until repaired.

The R gate now scans the captured log for either the testthat `══ Failed` section
or a positive `FAIL N`, in addition to its existing positive-skip check. Its
`--selftest` proves all four directions: `FAIL 0` and `SKIP 0` are accepted;
`FAIL 1` and `SKIP 1` are rejected. The stale failing assertion that exposed the
problem was removed rather than hidden behind the shell parser.

Grace independently reran:

```text
bash -n tools/run-v07-genomic-live-gate.sh                         PASS
bash tools/run-v07-genomic-live-gate.sh --selftest                PASS
git diff --check -- tools/run-v07-genomic-live-gate.sh            PASS
exact commit-pinned live R--Julia gate                             PASS
```

The live run completed `boundary-genomic`, `genomic`, and the independent
recomputation tests with no failed or skipped section, printed `Julia exit.`, and
then emitted:

```text
V07_GENOMIC_LIVE_GATE_PASS
hsquared_commit=d4cefe10c155f87625bd5304d77e388a657c4eca
HSquared_jl_commit=fade1d02cb2a9b404ec5d2d97da73fa291ac1237
fixture_tree=33bff946724b2ad7cf43e90e6a244079b917a747
```

The final verdict is therefore CLEAN from Grace's reproducibility lens. The
lesson is retained explicitly: a subprocess exit code is not sufficient evidence
when its test runner can report failure while returning zero; parse the semantic
failure surface and mutation-test both zero and positive counts.

## Scope

Independent review of campaign immutability, resume and denominator integrity,
Totoro resource controls, the live R--Julia gate, package-check separation, and
GitHub Actions/artifact exposure. I did not run a scientific pilot or edit the
implementation.

## Required changes

1. **A pilot resume can overwrite the records that are supposed to make the
   campaign immutable.** `manifest_mode` rewrites both `pilot_manifest.tsv` and
   `environment_manifest.txt`, and the Totoro launcher calls it on every pilot
   launch. A direct negative control appended a sentinel to the environment
   manifest and reran the documented manifest command; the sentinel disappeared
   and the file checksum changed. This lets a later driver recreate its own
   matching lock above old rows. Manifest creation must be create-once: refuse a
   nonempty campaign directory unless the existing manifest and environment
   digests match byte-for-byte. Confirmation-manifest creation needs the same
   create-once rule.

2. **The recorded engine state is not enforced.** Per-seed validation checks only
   the driver SHA. It does not compare the recorded `git_commit`, require a clean
   worktree, validate `pilot_manifest_sha256`, or freeze the resolved Julia
   environment and the package source used by `_genomic_activation_construction`
   and `fit_gblup_reml`. A direct negative control changed `git_commit` in the
   environment manifest to forty zeroes; `_validate_campaign_manifest` still
   accepted it. Record and validate at least the exact clean-tree commit, driver,
   `Project.toml`, resolved `Manifest.toml`, and pilot/confirmation manifest
   hashes on every seed run and before either summary. Use a fresh output
   directory after any mismatch.

3. **Resume accepts a semantically corrupt row as complete.** `_valid_existing`
   validates only schema plus tier/cell/seed. A direct negative control supplied
   the correct header and key but `n=999`, wrong truths, negative estimates, and
   bogus fingerprints; it returned `true`. Resume must validate every frozen
   manifest field, finite/type constraints, convergence/error consistency, and
   SHA-256 fingerprints before skipping a seed. Better, add a per-row checksum or
   bind each result to the exact manifest-row digest and environment digest.
   Failed fits should remain valid attempted rows, but only after the same
   design/provenance checks.

4. **Manual confirmation concurrency can exceed the RAM-derived cap.**
   `NWORKERS=auto` implements
   `min(96, floor(0.7 * available_RAM / pilot_peak_RSS))`, and the launcher caps
   all values at 96, but a user can pass any explicit `NWORKERS<=96` even when it
   exceeds the calculated RAM limit. Compute the safe cap for every confirmation
   launch and reject an explicit value above it. Keep the 16-worker pilot default,
   one process per seed, and all BLAS/Julia thread variables at one.

5. **The independent R raw seal is mutable across tiers.** The new P6 R gate
   correctly requires raw keys to equal manifest keys, retains failed seeds in
   denominators, independently recomputes the statistics, compares Julia at
   `1e-10`, and now tests scientific pilot/confirmation seed overlap. However,
   `v07_write_raw_lock()` silently overwrites one
   `campaign_raw_sha256.tsv`. Confirmation sealing therefore replaces the pilot
   seal, and rerunning `--write-lock=true` can bless altered files. Write separate
   create-once pilot and confirmation seals, refuse overwrite, verify that the
   current file set exactly equals each seal, and bank the seal digests before
   using pilot results to size confirmation.

6. **The authoritative live R--Julia gate can still pass by skipping the evidence
   it is meant to require.** The package tests appropriately use `skip_on_cran()`
   and `hs_julia_bridge_available()` so ordinary R checks remain toolchain-free.
   But the frozen-fixture test also skips when the sibling fixture is absent, and
   bridge availability checks only for Julia, JuliaCall, and a `Project.toml`--not
   the intended twin commit. Add a dedicated local gate/run script that sets
   `NOT_CRAN=true`, requires the exact `HSQUARED_JULIA_PROJECT` commit and fixture
   hashes, runs `test-genomic.R` in its own R process, and fails if any required
   live test skips. Record both twin commits and the zero-skip result in the
   check-log. Do not put this gate on GitHub Actions.

7. **Prevent accidental in-repository raw output.** The launcher defaults to an
   external Totoro directory, which is correct, but an `OUTDIR` inside the repo is
   accepted and no campaign-output ignore protects it. Reject output paths inside
   the checkout (or provide an explicit ignored local-output root plus a tracked
   summary-export step) so `git add` cannot sweep raw seed files into a PR.

## Checks that passed

- No v0.7 recovery command is wired into either repository's GitHub Actions.
  Current workflows remain package checks/docs; campaign output is not uploaded.
- The Totoro launcher uses one Julia process per seed, pins
  `OPENBLAS_NUM_THREADS`, `OMP_NUM_THREADS`, `VECLIB_MAXIMUM_THREADS`, and
  `JULIA_NUM_THREADS` to one, defaults the pilot to 16 workers, and never exceeds
  96 workers.
- Atomic per-seed writes prevent a partially written row from looking complete.
  Missing result files keep `n_attempted` below `n_expected`, so Julia summaries
  cannot report a completed cell; failed/nonfinite rows remain in the convergence
  denominator.
- The independent R recomputation validates exact manifest/raw seed membership,
  design/truth fields, ridge, fingerprints, duplicate seeds, failed-seed removal,
  and R-versus-Julia summaries. Its mutation tests are engine-free package tests.
- Ordinary R package checks and optional live JuliaCall tests are separated. The
  genomic live fixture exercises the public marker and supplied-precision routes;
  the repaired local gate makes that invocation non-skippable and commit-pinned.

## Neighbouring artifact finding

The existing opt-in plotting workflow uploads PNGs without `retention-days`, so
GitHub's longer default applies. This is unrelated to the genomic campaign, but it
conflicts with the standing short-retention rule. Set a few-day retention in a
separate narrow cleanup; do not broaden the genomic PR with plotting behavior.

## Gate decision

**CLEAN for launch from Grace's reproducibility lens.** Commit the repaired
harness in both twins, require clean trees, use a fresh external output directory,
then run the 16-worker smoke/pilot. No rows generated under the pre-repair harness
may be carried into activation evidence. Confirmation remains conditional on the
preregistered pilot decision, immutable pilot seal, independent R recomputation,
and every later Fisher/Rose/G10 gate.
