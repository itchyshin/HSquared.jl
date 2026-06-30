# After-task — session resume: #198 merge, h² scale contract, genomic BLUPF90 comparator (2026-06-30)

Resumed a frozen session. Three asks (a/b/c) from the maintainer: (a) merge #198; (b) resume the
paused v0.2 genomic comparator; (c) pin the h² scale contract + research non-Gaussian h² in a new
NotebookLM page. Claude solo, baton held. **Nothing promoted; public-covered FITTING surface
stays 1 (v0.1 Gaussian); `validation_status()` = 48 unchanged.**

## Live phase snapshot

- **As of 2026-06-30 (session resume; HSquared.jl `main` `948527cd`/#198 merged + this slice on a new branch).**
  (a) **#198 MERGED** (`948527cd`, CI green) — the RR k=2 covered aim + non-Gaussian family plan; local
  `main` fast-forwarded; the mission-control board (`:8791`) was down (died with the frozen session) and is
  **restored + regenerated** from live state (`public_covered=1` pin intact). (b) The paused **v0.2 genomic
  comparator is RUN and PASSES**: `blupf90+` 2.60 AI-REML on the same-`Ginv` isolation packet converges from
  a NEUTRAL start to `fit_gblup_reml`'s optimum (σ²g/σ²e/h² ~1e-5) — the same-estimand REML leg doc-18
  §priority-3 flagged as owed; banked as a recovery-checkpoint + a `V2-GREML` clause (point-estimate; stays
  `partial`). (c) The **h² scale contract is pinned** (`docs/design/19-h2-scale-contract.md`) and
  **literature-verified** against a new trusted-PDF NotebookLM page; the contract's load-bearing claims
  (π²/3 placement; QGglmm-integration vs NS-delta; Dempster–Lerner z²/[p(1−p)]; probit-latent=liability) all
  confirmed. **NEXT: code v0.2 (recovery study) → v0.4 (broader-DGP + in-suite sommer) → v0.5 (QTL thresholds).**
  START HERE: this report.

## What changed

- **(a)** `gh pr merge 198 --merge` → merged. Board server restarted (`python3 -m http.server 8791` in
  `~/.claude/hsquared-control-centre/`), `status.json` regenerated via `tools/gen_status_json.jl` (reads the
  committed count cache; no live `validation_status()` needed).
- **(b)** NEW tracked `comparator/prepare_blupf90_genomic.jl`; `.gitignore` += `/comparator/blupf90_genomic/`;
  NEW `docs/dev-log/recovery-checkpoints/2026-06-30-v2-genomic-blupf90-comparator.md`; `V2-GREML` debt row
  updated (executed-comparator clause).
- **(c)** NEW `docs/design/19-h2-scale-contract.md`; NEW NotebookLM page "Heritability scales for
  non-Gaussian animal models" (seeded by deep research + the maintainer's trusted PDFs; junk source pruned).

## Checks run and exact outcomes

- `julia comparator/prepare_blupf90_genomic.jl` → exit 0; engine target σ²a=0.575918, σ²e=0.389244,
  h²=0.596706, converged.
- `blupf90+` 2.60 (Rosetta) → 6 rounds, convergence 2.98e-13, σ²g=0.57592 / σ²e=0.38924 / h²=0.59671;
  agreement ~1e-5 (5-sig-fig printout floor).
- `Pkg.test()` → **"Testing HSquared tests passed"** (exit 0); count-guard 48 unchanged; BLUPF90 multivariate preflight 42/42 green; no `src/` edit.
- Documenter: not run — provably unaffected (no `docs/src/` change; doc-19 + register live in `docs/design/`).
- NotebookLM grounding asks (de Villemereuil 2016 / NS 2017 / Dempster–Lerner): confirmed the contract.

## Public claim audit (Rose)

**Real `rose-systems-auditor` audit → PROMOTE (clean; no changes required).** All honesty pins verified
INDEPENDENTLY against repo state: public-covered fitting = 1; `validation_status()` = 48 mechanically intact
(empty `src/`+`test/` diff → the `length==48` guard cannot have moved); genomic stays `partial`; nothing
promoted. doc-19 verified accurate to `src/nongaussian.jl` incl. the π²/3-placement trap and the
`Var(E[y|η])+E[Var(y|η]) = p̄(1−p̄)` denominator algebra (re-derived by Rose); the genomic checkpoint correctly
fenced to point-estimate / single-fixture / same-`Ginv` isolation; `V2-GREML` keeps `partial` and re-lists
every owed item. No API/default/R-wording change.

## Tests of the tests

The genomic comparator is a genuine INDEPENDENT check: BLUPF90 started from a NEUTRAL (1.0, 1.0) start, not
the engine's answer, and found the same optimum — so it tests the estimator, not a tautology. Same-`Ginv`
isolation means it does NOT test G-construction (deliberately; that is `V2-GRM`, still owed).

## Coordination notes

Claude solo, baton held. No R files touched. The h² contract, if exposed R-side later (v0.9 bridge), must
carry the scale label across the bridge — noted in doc-19 §6.

## What did not go smoothly

- The board server had died with the frozen session (`curl :8791` → connection refused); restarted.
- BLUPF90 binary was gone from disk (prior download not persisted); re-downloaded under maintainer
  authorization (untrusted-binary gate), `otool -L` verified before running.
- NotebookLM auto-research could not fetch paywalled publishers (OUP/Royal Society/Wiley) — the maintainer
  supplied those as trusted PDFs (#3 Nakagawa 2010 dropped as redundant with NS 2017).

## Known limitations

- The genomic comparator is ONE fixture / ONE truth point (point-estimate) on a supplied `Ginv` — NOT a
  recovery study, NOT coverage, NOT G-construction parity. Does not promote v0.2.
- doc-19 covers 4 wired families fully + the convention for the owed ones; the owed families' exact link
  variances/transforms are still to be derived per-family.

## Next actions

1. **v0.2:** a committed pre-declared genomic recovery study (+ optional `sommer` 2nd REML leg) → G10.
2. **v0.4:** broader-DGP MV recovery + the in-suite unstructured `sommer` test; FA/4B recovery (furthest).
3. **v0.5:** calibrated genome-wide thresholds (null-DGP sims) + `marker_scan()` activation.
