# After-task — H3 replacement S10 PATH_ONLY smokes

## 1. Goal

Run exactly two separately sealed H3 replacement S10 smokes on Totoro, retain
all output, and stop before S11 or any public-state action.

## 2. Implemented

Created and locally sealed a source-inert, per-cell runner, validator, launcher,
manifest, and normal-test inclusion at `dd7eeb60`.  Ran one one-thread Totoro
cell for `r_g` and one for `r_am`; both returned a retained valid receipt.

## 3a. Decisions and Rejected Alternatives

The old combined H3 smoke was not reused because it truth-warm-started `r_g`,
omitted the neutral maternal start, and pooled cells.  No alternate seed,
negative-control fit, retry, S11 job, R/bridge edit, capability flip, or release
action was taken.  The decision is HOLD, not promotion.

## 4. Files Touched

- S10 runner, validator, launcher, manifest, and focused test at `dd7eeb60`.
- This check log, decision card, after-task report, and coordination note.
- Local ignored Unlazy ledger and `/private/tmp` evidence cache.

## 5. Checks Run

- Focused local contract/mutation suite: `31/31` across runner and launcher.
- Sealed local validator: `H3_REPLACEMENT_S10_MANIFEST_OK`.
- Full single-thread Julia `Pkg.test()`: exit success.
- Totoro bundle and lock SHA-256 matched; isolated precompile succeeded.
- Totoro and local paired validators: `H3_REPLACEMENT_S10_RECEIPTS_OK`.
- Every retained non-self payload hash verified independently for both cells.

## 6. Tests of the Tests

The focused test initially failed when the self-excluding hash-inventory guard
was absent.  It passed after the single launcher change.  The original raw
inventories reproduce the expected self-check failure while all non-self files
verify, proving both the defect and the limited repair scope.

## 7a. Issue Ledger

- Fixed for future runs: `SHA256SUMS` is excluded from its own inventory.
- Preserved: executed raw inventories retain the historical self-entry; they
  were not rewritten.
- Held: S11, calibration classification, capability/public status, versioning,
  tags, registry actions, and release.

## 8. Consistency Audit

The remote launch used no source diff from `46232fbc`, separate frozen seeds,
the ratified cold/neutral starts, one thread, separate receipt paths, and no
claim-eligible record.  Neither twin's public API or capability ledger changed.

## 9. What Did Not Go Smoothly

The initial SSH output handle ended while `r_am` was still running, but the
unique staged directory and process/log check established that no duplicate was
started; it subsequently published normally.  The checksum self-entry defect
was discovered during post-run audit and transparently bounded.

## 10. Known Residuals

Two successes do not estimate interval coverage.  The S10 implementation commit
contains the original checksum-inventory behavior; the later source-inert fix
is not retroactively applied to raw evidence, and no re-run is authorized.

## 11. Team Learning

Separate receipt directories are necessary scientific controls, not merely
tidier output: they prevent `r_g` and `r_am` from acquiring a shared denominator.
An inventory must never hash itself; independent payload verification is the
safe remediation for already retained evidence.

## 12. Cross-Product Coverage

This covers one Julia-only PATH_ONLY smoke per ratified H3 cell on Totoro.  It
does not cover interval calibration, S11, any R bridge/public surface,
non-Gaussian behavior, promotion, versioning, tags, registry, or release.
