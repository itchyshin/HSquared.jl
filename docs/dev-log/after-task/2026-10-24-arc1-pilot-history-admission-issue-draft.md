# Issue draft: Complete retained-attempt history before Arc 1 pilot admission

## Problem

The eight-cell Arc 1 pilot candidate cannot be admitted because its batch does not provide a complete, independently reviewed consumed-attempt history. Hashing the current candidate and a finite set of records does not establish that every retained run root and relevant historical source was enumerated.

## Evidence established

- The retained 41-file archive is byte-verified against its retrieval manifest.
- Two byte-identical `run.toml` summaries describe completed diagnostic FA-interval work for outer 2 and outer 14. The first has 7/10 usable bootstrap samples and was refused; the second has 10/10 and formed.
- The pinned historical seed implementation reproduces the 20 bootstrap seeds and derives two outer-data seeds. These 22 identities have zero overlap with the batch's 240 unique candidate outer seeds.
- The candidate batch pins the same `tools/arc1_manifest.py` hash as the reconstruction, but the run's recorded `sim/arc1/execute_attempt.jl` hash (`f3482e64…60e72e9`) differs from the candidate hash (`9395f338…be8f971`). Seed collision status is verified; model-execution source parity is not.
- The retained v8 Julia/R source map was compared read-only against the isolated R tree named by its `source_roots`. Of 289 R paths, 4 match, 2 differ, and 283 are absent. The later v10/v11 candidates each pin 274 R paths; 4 match, 2 differ, and 268 are absent. A name search across both retained trees found no `DESCRIPTION`, `.Rbuildignore`, or `NAMESPACE`; the only matching Arc 1 R implementation file found was `R/arc1-uncertainty.R` in the isolated R tree. Its broken `.git` metadata was not accessed or repaired. Current R source identity therefore cannot be established from these retained trees.
- A supplementary read-only hash comparison against the Dropbox `hsquared` working tree found more mapped files but still no exact lineage: v8 has 111 matches, 85 changed paths, and 93 missing of 289; v10/v11 each have 111 matches, 85 changed, and 78 missing of 274. The checkout already had modified and untracked files, so these are working-tree counts rather than committed-HEAD counts. No Dropbox files were written or changed.
- The source-history archive itself is not an exhaustive retained-root inventory. Some source-map targets and possible attempt stores are absent. The batch therefore remains inadmissible.
- The retained seed-audit report records 834 historical baseline paths absent from the current filesystem and says their content exists in a pinned snapshot. Its scope excludes broad Git history and result, receipt, and check-log trees; it explicitly says this does not establish a complete historical seed inventory. The exact snapshot bytes and complete root coverage still need independent verification.
- The retained execution-history inventory reports 15,914 files across evidence buckets, including 15,800 under `recovery-20261019`. A fresh read-only traversal of the entire current evidence directory found 1,348 regular files, zero symlinks, and 19,768,244 bytes; the `recovery-20261019` bucket itself has 1,209 files and 16,717,195 bytes. The retained counts are not current verified file counts; their generation scope or snapshot must be reconciled before they define audit coverage. This traversal did not classify run records or prove seed consumption.
- The referenced historical-audit payload has expected SHA-256 `02a8eaec2b84dc2b332f516c1ce9521c6550fc31ec5cd54f5e835a9a36a7f44b`. An exact SHA-256 scan of all 1,348 regular files (19,768,244 bytes) under the current evidence directory found no payload with that digest. The search does not cover repository files outside `evidence` or external stores.
- The current dirty checkout passes 28 diagnostic seed-history/launcher unit tests, 8 amendment-contract tests, and 33 pilot-admission contract tests. These guardrail tests do not supply the missing complete historical inventory or admit the pilot.
- The diagnostic run's retained seed-list JSON contains a stale `NOT STARTED` field beside completed status and outcomes. The run summaries provide the supporting completion record; the stale field should be corrected in any future canonical evidence.

## Requested resolution

1. Produce a complete inventory of retained attempt roots and source lineages within the declared Arc 1 scope, including explicit listing, hash, parse status, unreadable count, and unparsed count for every root.
2. Resolve every structured seed derivation or source-map reference that can identify consumed work, preserving failed attempts and nested bootstrap seeds.
3. Have an independent reviewer verify the exact source bytes, root coverage, consumed seed set, and candidate collision screen.
4. Regenerate the candidate admission and plan against that reviewed history, then run plan-only validation. Keep fits and the pilot campaign stopped until a separate execution authorization is in force.

## Acceptance criteria

- Every declared root is listed and independently reviewed; no unreadable or unparsed entries remain unexplained.
- All consumed attempts have stable identities linked to exact source and protocol hashes, including deterministic nested seeds.
- Candidate seed uniqueness and no-reuse checks pass against the complete reviewed history.
- Launcher plan-only validation accepts the batch without starting fits.
- No scientific gate receives credit from history reconstruction alone.

## Scope note

This draft is local and unsubmitted. It does not request a threshold change, authorize a pilot campaign, or change G2-G8, `public_covered_count=7`, or v7 HOLD.
