# H3 G0 pre-run card — unarmed candidate

## Purpose

This card makes the next H3 prerequisite reviewable without changing the H3
scientific contract. It is engine- and capability-inert: it adds only a
governance manifest, validator, and test, and neither ratifies H3 nor
authorizes any compute.

## Frozen candidate and cells

The candidate is Julia `4d4a55c`, with the C1-ext driver, refusal-only sbatch
template, and ADEMP predeclaration pinned in the companion manifest.

- H3-rg: genetic correlation `r_g`, `genetic_correlation_interval`, Fisher-z;
  a tiny one-replicate smoke and the predeclared small 8:16:96 confirmation
  cell. The `|r_g|=0.9` boundary is characterization only.
- H3-ram: direct–maternal correlation `r_am`, `direct_maternal_interval`,
  Fisher-z; a tiny one-replicate smoke and the predeclared n=960 confirmation
  cell. The `|r_am|→0.9` boundary is non-interpretable if its interval path
  throws.

## Proposed later G1 smoke

If a maintainer separately authorizes it, run exactly one single-thread Totoro
smoke with `--mode=smoke --campaigns=h3_rg,h3_ram --reps=1 --seed=20260903`.
Retain the new TSV, command log, hashes, and resource output. The only allowed
smoke result is `PATH_ONLY`; no coverage or claim interpretation follows.

## Stop condition

Stop after that one smoke. Do not arm or submit the refusal-only DRAC template,
start the 2,000-replicate confirmation, alter public claims, promote a status,
change a version, tag, register, or release. A later DRAC decision must name a
candidate SHA, estimate from the Totoro receipt, exact array geometry, retained
failure accounting, and the H3 claim rule.

## Current authority

Every authority field in the companion manifest is false. This is a decision
packet for maintainer review, not an approval record.
