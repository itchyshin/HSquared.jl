# Arcs: speed12-20260919 (HSquared.jl)

| id | arc | ledger | status |
|---|---|---|---|
| S1 | `sim/profile_ai_reml_sections.jl`: per-section AI-REML profiler on the w4 half-sib ladder (q=1k/5k/20k/50k) and the F0 adversarial pedigree (fill ~75/150; q=5k fill-471 pre-run); Profile.@profile share of the real `fit_ai_reml` plus a faithful copy of the loop body (`src/likelihood.jl:457-533`) with `@elapsed`/`@allocated` per section, bitwise-gated; TSV under `sim/results/` | leaf-S1 | todo |
| S2 | `bench/Project.toml` (SelectedInversion.jl v0.2.1 as oracle) + `bench/selinv_arms.jl`: arms (a) current kernel, (b) hoisted `sparse(ch.L)` copy, (c) `selinv`/`selinv_diag`; Mac rungs fill <= 150 at q <= 50k; rtol 1e-10 gates; records every quantity in D-271's table | leaf-S2 (write before dispatch) | todo, after S1 |
| S2-totoro | the q=20k fill-471 arm, ~1.5 h on Totoro, one process, OPENBLAS_NUM_THREADS in {1,4} | STOP: Shinichi's yes with G1.4 shown | blocked |
| verify | Haiku mechanical re-verify of every leaf; Opus judgment review (refute one passed gate) | orchestrator | after S2 |
