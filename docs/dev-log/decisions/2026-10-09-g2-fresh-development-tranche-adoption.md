# G2 fresh development tranche adoption

Status: approved for manifest regeneration and the single measured pre-run only.

## Decision

Adopt the reviewed amendment that allocates amended-source FA-rank development indices 31–60 in each of the nine N-by-signal cells. Keep historical-source indices 1–30 separate from amended-source indices 31–60. Preserve the frozen DGP, selector, safeguards, thresholds, reference-audit subset, failure handling, pilot and confirmation partitions. Do not replace a failed attempt or reuse prior-source, pilot, or confirmation results.

Owner approval was given in this chat on 2026-10-09 for the reviewed amendment, manifest update, and one N=80/null outer-31 measured pre-run on Totoro. This approval does not authorize the rest of the 270-case tranche, pilot, confirmation, or any gate transition.

## Reviewed basis

- Proposal: `docs/dev-log/decisions/2026-10-08-g2-fresh-development-tranche-candidate.md`, SHA-256 `2a7ffa4b8395c63a8af73eb76b7d4fd59253986c7f803561f58742ac5502103f`.
- Independent review: `docs/dev-log/source-review/2026-10-08-g2-fresh-development-tranche-review.md`, SHA-256 `30ddbc0f3c92bb4aa0e643b87ee4ea88e480a9bdb7aa40d528187eefcf69db32`.

## Execution boundary

Regenerate and exhaustively validate the canonical outer-seed manifest under the existing namespace and seed hash rule. Confirm indices 31–60 are absent from retained attempt records and confirm all historical indices 1–30 remain byte-identical at the seed level. Build a new exact-source admission and obtain independent source review. Run only N=80/null development outer 31 with four Julia threads and one BLAS thread on Totoro. Stop after its retained outcome and measured elapsed time. Estimate the full tranche, including all preselected expanded-reference audits and every flagged-fit audit. If the estimate exceeds three hours, no further tranche work is admitted by this decision.

This decision grants no G2 credit and authorizes no change to acceptance thresholds, denominators, public capability status, or covered count.
