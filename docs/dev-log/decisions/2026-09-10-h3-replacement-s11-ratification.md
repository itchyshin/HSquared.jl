# H3 replacement S11 ratification

**Maintainer decision, 2026-09-10:** two distinct retained campaigns are
authorized for `r_g` and `r_am`. Each has 2,000 fresh, disjoint seeds, a
minimum of 1,800 successful intervals, coverage conditional on
`interval_success`, and binomial MCSE with the nominal 95% plus-or-minus two
MCSE classification band. Each campaign is a one-thread DRAC array capped at
100 concurrent tasks.

Narval is the selected CPU route because the matching H1 retained campaign
already used it. The S10 measured paths are 8.15 seconds (`r_g`) and 43.26
seconds (`r_am`), so the fixed five-minute per-task request is conservatively
above the slower path and remains bounded. A one-task-per-cell pre-run is
required before either full array.

This ratification authorizes the sealed manifest, launcher, pre-run, and
retained campaign only. It does not authorize capability promotion, versioning,
tags, registry action, merge-to-main, or release. Results remain separately
reported and `claim_eligible=false` unless a later Gate B says otherwise.
