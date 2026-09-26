# Check-log: 2026-09-26 #366 N=2000 Rose read (no flip)

## Goal

Claim-vs-evidence read of the Totoro vs DRAC N=2000 pair against the
N=500 bank, after #396 merged as `be25772a`. No covered flip. No
version bump. `public_covered_count` stays 7.

## Commands

```sh
# Lane: ~/local-scratch/lanes/HSquared.jl-coverage-366-n2000
~/shinichi-brain/tools/pr_merge_when_green.sh itchyshin/HSquared.jl 396 --squash
# MERGED 2026-09-26T00:31:48Z mergeCommit be25772a
# settled: 5x SUCCESS CI/docs, SKIPPED live-draw, SUCCESS documenter/deploy
# never --auto on trust; never --admin

# Read (not recomputed):
# docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-totoro-n500-combined-summary.tsv
# …-s5-totoro-n2000-combined-summary.tsv
# …-s5-drac-n2000-combined-summary.tsv
```

## Verdict

HOLD. Same soft spots as N=500. Interior Va 0.903 (Totoro) / 0.915
(DRAC) vs 0.922 (N=500). Near_va h2 0.762 / 0.774 vs 0.763. Not
nominal. Not a flip.

## Fences

No `docs/design/capability-status.md` edit. No `Project.toml` edit.
No `public_covered_count` change.
