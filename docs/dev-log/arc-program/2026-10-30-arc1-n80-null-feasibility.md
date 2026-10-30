# Arc 1 feasibility note: N80/null FA bootstrap refusal

Binding decision: [Decision (Shinichi, 25 Oct 2026) on #478](https://github.com/itchyshin/HSquared.jl/issues/478#issuecomment-6402038029).
Record the explicit `insufficient_usable_bootstrap` refusal for the N80/null
four-trait FA diagnostic and close that diagnostic. Do not try to raise
selector reliability for this cell. G4 stays open.

This note is the Arc 1 feasibility finding for that cell. It is not
calibration evidence, not gate credit, and not a covered-status change.

## Frozen requirement

A B=199 parametric bootstrap needs 198 usable draws. Failed draws are not
replaced. Consumed seeds are not rerun. The formation threshold is frozen.

## N80/null retained diagnostic

Owner-authorized formation diagnostic on retained N=80/null four-trait FA
outers 2 and 14. Full-selector parametric bootstrap. Formation only.

| Outer | Result | Vs frozen 198 usable |
| --- | --- | --- |
| 2 | First 10 draws: 7 usable. Three fixed failures cap a B=199 run at 196 usable, so the remaining 189 attempts were not run. | 196 cap is below 198 |
| 14 | B=199 produced 184 usable attempts. All four trait-specific h2 intervals were refused with `insufficient_usable_bootstrap`. | 184 is below 198 |

No failed draw was replaced. No consumed seed was rerun. No interval
calibration is claimed. No G2-G8 credit is claimed.

Retained report (off-repo evidence tree):
`LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/recovery-20261019/bootstrap-score-20261022T190407Z/bootstrap-interval-score.md`.

Combined outer-14 result SHA-256:
`dd10985ce64f07d1ed0207c5bbe93876333e49fae352016026c03752cbc3548f`.

Issue body: https://github.com/itchyshin/HSquared.jl/issues/478.

## Related K1 reference finding (issue #476)

[Decision (Shinichi, 25 Oct 2026) on #476](https://github.com/itchyshin/HSquared.jl/issues/476#issuecomment-6402037556):
do not add a guarded covariance-to-parameter start (for example a small jitter)
for the K1 reference search at N80/null outers 2 and 14. That would change the
frozen comparison. The unresolved K1 reference maxima are a valid finding.

Those two expanded-reference comparisons remain unresolved under the frozen
rule. This note does not repair the initializer, rerun the K1 grid, or change
source.

## What stays open

- G4 stays open.
- G2-G8 remain open overall.
- `public_covered_count` remains 7.
- v7 remains HOLD.
- `GATES.md` is not edited by this record.
- No selector, freeze, seed, or source change is authorized here.

## Closeout

#478 is the diagnostic this note closes once the record is on `main`. #476 is
the rejected repair path for the same cell; its unresolved K1 result is
retained above.
