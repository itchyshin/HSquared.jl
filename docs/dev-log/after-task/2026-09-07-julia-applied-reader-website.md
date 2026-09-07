# 2026-09-07 Julia applied-reader website

## 1. Goal

Make the Julia documentation site readable as an applied-reader journey while
preserving its engine-only truth, repair carried-over claim wording, and retain
testable evidence. This is a draft website candidate; it does not publish,
change a status symbol/count, or add a fitted capability.

## 2. Implemented

- Added the five-stage home journey, task-first navigation, R handoff, and the
  `progression-evidence` page.
- Repaired stale 0.7/0.8, FA/SS, bridge, grammar, generated-status, and
  route-specific interval wording without a covered flip.
- Removed source-page CSS links in favour of the VitePress theme import; fixed
  changelog fragments and malformed `g0-rg-teaching.svg` XML.
- Replaced the ineffective flex-card grid override with the actual `display:
  grid` plus item-width override (desktop 5, tablet 3+2); the generated home
  now has an explicit `<ol start="1">` and a real experimental-fit anchor.

## 3a. Decisions and Rejected Alternatives

- Keep `HSquared.jl` the engine route and send applied formula users to
  `hsquared`; do not create a parallel Julia public formula story.
- Keep route-specific interval statements rather than a blanket calibration
  claim. Do not promote any status, change the API, version, or release.
- Use `@raw html` only for the ordered journey list: Documenter shifted every
  Markdown list start to 2. Do not hide responsive overflow globally; correct
  the VitePress flex container itself.
- Treat `versions.js` as a local-build deployment exception: DocumenterVitepress
  only creates it in the post-deployment path, as the build log records.

## 4. Files Touched

`docs/make.jl`; `docs/src/index.md`; `docs/src/progression-evidence.md`;
`docs/src/{quickstart,model-spec-grammar,genomic-models,multivariate-models,fitting-at-scale,standard-qg-models,twin-boundary,validation-status,changelog,genomics-qtl-gpu-hpc}.md`;
`docs/src/.vitepress/theme/{index.ts,overrides.css}`;
`docs/src/assets/g0-rg-teaching.svg`; `src/validation_status.jl`;
`docs/design/{06-public-claims-register,12-bridge-compatibility,capability-status}.md`.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using Pkg; Pkg.test()'`:
  PASS (`Testing HSquared tests passed`), log
  `/private/tmp/hsq-web-20260907-julia-pkgtest-final.log`. This is earlier
  local candidate evidence, not a claim about the later integrated `main`.
- `OPENBLAS_NUM_THREADS=1 julia --project=docs docs/make.jl`: PASS, 20 HTML
  pages; final log `/private/tmp/hsq-web-20260907-julia-documenter-final.log`.
- Rebased candidate build: `OPENBLAS_NUM_THREADS=1 julia --project=docs
  docs/make.jl`: PASS, 20 HTML pages; retained log
  `/private/tmp/hsq-web-20260907-julia-documenter-rebased-candidate.log`.
- `git diff --check`: PASS. `xmllint --noout docs/src/assets/*.svg`: PASS.
- Link audit after rebuild: 20 HTML, 1,591 references, zero fragments and
  zero alternative missing assets; the 20 local `/versions.js` references are
  the known deployment-generation exception.
- Parent browser refresh: 20 pages × 4 viewports = 80 HTTP-200 observations;
  zero bad images, missing alternative text, page-script errors, or page-level
  width mismatch, retained in
  `/private/tmp/hsq-web-20260907-julia-verified-routes.json`. Terra's local
  usability recheck is PASS at `a3342cf`; Sol's exact-head F4 claims recheck is
  CLEAN at `a3342cf` (`/private/tmp/hsq-web-20260907-usability-review.md` and
  `/private/tmp/hsq-web-20260907-claims-review.md`).

## 6. Tests of the Tests

