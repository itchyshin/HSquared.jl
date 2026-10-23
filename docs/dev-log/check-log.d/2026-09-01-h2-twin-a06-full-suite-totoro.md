# H² twin A06 — full Julia suite on Totoro — 2026-09-01

Closes the open B1/A06 item: the full `Pkg.test()` had never completed in this
campaign. The B1 receipt records the laptop attempt as
**"TERM after ~12 min at `test/runtests.jl:6395` (OpenBLAS thread killed; not a
clean pass/fail verdict)"** and defers the suite to *"B6 / Totoro, not laptop"*.
This is that run.

## Command

```sh
# staged with: rsync -a --delete --exclude .git \
#   ~/local-scratch/lanes/HSquared.jl-h2-twin-20260901/ totoro:~/hsq_work/h2-jltest-20260901/
cd ~/hsq_work/h2-jltest-20260901
env OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  ~/hsq_work/julia-1.10.10/bin/julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

- **Host:** Totoro (384 cores; this job is single-core — D-143 cap not approached)
- **Julia:** 1.10.10 — the pinned lower CI matrix leg, and the same interpreter as the
  A07 S5 evidence-of-record run
- **Tree:** `claude/lane-h2-twin-20260901` @ `294cdcb8` (working copy, `.git` excluded)
- **Log:** `totoro:~/hsq_work/h2-jltest-20260901/jltest.log` (441 lines)

## Outcome

**PASS** — `Testing HSquared tests passed`

| Measure | Value |
|---------|-------|
| Test sets (`Test Summary:` blocks) | **139** |
| Passing assertions (sum of Pass column) | **4,053** |
| Fail / Error / Broken columns emitted | **none** (Julia prints these columns only when non-zero) |
| Wall clock incl. precompilation | **~3 min** |

## What this does and does not settle

- **Settles:** the in-CI Julia suite is green on Julia 1.10.10 at `294cdcb8`, measured
  rather than assumed, with a clean verdict line — which the laptop attempt never produced.
- **Does not settle:** the opt-in, RNG-heavy drivers deliberately excluded from the
  in-CI count by the 2026-08-04 fix (`sim/f6_matfree_recovery.jl` and siblings) are not
  part of `Pkg.test()` and were not run here.
- **Does not settle:** CI itself. This is a local-equivalent run on a different host;
  GitHub Actions remains unverified for this branch, which is unpushed by design.
- **Promotes nothing.** `public_covered_count` stays **5**.

## Note on the laptop/Totoro gap

The laptop failure was an OpenBLAS thread kill, not a test failure. Totoro completed the
same suite single-threaded in ~3 minutes. Read the B1 "TERM after ~12 min" line as an
environment result, not as evidence about the suite.
