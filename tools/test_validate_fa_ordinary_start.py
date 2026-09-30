#!/usr/bin/env python3
"""Synthetic controls: no Julia dependency and no campaign data fabrication."""

import contextlib
import io
import json
import math
from pathlib import Path
import tempfile
import unittest

import validate_fa_ordinary_start as validator

SOURCE = "d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a"
DRIVER = "2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b"


def row(seed, klass="recovered"):
    values = [str(seed), "primary", "ok", "true", "true", "recovered", ".2", ".1", "5", ".1", "1200", "default_and_balanced", "2", "default", ".02", ".0999", "false", ".01", ".02", "false", "default:true:true:1200;balanced:true:true:1400", "12", ""]
    item = dict(zip(validator.HEADER, values))
    item["class"] = klass
    item["recovered"] = "true" if klass == "recovered" else "false"
    if klass == "exception":
        item.update(fit_status="exception", converged="false", error="synthetic fit exception")
        item.update({k: "NA" for k in validator.HEADER[6:21]})
        item["seconds"] = "NA"
    elif klass == "nonconverged":
        item.update(converged="false", iterations="5000", per_start="default:true:false:5000;balanced:true:false:5000")
    elif klass == "nonfinite":
        item.update(rel_G="NA", rel_R="NA")
    elif klass == "G_error":
        item["rel_G"] = ".6"
    elif klass == "R_error":
        item["rel_R"] = ".3"
    elif klass == "uniqueness_floor":
        item.update(min_psi=".00005", uniqueness_floor_distance="-.00005", near_uniqueness_floor="true")
    elif klass == "below_truth_objective":
        item["dlog"] = "-.001"
    elif klass == "other_failure":
        item["dlog"] = "NA"
    return item


def manifest():
    return ["# ordinary-start FA recovery; mode=primary; timestamp=2026-09-30T12:00:00",
            f"# source_tree_sha256={SOURCE}; driver_sha256={DRIVER}; host=synthetic",
            "# julia=1.10.0; threads=4; BLAS_threads=1",
            "# seeds=20261200:20261399; attempts=200; iterations=5000",
            "# DGP: 60 pedigree animals (6 sires,12 dams,42 offspring), 3 records each, T=4,K=1, complete; slack=4",
            "# no initial supplied; criteria: conv, finite, relG<=0.45, relR<=0.25, minPsi>=0.0001, dlog>=-1.0e-6, slack>0",
            "# thresholds reused from frozen S2 as conservative diagnostics; not a validated ordinary-start accuracy bar",
            "\t".join(validator.HEADER)]


def terminal_summary(rows):
    # Independent standard Wilson algebra, without calling the implementation.
    n = len(rows)
    k = sum(r["recovered"] == "true" for r in rows)
    p = k / n
    z = 1.959963984540054
    center = (k + z*z/2) / (n + z*z)
    radius = z * (n*p*(1-p) + z*z/4)**.5 / (n + z*z)
    fmt = lambda x: format(x, ".12g")
    return f"# summary n={n} recovered={k} rate={fmt(p)} mcse={fmt((p*(1-p)/n)**.5)} wilson95=[{fmt(center-radius)},{fmt(center+radius)}]"


class ValidatorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.tsv = Path(self.temp.name) / "primary.tsv"
        self.log = Path(self.temp.name) / "primary.log"
        self.log.write_text("SUMMARY synthetic\nWROTE /remote/frozen/primary.tsv\n")
        classes = ["recovered", "G_error", "R_error", "nonconverged", "uniqueness_floor", "below_truth_objective", "exception", "nonfinite", "other_failure"]
        self.rows = [row(seed, classes[i % len(classes)]) for i, seed in enumerate(validator.SEEDS)]

    def write(self, rows=None, summary=True, initial=None):
        rows = self.rows if rows is None else rows
        lines = manifest() if initial is None else initial
        lines += ["\t".join(r[k] for k in validator.HEADER) for r in rows]
        if summary:
            lines.append(terminal_summary(rows))
        self.tsv.write_text("\n".join(lines) + "\n")

    def check(self, **kwargs):
        return validator.validate(self.tsv, SOURCE, DRIVER, log=self.log, **kwargs)

    def rejected(self, pattern, **kwargs):
        with self.assertRaisesRegex(validator.ValidationError, pattern):
            self.check(**kwargs)

    def test_mixed_success_all_200_remain_in_denominator(self):
        self.write()
        result = self.check()
        self.assertEqual(result["n"], 200)
        self.assertEqual(result["recovered"], 23)
        self.assertEqual(result["class_counts"]["exception"], 22)
        self.assertEqual(sum(result["class_counts"].values()), 200)
        self.assertEqual(result["finite_error_summaries"]["all"]["rel_G"]["n"], 156)
        self.assertTrue(result["campaign_complete"])
        self.assertEqual(result["per_start"]["default"]["attempted"], 178)
        self.assertEqual(result["per_start"]["default"]["selected"], 178)
        self.assertEqual(result["per_start"]["balanced"]["selected"], 0)
        self.assertGreater(result["total_start_iterations"], sum(1200 for r in self.rows if r["fit_status"] == "ok"))

    def test_altered_each_hash(self):
        for digest in (SOURCE, DRIVER):
            with self.subTest(digest=digest):
                self.write()
                self.tsv.write_text(self.tsv.read_text().replace(digest, "0"*64))
                self.rejected("hash mismatch")

    def test_truncation_never_complete(self):
        self.write(self.rows[:199], summary=False)
        self.rejected("all 200")
        self.write(summary=False)
        self.rejected("terminal summary")

    def test_duplicates_and_order(self):
        for bad in (validator.SEEDS[0], validator.SEEDS[2]):
            with self.subTest(bad=bad):
                self.rows[1]["seed"] = str(bad)
                self.write()
                self.rejected("unique ordered")

    def test_wrong_field_count_and_header(self):
        self.write()
        lines = self.tsv.read_text().splitlines()
        lines[8] += "\textra"
        self.tsv.write_text("\n".join(lines)+"\n")
        self.rejected("23 fields")
        self.write()
        self.tsv.write_text(self.tsv.read_text().replace("seed\tmode\t", "seed\tMODE\t", 1))
        self.rejected("header")

    def test_all_boolean_fields_strict(self):
        for key in (*validator.BOOLS, *validator.OPTIONAL_BOOLS):
            with self.subTest(key=key):
                saved = self.rows[0][key]
                self.rows[0][key] = "1"
                self.write()
                self.rejected("expected true/false")
                self.rows[0][key] = saved
        self.rows[0]["per_start"] = "default:true:False:1200;balanced:true:true:1400"
        self.write()
        self.rejected("expected true/false")

    def test_every_nullable_numeric_parsed(self):
        for key in validator.NUMBERS:
            with self.subTest(key=key):
                saved = self.rows[0][key]
                self.rows[0][key] = "NaN"
                self.write()
                self.rejected("invalid number")
                self.rows[0][key] = saved

    def test_wrong_summary_count_mcse_and_wilson(self):
        for before, after in (("n=200", "n=199"), ("recovered=23", "recovered=24"), ("mcse=", "mcse=9"), ("wilson95=[", "wilson95=[9")):
            with self.subTest(before=before):
                self.write()
                lines = self.tsv.read_text().splitlines()
                lines[-1] = lines[-1].replace(before, after)
                self.tsv.write_text("\n".join(lines)+"\n")
                self.rejected("summary")

    def test_changed_class_and_false_recovery_rejected(self):
        self.rows[1]["class"] = "R_error"
        self.write()
        self.rejected("recovery/class")
        self.rows[1]["class"] = "G_error"
        self.rows[1]["recovered"] = "true"
        self.write()
        self.rejected("recovery/class")

    def test_precedence_and_overlapping_failures(self):
        self.rows[1].update(rel_R=".4", dlog="-.2")
        self.write()
        result = self.check()
        self.assertEqual(result["class_counts"]["G_error"], 23)
        self.assertEqual(result["overlapping_criterion_failures"]["rel_R"]["definite"], 23)
        self.rows[1]["class"] = "R_error"
        self.write()
        self.rejected("precedence")

    def test_terminal_marker_required_and_final(self):
        self.write()
        for contents in ("SUMMARY synthetic\n", "WROTE /remote/primary.tsv\ncrash\n", "WROTE /remote/other.tsv\n"):
            with self.subTest(contents=contents):
                self.log.write_text(contents)
                self.rejected("WROTE")
        with self.assertRaisesRegex(validator.ValidationError, "--log"):
            validator.validate(self.tsv, SOURCE, DRIVER)

    def test_exception_only_denominator(self):
        self.rows = [row(seed, "exception") for seed in validator.SEEDS]
        self.write()
        result = self.check()
        self.assertEqual(result["recovered"], 0)
        self.assertEqual(result["n"], 200)
        self.assertEqual(result["mcse"], 0)
        self.assertAlmostEqual(result["wilson95"][1], .0188453263772666, places=12)
        self.assertEqual(result["finite_error_summaries"]["all"]["rel_G"]["n"], 0)
        self.assertEqual(result["per_start"]["default"]["attempted"], 0)

    def test_partial_prefix_acceptance_never_implies_completion(self):
        self.write(self.rows[:10], summary=False)
        result = validator.validate(self.tsv, SOURCE, DRIVER, allow_partial=True)
        self.assertEqual(result["status"], "partial")
        self.assertFalse(result["campaign_complete"])
        self.assertEqual(result["n"], 10)
        self.write(self.rows[:10])
        self.rejected("partial stream", allow_partial=True)
        self.rows[0]["seed"] = str(validator.SEEDS[1])
        self.write(self.rows[:10], summary=False)
        self.rejected("unique ordered", allow_partial=True)

    def test_threshold_boundary_rounding_admits_both_classes(self):
        self.rows[0]["rel_G"] = ".45"
        self.write()
        self.assertIn("rel_G", self.check()["threshold_ambiguities"][0]["fields"])
        self.rows[0].update(recovered="false", **{"class": "G_error"})
        self.write()
        self.assertIn("rel_G", self.check()["threshold_ambiguities"][0]["fields"])
        self.rows[0]["rel_G"] = ".44999999999"
        self.write()
        self.rejected("recovery/class")

    def test_other_thresholds_and_na_projection(self):
        for field, value, klass, overrides in (("rel_R", ".25", "R_error", {}),
                                               ("dlog", "-.000001", "below_truth_objective", {}),
                                               ("min_psi", ".0001", "uniqueness_floor", dict(uniqueness_floor_distance="0", near_uniqueness_floor="true"))):
            with self.subTest(field=field):
                self.rows[0] = row(validator.SEEDS[0])
                self.rows[0].update({field: value}, **overrides)
                self.write()
                self.assertIn(field, self.check()["threshold_ambiguities"][0]["fields"])
                self.rows[0].update(recovered="false", **{"class": klass})
                self.write()
                self.assertIn(field, self.check()["threshold_ambiguities"][0]["fields"])
        self.rows[0] = row(validator.SEEDS[0], "other_failure")
        self.rows[0]["rel_G"] = "NA"
        self.write()
        result = self.check()
        self.assertEqual(result["missing_scalar_metric_rows"][0]["fields"], ["rel_G", "dlog"])
        self.assertEqual(result["overlapping_criterion_failures"]["rel_G"]["missing"], 23)
        self.assertEqual(result["overlapping_criterion_failures"]["rel_G"]["definite"], 23)

    def test_nonfinite_scalar_projection_matches_hidden_comparisons(self):
        # Independently evaluate IEEE comparisons before emulating frozen _num.
        # These are synthetic scalar projections, not claims about a real fit.
        cases = [(math.inf, .1, 5, "G_error"),
                 (math.nan, .4, 5, "R_error"),
                 (math.nan, .1, 5, "other_failure"),
                 (math.nan, .1, -math.inf, "below_truth_objective"),
                 (math.nan, math.inf, -math.inf, "R_error"),
                 (math.inf, math.inf, -math.inf, "G_error"),
                 (.2, .1, -math.inf, "below_truth_objective"),
                 (.2, .1, math.nan, "other_failure"),
                 (.2, .1, math.inf, "recovered"),
                 (math.nan, math.nan, 5, "other_failure")]
        for i, (g, r, dlog, expected_class) in enumerate(cases):
            recovered = g <= .45 and r <= .25 and dlog >= -1e-6
            primary_class = ("recovered" if recovered else "G_error" if g > .45 else
                             "R_error" if r > .25 else "below_truth_objective" if dlog < -1e-6 else "other_failure")
            self.assertEqual(primary_class, expected_class)
            item = row(validator.SEEDS[i])
            item.update(rel_G=format(g, ".12g") if math.isfinite(g) else "NA",
                        rel_R=format(r, ".12g") if math.isfinite(r) else "NA",
                        dlog=format(dlog, ".12g") if math.isfinite(dlog) else "NA",
                        recovered="true" if recovered else "false", **{"class": primary_class})
            self.rows[i] = item
        self.write()
        result = self.check()
        self.assertEqual(result["n"], 200)
        self.assertEqual(result["recovered"], sum(r["recovered"] == "true" for r in self.rows))
        self.assertEqual(sum(result["class_counts"].values()), 200)
        self.assertEqual(result["scalar_projection_ambiguities"][0]["fields"], ["rel_G"])
        self.assertIn({"recovered": False, "primary_class": "G_error"}, result["scalar_projection_ambiguities"][0]["compatible_outcomes"])
        self.assertIn({"recovered": False, "primary_class": "other_failure"}, result["scalar_projection_ambiguities"][0]["compatible_outcomes"])
        self.assertGreater(result["overlapping_criterion_failures"]["rel_G"]["possible"], result["overlapping_criterion_failures"]["rel_G"]["definite"])
        self.assertEqual(result["finite_error_summaries"]["recovered"]["dlog"]["n"], result["recovered"] - 1)

    def test_na_projection_does_not_allow_impossible_recovery_or_class(self):
        for overrides in (dict(rel_G="NA"), dict(rel_R="NA"),
                          dict(dlog="NA", **{"class": "G_error", "recovered": "false"}),
                          dict(rel_G="NA", **{"class": "uniqueness_floor", "recovered": "false"})):
            with self.subTest(overrides=overrides):
                self.rows[0] = row(validator.SEEDS[0])
                self.rows[0].update(**overrides)
                self.write()
                self.rejected("recovery/class")

    def test_minimum_nonfinite_projection_constrains_full_finite_gate(self):
        self.rows[0] = row(validator.SEEDS[0], "nonfinite")
        self.rows[0].update(min_psi="NA", uniqueness_floor_distance="NA", near_uniqueness_floor="true")
        self.write()
        self.assertEqual(self.check()["class_counts"]["nonfinite"], 23)
        self.rows[0]["near_uniqueness_floor"] = "false"
        self.write()
        self.assertEqual(self.check()["class_counts"]["nonfinite"], 23)
        self.rows[0]["rel_G"] = ".2"
        self.write()
        self.rejected("contradicts nonfinite uniqueness")

    def test_flags_among_recovered_and_selected_iterations(self):
        self.rows[0].update(min_psi=".0001005", uniqueness_floor_distance=".0000005", near_uniqueness_floor="true",
                            better_nonconverged_start="true", per_start="default:true:true:1200;balanced:true:false:5000")
        self.write()
        result = self.check()
        self.assertEqual(result["diagnostic_flags"]["near_uniqueness_floor"]["recovered"]["true"], 1)
        self.assertEqual(result["diagnostic_flags"]["better_nonconverged_start"]["recovered"]["true"], 1)
        self.rows[0]["iterations"] = "1400"
        self.write()
        self.rejected("selected-start")

    def test_exception_and_diagnostic_null_contract(self):
        self.rows[6]["rel_G"] = ".1"
        self.write()
        self.rejected("exception diagnostics")
        self.rows[6]["rel_G"] = "NA"
        self.rows[0]["near_uniqueness_floor"] = "NA"
        self.write()
        self.rejected("requires diagnostic booleans")

    def test_frozen_manifest_mode_threshold_and_seed_contract(self):
        for before, after in (("mode=primary", "mode=development"), ("relG<=0.45", "relG<=0.5"), ("attempts=200", "attempts=199"), ("slack=4", "slack=0")):
            with self.subTest(before=before):
                self.write()
                self.tsv.write_text(self.tsv.read_text().replace(before, after))
                self.rejected("manifest")

    def test_cli_json_and_failed_exit(self):
        self.write()
        arguments = [str(self.tsv), "--expected-source-sha256", SOURCE, "--expected-driver-sha256", DRIVER, "--log", str(self.log)]
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertEqual(validator.main(arguments), 0)
        self.assertEqual(json.loads(output.getvalue())["status"], "complete")
        self.log.write_text("incomplete\n")
        error = io.StringIO()
        with contextlib.redirect_stderr(error):
            self.assertEqual(validator.main(arguments), 1)
        self.assertEqual(json.loads(error.getvalue())["status"], "invalid")


if __name__ == "__main__":
    unittest.main()
