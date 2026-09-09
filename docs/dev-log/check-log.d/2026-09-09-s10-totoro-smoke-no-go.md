# S10 Totoro smoke — retained no-go

Candidate: `988eec84248964287c4d363bfb598554f48b0822`.
Runtime lock digest: `a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221`.

The final one-task smoke ran on Totoro with one Julia/BLAS thread, one
replicate, seed `20260903`, level `0.95`, and a 1,470-second hard timeout. It
completed its driver in 10.75 seconds (99% CPU; maximum RSS 453,444 KiB), but
the post-run S10 validator correctly rejected the receipt. The published
failure directory is retained on Totoro at
`/home/snakagaw/hsq_work/hsq09-s10-prerun-988eec84/results/hsq09-s10-20260909-988eec84-01.failed/`.

## Decisive gate

`h1_two / ratio1 / tiny / interior / 0.95` had `fit_success=true`,
`fit_converged=false`, `interval_success=false`, and the retained reason
`interval_failed`. Its summary denominator was zero. S10 therefore fails its
predeclared H1-two sentinel rule. The retained `h3_ram` row also failed with a
nonempty positive-definite-information error; it remains in the denominator
record rather than being filtered out.

The other four interval rows that completed do not rescue S10: the smoke is
`PATH_ONLY`, all seven summary `claim_eligible` values were false, and the
required sentinel did not succeed.

## Decision

**NO-GO for S11.** Do not launch a DRAC screen or confirm array, promote any
capability, change versions, tag, register, or release from this evidence.
The next scientific action is diagnosis of the H1-two tiny-cell convergence
failure in a separately preregistered recovery slice; it is not an extension
of this S10 receipt.

## Infrastructure history

Two earlier bounded attempts are retained as launcher repairs, not scientific
evidence: the first cleaned a failed stage (fixed at `63ab216a`), and the
second used `--output` rather than the driver's `--out` flag (fixed at
`988eec84`). The final receipt above is the only complete structural result.
