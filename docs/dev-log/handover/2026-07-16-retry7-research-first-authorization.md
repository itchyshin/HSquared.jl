# Handover — Retry-7 authorized (research-first); adjudicator re-architecture rule

Meta: 2026-07-16 MDT · author = Claude (daily brain-check session, live-directed by Shinichi) · sole sequential H² lane

## Why this note exists

Shinichi answered the 2026-07-16 daily brain-check "Your call" (six genomic retries,
all tripping on post-run receipt/plumbing machinery, never on the statistics). His
ruling, verbatim intent:

> "yes do a NotebookLM deep research (Ranga) and try again"

This supersedes the prior terminal handover's step 3 ("Stop. Do not mint a Retry-7
contract or seed allocation without a distinct next goal and fresh review cycle"):
Shinichi has now supplied the **distinct next goal**. Retry 7 is authorized — but
**research-first**, and still fully gated per the guards below.

## Decision (record; do not contradict without superseding)

1. **Research-first sequencing.** A NotebookLM deep-research pass (Ranga) on the
   recurring failure class — *post-run adjudicator / write-once receipt loses or
   rebinds a row's route/provenance tag during summary reconstruction* — runs and
   lands BEFORE Retry 7 is minted. Dispatched 2026-07-16; output will land at
   `docs/dev-log/scout/2026-07-16-postrun-adjudicator-provenance-research.md` and the
   brain ENGINEERING-NOTEBOOK.
2. **Retry 7 is informed by that research**, not another blind patch of the summary
   helper. The intent of the research is to decide whether the post-run adjudicator
   should be **re-architected so route-rebinding is structurally impossible** (route
   as a single-source-of-truth / type-level tag; idempotent write-once receipt;
   route-tag conservation asserted at the summary boundary by the cheapest possible
   contract test) rather than defended at runtime after the fact.
3. **Standing rule adopted:** run the research-informed Retry 7 once. **If Retry 7
   also dies in post-run receipt/plumbing (not the science), STOP grinding retries
   and re-architect the adjudicator before any Retry 8.** Do not mint Retry 8 as
   another finish-line patch.

## Retry-7 gating (unchanged from the terminal handover — all still required)

A Retry-7 successor needs, before any RNG: a new preregistered contract, mutation
controls, exact reviews, a clean deploy, preseal, an independent chronology audit,
and an explicit **disjoint** seed-lock amendment. Spend no retired seed. Compute is
**Totoro/DRAC only**, never GitHub Actions. `public_covered_count` stays **5** and G10
is not claimed until Retry 7 actually passes and is adjudicated. Preserve every
retired Retry-1…Retry-6 root and seed space, the H2-2 Retry-5 drafts (uncommitted user
state, unstaged), and the quarantined untracked Julia scaffold
`sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl` (SHA-256 `30838979…6155`).

## Lane boundary (honest scope)

This note was written by the daily brain-check session on Shinichi's live directive.
It **authorizes and sequences** Retry 7 and dispatches the research; it does **not**
mint the Retry-7 preregistered contract or seed allocation, and it did **not** run any
fit/campaign. Minting the contract, the seed-lock amendment, the fresh review cycle,
and executing the campaign on Totoro/DRAC are the **engine session's turnkey job**
(live R/Julia toolchain), to begin **after** the Ranga research lands.

## Next immediate steps

1. Collect the Ranga NotebookLM research when it lands (scout note + engineering
   notebook); read the ranked architectural recommendations and the cheapest
   pre-campaign test gate.
2. Decide re-architect-now vs. informed-retry from that synthesis.
3. Only then mint the Retry-7 preregistered contract per the gating above.
