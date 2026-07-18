# D1 pre-draw readiness audit — v07 genomic recovery-v3 (READ-ONLY, no seeds)

**Provenance.** Adversarial paper-audit of the D1 pre-registration
(`docs/dev-log/2026-07-18-d1-campaign-preregistration.md`), run 2026-07-18 as a Claude Workflow
(`d1-predraw-readiness-audit`, run `wf_b6655f9c-217`): 3 recon extractors → 6 adversarial lenses
(seed-math/Noether, estimand-predicates/Fisher, contract-schema-phaseorder/Hopper, scope-claims-bounds/Rose,
validation-gates-smoke/Curie, deployment-determinism/Gauss) → per-finding independent adversarial verify →
Ada synthesis. 25 agents, 0 errors, 14 CONFIRMED findings, 0 refuted at synthesis. **No orchestrator command,
seed draw, Totoro state change, or repo edit was made by the audit** — it is a read-only cross-check of the
plan against `doc49 §D1`, the driver, the orchestrator, and the R tooling on the local twins.

**Verdict: NOT-READY (3 blockers, 2 majors)** — for the *pre-registration as first drafted*. The blockers
have since been fixed in the pre-registration doc (deployment re-pinned to the sanctioned heads; smoke moved
behind the GO; missing PRE-items added). The remaining non-doc blocker is the **Totoro re-deployment** to the
sanctioned heads, which is live work gated on the R-twin certification + the user's GO. **Zero seeds spent.**

---

## Blockers (all CONFIRMED, git-verified)

**B-1 — the pre-reg bound stale pre-fix ancestor code.** The first draft bound deployment
`code-d3835fe-1a538212` (Julia `1a538212` / R `d3835fe`) and asserted these were *descendants* of the D0F
seal. `git merge-base` refutes it: **both are older ANCESTORS** — Julia `1a538212` is an ancestor of `976814`
(~29 commits / 3 days); R `d3835fe` is an ancestor of `a23b15b` (~53 commits / 4 days). At those heads:
- Julia `1a538212` LACKS `_validate_d0f_predecessor`, `D0F_ADJUDICATION_SCHEMA`, `EvidenceRoute`,
  `COMPONENT_RATIO_TOLERANCE` (the §1 gate + acceptance-predicate machinery, added later by `e45dbe0a`); its
  preseal errors if a receipt is present.
- R `d3835fe` is schema `adjudication-1`, and `admission.R` + `downstream_contract.R` do not exist there;
  it predates route-repair `b8096e5` and fail-closed fix `96529fd`. ⇒ the D0F re-derivation preflight
  (`v3r_validate_final(retry8-prep/d0f,'d0f')`) aborts on schema mismatch, so PRE-1 is unattainable there.

**Correct heads:** R `a23b15b`, Julia `976814`/HEAD `27d5047d` — they contain the gate + schema-2 and already
earned the D0F PASS byte-reproducibly. Fix = re-pin + rebuild/rename the Totoro checkout (live work).

**B-2 — the pre-reg stamped a git-refuted ancestry "verified."** The ⚠ OPEN flag asked only to "confirm
d3835fe is the sanctioned R head" while asserting the false ancestry as fact — a remediation path that would
have produced a false-positive certification. Fix (done) = corrected ancestry + rewrote the flag to require
the deployed driver to *contain* the gate + schema-2, git-evidenced, plus a dry `validate-final` re-emitting
`04cc0740…` byte-identical.

**B-3 — PRE-4 "smoke" would draw official seeds before the GO.** `smoke-n-ladder`/`smoke-16` use the same
`run-one` RNG path as `run-official` on real `2028000000/101:148` seeds; the zero-seed gate is the Julia
`preflight` mode (no summary). Listing smoke in the pre-draw green-gate would have an operator perform the
draw before the panel + GO. Fix (done) = smoke moved into §8 behind the GO as the FIRST irreversible command;
PRE-2 `preflight` is the pre-draw gate; smoke removed from PRE-1..PRE-N.

## Majors (doc fixes, applied)

- **M-1** — no named D1 analog of the D0F adjudicator-tail / route-repair regression. Fix = PRE-5 now cites
  the D1-parametrized mutation suite (`test-v07-genomic-recovery-v3-retry7-mutations.R`, `stage='d1'`) GREEN;
  D1 has no bootstrap, so the parity-triple-compare has no D1 analog (stated explicitly).
- **M-2** — R-head sanctioning lived only in free text. Fix = PRE-4 is now an explicit named gate with the
  B-1/B-2 evidence requirements.

## Watch items (not draw-blocking on current evidence)

- OrderedCollections global-vs-project split — require a clean precompile (no "different version" warning) +
  byte-identical serialized receipt/summary across two precompiles before the draw (adversarially REJECTED as
  a hard blocker; exposure low — receipts use fixed column vectors, not Dict-order).
- Receipt content-hash rebinds fresh at preseal (not pinned to the literal `04cc0740…`) — confirm the D0F
  corpus is untouched between now and the D1 preseal.
- Cell-id string format differs between R seed-lock (`n120_m60_r050`) and Julia `_cell_table`
  (`n0120_m0060_q0500_r050`) — seeds unaffected (depend only on `cell_index`), but verify at `prepare` time
  that R-preseal's manifest cell_id matches the Julia format so `_validate_manifest` does not error.
- Phase-order enforcement: the driver strictly enforces `summarize-r` before `summarize-julia`, not directly
  before `replay-julia` (doc corrected).

## Confirmations — the design core is SOUND (14 findings)

- **Seed math:** base `2_028_000_000`, `base + 10_000·cell_index + offset`, `offset ∈ 101:148` (48), 12
  interior cells `{2,5,8,11,14,17,20,23,26,29,32,35}`, 576 = 12×48 — byte-identical across pre-reg,
  `seed_lock.R`, and the Julia driver; **disjoint** from all spent/retired/historical/downstream spaces; **no
  bootstrap base** (enforced). *(One audit agent mis-listed the cell set as `4,8,…,32`; the synthesis caught
  and corrected it — the correct set is above.)*
- **Estimand + predicates:** outcome-neutral (PASS written only via successful adjudication that aborts on
  parity failure; `stage_decision` is a data-derived tally); eligibility precedence matches doc49; route-label
  immutability is a type-level guarantee at the sanctioned head.
- **Schema/contract:** receipt bound by SHA-256 content hash not head-equality; `adjudication-2` agrees across
  Julia + R preseal/admission/contract; blocked-root byte-identical; D1 boundary summary columns genuinely
  computed.
- **Scope/bounds:** `public_covered_count` stays 5; V2-GRM/V2-GINV stay partial; route not activated;
  "D1 PASS only OPENS D2" correctly hedged; HELD-at-S4 honest.

## Bottom line

The plan measures the right thing with the right seeds and correct bounds, and the correct deployment code
already exists and already passed D0F — but the first draft bound 4-day-older pre-fix ancestor code that
cannot enforce its own §1 gate, stamped a git-refuted ancestry as "verified," and listed a "smoke" gate that
draws seeds. Doc blockers fixed; the live remediation is a Totoro re-pin to R `a23b15b` / Julia `976814`,
after which PRE-1..PRE-6 + the live adversarial panel + user GO gate the draw. The user's decision to pause
"R twin confirms first" is what kept S4 from running on the broken deployment.

*(Per-lens detail files and the full synthesis are session-local under the scratchpad; this committed copy is
the durable record.)*