The initial docs build failed on an unquoted YAML colon; the source was quoted
and the succeeding build is retained. The first fresh test found a stale
`public_covered_count` exact-string expectation; source and generated table
were reconciled before the final PASS. The browser/link audit first exposed
eight missing CSS assets, four bad changelog anchors, a malformed SVG, flex
cards that ignored `grid-template-columns`, and the list-start transformation;
each is now represented in generated output or source inspection.

## 7a. Issue Ledger

- Fixed: stale universal H0 interval wording, stale MV count wording, FA 8/10
  denominator ambiguity, AGHmatrix construction-vs-fit ambiguity, private
  scratch citation, CSS/anchor/SVG defects, 4+1 desktop/tablet cards, and 2–6
  journey numbering.
- Completed after the initial receipt: parent browser sweep at 320/768/1024/
  1440; #317 merged as `5471354`, and the reconciled #318 merged as
  `022e8503` after exact-head CI.
- Deferred: candidate PR CI/review and any publication remain separate. The
  website is not deployed or merged by this record.

## 8. Consistency Audit

The full initial inventory below was checked, not only the pages edited.
Navigation and the generated build include the 18 original source pages plus
new progression (19 source pages; 20 HTML including 404). Historical wording
now distinguishes the verified R v0.1.0 GitHub release from the later Julia
0.5 numbering marker; it does not create a tag or release.

| Source page | Disposition | Reader role |
| --- | --- | --- |
| index | correct | Get started |
| quickstart | correct | Get started |
| data | retain | Get started |
| pedigree-ainv | retain | Get started |
| standard-qg-models | retain | Choose model |
| model-spec-grammar | correct | Choose model |
| genomic-models | correct | Choose model |
| multivariate-models | correct | Choose model |
| fitting-at-scale | retain | Fit |
| validation-status | correct | Diagnose |
| twin-boundary | correct | Report |
| audience-comparators | retain | Report |
| api | retain | Reference |
| roadmap | retain | Developer |
| backend-algorithm-roadmap | retain | Developer |
| genomics-qtl-gpu-hpc | correct | Developer |
| changelog | restructure | Progression |
| mission-control | retain | Developer |
| progression-evidence (new) | add | Report/history |

## 9. What Did Not Go Smoothly

The first generator call hit a stale Julia precompile pidfile after superseded
test processes; process inspection confirmed no live owner, then one-thread
generation succeeded. A candidate package test had no duplicate sibling but
ran for about three minutes. Documenter escaped bare HTML and shifts Markdown
ordered-list starts, so the final solution uses its supported `@raw html`
fence. PR #317's first all-green head was non-mergeable and required a rebase;
its rebased exact head later merged. #318 likewise required a clean rebase to
replace stale #315/#316 bridge wording before its exact-head checks could run.

## 10. Known Residuals

The rebased website candidate is `8099e0e1`, four commits ahead of integrated
`origin/main` `022e8503`, and remains local/draft-only until its draft PR and
candidate CI complete. #317 merged as `5471354`; the rebase-reconciled #318
merged as `022e8503` after all of its exact-head checks were green. Main's
Documenter run `34150274656` and parent-dispatched package CI run
`34150400073` are SUCCESS at that same head; this current-main proof is
distinct from the earlier local `Pkg.test` PASS.
No local build can contain deployment-created `versions.js`; no publication is
authorized or implied.

## 11. Team Learning

Memory receipt: loaded the HSquared rehydration, prose-style, bridge, and
after-task instructions; the route-specific public/engine boundary and the
no-covered-flip rule shaped every edit. Golden Set: not applicable; this is
documentation/status repair, not a new estimator. Durable lesson:
VitePress home features use flex widths, so a responsive column repair must
change `display` and child width, not only `grid-template-columns`; verify the
rendered DOM, not the source selector.

## 12. Cross-Product Coverage

The reader journey covers ✓ source navigation, generated HTML, local link
targets, responsive CSS intent, interval wording, and R-versus-engine wayfinding.
It does NOT cover ✗ public deployment, a Julia General release, R API changes,
new fitting science, status promotion, calibrated intervals, candidate-PR CI /
review, or website publication. The 80-observation browser receipt is local
rendered evidence, not deployed-site or assistive-technology proof.
