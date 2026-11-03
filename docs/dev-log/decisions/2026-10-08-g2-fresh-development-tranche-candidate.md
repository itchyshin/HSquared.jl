# G2 fresh development tranche candidate

Status: proposed for independent review and owner approval. This document changes no executable plan, seed manifest, gate, or study admission.

## Reason

The adopted six-split K0 amendment requires untouched allocated development cases. An independent audit checked the frozen manifest and all nine cells. All 270 development indices 1–30 are consumed; no amendment-qualified development case remains. The eight non-N80/null receipts contain 30 started/result records each. The N80/null replay also covers indices 1–30 and is explicitly diagnostic-only. The six-split v4 replay covers consumed N80/null outer 7 and 10 and grants zero G2 credit.

The current amendment therefore cannot complete its development qualification screen without a further allocation decision. Existing results, pilot indices, and confirmation indices cannot be substituted or pooled.

## Proposed bounded allocation change

Preserve the original 30 development attempts per cell as historical evidence for their exact source versions. Add a separate amended-source development tranche for outer indices 31–60 in each of the nine FA selection cells (N=80, 160, 320 crossed with null, weak, strong), for 30 fresh cases per cell and 270 total. Keep the frozen DGP, optimizer safeguards, selection score, reliability criteria, all-attempt denominators, confirmation design, and public API unchanged.

The new tranche is identified by its exact decision hash, Julia and R source hashes, manifest revision, runtime identity, and retained output. Its qualification numerator uses only indices 31–60 under the amended six-split source. It excludes prior one-start results, consumed diagnostics, failures from other source versions, pilot seeds, and confirmation seeds. No failed case is replaced. The original and amended-source evidence remain separate. Preselect outer indices 31–50 in every cell for expanded-reference comparison, and audit every flagged fit among indices 31–60 as well, using the frozen reference algorithm and tolerance. The existing confirmation reference subset remains outer indices 1–20 per cell; no confirmation case is borrowed for development.

Before any run, regenerate and independently validate the outer-seed manifest with the same frozen namespace and hash rule, verify indices 31–60 are unique and absent from all historical attempt/result records, and obtain exact source/manifest admission. The measured pre-run is the predeclared N=80/null outer31 attempt; it remains in that cell's 30-case denominator and in its preselected reference subset even if it fails. Apply the frozen refusal and stop rules. Do not replace or rerun it as a new observation. Use its elapsed time and retained reference-audit requirements to estimate all 270 attempts and flagged-case references. If the projected work exceeds three hours, stop after the pre-run and obtain the required separate approval before the full tranche. Run on Totoro under the existing thread limits.

This proposed expansion does not qualify G2, admit a pilot or confirmation study, advance G3, or change any gate threshold. If the amendment is not approved, G2 remains unmet under the exhausted allocation.

## Review requested

An independent reviewer should check that this tranche preserves seed separation, the frozen estimand and thresholds, all-attempt accounting, and the distinction between old-source and amended-source results. Owner approval is required before adding indices 31–60 to the manifest or running the measured pre-run.
