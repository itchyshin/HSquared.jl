# Independent genomic G2–G6 contract review

Date: 2026-09-30. Verdict: **HOLD for G3 representable-contribution arithmetic**. The exact supplied 88 controls pass; four new public-path boundary assertions fail. G2 label checks, G4 original-Real probability behavior, and scoped G5/G6 wording have no blocker found in this bounded review. Whole-file, calibration and integrated-source approval remain separate.

## Exact proposal and integrity

Prepared root: `/private/tmp/hsq-genomic-contracts-fix-20260930`. Independent scripts/logs: `/private/tmp/e1-genomic-contracts-independent-20260930`.

| Artifact | SHA-256 |
| --- | --- |
| Patch | `aa67600abde5cff6f62de93a7cfe903bf2a583751e893ae44493a811d3209d40` |
| Frozen genomic source | `76c4053d00ed3f35db133089c5f0bfb979c1da70503a4697054bf9fa002d4b9f` |
| Prepared genomic source | `65c97421e92b3a731e49dda7122c19449dbbe43707d7a635825746be6ea9bce2` |
| Prepared source tree | `ab724bd7b701bcd4f80b98e655abab13b8d91301a5301e9694b5f0121be71e97` |
| Summary test | `4abf2b647d13110f92fb91f572e182a914f50f982fa513b37c4645b668e8c23c` |
| Docs binding test | `9d18639f80a0a6847f13128a26fe6a77117d9a58b4c0f08012f56c2eb37c0b27` |
| Independent public boundary script | `27a25616e506faebe2d54931872f152c24da215a0db064e76fce9433ad2df4a1` |
| Independent boundary log | `30b8c596ac859052e1ceccde1e81f4f7506f77cc9b0c240ac60fc7ffa2546282` |
| Independent main log | `9610a44b692c7976301033ff6ad1af8d7ce43868024dadee9da1f7ac4943f85d` |

All supplied inventory entries independently match before and after checks, including Project/Manifest, original/proposal logs, receipt and frozen source. Both aggregate source trees reproduce the specified algorithm. Live Julia source remains `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`; the expected 6271cfd5 checkpoint is source-neutral. `git apply --check` passes without applying to the live checkout. No live or prepared-owner files changed.

## Required repair: rounded square overflow

Prepared src/genomic.jl:2157–2162 computes `(sqrt(allele_variance)*effect)^2`, then rejects nonfinite contributions. This avoids ordinary intermediate effect-square overflow, but an upward-rounded product near sqrt(floatmax) can still overflow when the exact weighted answer is representable.

A concrete Float64 case is p=0.5, effect=1.8961503816218352e154. The exact BigFloat reference `Float64(2*BigFloat(p)*(1-BigFloat(p))*BigFloat(effect)^2)` equals 1.7976931348623155e308 and is finite. The proposal throws ArgumentError. A second Float64 case p=0.1, effect=3.160250636036392e154 also has a finite independent reference and is rejected. These use ordinary Float64 inputs; original high-precision frequency conversion is not the cause.

The independent boundary script checks finite exact references, then calls both public marker_variance_explained and marker_scan_table. **2 pass / 4 fail / 0 error**, testset 0.5 seconds, exit 1. Both public paths fail at both frequencies. This contradicts the proposal's declared preservation of representable contributions.

Minimal repair recommendation: retain the normal fast arithmetic, but when its candidate is nonfinite, compute the exact converted allele-weight/effect product with BigFloat or another bounded-exponent formulation and convert the result to Float64. Accept a finite representable result; retain ArgumentError for genuinely unrepresentable results. Keep the monomorphic zero controls and positive-subnormal median fix. Add both public boundary cases as regression tests. No proposal edits were made by this reviewer. The reviewed summaries return per-marker contributions/proportions; no new aggregate-sum contract was introduced or certified.

## Passing evidence

Estimate before each run: under one minute, one Julia and one BLAS thread, Julia 1.10.0, copied Manifest, --startup-file=no --compiled-modules=no and approved depot order. The exact supplied parent testset passes **88/88**, 23.1 seconds, exit 0. The verified author frozen-source log gives 42 pass / 46 fail out of 88; this review reproduced green and hash-checked the retained frozen red evidence. No fit, optimizer or campaign ran.

- G2: helper at 2214–2227 rejects missing/nothing/empty/whitespace labels before conversion. LOCO construction/scanning, precision keys, scan IDs/group metadata, Manhattan ordering/region selection and optional summaries use it. Literal string missing, ordinary strings/Symbols, collision diagnostics and ordered mapping remain represented by controls.
- G3: the 1e200-effect/1e-200-frequency BigFloat oracle, negative signs, monomorphic endpoints, unrepresentable contribution/proportion guards and ordinary medians pass. Median at 2413–2426 preserves direct subnormal rounding when addition is safe and avoids large same-sign/opposite-sign overflow. Derived inflation is checked for finiteness. These passing cases do not remove the new near-maximum failure.
- G4: alpha helper at 2820–2825 requires the actual Float64 probability inside (0,1). Threshold/permutation entry and returned metadata use that same value. P-value comparison at 2887–2897 retains the original finite observed Real; ±tiny/±huge BigFloat observations are not rounded to tied zero or rejected for Float64 overflow. Existing finite-null and add-one behavior pass.
- G5/G6: genome-wide scan documentation limits evidenced exact/conservative interpretation to intercept-only exchangeable Gaussian residuals; accepted general-covariate residual permutation remains experimental and uncalibrated. Centering/null-vector claims require sample-estimated frequencies, single-step reduction states tau=omega=1/ridge=0, and supplied row-index order is explicit. The probability helper precedes the public docstring; actual Docs.meta binding tests pass for all four public names.

## G1 compatibility and remaining gates

The entire common/cache/stats source segment is byte-identical between frozen and this prepared G2–G6 proposal. The separately approved G1 genomic file remains at `d99ab651d2be5e8612e1c97edcac8b3dcfbe98ee579bad0c71b452f04ad209d9`; its convergence/raw-negative-sign/zero-additive changes are separate. No G1 repair was silently included here. These disjoint changes still require composition, changed combined pins and justified integrated checks after final approval. Source composition should wait for the G3 boundary repair.

Dense storage/inversion, conditioning, provenance, repeated permutation work, external comparison, broad calibration, whole-file review and status promotion remain carried. Public count stays seven. No R activation, release, GPU or E1 approval follows. Parent should return the numeric repair to its original owner, retain this 88-pass plus boundary-HOLD trace, and request a changed-pin independent recheck. Existing exact source context sufficed; no new Graft query was needed.
