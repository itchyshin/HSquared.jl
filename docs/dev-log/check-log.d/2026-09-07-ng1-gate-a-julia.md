# Check log — 2026-09-07 Gate-A NG-1 Julia scale summary

- Scope: local Julia engine/source-test implementation only.  No R public API,
  compute campaign, promotion, version change, tag, registry action, push, or
  release action occurred.  The only accompanying documentation changes are
  this check-log shard, the matching after-task receipt, and a coordination
  board note.
- Candidate: `codex/hsq09-ng-contract-julia-repair` at local commits
  `28a26bcc`, `cc0aac0`, and `cc2db0d`, descended from verified live main
  `6987871b3b8c257cdb23100246d768f8a6fd5397`.
- `git merge-base --is-ancestor 6987871b3b8c257cdb23100246d768f8a6fd5397 HEAD`
  and `git diff --check`: **PASS**.
- `~/.juliaup/bin/julia --project=. test/gate_a_nongaussian.jl`: **PASS**
  (`HSQ09_NG_GATEA_TESTS_OK`).
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: **PASS**
  (`Testing HSquared tests passed`).
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: **PASS**; its generated
  timestamp-only mutation was restored.
- Unlazy: leaf S5 **3/3** and root Julia ledger **6/6** met after final parent
  re-verification.  The final root run used retained session polling so the
  full-suite and Documenter evidence persisted.
- Independent review: NG-1 specification **PASS**; numerical/code quality
  **PASS** after both correction commits; bridge-contract review **PASS**.
- Negative controls: missing-helper RED at live main; Bernoulli output-label
  RED (`:bernoulli` rather than required `:binomial`) before `cc2db0d`.
