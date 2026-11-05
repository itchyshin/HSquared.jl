# PR 496 exploratory paired timing diagnostic

This scratch-only diagnostic compares two fixed Julia source trees on one host.
It changes no PR, workflow, threshold, scientific gate, or package code. It is
not a replacement for the original hosted `Pkg.test()` job. **Do not run it
remotely until the job and evidence-transfer path are reviewed and authorized.**

The driver launches four independent Julia processes in baseline, candidate,
candidate, baseline order. Each process recreates the existing deterministic
q = n = 2000 package-test fixture, warms its own code, runs the public call,
and times the fit call. Two observations per source are **exploratory** and
cannot support a reliable statistical estimate of runner variability.

Each child uses `--check-bounds=yes --compiled-modules=yes --depwarn=yes` and
`--code-coverage=@<per-run-package-root>`, matching the relevant action flags.
Coverage records remain in each retained per-run package copy. The original
source trees are checked before and after, and copied source is checked after
each child while allowing only `.jl[.<pid>].cov` records tied to existing files.
This direct driver does not reproduce the full `Pkg.test` sandbox.

Each run records Julia/OS/CPU and runner-image metadata, thread settings,
project, manifest and `src/` SHA-256, a fixture fingerprint, elapsed time, GC,
allocations, compilation time when available, convergence, objective and
output shape. Outside the timed call it audits selected-inverse entries for
`H = Z'Z + Ainv/0.4`, a **unit-weight structural proxy**. This is not the
actual initial Hessian and does not count timed-run fallback calls.

The driver requires Julia 1.13.3 and the exact project, manifest and expected
`src/` hashes. It rejects mismatched fixtures and invalid outputs. It applies
the original `< 10.0 s` fit and allocation assertions to every repetition,
including baseline. Repeating the assertions is stricter than the original
single timing; the result does not redefine that original gate. Each child's
stdout, stderr, start marker and completed result are retained under the
provided output directory. A 10-minute monotonic execution deadline terminates
and reaps the active worker; on Windows the code requests `taskkill /T /F`.
The Windows cleanup path has not been tested on Windows.

## Source and dependency pins

- Baseline: `623a54bddd82e7268cf3845a25e278c024515074`, `src/` SHA-256
  `af70fd707b0e142eb5dede4da74a638f239e1805683ec16a160f78126eb8f04b`.
- Candidate: `c2c18582fd53c76d760618684001a2758ba33ced`, `src/` SHA-256
  `b1087932ea7324a0422ddb3a877e865335bba522529e430bab5481b933a20182`.
  This is a **historical combined candidate**. Current main later advanced to
  `c36c4f424ce220f9b9ce050ff21f64adb921d3dc`; this diagnostic does not test
  current-base integration. The two sources also differ in other main changes,
  so their timing difference cannot be attributed solely to the sparse fix.
- Both `Project.toml` SHA-256:
  `8797dab5ac93c3c03e29c6fa3924056c173873d40356e8be86a7367344cdd9dc`.
- Included Julia 1.13.3 manifest SHA-256:
  `272ce679b561dedde1d733b783905cc6201cd9ed08b99acc1f87082e5454597b`.

The provisioning script checks Julia and both project/manifest hashes **before
and after** `Pkg.instantiate()`. `src/` hashes are computed from sorted relative
path + NUL + file bytes + NUL and verified before timing. The `src/` digest
alone does not attest the full Git tree; provisioning also checks both commit
IDs and clean tracked files. The pinned local manifest can differ from the
hosted `Pkg.test()` environment, and platform binary artifacts can differ.

## Proposed Windows package-check job

The following is a reviewable recipe, **not a change to CI**. A separate
approved staging step must place `paired.jl`, `provision.ps1`, `run.ps1`, and
`pinned-Manifest-1.13.3.toml` together in the indicated directory on the runner.
Neither script uploads those files or launches a job.

```yaml
jobs:
  exploratory-paired-timing:
    runs-on: windows-latest
    timeout-minutes: 30
    steps:
      - uses: julia-actions/setup-julia@v3
        with:
          version: '1.13.3'
      # Stage the four reviewed files at RUNNER_TEMP/pr496-diag first.
      - name: Provision pinned sources and dependencies
        shell: pwsh
        timeout-minutes: 15
        run: '& "$env:RUNNER_TEMP/pr496-diag/provision.ps1" -DiagDir "$env:RUNNER_TEMP/pr496-diag"'
      - name: Run exploratory paired check
        shell: pwsh
        timeout-minutes: 12
        run: '& "$env:RUNNER_TEMP/pr496-diag/run.ps1" -DiagDir "$env:RUNNER_TEMP/pr496-diag"'
      - name: Retain results even on failure
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: pr496-paired-evidence
          path: ${{ runner.temp }}/pr496-paired-evidence
          if-no-files-found: warn
```

Both source trees and the evidence directory must be new; provisioning does not
remove existing files. The job enforces one BLAS thread and two Julia threads.
The original CI did not pin these values, so these measurements are controlled
comparisons, not a reconstruction of all earlier hosted settings. The 12-minute
step timeout leaves room after the driver's 10-minute limit for cleanup and the
always-run upload. An infrastructure failure or total job timeout can still
prevent an upload; retain the workflow log as well. Per-step and Windows
process-tree cleanup have not been exercised on Windows.

Expected warm-up and execution time is **4–8 minutes**, capped at 10 minutes by
the driver; checkout and dependency provisioning can take longer. The job has
separate 15-minute provisioning and 12-minute execution limits inside a
30-minute overall cap. This uses existing #421 package-test fixtures, not Arc 1
study attempts or a simulation campaign.

## Local checks

An earlier no-coverage Julia 1.13.3 Mac run produced baseline fit times 0.686 and 0.644 s,
and candidate times 0.678 and 0.685 s. All repeated original limits passed,
objectives matched, and the unit-weight proxy reported zero missing entries.
Each child result and stderr/stdout file was retained. This establishes harness
operation on this Mac, not Windows performance or general scalability.
The earlier driver rejected an incorrect source hash and wrong Julia version
before a fit. An earlier driver rejected mismatched manifests; the earlier
version enforces the stricter pinned manifest hash, but that negative case was
not rerun. A one-second local timeout test terminated and reaped its child.
The Windows cleanup and PowerShell scripts remain untested. An earlier scratch
version had a Julia world-age import error and was fixed before the final smoke
run. No hosted job was launched.

The revised bounds-and-coverage driver passed a local Julia 1.13.3 Mac smoke:
baseline fit times 2.802 and 2.824 s, historical candidate 2.821 and 2.821 s.
All repeated original time and allocation assertions passed. Four isolated
package copies retained 16 generated coverage files in total; original source
hashes and the copied source hashes passed the driver checks. This smoke does
not test Windows, the PowerShell recipe, or full `Pkg.test` sandbox behavior.
