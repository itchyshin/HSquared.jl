"""Synthetic contract tests for the eight-cell Arc 1 pilot launcher."""
from __future__ import annotations

import importlib.util
import hashlib
import json
import os
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "arc1_pilot_cells", ROOT / "sim/arc1/run_pilot_cells.py")
assert SPEC and SPEC.loader
pilot = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = pilot
SPEC.loader.exec_module(pilot)


def expected_cells():
    return [
        {"programme": "fa_rank", "phase": "pilot", "N": n, "signal": signal}
        for n in (80, 160, 320)
        for signal in ("null", "weak", "strong")
        if (n, signal) != (80, "null")
    ]


def attach_history(container, root: Path):
    root.mkdir(parents=True, exist_ok=True)
    source = root / "attempt-record.json"
    source.write_text(json.dumps({
        "programme": "fa_rank", "phase": "development", "N": 80,
        "signal": "null", "outer": 1, "seed": 999999,
        "status": "child_error", "consumed": True,
    }, sort_keys=True) + "\n", encoding="utf-8")
    listing = root / "root-listing.json"
    listing_value = {
        "schema": "arc1-retained-attempt-root-listing-v1",
        "root_id": "synthetic-root-1",
        "root_path": str(root.resolve()),
        "enumeration_complete": True,
        "entries": [{"path": str(source.resolve()),
                     "sha256": hashlib.sha256(source.read_bytes()).hexdigest()}],
    }
    listing.write_text(json.dumps(listing_value, sort_keys=True) + "\n", encoding="utf-8")
    root_inventory = {
        "schema": "arc1-retained-attempt-root-inventory-v1",
        "scope": "all-retained-arc1-attempt-records",
        "status": "complete",
        "roots": [{
            "root_id": "synthetic-root-1",
            "path": str(root.resolve()),
            "status": "complete",
            "listing_path": str(listing.resolve()),
            "listing_sha256": hashlib.sha256(listing.read_bytes()).hexdigest(),
            "record_count": 1,
            "unreadable_count": 0,
            "unparsed_count": 0,
        }],
    }
    root_inventory["inventory_sha256"] = pilot._canonical_sha256(root_inventory)
    inventory_path = root / "root-inventory.json"
    inventory_path.write_text(json.dumps(root_inventory, sort_keys=True) + "\n",
                              encoding="utf-8")
    history = {
        "schema": "arc1-consumed-attempt-history-v1",
        "scope": "all-retained-arc1-attempt-records",
        "status": "complete",
        "attempts": [{
            "programme": "fa_rank", "phase": "development", "N": 80,
            "signal": "null", "outer": 1, "seed": 999999,
            "status": "child_error", "consumed": True,
            "root_id": "synthetic-root-1",
            "source_path": str(source.resolve()),
            "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        }],
        "sources": {
            str(source.resolve()): hashlib.sha256(source.read_bytes()).hexdigest(),
            str(listing.resolve()): hashlib.sha256(listing.read_bytes()).hexdigest(),
        },
        "root_inventory_path": str(inventory_path.resolve()),
        "root_inventory_sha256": hashlib.sha256(inventory_path.read_bytes()).hexdigest(),
    }
    history_path = root / "consumed-attempt-history.json"
    history_path.write_text(json.dumps(history, sort_keys=True) + "\n", encoding="utf-8")
    history_sha = hashlib.sha256(history_path.read_bytes()).hexdigest()
    review = {
        "schema": "arc1-consumed-attempt-history-review-v1",
        "status": "complete",
        "scope": "all-retained-arc1-attempt-records",
        "history_sha256": history_sha,
        "root_inventory_sha256": history["root_inventory_sha256"],
        "reviewer": "independent-reviewer",
        "reviewed_at_utc": "2026-10-23T00:00:00Z",
        "independent": True,
        "scope_complete": True,
        "attempt_count": len(history["attempts"]),
        "root_count": len(root_inventory["roots"]),
        "source_count": len(history["sources"]),
    }
    review_path = root / "consumed-attempt-history-review.json"
    review_path.write_text(json.dumps(review, sort_keys=True) + "\n", encoding="utf-8")
    container["consumed_attempt_history"] = {
        "history_path": str(history_path.resolve()),
        "history_sha256": history_sha,
        "review_path": str(review_path.resolve()),
        "review_sha256": hashlib.sha256(review_path.read_bytes()).hexdigest(),
    }


def rewrite_history_bundle(plan, *, mutate_inventory, mutate_listing=None,
                           mutate_history=None):
    reference = plan["consumed_attempt_history"]
    history_path = Path(reference["history_path"])
    review_path = Path(reference["review_path"])
    history = json.loads(history_path.read_text(encoding="utf-8"))
    inventory_path = Path(history["root_inventory_path"])
    inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    if mutate_listing is not None:
        listing_path = Path(inventory["roots"][0]["listing_path"])
        listing = json.loads(listing_path.read_text(encoding="utf-8"))
        mutate_listing(listing)
        listing_bytes = (json.dumps(listing, sort_keys=True) + "\n").encode()
        listing_path.write_bytes(listing_bytes)
        listing_hash = hashlib.sha256(listing_bytes).hexdigest()
        history["sources"][str(listing_path)] = listing_hash
        inventory["roots"][0]["listing_sha256"] = listing_hash
    mutate_inventory(inventory)
    inventory_body = {key: value for key, value in inventory.items()
                      if key != "inventory_sha256"}
    inventory["inventory_sha256"] = pilot._canonical_sha256(inventory_body)
    inventory_bytes = (json.dumps(inventory, sort_keys=True) + "\n").encode()
    inventory_path.write_bytes(inventory_bytes)
    history["root_inventory_sha256"] = hashlib.sha256(inventory_bytes).hexdigest()
    if mutate_history is not None:
        mutate_history(history)
    history_bytes = (json.dumps(history, sort_keys=True) + "\n").encode()
    history_path.write_bytes(history_bytes)
    review = json.loads(review_path.read_text(encoding="utf-8"))
    review["history_sha256"] = hashlib.sha256(history_bytes).hexdigest()
    review["root_inventory_sha256"] = history["root_inventory_sha256"]
    review_bytes = (json.dumps(review, sort_keys=True) + "\n").encode()
    review_path.write_bytes(review_bytes)
    reference["history_sha256"] = hashlib.sha256(history_bytes).hexdigest()
    reference["review_sha256"] = hashlib.sha256(review_bytes).hexdigest()
    plan["plan_sha256"] = pilot._canonical_sha256(
        {key: value for key, value in plan.items() if key != "plan_sha256"})


def batch_fixture(admission_dir: Path):
    jobs = []
    admission_dir.mkdir(parents=True, exist_ok=True)
    for i, cell in enumerate(expected_cells()):
        admission = {
            "schema": "arc1-run-admission-v2",
            "cell": cell,
            "planned_attempts": 30,
            "expected_outer_seeds": list(range(i * 100 + 1, i * 100 + 31)),
            "source_sha256": {"Project.toml": "a" * 64,
                              "Manifest.toml": "b" * 64,
                              "tools/arc1_manifest.py": "c" * 64},
            "threads": {"julia": 1, "blas": 1},
            "thread_environment": {"JULIA_NUM_THREADS": "1",
                                  "OPENBLAS_NUM_THREADS": "1"},
            "julia_version": "1.10.0",
            "status": "admitted_before_execution",
        }
        admission_path = admission_dir / f"{i}.json"
        admission_path.write_text(json.dumps(admission), encoding="utf-8")
        jobs.append({"cell": cell, "admission": admission,
                     "admission_path": str(admission_path)})
    batch = {"schema": pilot.BATCH_SCHEMA, "jobs": jobs}
    attach_history(batch, admission_dir.parent / "history")
    return batch


def authorization_plan(root: Path, *, include_history: bool = True):
    output = (root / "results").resolve()
    jobs = []
    source_hashes = {"src/HSquared.jl": "b" * 64}
    source_lock_sha256 = pilot._canonical_sha256(source_hashes)
    for i, cell in enumerate(expected_cells(), start=1):
        admission = {"schema": "arc1-run-admission-v2", "cell": cell,
                     "planned_attempts": 30,
                     "expected_outer_seeds": list(range(i * 100 + 1, i * 100 + 31)),
                     "source_sha256": source_hashes,
                     "threads": {"julia": 1, "blas": 1},
                     "thread_environment": {"JULIA_NUM_THREADS": "1",
                                            "OPENBLAS_NUM_THREADS": "1"},
                     "julia_version": "1.10.0", "status": "admitted_before_execution"}
        admission_path = root / f"{i}.admission.json"
        admission_path.write_text(json.dumps(admission), encoding="utf-8")
        jobs.append({"cell": cell, "admission_path": str(admission_path),
                     "admission_sha256": pilot._canonical_sha256(admission),
                     "source_lock_sha256": source_lock_sha256,
                     "expected_outer_seeds": admission["expected_outer_seeds"],
                     "output_dir": str(pilot.runner.cell_output_dir(output, cell)),
                     "outers": list(range(1, 31)), "threads": {"julia": 1, "blas": 1}})
    plan = {"schema": pilot.PLAN_SCHEMA, "scope": pilot.EXECUTION_SCOPE,
            "batch_sha256": "a" * 64, "source_lock_sha256": source_lock_sha256,
            "source_root": str(ROOT.resolve()),
            "output_root": str(output),
            "launcher_sha256": hashlib.sha256((ROOT / "sim/arc1/run_pilot_cells.py").read_bytes()).hexdigest(),
            "jobs": jobs, "planned_cells": 8, "planned_attempts": 240,
            "maximum_concurrent_cell_workers": 4, "julia_threads_per_job": 1,
            "blas_threads_per_job": 1, "execution_started": False}
    if include_history:
        attach_history(plan, root / "history")
    plan["plan_sha256"] = pilot._canonical_sha256(plan)
    return plan


def prerun_receipt(plan):
    attempts = []
    for job in plan["jobs"]:
        path = Path(job["output_dir"]) / "attempts" / "0001.result.json"
        path.parent.mkdir(parents=True, exist_ok=True)
        result = {"outer": 1, "seed": job["expected_outer_seeds"][0],
                  "admission_sha256": job["admission_sha256"], "status": "ok",
                  "success": True, "elapsed_seconds": 8.0,
                  "child_elapsed_seconds": 9.0,
                  "execution_identity": {"fixture": True}}
        path.write_text(json.dumps(result), encoding="utf-8")
        launcher_path = (Path(job["output_dir"]) / "launcher-attempts" /
                         "0001.result.json")
        launcher_path.parent.mkdir(parents=True, exist_ok=True)
        launcher_result = {"outer": 1, "seed": job["expected_outer_seeds"][0],
                           "admission_sha256": job["admission_sha256"],
                           "plan_sha256": plan["plan_sha256"],
                           "batch_sha256": plan["batch_sha256"],
                           "launcher_sha256": plan["launcher_sha256"],
                           "status": "child_complete", "success": True,
                           "returncode": 0, "elapsed_seconds": 10.0,
                           "runner_result_sha256": hashlib.sha256(
                               path.read_bytes()).hexdigest()}
        launcher_path.write_text(json.dumps(launcher_result), encoding="utf-8")
        attempts.append({"cell": job["cell"], "outer": 1,
                         "seed": job["expected_outer_seeds"][0],
                         "admission_sha256": job["admission_sha256"],
                         "status": "child_complete", "success": True,
                         "returncode": 0, "elapsed_seconds": 10.0,
                         "runner_result_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                         "launcher_result_sha256": hashlib.sha256(
                             launcher_path.read_bytes()).hexdigest()})
    receipt = {"schema": pilot.PRERUN_SCHEMA, "status": "complete",
               "plan_sha256": plan["plan_sha256"],
               "batch_sha256": plan["batch_sha256"],
               "source_root": plan["source_root"], "output_root": plan["output_root"],
               "estimation_method": pilot.ESTIMATION_METHOD,
               "attempts": attempts}
    with patch.object(pilot.manifest, "verify_run_admission"), \
            patch.object(pilot.manifest, "verify_execution_identity"):
        receipt["estimated_total_seconds"] = pilot._measured_prerun_estimate(receipt, plan)
    return receipt


class PilotBatchContract(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.admissions = self.root / "admissions"
        self.source = ROOT.resolve()

    def tearDown(self):
        self.tempdir.cleanup()

    def validate(self, batch):
        return pilot.validate_batch(batch, source_root=self.source,
                                    verify_admission=lambda *_args, **_kwargs: None)

    def test_accepts_exact_eight_unrun_cells_with_one_thread_each(self):
        batch = batch_fixture(self.admissions)
        plan = self.validate(batch)
        self.assertEqual(len(plan["jobs"]), 8)
        self.assertEqual(plan["planned_attempts"], 240)
        self.assertEqual(plan["maximum_concurrent_cell_workers"], 4)
        self.assertTrue(all(job["threads"] == {"julia": 1, "blas": 1}
                            for job in plan["jobs"]))

    def test_rejects_admissions_with_divergent_source_locks(self):
        for mutation in ("digest", "path_set"):
            with self.subTest(mutation=mutation):
                batch = batch_fixture(self.admissions / mutation)
                admission = batch["jobs"][1]["admission"]
                if mutation == "digest":
                    admission["source_sha256"]["tools/arc1_manifest.py"] = "e" * 64
                else:
                    del admission["source_sha256"]["tools/arc1_manifest.py"]
                Path(batch["jobs"][1]["admission_path"]).write_text(
                    json.dumps(admission), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "share one complete source lock"):
                    self.validate(batch)

    def test_resume_plan_rejects_admissions_with_divergent_source_locks(self):
        plan = authorization_plan(self.root)
        job = plan["jobs"][1]
        admission_path = Path(job["admission_path"])
        admission = json.loads(admission_path.read_text(encoding="utf-8"))
        admission["source_sha256"]["src/HSquared.jl"] = "c" * 64
        admission_path.write_text(json.dumps(admission), encoding="utf-8")
        job["admission_sha256"] = pilot._canonical_sha256(admission)
        plan["plan_sha256"] = pilot._canonical_sha256(
            {key: value for key, value in plan.items() if key != "plan_sha256"})
        with patch.object(pilot.manifest, "verify_run_admission"):
            self.assertFalse(pilot._plan_contract_valid(plan))

    def test_resume_plan_rejects_worker_count_above_four(self):
        plan = authorization_plan(self.root)
        with patch.object(pilot.manifest, "verify_run_admission"):
            self.assertTrue(pilot._plan_contract_valid(plan))
            plan["maximum_concurrent_cell_workers"] = 8
            self.assertFalse(pilot._plan_contract_valid(plan))

    def test_source_configuration_loads_engine_modules_from_requested_root(self):
        recovery = Path("/private/tmp/HSquared.jl-arc1-recovery-20261015")
        original_root = pilot.ENGINE_ROOT
        try:
            pilot.configure_source_root(recovery)
            self.assertEqual(pilot.ENGINE_ROOT, recovery.resolve())
            self.assertEqual(Path(pilot.runner.__file__).resolve(),
                             recovery / "sim/arc1/runner.py")
            self.assertEqual(Path(pilot.manifest.__file__).resolve(),
                             recovery / "tools/arc1_manifest.py")
            self.assertIs(pilot.runner.manifest, pilot.manifest)
        finally:
            pilot.configure_source_root(original_root)

    def test_plan_pins_eight_cells_and_is_source_output_disjoint(self):
        batch = batch_fixture(self.admissions)
        plan = pilot.make_plan(batch, source_root=self.source,
                               output_root=self.root / "results",
                               verify_admission=lambda *_args, **_kwargs: None)
        self.assertEqual(plan["planned_cells"], 8)
        self.assertEqual(plan["planned_attempts"], 240)
        source_lock = pilot._canonical_sha256(
            batch["jobs"][0]["admission"]["source_sha256"])
        self.assertEqual(plan["source_lock_sha256"], source_lock)
        self.assertTrue(all(job["source_lock_sha256"] == source_lock
                            for job in plan["jobs"]))
        self.assertEqual(plan["plan_sha256"], pilot._canonical_sha256(
            {key: value for key, value in plan.items() if key != "plan_sha256"}))
        with self.assertRaisesRegex(ValueError, "disjoint"):
            pilot.make_plan(batch, source_root=self.source,
                            output_root=self.source,
                            verify_admission=lambda *_args, **_kwargs: None)

    def test_plan_rejects_output_inside_git_checkout_before_writing(self):
        batch = batch_fixture(self.admissions)
        checkout = self.root / "checkout"
        checkout.mkdir()
        (checkout / ".git").write_text("gitdir: /missing", encoding="utf-8")
        results = checkout / "results"
        with self.assertRaisesRegex(ValueError, "inside a Git checkout"):
            pilot.make_plan(batch, source_root=self.source, output_root=results,
                            verify_admission=lambda *_args, **_kwargs: None)
        self.assertFalse(results.exists())

    def test_rejects_consumed_n80_null_cell(self):
        batch = batch_fixture(self.admissions)
        batch["jobs"][0]["cell"] = {
            "programme": "fa_rank", "phase": "pilot", "N": 80, "signal": "null"}
        batch["jobs"][0]["admission"]["cell"] = dict(batch["jobs"][0]["cell"])
        with self.assertRaisesRegex(ValueError, "exact eight unrun"):
            self.validate(batch)

    def test_rejects_missing_duplicate_or_extra_cells(self):
        for mutation in ("missing", "duplicate", "extra"):
            with self.subTest(mutation=mutation):
                batch = batch_fixture(self.admissions)
                if mutation == "missing":
                    batch["jobs"].pop()
                elif mutation == "duplicate":
                    batch["jobs"][-1] = dict(batch["jobs"][0])
                else:
                    batch["jobs"].append(dict(batch["jobs"][0]))
                with self.assertRaises(ValueError):
                    self.validate(batch)

    def test_rejects_wrong_attempt_count_seed_count_or_threads(self):
        for field, value in (("planned_attempts", 29),
                             ("expected_outer_seeds", list(range(29))),
                             ("threads", {"julia": 4, "blas": 1})):
            with self.subTest(field=field):
                batch = batch_fixture(self.admissions)
                batch["jobs"][0]["admission"][field] = value
                with self.assertRaises(ValueError):
                    self.validate(batch)

    def test_rejects_single_attempt_scope_in_full_batch_admission(self):
        batch = batch_fixture(self.admissions)
        job = batch["jobs"][0]
        job["admission"]["single_attempt_review_scope"] = {
            "schema": "arc1-single-attempt-review-scope-v1",
            "cell": job["cell"],
            "outer": 1,
            "seed": job["admission"]["expected_outer_seeds"][0],
            "attempts": 1,
            "gate_credit": False,
            "retry_permitted": False,
            "replacement_permitted": False,
        }
        Path(job["admission_path"]).write_text(
            json.dumps(job["admission"]), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "single-attempt.*batch"):
            self.validate(batch)

    def test_requires_execution_authorization_bound_to_plan(self):
        plan = authorization_plan(self.root)
        original_output = plan["output_root"]
        self.assertFalse(pilot.execution_authorized(None, plan))
        receipt_path = self.root / "measured-prerun.json"
        receipt = prerun_receipt(plan)
        receipt_path.write_text(json.dumps(receipt) + "\n", encoding="utf-8")
        auth = {"schema": pilot.AUTHORIZATION_SCHEMA,
                "scope": pilot.EXECUTION_SCOPE,
                "approval": pilot.OWNER_APPROVAL_TEXT,
                "plan_sha256": plan["plan_sha256"],
                "batch_sha256": plan["batch_sha256"],
                "source_root": plan["source_root"],
                "output_root": plan["output_root"],
                "pre_run_receipt_path": str(receipt_path),
                "pre_run_receipt_sha256": hashlib.sha256(receipt_path.read_bytes()).hexdigest(),
                "estimated_total_seconds": receipt["estimated_total_seconds"],
                "owner_approved_total_seconds": receipt["estimated_total_seconds"],
                "approved_by_owner": True}
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            self.assertTrue(pilot.execution_authorized(auth, plan))
            receipt_path.write_text("changed after approval", encoding="utf-8")
            self.assertFalse(pilot.execution_authorized(auth, plan))
            bad_receipt = dict(receipt)
            bad_receipt["attempts"] = [dict(row) for row in receipt["attempts"]]
            bad_receipt["attempts"][0]["status"] = "failed"
            receipt_path.write_text(json.dumps(bad_receipt) + "\n", encoding="utf-8")
            auth["pre_run_receipt_sha256"] = hashlib.sha256(receipt_path.read_bytes()).hexdigest()
            self.assertFalse(pilot.execution_authorized(auth, plan))
            receipt_path.write_text(json.dumps(receipt) + "\n", encoding="utf-8")
            auth["pre_run_receipt_sha256"] = hashlib.sha256(receipt_path.read_bytes()).hexdigest()
            plan["output_root"] = "/changed"
            self.assertFalse(pilot.execution_authorized(auth, plan))
            plan["output_root"] = original_output
            auth["batch_sha256"] = "c" * 64
            self.assertFalse(pilot.execution_authorized(auth, plan))

    def test_execution_authorization_parses_the_hash_verified_receipt_bytes(self):
        plan = authorization_plan(self.root)
        receipt_path = self.root / "measured-prerun.json"
        receipt = prerun_receipt(plan)
        receipt_path.write_text(json.dumps(receipt) + "\n", encoding="utf-8")
        auth = {"schema": pilot.AUTHORIZATION_SCHEMA,
                "scope": pilot.EXECUTION_SCOPE,
                "approval": pilot.OWNER_APPROVAL_TEXT,
                "plan_sha256": plan["plan_sha256"],
                "batch_sha256": plan["batch_sha256"],
                "source_root": plan["source_root"],
                "output_root": plan["output_root"],
                "pre_run_receipt_path": str(receipt_path),
                "pre_run_receipt_sha256": hashlib.sha256(receipt_path.read_bytes()).hexdigest(),
                "estimated_total_seconds": receipt["estimated_total_seconds"],
                "owner_approved_total_seconds": receipt["estimated_total_seconds"],
                "approved_by_owner": True}
        original_read_text = Path.read_text

        def reject_second_receipt_read(path, *args, **kwargs):
            if path.resolve() == receipt_path.resolve():
                raise OSError("simulated receipt replacement between reads")
            return original_read_text(path, *args, **kwargs)

        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"), \
                patch.object(Path, "read_text", reject_second_receipt_read):
            self.assertTrue(pilot.execution_authorized(auth, plan))

    def test_plan_contract_rejects_missing_consumed_attempt_history(self):
        plan = authorization_plan(self.root, include_history=False)
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            self.assertFalse(pilot._plan_contract_valid(plan))

    def test_plan_contract_rejects_root_claimed_complete_when_root_is_missing(self):
        plan = authorization_plan(self.root)
        rewrite_history_bundle(
            plan,
            mutate_inventory=lambda inventory: inventory["roots"][0].update(
                path=str(self.root / "does-not-exist")))
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            self.assertFalse(pilot._plan_contract_valid(plan))

    def test_plan_contract_rejects_root_listing_hash_not_in_source_pins(self):
        plan = authorization_plan(self.root)
        rewrite_history_bundle(
            plan,
            mutate_inventory=lambda inventory: inventory["roots"][0].update(
                listing_sha256="f" * 64))
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            self.assertFalse(pilot._plan_contract_valid(plan))

    def test_plan_contract_rejects_incomplete_root_listing(self):
        plan = authorization_plan(self.root)
        rewrite_history_bundle(
            plan, mutate_inventory=lambda _inventory: None,
            mutate_listing=lambda listing: listing.update(enumeration_complete=False))
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            self.assertFalse(pilot._plan_contract_valid(plan))

    def test_plan_contract_rejects_attempt_not_present_in_its_root_listing(self):
        plan = authorization_plan(self.root)
        rewrite_history_bundle(
            plan, mutate_inventory=lambda _inventory: None,
            mutate_history=lambda history: history["attempts"][0].update(
                source_path=str(self.root / "unlisted-attempt.json")))
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            self.assertFalse(pilot._plan_contract_valid(plan))

    def test_plan_contract_rejects_root_listing_entry_outside_root(self):
        plan = authorization_plan(self.root)
        outside = self.root / "outside-attempt.json"
        outside.write_text(json.dumps({"unrelated": True}), encoding="utf-8")
        outside_hash = hashlib.sha256(outside.read_bytes()).hexdigest()

        def replace_entry(listing):
            listing["entries"][0].update(path=str(outside.resolve()), sha256=outside_hash)

        def pin_outside_source(history):
            history["sources"][str(outside.resolve())] = outside_hash

        rewrite_history_bundle(
            plan, mutate_inventory=lambda _inventory: None,
            mutate_listing=replace_entry, mutate_history=pin_outside_source)
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            self.assertFalse(pilot._plan_contract_valid(plan))

    def test_plan_contract_rejects_root_path_that_is_a_file(self):
        plan = authorization_plan(self.root)
        file_path = self.root / "not-a-directory"
        file_path.write_text("x", encoding="utf-8")

        def bind_file_as_root(inventory):
            inventory["roots"][0]["path"] = str(file_path.resolve())

        def bind_listing_root(listing):
            listing["root_path"] = str(file_path.resolve())

        rewrite_history_bundle(
            plan, mutate_inventory=bind_file_as_root,
            mutate_listing=bind_listing_root)
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            self.assertFalse(pilot._plan_contract_valid(plan))

    def test_plan_contract_rejects_attempt_identity_mismatch_with_source_record(self):
        plan = authorization_plan(self.root)
        rewrite_history_bundle(
            plan, mutate_inventory=lambda _inventory: None,
            mutate_history=lambda history: history["attempts"][0].update(seed=1000000))
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            self.assertFalse(pilot._plan_contract_valid(plan))

    def test_execution_refuses_missing_authorization_before_dispatch(self):
        with self.assertRaises(PermissionError):
            pilot.execute_plan({}, authorization={})

    def test_timeout_stops_child_process_group(self):
        pid_file = self.root / "grandchild.pid"
        heartbeat_file = self.root / "grandchild-heartbeat.txt"
        heartbeat = ("import pathlib,time; p=pathlib.Path(" + repr(str(heartbeat_file)) + "); i=0; "
                     "exec('while True:\\n i += 1\\n p.write_text(str(i))\\n time.sleep(0.02)')")
        child_code = ("import subprocess,sys,time; "
                      f"child=subprocess.Popen([sys.executable,'-c',{heartbeat!r}]); "
                      f"open({str(pid_file)!r},'w').write(str(child.pid)); time.sleep(30)")
        real_popen = pilot.subprocess.Popen
        launched = []

        def tracking_popen(*args, **kwargs):
            process = real_popen(*args, **kwargs)
            launched.append(process)
            return process

        with patch.object(pilot.subprocess, "Popen", tracking_popen):
            with self.assertRaises(subprocess.TimeoutExpired):
                pilot._run_child([sys.executable, "-c", child_code],
                                 env=os.environ.copy(), timeout=1.5)
        self.assertEqual(len(launched), 1)
        self.assertIsNotNone(launched[0].poll())
        self.assertTrue(pid_file.exists())
        grandchild_pid = pid_file.read_text(encoding="utf-8").strip()
        self.assertTrue(heartbeat_file.exists())
        before = heartbeat_file.read_text(encoding="utf-8")
        time.sleep(0.15)
        after = heartbeat_file.read_text(encoding="utf-8")
        if after != before:
            os.kill(int(grandchild_pid), signal.SIGKILL)
        self.assertEqual(after, before, "grandchild continued running after parent timeout")

    # These synthetic tests exercise lower-level handling below the temporary pause.
    @patch.object(pilot, "require_verified_attempt_record", lambda: None)
    def test_unresolved_retained_outer_stops_later_outers(self):
        for record_kind in ("launcher_error", "launcher_started", "runner_failed",
                            "launcher_stale_success", "runner_identityless_success"):
            with self.subTest(record_kind=record_kind):
                output_dir = self.root / record_kind / "cell"
                record_dir = output_dir / "launcher-attempts"
                record_dir.mkdir(parents=True)
                admission_sha = "d" * 64
                common = {"outer": 1, "seed": 101,
                          "admission_sha256": admission_sha}
                if record_kind == "launcher_error":
                    record_path = record_dir / "0001.result.json"
                    record = {**common, "status": "launcher_error", "success": False}
                elif record_kind == "launcher_started":
                    record_path = record_dir / "0001.started.json"
                    record = {**common, "status": "launcher_started"}
                elif record_kind == "launcher_stale_success":
                    runner_path = output_dir / "attempts" / "0001.result.json"
                    runner_path.parent.mkdir(parents=True)
                    runner_record = {**common, "status": "ok", "success": True}
                    runner_path.write_text(json.dumps(runner_record), encoding="utf-8")
                    record_path = record_dir / "0001.result.json"
                    record = {**common, "status": "child_complete", "success": True,
                              "returncode": 0, "plan_sha256": "0" * 64,
                              "batch_sha256": "b" * 64, "launcher_sha256": "c" * 64,
                              "runner_result_sha256": hashlib.sha256(
                                  runner_path.read_bytes()).hexdigest()}
                else:
                    record_path = output_dir / "attempts" / "0001.result.json"
                    record_path.parent.mkdir(parents=True)
                    if record_kind == "runner_identityless_success":
                        record = {**common, "status": "ok", "success": True}
                    else:
                        record = {**common, "status": "failed", "success": False}
                record_path.write_text(json.dumps(record), encoding="utf-8")
                job = {"cell": expected_cells()[0],
                       "output_dir": str(output_dir),
                       "admission_path": str(self.root / "unused-admission.json"),
                       "admission_sha256": admission_sha,
                       "expected_outer_seeds": [101, 102], "outers": [1, 2]}
                with patch.object(pilot, "child_command",
                                  side_effect=AssertionError("later outer launched")):
                    result = pilot._execute_cell(
                        job, source_root=self.source, julia="julia",
                        output_root=self.root, timeout=1,
                        plan_sha256="a" * 64, batch_sha256="b" * 64,
                        launcher_sha256="c" * 64)
                self.assertEqual(len(result["attempts"]), 1)
                self.assertFalse(result["all_attempts_terminal"])
                self.assertFalse((record_dir / "0002.started.json").exists())
                self.assertFalse((record_dir / "0002.result.json").exists())

    @patch.object(pilot, "require_verified_attempt_record", lambda: None)
    def test_new_failed_outer_stops_later_outers(self):
        output_dir = self.root / "new-failure" / "cell"
        admission = {"fixture": "admission"}
        admission_path = self.root / "admission.json"
        admission_path.write_text(json.dumps(admission), encoding="utf-8")
        job = {"cell": expected_cells()[0], "output_dir": str(output_dir),
               "admission_path": str(admission_path),
               "admission_sha256": pilot._canonical_sha256(admission),
               "expected_outer_seeds": [101, 102], "outers": [1, 2]}
        with patch.object(pilot, "child_command", return_value=["synthetic-child"]), \
                patch.object(pilot, "_run_child", return_value=subprocess.CompletedProcess(
                    ["synthetic-child"], 1, "", "synthetic failure")) as run_child:
            result = pilot._execute_cell(
                job, source_root=self.source, julia="julia", output_root=self.root,
                timeout=1, plan_sha256="a" * 64, batch_sha256="b" * 64,
                launcher_sha256="c" * 64)
        self.assertEqual(run_child.call_count, 1)
        self.assertEqual(len(result["attempts"]), 1)
        self.assertFalse(result["all_attempts_terminal"])
        self.assertFalse((output_dir / "launcher-attempts" /
                          "0002.started.json").exists())

    @patch.object(pilot, "require_verified_attempt_record", lambda: None)
    def test_zero_exit_without_runner_result_stops_later_outers(self):
        output_dir = self.root / "missing-runner-result" / "cell"
        admission = {"fixture": "admission"}
        admission_path = self.root / "missing-result-admission.json"
        admission_path.write_text(json.dumps(admission), encoding="utf-8")
        job = {"cell": expected_cells()[0], "output_dir": str(output_dir),
               "admission_path": str(admission_path),
               "admission_sha256": pilot._canonical_sha256(admission),
               "expected_outer_seeds": [101, 102], "outers": [1, 2]}
        with patch.object(pilot, "child_command", return_value=["synthetic-child"]), \
                patch.object(pilot, "_run_child", return_value=subprocess.CompletedProcess(
                    ["synthetic-child"], 0, "", "")) as run_child:
            result = pilot._execute_cell(
                job, source_root=self.source, julia="julia", output_root=self.root,
                timeout=1, plan_sha256="a" * 64, batch_sha256="b" * 64,
                launcher_sha256="c" * 64)
        self.assertEqual(run_child.call_count, 1)
        self.assertEqual(result["attempts"][0]["status"], "launcher_error")
        self.assertFalse(result["attempts"][0]["success"])
        self.assertFalse(result["all_attempts_terminal"])
        self.assertFalse((output_dir / "launcher-attempts" /
                          "0002.started.json").exists())

    @patch.object(pilot, "require_verified_attempt_record", lambda: None)
    def test_resume_accepts_source_verified_launcher_and_runner_pair(self):
        plan = authorization_plan(self.root)
        job = dict(plan["jobs"][0])
        job["outers"] = [1]
        output_dir = Path(job["output_dir"])
        runner_path = output_dir / "attempts" / "0001.result.json"
        runner_path.parent.mkdir(parents=True)
        runner_record = {"outer": 1, "seed": job["expected_outer_seeds"][0],
                         "admission_sha256": job["admission_sha256"],
                         "status": "ok", "success": True,
                         "elapsed_seconds": 8.0, "child_elapsed_seconds": 9.0,
                         "execution_identity": {"fixture": True}}
        runner_path.write_text(json.dumps(runner_record), encoding="utf-8")
        launcher_dir = output_dir / "launcher-attempts"
        launcher_dir.mkdir(parents=True)
        launcher_record = {"outer": 1, "seed": job["expected_outer_seeds"][0],
                           "admission_sha256": job["admission_sha256"],
                           "plan_sha256": plan["plan_sha256"],
                           "batch_sha256": plan["batch_sha256"],
                           "launcher_sha256": plan["launcher_sha256"],
                           "runner_result_sha256": hashlib.sha256(
                               runner_path.read_bytes()).hexdigest(),
                           "status": "child_complete", "success": True,
                           "returncode": 0, "elapsed_seconds": 10.0}
        launcher_path = launcher_dir / "0001.result.json"
        launcher_path.write_text(json.dumps(launcher_record), encoding="utf-8")
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            result = pilot._execute_cell(
                job, source_root=self.source, julia="julia",
                output_root=Path(plan["output_root"]), timeout=1,
                plan_sha256=plan["plan_sha256"],
                batch_sha256=plan["batch_sha256"],
                launcher_sha256=plan["launcher_sha256"])
        self.assertTrue(result["all_attempts_terminal"])
        self.assertEqual(result["terminal_attempts"], 1)
        self.assertFalse(result["attempts"][0]["launched"])
        launcher_record["elapsed_seconds"] = 0.0
        launcher_path.write_text(json.dumps(launcher_record), encoding="utf-8")
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            invalid_timing = pilot._execute_cell(
                job, source_root=self.source, julia="julia",
                output_root=Path(plan["output_root"]), timeout=1,
                plan_sha256=plan["plan_sha256"],
                batch_sha256=plan["batch_sha256"],
                launcher_sha256=plan["launcher_sha256"])
        self.assertFalse(invalid_timing["all_attempts_terminal"])
        self.assertFalse(invalid_timing["attempts"][0]["terminal"])

    def test_signal_cancellation_stops_child_process_group(self):
        pid_file = self.root / "signal-grandchild.pid"
        heartbeat_file = self.root / "signal-grandchild-heartbeat.txt"
        heartbeat = ("import pathlib,time; p=pathlib.Path(" + repr(str(heartbeat_file)) + "); i=0; "
                     "exec('while True:\\n i += 1\\n p.write_text(str(i))\\n time.sleep(0.02)')")
        child_code = ("import subprocess,sys,time; "
                      f"child=subprocess.Popen([sys.executable,'-c',{heartbeat!r}]); "
                      f"open({str(pid_file)!r},'w').write(str(child.pid)); time.sleep(30)")
        launched = []
        child_outcome = []
        real_popen = pilot.subprocess.Popen

        def tracking_popen(*args, **kwargs):
            process = real_popen(*args, **kwargs)
            launched.append(process)
            return process

        def run_child():
            try:
                child_outcome.append(pilot._run_child(
                    [sys.executable, "-c", child_code],
                    env=os.environ.copy(), timeout=10))
            except BaseException as error:
                child_outcome.append(error)

        pilot._CANCEL.clear()
        with patch.object(pilot.subprocess, "Popen", tracking_popen):
            thread = threading.Thread(target=run_child)
            thread.start()
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline and not pid_file.exists():
                time.sleep(0.02)
            self.assertTrue(pid_file.exists(), "synthetic child did not start")
            grandchild_pid = int(pid_file.read_text(encoding="utf-8"))
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline and not heartbeat_file.exists():
                time.sleep(0.02)
            self.assertTrue(heartbeat_file.exists(), "synthetic grandchild did not start")
            pilot._CANCEL.clear()
            with self.assertRaises(KeyboardInterrupt):
                pilot._cancel_children(signal.SIGTERM, None)
            thread.join(timeout=5)
        self.assertFalse(thread.is_alive(), "child runner did not stop after cancellation")
        self.assertEqual(len(launched), 1)
        self.assertIsNotNone(launched[0].poll())
        before = heartbeat_file.read_text(encoding="utf-8")
        time.sleep(0.15)
        after = heartbeat_file.read_text(encoding="utf-8")
        if after != before:
            os.kill(grandchild_pid, signal.SIGKILL)
        pilot._CANCEL.clear()
        self.assertEqual(after, before, "grandchild continued running after signal cancellation")
        self.assertEqual(len(child_outcome), 1)
        self.assertNotEqual(child_outcome[0].returncode, 0)

    def test_prerun_uses_parent_wall_time_not_nested_runner_timing(self):
        plan = authorization_plan(self.root)
        receipt = prerun_receipt(plan)
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            estimate = pilot._measured_prerun_estimate(receipt, plan)
        self.assertIsInstance(estimate, int)
        self.assertGreater(estimate, 0)
        self.assertEqual(receipt["attempts"][0]["elapsed_seconds"], 10.0)

    def test_hash_only_prerun_receipt_is_not_measured_evidence(self):
        plan = authorization_plan(self.root)
        receipt_path = self.root / "prerun.json"
        receipt_path.write_text('{"schema":"measured-pre-run"}\n', encoding="utf-8")
        auth = {"schema": pilot.AUTHORIZATION_SCHEMA,
                "scope": pilot.EXECUTION_SCOPE,
                "approval": pilot.OWNER_APPROVAL_TEXT,
                "plan_sha256": plan["plan_sha256"],
                "batch_sha256": plan["batch_sha256"],
                "source_root": plan["source_root"],
                "output_root": plan["output_root"],
                "pre_run_receipt_path": str(receipt_path),
                "pre_run_receipt_sha256": hashlib.sha256(receipt_path.read_bytes()).hexdigest(),
                "estimated_total_seconds": 60,
                "owner_approved_total_seconds": 60,
                "approved_by_owner": True}
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            self.assertFalse(pilot.execution_authorized(auth, plan))

    def test_prerun_receipt_must_match_retained_runner_result(self):
        plan = authorization_plan(self.root)
        receipt = prerun_receipt(plan)
        job = plan["jobs"][0]
        result_path = Path(job["output_dir"]) / "attempts" / "0001.result.json"
        launcher_path = (Path(job["output_dir"]) / "launcher-attempts" /
                         "0001.result.json")
        receipt_path = self.root / "prerun.json"
        receipt_path.write_text(json.dumps(receipt), encoding="utf-8")
        auth = {"schema": pilot.AUTHORIZATION_SCHEMA,
                "scope": pilot.EXECUTION_SCOPE,
                "approval": pilot.OWNER_APPROVAL_TEXT,
                "plan_sha256": plan["plan_sha256"],
                "batch_sha256": plan["batch_sha256"],
                "source_root": plan["source_root"],
                "output_root": plan["output_root"],
                "pre_run_receipt_path": str(receipt_path),
                "pre_run_receipt_sha256": hashlib.sha256(receipt_path.read_bytes()).hexdigest(),
                "estimated_total_seconds": receipt["estimated_total_seconds"],
                "owner_approved_total_seconds": receipt["estimated_total_seconds"],
                "approved_by_owner": True}
        with patch.object(pilot.manifest, "verify_run_admission"), \
                patch.object(pilot.manifest, "verify_execution_identity"):
            self.assertTrue(pilot.execution_authorized(auth, plan))
            original_launcher_bytes = launcher_path.read_bytes()
            stale_launcher = json.loads(launcher_path.read_text(encoding="utf-8"))
            stale_launcher["launcher_sha256"] = "f" * 64
            stale_bytes = json.dumps(stale_launcher).encode("utf-8")
            launcher_path.write_bytes(stale_bytes)
            stale_receipt = json.loads(json.dumps(receipt))
            stale_receipt["attempts"][0]["launcher_result_sha256"] = hashlib.sha256(
                stale_bytes).hexdigest()
            receipt_path.write_text(json.dumps(stale_receipt), encoding="utf-8")
            auth["pre_run_receipt_sha256"] = hashlib.sha256(
                receipt_path.read_bytes()).hexdigest()
            self.assertFalse(pilot.execution_authorized(auth, plan))
            launcher_path.write_bytes(original_launcher_bytes)
            receipt_path.write_text(json.dumps(receipt), encoding="utf-8")
            auth["pre_run_receipt_sha256"] = hashlib.sha256(
                receipt_path.read_bytes()).hexdigest()
            bad_timing = dict(receipt)
            bad_timing["attempts"] = [dict(row) for row in receipt["attempts"]]
            bad_timing["attempts"][0]["elapsed_seconds"] = 5.0
            receipt_path.write_text(json.dumps(bad_timing), encoding="utf-8")
            auth["pre_run_receipt_sha256"] = hashlib.sha256(receipt_path.read_bytes()).hexdigest()
            self.assertFalse(pilot.execution_authorized(auth, plan))
            receipt_path.write_text(json.dumps(receipt), encoding="utf-8")
            auth["pre_run_receipt_sha256"] = hashlib.sha256(receipt_path.read_bytes()).hexdigest()
            result_path.write_text('{"status":"ok","success":true}\n', encoding="utf-8")
            self.assertFalse(pilot.execution_authorized(auth, plan))

    def test_retained_attempt_identity_must_match_admission(self):
        path = self.root / "attempt.json"
        path.write_text(json.dumps({"outer": 3, "seed": 42,
                                    "admission_sha256": "a" * 64}), encoding="utf-8")
        pilot._verify_retained_record(path, outer=3, seed=42, admission_sha256="a" * 64)
        with self.assertRaisesRegex(ValueError, "differs"):
            pilot._verify_retained_record(path, outer=3, seed=43,
                                          admission_sha256="a" * 64)

    def test_child_command_pins_julia_and_blas_to_one(self):
        command = pilot.child_command(
            julia="julia", source_root=Path("/source"), output_root=Path("/out"),
            admission_path=Path("/admission.json"), outer=7)
        self.assertIn("--julia-threads=1", command)
        self.assertIn("--blas-threads=1", command)
        self.assertIn("--timeout", command)
        self.assertEqual(pilot.child_environment({})["JULIA_NUM_THREADS"], "1")
        self.assertEqual(pilot.child_environment({})["OPENBLAS_NUM_THREADS"], "1")
        self.assertEqual(pilot.child_environment({})["OMP_NUM_THREADS"], "1")


if __name__ == "__main__":
    unittest.main()
