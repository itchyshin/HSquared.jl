# D1 blocker — latent R-lane recomputer-path bug forces a D0F re-seal (no seeds spent)

**2026-07-18. READ-ONLY investigation; no seed drawn, D0F receipt `04cc0740` still intact on disk.**
Surfaced when the first zero-seed D1 admission step (`prepare d1`) was run on the certified `retry8-prep`
deployment (R `a23b15b` / Julia `976814`). It failed fast (rc=1, 9 s, no partial state).

## The bug (verified in code)

`hsquared/tools/v07_genomic_recovery_v3_recompute.R:278` sets `r_recomputer_path = script`, where
`script = v3r_script_path()`. That self-locator (recompute.R:15–33) reads `sys.frames()$ofile`, else falls
back to `commandArgs("--file=")`. Its sibling paths (`:277 r_driver_path`, `:282 d0_recomputer_path`) are
derived **by name** from `r_root` — only line 278 uses `script`.

On D1's predecessor re-validation, `v3p_validate_d0f_final_tree` (preseal.R:482–492) `sys.source`s the
recomputer and **then** calls `v3r_validate_final` in-process. `sys.source` does not set `$ofile`, and the
source frame has already returned when `v3r_script_path` runs — so it falls to `--file=`, which is the
**driver** (the orchestrator runs the driver for `prepare`, `run-…sh:591`). `r_recomputer_path` therefore
collapses onto the driver, and the tool loop checks the driver's hash `d1a7d930` against the preseal's
`r_recomputer_sha256 = cef0b993` → mismatch, printing the driver path.

**Why it never fired before:** D0F's own `validate-final` runs *standalone* (`Rscript --file=…recompute.R`),
so `--file=` = the recomputer → correct. Only `stage==d1` inline-sources it. Retries 4–7 died earlier (the
JuliaCall tail), so this path had literally never executed. It blocks both D1 `prepare` and D1 `preseal`.

## Why no seal-preserving fix exists

`preseal.R` is not a sha-bound tool, but that is irrelevant: two **unconditional git-identity gates** in
`v3p_validate_stage_preseal` bind the whole `r_root` worktree, and both fire at D1 `prepare` (pre-draw) via
the inline D0F re-validation, again at preseal, and again at run-one (post-draw):
- **preseal.R:967** — `v3p_git_clean` (`git status --porcelain`, untracked counted) → aborts if dirty.
- **preseal.R:972–976** — live `v3p_git_head(r_root)` must equal the frozen D0F preseal's
  `r_driver_commit`/`r_recomputer_commit` = **`a23b15b`**.

Any R-lane edit breaks one gate: a **dirty** file trips :967; a **commit** (HEAD ≠ `a23b15b`) trips
:972–976. A tracked file cannot change without doing one or the other, and `a23b15b` is frozen into the D0F
seal. So the fix cannot be applied without re-sealing D0F.

## The only correct route — re-seal D0F, then D1

1. Fix `recompute.R:278` → `r_recomputer_path = file.path(r_root, "tools", "v07_genomic_recovery_v3_recompute.R")`
   (matches how `r_driver_path`/`d0_recomputer_path` already resolve). R lane (`hsquared`).
2. Commit (new R HEAD `C_fix`; **driver bytes unchanged** → driver still hashes `d1a7d930`; `recompute.R`
   sha changes from `cef0b993`). Redeploy a clean tree at `C_fix`.
3. Re-run the **full D0F stage** in a fresh output tree: `prepare → preseal → run-official → summarize-r →
   replay-julia → summarize-julia → adjudicate → validate-final`. This is **re-fit + re-adjudicate** (a fresh
   `attempts/` is empty; `run-official` only skips already-present seeds), but the **576 fits reproduce
   byte-identically** (seed-locked; driver, Julia replay, and the shared external corpus are unchanged).
   Pure compute, ~same wall-clock as the original D0F (Totoro, ≤96 workers). Result: a **new D0F receipt**
   recording `C_fix` + the fixed recomputer sha, re-confirmed PASS/COMPLETE by `validate-final` + a spawned
   Rose.
4. D1 then binds the **new** D0F receipt (the old `04cc0740` is superseded — update capability-status,
   coordination-board, the D0F after-task, and the D1 pre-reg's predecessor sha).

**Governance:** re-sealing supersedes the landed, Rose-confirmed D0F PASS `04cc0740`. No scientific change
(identical fits), but the receipt identity + all docs that cite `04cc0740` change. `public_covered_count`
stays **5** throughout; no seed is drawn by the re-seal (D0F seeds `2042/2043` reproduce deterministically).

Session-local detail: `scratchpad/d1_prepare_rootcause.md`, `scratchpad/d1_seal_preserving_eval.md`.

## Review corrections (Rose + Gauss, 2026-07-18) — fix committed as hsquared `5325e95` (C_fix)

The fix (`recompute.R:278` → derive `r_recomputer_path` by name) was reviewed read-only before commit:
**Rose = CLEAN** (minimal, integrity-preserving; it makes the recomputer's validator agree with the driver's
sealer at `v07_genomic_recovery_v3.R:340`) and **Gauss = NO-NUMERIC-CHANGE** (`r_recomputer_path` is
identity-only; never feeds a fit/recompute/parity/adjudication path). Two corrections to the wording above:

- **Reproduction claim (Gauss).** The "576 fits reproduce byte-identically" phrasing is too strong. What
  reproduces EXACTLY is the **scientific-numeric core** (sigma/ratio/loglik/gradient/objective/iterations/
  variance components/info matrices) and therefore the parity max-diffs + the PASS/COMPLETE verdict. The
  attempt/summary TSVs are **NOT** byte-identical cross-run: they carry `driver_commit`/`preseal_sha256`
  (which change because the commit moves HEAD and the preseal identity changes) and per-run
  `runtime_seconds`/`peak_rss_mb`. The pipeline excludes exactly these from parity (`recompute.R:1546-1549`).
- **Receipt delta (Gauss).** The new D0F receipt changes **five** identity fields, not two:
  `r_driver_commit`, `r_recomputer_commit`, `r_recomputer_sha256`, `preseal_sha256`, `adjudication_key_sha256`
  (`r_driver_commit` also advances because for a single-repo D0F run `driver_root == r_root`). The driver
  **content** sha stays `d1a7d930` (driver bytes unchanged); the recomputer sha moves `cef0b993 → eb29c8f4`
  and the regenerated tracked sidecar `recompute.R.sha256` ships in the same commit.
- **Supersede ledger (Rose).** When the new receipt is minted, ALL of these HSquared.jl docs that cite
  `04cc0740`/`a23b15b`/`cef0b993`/`adjudication-2` must move (12, not the 4 named in step 4 above): ROADMAP.md,
  AGENTS.md snapshot, capability-status.md, validation-debt-register.md, coordination-board.md, this file,
  the D1 pre-registration, the handover doc, the D1 pre-draw audit, check-log.md, the D0F retry8 after-task,
  and its check-log.d sibling. Post-reseal wording must say "identical fits, new receipt identity" — never
  "receipt 04cc0740 re-derived byte-identical". A spawned-Rose close-out re-confirms PASS/COMPLETE + that every
  `04cc0740`/`a23b15b`/`cef0b993` citation has moved and the new receipt's id label is not falsely `04cc0740`.</new_string>
</invoke>

