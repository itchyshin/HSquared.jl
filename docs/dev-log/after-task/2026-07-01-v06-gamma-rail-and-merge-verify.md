# After-task — v0.6 Gamma joint-fit safety rail + verified merge recipe — 2026-07-01

## Task goal
Continue the frozen v0.6 session: close the last engineering gap (a runaway Gamma shape on
uninformative data) and de-risk the maintainer's 6-PR merge. Scope is a robustness guard + evidence
hygiene + integration verification — NOT a new capability and NOT a covered flip. Branch
`feat/2026-07-01-v06-gamma-recovery` (#219).

## Active lenses and spawned agents
- **Real subagent:** `rose-systems-auditor` on the Gamma rail slice → **PROMOTE-WITH-CHANGES** (3
  documentation-lockstep fixes; Rose independently re-ran the 48-seed gate + full suite + verified the
  rail inert and no overclaim). All required changes applied.
- Review lenses (perspective only): Gauss/Fisher (the rail + identifiability), Curie (the informative
  fixture), Grace (the integration suite).

## Live phase snapshot
Both v0.6 non-Gaussian families (ordinal + Gamma) are **covered-READY** (joint estimator + agreeing
same-estimand comparator + passing pre-declared 48-seed gate). Six stacked PRs #215–#220 open. `main`
@ `94d20319`, count 50, covered 8, public-covered fitting 1 — all UNCHANGED. Merge + G10 are
maintainer-gated; the merge recipe is verified.

## Files changed (this slice)
- `src/nongaussian.jl` — `:gamma` case: σ²a + ν safety rail (`log(init)±8`) + Singular/PosDef/Domain
  guard (finite penalty). No other engine change.
- `test/runtests.jl` — Phase-2 Gamma-fit fixture → A=I/repeated-records (q=6×4); bounded shape assertion.
- `src/validation_status.jl`, `docs/design/capability-status.md`,
  `docs/design/validation-debt-register.md` — V6-GAMMA row lockstep (fixture + rail + passed gate;
  owed field de-contradicted).
- `docs/dev-log/recovery-checkpoints/2026-07-01-gamma-recovery-48seed.md` — post-rail re-confirmation.
- `docs/dev-log/check-log.d/2026-07-01-v06-gamma-rail-hardening.md`,
  `docs/dev-log/handover/2026-07-01-claude-handover.md`, this report, `AGENTS.md` snapshot.

## What changed
The `:gamma` joint optimizer returned `ν≈4e5` on a tiny uninformative fixture (the shape is weakly
identified through a flat large-ν likelihood). Added a rail confining `log σ²a` and `log ν` to
`init±8`, mirroring the ordinal σ²a guard (Rose principle). The rail is INERT on identified data. Then
verified the whole v0.6 integration via a throwaway trial-merge (`main→#220→#219`): 3 trivial
keep-both conflicts, integrated suite green.

## Checks run and exact outcomes
- `sim/phase6_gamma_recovery.jl --seeds=48` post-rail → **byte-identical** to the pre-rail checkpoint
  (σ²a bias −0.0033/MCSE 0.0089; ν −0.0019/0.0434; 48/48; `gate_pass=true`).
- `Pkg.test()` (rail + fixture + lockstep) → **PASS**, count guard `== 50`.
- `docs/make.jl` → exit 0.
- Trial-merge integrated `Pkg.test()` → **PASS** (ordinal JOINT 10/10, Gamma JOINT 6/6, kernels 62/62
  + 31/31); both families symbol-reachable (`:gamma`→shape 28.33, `:ordered_probit`→cutpoints [0,0.98]).
- Rose (real subagent) re-ran the gate + suite independently → matched.

## Public claim audit
V6-GAMMA stays `partial`/`experimental` on all three surfaces; no "unbiased" wording ("no detectable
bias" idiom); `public_covered_count` = 1; covered flip explicitly reserved to maintainer G10. The rail
is documented as a robustness guard, not a re-estimation. Nothing exported, nothing wired to R.

## Tests of the tests
The fixture change was the point: the old 12-animal fixture did not identify ν (hence the runaway the
old test failed to catch); the new A=I/repeated-records fixture identifies ν and the bounded assertion
(`0<ν<1e4`) would now catch a runaway. The rail's inertness is tested by the byte-identical 48-seed
re-run (a real bias would have to survive `init±8` ≈ 3000×, which the gate optimum is nowhere near).

## Coordination notes
Julia-engine lane, solo. No `hsquared` (R) edits. The ordinal chain (#215/#218/#220) was authored in
parallel; its evidence lives on its own branch (so this Gamma branch correctly shows the ordinal row
still owing its comparator/gate — they land when the ordinal chain merges).

## What did not go smoothly
Rose caught that the first lockstep pass updated 2 of 3 surfaces (missed `capability-status.md`) and
left the runtime owed-field self-contradictory — fixed. The naive trial-merge tangled the two
`try/catch` objectives around one shared `catch…end`; resolved by rebuilding two independent `elseif`
blocks (recorded in the handover recipe so the maintainer avoids the tangle).

## Known limitations
Single design (A=I / q=80 gate; small test fixture). Broader-DGP + pedigree-A recovery, a 2nd
same-estimand comparator per family, the `:symbol`→R bridge, and scale-labelled h² (doc-20 Step 4;
ordinal liability is clean, Gamma observation needs an NS-2017 trigamma lit-check — deliberately NOT
guessed tonight) are all follow-ups, none a covered blocker.

## Next actions
1. **Maintainer:** merge the 6 PRs (verified recipe) → G10 covered flip (public-covered 1→3) + a final
   full-chain Rose.
2. **Autonomous follow-up:** doc-20 Step-4 ordinal liability-scale h² (exact, `V_A/(V_A+1+V_fixed)`);
   then the Gamma observation-scale h² after verifying the NS-2017 distribution-specific variance.
3. Broader-DGP / pedigree-A recovery runs (Totoro) to widen the covered-READY scope.
