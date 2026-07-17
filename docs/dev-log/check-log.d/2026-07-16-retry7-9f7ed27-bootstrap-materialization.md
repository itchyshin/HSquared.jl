# Retry-7 D0F bootstrap materialization cross-twin receipt

**Date:** 2026-07-16
**Role:** Julia deployment identity only; no Julia preflight or replay was run.

The R-owned D0F materializer completed exactly once on Totoro at
`/home/snakagaw/hsq_work/retry7-preseal-9f7ed27-97681439-c/d0f`, bound to this
Julia replay/candidate commit:

`976814393043d3a4af5ce343d8ac4b05c43eac41`

- Stage-preseal SHA-256:
  `be42dc7d58f8747fdc7bff44c553a630bba4da48c05b9ce8faae97b32e87a312`
- D0F bootstrap manifest SHA-256:
  `f53967b5496aef51fcbac166e8dc5a00aaa6d69f8a8eb68cca42c05adbff7162`
- Sidecar SHA-256:
  `ac49fb10a2b2cb9969b8ce2adc7030934f2c719afda29dfc0d7ceda0d634fc78`
- Bootstrap rows: `720000` (plus header)

No Julia zero-seed preflight, phenotype generation, replay, model fitting,
adjudication, or downstream stage was invoked. Further work remains separately
gated.
