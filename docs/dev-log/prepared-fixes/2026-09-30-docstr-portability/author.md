# DocStr portability repair: public prose copy

The original signed receipt is preserved verbatim in hsq-docstr-contract-fix-20261001.tar.gz. Prose-only edits are recorded in this copy.

Author: actual GPT-6.1 Sol, High effort. Date: 2026-10-01 UTC. Baseline HEAD: `ec9414c35d7621c6bd4321a9d16067ac9a2ea2eb`. Scratch author proposal for independent review; final CI approval remains pending. No live source/test, statistical source, Project/Manifest, campaign or protected file was edited. No fit, full suite, build or public mutation was run.

## Failure and supported API

Latest Linux/Windows Julia failed the unchanged exact phrase assertion at `test/runtests.jl:11138`. The hosted log is `/private/tmp/hsq-final-integrated-checks-20260930/repaired-ci-110159958280.log`, lines 1011-1013. `string(@doc fit_payload_v2)` returned the `Base.Docs.DocStr` storage representation, including escaped newlines, rather than parsed human documentation. The unchanged source paragraph splits `is` and `currently` across a raw newline; canonical Markdown joins that paragraph.

Julia 1.13.1's shipped `base/docs/Docs.jl:839-856` documents that `Docs.doc` requires the REPL stdlib to be loaded on Julia 1.11 and newer. Its supported object convenience method is in `stdlib/v1.13/REPL/src/docview.jl:255-257`; the binding path parses and concatenates documentation. Diagnostic evidence confirms raw `DocStr` fails the phrase check, while `string(Base.Docs.doc(fit_payload_v2))` after importing REPL yields `Markdown.MD` human content and passes. Plain terminal MIME rendering wraps lines and splits the same phrase, so this proposal uses the canonical Markdown content string, without a whitespace workaround or changed assertion.

An exhaustive Graft query and test-tree scan found exactly two `string(@doc)` readers: this coefcov contract and the neighboring `fit_animal_model` help test. Both are repaired.

## Exact patch and unchanged criteria

The two-file patch imports REPL and replaces the two readers with `string(Base.Docs.doc(...))`. All original assertions, expected phrases, runtime error checks and public API docstring-presence checks remain unchanged. No unsupported fitting route is opened or silently ignored.

- `docstr-contract.patch`: `c818a18f2cc0e428709f213a07ff02c8a4f9fee72c1395d564c11454ca6d2d88`.
- Original runner: `095f584c0a78e4f51fc34f37f1feb81f314c45831bd24f5e7bdec4ffdc30ea97`.
- Prepared runner: `27b7adbfe0b1c8d397e9041710fe713410d6692d9ef8ebf50af4354a0429adf3`.
- Original API doc test: `11aef2709edc07e7c4497e763e77868a66b7c0c9bf551700e0820a9b8c20a068`.
- Prepared API doc test: `3a3afbfbfb1cf3f81566b8cdb7871dd874b73c4481736a8f097fda8dd3215299`.

`pins.json` records these files, the exact assertion drivers, copied API reference, all current source/Project/Manifest pins and every retained run log/result. `git apply --check` succeeds against the current live candidate. The prepared files are under `candidate/test/`; source/environment bytes are read-only references, not proposal edits.

## Bounded red/green and neighbors

Estimated under 30 seconds per batch; owned timeout 30 seconds, Julia/BLAS one thread, `--startup-file=no`, offline package mode. No heavy/statistical replay was performed.

- Original isolated exact coefcov assertion, Julia 1.13.1: **1 FAIL**, exit 1, 2.77 seconds. This reproduces the hosted representation issue.
- Original isolated exact coefcov assertion, Julia 1.10.0: **1 PASS**, exit 0, 4.70 seconds. Expected older-runtime valid control.
- Prepared exact malformed-block group including unsupported coefcov dispatch/error/doc assertions: **13/13 PASS** on each runtime.
- Prepared neighboring complete API documentation-presence property: **3/3 PASS** on each runtime.
- Prepared neighboring `fit_animal_model` help assertions: **5/5 PASS** on each runtime.
- Green total: **21/21 PASS** on each runtime; 7.51 seconds on 1.13.1 and 5.77 seconds on 1.10.0. `DOC_CONTRACTS_PASS`, exit 0, no estimate overrun.

The green driver copies the original malformed-block group and its exact shared four-animal/eight-record fixture, plus includes the prepared API doc test and unchanged copied `api.md`. Its only engine-dispatch call is the deliberately unsupported coefcov route, which throws before fitting.

An initial diagnostic probe used an unparenthesized `@doc` assignment and Julia interpreted the next expression as doc registration, producing a probe syntax error. Its log/result are retained. Parenthesizing the retrieval fixed the probe; no source/test change was made to resolve that diagnostic mistake.

## Executables, depot, and handoff

Julia 1.13.1 executable: `/Users/z3437171/.julia/juliaup/julia-1.13.1+0.aarch64.apple.darwin14/Julia-1.13.app/Contents/Resources/julia/bin/julia`.

Julia 1.10.0 executable: `/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia`.

Depot: `/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`. Project: `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`. Exact commands, UTC starts, elapsed times and exit statuses are retained in `logs/*-result.json`; `run_owned.py` enforces the process-group timeout. No dependency additions or environment-manifest mutations are proposed.

Independent review, parent integration, one fresh full package suite and renewed current-head hosted checks remain required. Source-identical bridge/docs evidence may retain its existing scope subject to the owner's input attestation. No expanded scientific, production, release or landing claim follows from these documentation controls.

The original frozen receipt is signed by GPT-6.1 Sol, High, author of this isolated test portability proposal.
