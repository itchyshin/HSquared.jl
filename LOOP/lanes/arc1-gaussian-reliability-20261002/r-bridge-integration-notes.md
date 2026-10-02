# Arc 1 R integration notes

This is a pending implementation brief, not evidence of R access. Use only the isolated R checkout `/private/tmp/hsquared-auto-fa-r-20261001`, branch `codex/arc1-gaussian-reliability-20261002`. Preserve the original dirty Dropbox checkout. Claim exact R paths before editing.

## Verified source anchors

- `R/hs_control.R`, lines 336-375: expert controls live in the named `engine_control` list. Add narrow validation and forwarding without changing omitted controls.
- `R/fa-rank-selection.R`, lines 166-235: normalizer uses explicit candidate and attempt schemas. New policy, gradient, version, source and failure metadata will be lost unless transported here and in serialization.
- `R/fa-rank-selection.R`, print method immediately after line 235: currently labels `nrow(attempts)` as actual optimizer starts. Arc 1 retains unattempted derived starts; report attempted and scheduled counts separately.
- `R/julia-bridge.R`, lines 3246-3287: automatic selector already builds a validated pedigree, checks ID ordering, uses a request-local ledger reference and preserves partial interruption evidence. Extend this path with explicit optimizer policy and frozen effective defaults.
- `R/hsquared.R`, automatic branch around lines 90-120: forward new controls through existing selection dispatch. Do not invent a second automatic-rank API.

## Required behavior

The new fixed-K1 Julia policy requires a validated Pedigree overload. Existing matrix-based and omitted-policy paths keep their current semantics. Selected-fit normalization must retain the new metadata rather than discard it.

Use raw engine parameter count `q=14/18`, AIC penalty `28/36`, and criterion `-2*loglik+penalty`. Attempted and unattempted rows are distinct. Required live tests exercise selection, refusal, interruption, source identity and failure status, not only mocked transport. Tests need an explicit required-live switch that fails when Julia is absent.

Profile and bootstrap uncertainty must use explicit expert methods and preserve current uncertainty meanings. Return estimand labels, method/policy versions, source identity, failure counts, interval statuses and disconnected profile segments. Do not print unconditional calibration claims before the scientific gates pass.


## Coordination receipt

The parent claimed `R/hsquared.R`, `R/hs_control.R`, `R/fa-rank-selection.R`, `R/julia-bridge.R`, `R/extractors.R`, the two new Arc 1 test files, and `man/hs_control.Rd` under `codex-h2-arc1-20261002` for four hours on 2026-10-02 at about 16:20 UTC. Children work under this lease; do not create an overlapping child lease. Preflight identified this lane's own completed predecessor and old refs, with no live R lease before this claim. The parent inspected the suggested old `cursor/237-mv-permanent-r` and stash diffs: they contain broader historical changes, not the new Arc 1 controls. Keep this accepted isolated lineage and its existing behavior. The September cursor handover pointer is superseded by the October automatic-FA final handover.
