# D1 reseal4 adversarial pre-draw panel

**Decision:** GREEN — 2026-07-20 UTC. This record closes the reversible D1 admission
gate only. It does not change `public_covered_count = 5`, activate
`ordinary_auto_genomic`, or promote V2-GRM/V2-GINV.

## Admission evidence

- Sole controller `d1_reseal4_admission.sh` completed `prepare → preseal → preflight`
  with `RC=0`; Julia reported its preflight PASS with no official RNG or seed consumed.
- The fresh, non-nested D1 root is `~/hsq_work/d1-reseal4`; its reviews root is
  `~/hsq_work/d1-reseal4-reviews`; predecessor is `~/hsq_work/reseal4-d0f`.
  No attempts, packets, summaries, locks, official output, or active D1 campaign
  process existed at panel time.
- The D1 preseal binds `reseal4-d0f` receipt
  `e88207e576f08a34d49ce7c7f4f2d5f795eee3d3ba58cd2eb364fb1d3f293b60`,
  R `5325e9532f93117a47b26acf7b126f02a74d0d5a`, Julia
  `418be98432d1e6fea3615d3bfa37194f84253c07`, and replay sidecar
  `03bda8b8144d4dac51182b30f23cc039bf1a2f68770251be497276f2d58e9b51`.
- D0F is schema-2, PASS/COMPLETE; controller and independent final-tree
  re-derivations returned `RC=0`. Tally is 576 total / 556 interior / 10 lower /
  10 upper / 0 errors; attempt and summary parity are below `1e-10`.
- The D1 manifest has 576 ordered rows: 12 declared cell indices, offsets `101:148`
  (48 each), exact disjoint formula `2028000000 + 10000 * cell_index + offset`,
  and no duplicate or malformed seed.

## Independent verdicts

| Lens | Verdict | Scope |
| --- | --- | --- |
| Rose | GREEN | Claims, canonical predecessor, roots, sidecars, public fence |
| Curie | GREEN | Admission order, zero outputs, manifest/cell/seed contract |
| Gauss | GREEN | Numerical/environment freeze, parity, sidecars, deployment |
| Shannon | GREEN | Single-owner coordination, active-driver absence, cross-surface binding |

All reviewers were read-only. No reviewer launched, edited, restarted, or otherwise
mutated a Totoro stage.

## Authorization and next action

> **SUPERSEDED POST-DRAW (2026-07-20):** this panel was GREEN and correctly opened the first official
> smoke draw, but `d1-reseal4` then terminated `RC=21`. Its root and full `2028000000/101:148` seed space
> are retired. The authorization below is historical only and must not be used to launch, resume, or repair.

Historically, Shinichi's documented standing authorization applied because every panel verdict was
GREEN. The first irreversible official seed was therefore `smoke-n-ladder`; the controller then followed
the declared phase order until its terminal failure. Any
terminal post-draw failure retires this D1 root and the whole `2028000000/101:148`
space; there is no in-place repair or public promotion.
