# 2026-07-15 — v0.7 D0F Retry-5 post-preseal tree blocker

- Final classification: **`UNADJUDICATED — POST-PRESEAL TREE-VALIDATION
  BLOCKER (ADMISSION CONTRACT NOT PROVEN)`**.
- Exact execution identity: R `fcfde69dbc283aea66a6efb1134f5a468e4e655a`,
  Julia `069419977fff76e87eca45c4410b65bca1ca3592`, frozen doc-49
  SHA-256 `2f669d24d14d52cefc1d0d77d8d6c2f19b9edb4fafd8cc6ae681465cb7591c6a`.
- Exact-head CI, clean hash-matched deployments, five CLEAN review receipts,
  and schema-3 preseal preceded the first phenotype.
- The first phenotype (`2038101001`) produced one successful, converged,
  interior official fit. Before seed 2, runtime validation rejected the
  legitimate first `attempts/` and `packets/` members as extra input.
- The post-run contract audit found the typed Julia infrastructure-error gate
  absent at the deployed head. The generic do-block mutation helper could pass
  by catching an unrelated `MethodError`; exact-head CI did not run the
  standalone replay selftest. Durable proof of the fixed 16-packet preflight
  and two review batches is also unavailable.
- Read-only Totoro audit: 38 files, nine directories, all files mode `444`, all
  directories mode `555`, zero writable/link/special members, 19/19
  primary-sidecar pairs valid, and no live Retry-5 process in three probes.
- Sorted relative-path tree digest before and after audit:
  `f97d1c15600307238eef794c80bfc3644715421ee93f0812527f951727cc1b02`.
- A final independent Totoro recheck returned the same digest, zero writable
  files, zero writable directories, and no matching process under three
  self-excluding probes.
- Exactly one phenotype, packet, and attempt exist. There is no corpus lock,
  base-R summary, Julia replay/summary, adjudication receipt, D1, or D2.
- The entire root and phenotype/bootstrap bases `2038000000` / `2039000000`
  are retired. No seed may be reused and no root member may be repaired.
- No capability promotion, activation, merge, release, G10, or
  `public_covered_count` change occurred. Prospective Retry 6 is separate work.
- `git diff --check` passed in both twins. Both after-task reports passed
  `tools/check-after-task.R`; Julia `tools/preamble_cap.sh` passed at 7,268
  bytes with exactly one live phase snapshot.
- The paired recovery checkpoints and paired check-log entries compare
  byte-identical. Targeted stale-future wording searches returned no current
  Retry-5-as-next-step hits.
- `tools/handoff_gate.sh` was run in both twins before handoff drafting and
  again after the closure landed. The initial Retry-6 R WIP was subsequently
  landed at `8dea0ad`; the final ledger carries only the Julia scaffold.

See
`docs/dev-log/recovery-checkpoints/2026-07-15-v07-d0f-retry5-post-preseal-tree-blocker.md`
for the complete evidence and claim boundary.
