# Approved design acceptance

- [x] D1: Model contract and symbolic likelihood/rank criteria are written with checked primary sources.
  CHECK: test -s docs/design/auto-fa-rank-contract.md && printf 'FA_DESIGN_CONTRACT_PRESENT\n'
  EXPECT: FA_DESIGN_CONTRACT_PRESENT
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl; path=052de112f0da/35 entries; output=FA_DESIGN_CONTRACT_PRESENT

- [x] D2: Validation plan names independent oracles, all failure denominators and a bounded future pre-run.
  CHECK: test -s docs/design/auto-fa-rank-validation-plan.md && printf 'FA_DESIGN_VALIDATION_PRESENT\n'
  EXPECT: FA_DESIGN_VALIDATION_PRESENT
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl; path=052de112f0da/35 entries; output=FA_DESIGN_VALIDATION_PRESENT

- [x] D3: No implementation, tests or status rows have changed from the approved base.
  CHECK: git diff --exit-code 28f90e09 -- src test Project.toml docs/design/capability-status.md docs/design/validation-debt-register.md && printf 'FA_DESIGN_SOURCE_UNCHANGED\n'
  EXPECT: FA_DESIGN_SOURCE_UNCHANGED
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl; path=052de112f0da/35 entries; output=FA_DESIGN_SOURCE_UNCHANGED

- [x] D4: Independent final judgment is retained.
  CHECK: test -s docs/dev-log/source-review/2026-10-01-auto-fa-rank-design-independent.md && printf 'FA_DESIGN_REVIEW_PRESENT\n'
  EXPECT: FA_DESIGN_REVIEW_PRESENT
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl; path=052de112f0da/35 entries; output=FA_DESIGN_REVIEW_PRESENT

- [x] M1: Independent method and claim reviewers accept the full bounded contract and validation plan.
  EVIDENCE: docs/dev-log/source-review/2026-10-01-auto-fa-rank-design-independent.md; final method and user judgments PASS V0, mechanical PASS, initial HOLDs retained with inspected resolutions. Final core SHA256 pins in docs/dev-log/check-log.d/2026-10-01-auto-fa-rank-design/reviewed-artifacts.json. No implementation/performance claim. Artifact existence alone does not discharge this judgment.
