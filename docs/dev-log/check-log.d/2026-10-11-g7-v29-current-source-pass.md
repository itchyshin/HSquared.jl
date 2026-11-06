# G7 current-source paired package pass, 2026-10-11

Astra's read-only exact-source review passed the v29 package freeze. The review receipt SHA-256 is `0d0ee0883b7365d86e437bf6a3d18c3f711a340d188fc90b7f60a08b16023c7b`; the reviewed freeze SHA-256 is `42a3e955031d1b1c082b239ff010ad315668959514c4085a0f796851c6c22073`.

The complete runner `20261011T002221Z-cddfeed0e0` passed in 8,383.539 seconds. Julia passed 11,902 assertions with zero failures. Required-live R passed 682/682 assertions. `R CMD check` ended `Status: OK`. Its wrapper output also records a macOS `sysctl` permission warning during the `quarto -V` probe; the package check itself completed with status OK. The local Julia documentation build passed, and the runner emitted `ARC1_PACKAGE_CHECKS_G7_PASS`.

Independent retained verification passed with `ARC1_G7_RETAINED_RECEIPT_VERIFIED`, exit 0. The exact run receipt SHA-256 is `4581b992784999bbb04088caec67daf6936b4321faec61bb226c63f7c8499866`. The retained-verification output log SHA-256 is `2e03ac424a10fb2748abc2b428a7a3a49392629ee6e154faccf3ab47f3afe269`; the status file records exit 0 and has SHA-256 `9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa`. The verification ran under `/bin/zsh` from `/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl`.

G7 is met for this source freeze. This package run provides no scientific coverage credit. G2-G5 and G8 remain open, no pilot or confirmation study has passed, and capability remains experimental with covered count seven.

Review note: Style 2/10, high confidence because this is a short evidence log. Genre and coverage: whole technical check report. Evidence and repair: the phrase “G7 is met for this source freeze” states the scope of the retained proof and needs no change. Gates: science not applicable to package execution; facts pass against the runner, source freeze, review receipt, and retained-verifier output; references not applicable because the report contains no external citations. Provenance: self-review of this report on 2026-10-11; v28 package evidence was already seen, and v29 results were checked against their own retained artifacts.
