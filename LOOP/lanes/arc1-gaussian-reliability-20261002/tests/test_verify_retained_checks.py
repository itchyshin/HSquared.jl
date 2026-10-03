"""Synthetic adversaries for the retained-check verifier.

These fixtures exercise receipt integrity only. They are not Arc1 scientific
evidence and cannot qualify a G1, G6, or G7 gate.
"""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import shutil
import tempfile
from types import SimpleNamespace
import unittest
from pathlib import Path
from typing import Any


SCRIPT = Path(__file__).resolve().parents[1] / "verify_retained_checks.py"
SPEC = importlib.util.spec_from_file_location("verify_retained_checks", SCRIPT)
assert SPEC and SPEC.loader
verify = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(verify)
SYNTHETIC_JULIA_TESTSETS = ("synthetic Arc1 testset",)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class SyntheticAdapter:
    def __init__(self, kind: str, root: Path, runner: Path, freeze_files: dict[str, dict[str, str]]):
        self.kind = kind
        self.runner_path = runner
        self.roots = {"julia": str(root / "julia"), "r": str(root / "r")}
        self.freeze_files = freeze_files
        self.runtime = {"julia": "julia test version", "rscript": "R test version"}
        self.JULIA_BIN = "julia"
        self.RSCRIPT_BIN = "Rscript"
        self.julia_argv = lambda test: ["julia", "--startup-file=no", "--project=.", "-e", "synthetic", str(Path(self.roots["julia"]) / test)]
        self.julia_env = lambda: {"JULIA_DEPOT_PATH": "synthetic depot", "JULIA_NUM_THREADS": "4",
                                  "OPENBLAS_NUM_THREADS": "1", "ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER": "0"}
        self._version_command = lambda name: [self.JULIA_BIN, "--startup-file=no", "--version"] if name == "julia" else [self.RSCRIPT_BIN, "--version"]
        self._julia_command = lambda capture, sandbox: (
            [self.JULIA_BIN, "--startup-file=no", "--project=.", "-e", "synthetic-pkg-test"],
            {"ARC1_TEST_SANDBOX_CAPTURE_DIR": str(capture.resolve()),
             "ARC1_TEST_SANDBOX_PROJECT_SHA256": sandbox["project_sha256"],
             "ARC1_TEST_SANDBOX_MANIFEST_SHA256": sandbox["manifest_sha256"],
             "JULIA_NUM_THREADS": "1", "OPENBLAS_NUM_THREADS": "1"})

    def current_snapshot(self) -> dict[str, dict[str, str]]:
        return self.freeze_files

    def _validate_fixture_freeze(self, doc: dict[str, Any]) -> None:
        expected = "hsquared-arc1-oracle-freeze-v1" if self.kind == "oracle" else "hsquared-arc1-package-freeze-v3"
        if doc.get("schema") != expected:
            raise verify.ReceiptError("freeze schema mismatch")
        if doc.get("roots") != self.roots or doc.get("files") != self.freeze_files:
            raise verify.ReceiptError("freeze inventory mismatch")
        if doc.get("runtime", {}).get("julia") != self.runtime["julia"]:
            raise verify.ReceiptError("freeze runtime mismatch")

    def validate_freeze(self, doc: dict[str, Any], gate: str) -> None:
        expected = "hsquared-arc1-oracle-freeze-v1" if self.kind == "oracle" else "hsquared-arc1-package-freeze-v3"
        if doc.get("schema") != expected:
            raise verify.ReceiptError("freeze schema mismatch")
        if doc.get("roots") != self.roots or doc.get("files") != self.freeze_files:
            raise verify.ReceiptError("freeze inventory mismatch")
        if doc.get("runtime", {}).get("julia") != self.runtime["julia"]:
            raise verify.ReceiptError("freeze runtime mismatch")

    def tree_hash(self, path: Path) -> str:
        values = []
        for p in sorted(x for x in path.rglob("*") if x.is_file()):
            values.append(f"{p.relative_to(path).as_posix()}\0{sha(p)}\n")
        return hashlib.sha256("".join(values).encode()).hexdigest()

    def frontend_tree_hash(self, path: Path) -> str:
        return self.tree_hash(path)


class RetainedReceiptTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory(prefix="arc1-retained-check-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / "repo"
        self.repo.mkdir()
        self.runner = self.repo / "runner.py"
        self.runner.write_text("immutable synthetic runner\n")
        self.external = self.base / "external"
        self.external.mkdir()
        self.evidence_root = self.repo / "receipt-root"
        self.evidence_root.mkdir()
        self.review = self.external / "review.json"
        self.review.write_text('{"review":"synthetic fixture only"}\n')
        self.run_dir = self.repo / "receipt-root" / "run-1"
        self.run_dir.mkdir(parents=True)
        self.inputs: dict[str, dict[str, str]] = {}
        for group in ("julia", "r"):
            path = self.base / group / "input.txt"
            path.parent.mkdir()
            path.write_text(f"{group} source\n")
            self.inputs[group] = {"input.txt": sha(path)}
        docs_source = self.base / "julia/docs/src/validation-status.md"
        docs_source.parent.mkdir(parents=True, exist_ok=True)
        docs_source.write_text("synthetic frozen docs source\n")
        (self.base / "julia" / "docs" / "make.jl").write_text("# synthetic docs make input\n")
        self.inputs["julia"]["docs/src/validation-status.md"] = sha(docs_source)
        self.oracle = SyntheticAdapter("oracle", self.base, self.runner, self.inputs)
        self.package = SyntheticAdapter("package", self.base, self.runner, self.inputs)
        for adapter in (self.oracle, self.package):
            adapter.RUNNER = self.runner
            adapter.JULIA_ROOT = Path(adapter.roots["julia"])
            adapter.R_ROOT = Path(adapter.roots["r"])
            adapter.RUNS_ROOT = self.evidence_root
            adapter.EVIDENCE_ROOT = self.evidence_root
            adapter.JULIA_TESTS = (
                "test/arc1_exact_objectives.jl", "test/arc1_optimizer_contracts.jl",
                "test/arc1_profiles.jl", "test/arc1_bootstrap.jl", "test/arc1_interfaces.jl",
                "test/arc1_simulation_dgp.jl", "test/arc1_simulation_reference.jl",
                "test/arc1_simulation_executor.jl")
            adapter.R_DRIVER = "synthetic reviewed R driver\n"
            adapter.R_PACKAGE_DRIVER = "synthetic reviewed R CMD check driver\n"
            adapter._oracle = SimpleNamespace(R_DRIVER=adapter.R_DRIVER)
            adapter.make_local_docs_script = lambda source, **kwargs: "synthetic freshly derived docs script\n"
            adapter.REQUIRED_ARC1_TESTSETS = SYNTHETIC_JULIA_TESTSETS
            adapter.inputs = self.inputs
            adapter.file_map = lambda a=adapter: a.inputs
            adapter.build_file_map = lambda a=adapter: a.inputs
            adapter.snapshot = lambda files: files
            adapter.validate_freeze = lambda doc, *args, a=adapter, **kwargs: a._validate_fixture_freeze(doc)
            adapter.validate_docs_frontend = lambda spec, verify_runtime=False: dict(spec)
        self.oracle_freeze = self.external / "oracle-freeze.json"
        self.package_freeze = self.external / "package-freeze.json"
        self._write_freeze("oracle")
        self._write_freeze("package")

    def _write_freeze(self, kind: str) -> None:
        doc: dict[str, Any] = {
            "schema": "hsquared-arc1-oracle-freeze-v1" if kind == "oracle" else "hsquared-arc1-package-freeze-v3",
            "review": {"status": "reviewed", "reviewer": "synthetic test", "reviewed_at_utc": "fixture"},
            "roots": {"julia": str(self.base / "julia"), "r": str(self.base / "r")},
            "runtime": {"julia": "julia test version", "rscript": "R test version"},
            "files": self.inputs,
        }
        if kind == "package":
            doc["review"].update({"review_receipt_path": str(self.review), "review_receipt_sha256": sha(self.review)})
            for filename, contents in (("test-Project.toml", "[deps]\n"),
                                       ("test-Manifest.toml", "# synthetic test manifest\n"),
                                       ("bootstrap-Project.toml", "[deps]\n"),
                                       ("bootstrap-Manifest.toml", "# synthetic bootstrap manifest\n")):
                (self.external / filename).write_text(contents)
            doc["julia_test_sandbox"] = {
                "project_path": str(self.external / "test-Project.toml"),
                "manifest_path": str(self.external / "test-Manifest.toml"),
                "project_sha256": sha(self.external / "test-Project.toml"),
                "manifest_sha256": sha(self.external / "test-Manifest.toml")}
            doc["julia_call_bootstrap"] = {
                "project_path": str(self.external / "bootstrap-Project.toml"),
                "manifest_path": str(self.external / "bootstrap-Manifest.toml"),
                "project_sha256": sha(self.external / "bootstrap-Project.toml"),
                "manifest_sha256": sha(self.external / "bootstrap-Manifest.toml")}
            doc["docs_frontend"] = {
                "package_json_sha256": "a"*64, "package_lock_sha256": "b"*64,
                "node_modules_tree_sha256": "c"*64}
        else:
            project = self.external / "bootstrap-Project.toml"
            manifest = self.external / "bootstrap-Manifest.toml"
            project.write_text("[deps]\n")
            manifest.write_text("# synthetic bootstrap manifest\n")
            doc["julia_call_bootstrap"] = {
                "project_path": str(project), "manifest_path": str(manifest),
                "project_sha256": sha(project), "manifest_sha256": sha(manifest)}
        path = self.oracle_freeze if kind == "oracle" else self.package_freeze
        path.write_text(json.dumps(doc, sort_keys=True) + "\n")

    def _log(self, name: str, content: str) -> tuple[str, str]:
        path = self.run_dir / name
        path.write_text(content)
        return name, sha(path)

    def _clear_run(self) -> None:
        for child in self.run_dir.iterdir():
            if child.is_dir() and not child.is_symlink():
                shutil.rmtree(child)
            else:
                child.unlink()

    def _oracle_receipt(self, gate: str) -> tuple[dict[str, Any], dict[str, Any]]:
        self._clear_run()
        tests = verify.ORACLE_JULIA_TESTS if gate == "G1" else []
        command_names = ["julia-version", "rscript-version"]
        if gate == "G1":
            command_names.extend("julia-" + Path(x).stem for x in tests)
        else:
            command_names.append("r-devtools-arc1-live")
        commands = []
        logs = {}
        driver_path = self.run_dir / "arc1_live_driver_fixture.R" if gate == "G6" else None
        if driver_path is not None:
            driver_path.write_text(self.oracle.R_DRIVER)
        for i, name in enumerate(command_names, 1):
            if name.startswith("julia-") and name not in {"julia-version"}:
                output = "ARC1_TEST_COUNTS passes=3 failures=0 errors=0 broken=0\n"
            elif name == "r-devtools-arc1-live":
                output = "ARC1_TESTTHAT_COUNTS four files assertions positive\n"
            else:
                output = "julia test version\n" if name == "julia-version" else "R test version\n"
            argv = (["julia", "--startup-file=no", "--version"] if name == "julia-version" else
                    ["Rscript", "--version"] if name == "rscript-version" else
                    ["Rscript", "--vanilla", str(driver_path)] if name == "r-devtools-arc1-live" else
                    self.oracle.julia_argv(next(x for x in self.oracle.JULIA_TESTS if Path(x).stem == name.removeprefix("julia-"))))
            log, log_hash = self._log(f"{i:02d}-{name}.log", output)
            record = {"name": name, "process_status": 0, "timed_out": False, "interrupted": False,
                      "log": log, "log_sha256": log_hash, "before_sha256": self.inputs,
                      "after_sha256": self.inputs, "argv": argv,
                      "cwd": self.oracle.roots["r"] if name.startswith("r-") or name == "rscript-version" else self.oracle.roots["julia"]}
            if name == "r-devtools-arc1-live":
                record["argv"] = ["Rscript", "--vanilla", str(driver_path)]
                record["julia_call_bootstrap_changed"] = False
                record["julia_call_bootstrap_before_sha256"] = {
                    "Project.toml": "0" * 64, "Manifest.toml": "1" * 64}
                record["julia_call_bootstrap_after_sha256"] = {
                    "Project.toml": "0" * 64, "Manifest.toml": "1" * 64}
                record["env_overrides"] = {
                    "ARC1_ORACLE_PACKAGE_ROOT": str(self.oracle.R_ROOT),
                    "ARC1_ORACLE_RESULTS_CSV": str((self.run_dir / "testthat-results.csv").resolve()),
                    "ARC1_ORACLE_RESULTS_RDS": str((self.run_dir / "testthat-results.rds").resolve()),
                    "HSQUARED_ARC1_REQUIRE_LIVE": "true", "JULIA_NUM_THREADS": "4",
                    "OPENBLAS_NUM_THREADS": "1"}
            elif name.startswith("julia-") and name != "julia-version":
                record["env_overrides"] = self.oracle.julia_env()
            commands.append(record)
            logs[name] = record
        if gate == "G6":
            csv_path = self.run_dir / "testthat-results.csv"
            rows = [{"file": x, "assertions": 3, "successes": 3, "failures": 0,
                     "errors": 0, "skips": 0, "warnings": 0} for x in verify.REQUIRED_R_TESTS]
            with csv_path.open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
                writer.writeheader()
                writer.writerows(rows)
            rds = self.run_dir / "testthat-results.rds"
            rds.write_bytes(b"synthetic opaque RDS bytes")
            rec = logs["r-devtools-arc1-live"]
            rec.update({"result_csv": csv_path.name, "result_csv_sha256": sha(csv_path),
                        "result_table": rds.name, "result_table_sha256": sha(rds)})
        freeze_path = self.oracle_freeze
        receipt = {"schema": verify.ORACLE_RUN_SCHEMA, "gate": gate.lower(), "status": "passed",
                   "run_id": self.run_dir.name, "julia_root": self.oracle.roots["julia"],
                   "r_root": self.oracle.roots["r"], "freeze_path": str(freeze_path),
                   "freeze_sha256": sha(freeze_path), "runner_sha256": sha(self.runner),
                   "required_file_counts": {key: len(value) for key, value in self.inputs.items()},
                   "runtime_expected": self.oracle.runtime, "runtime_observed": self.oracle.runtime,
                   "review": {"status": "reviewed", "reviewer": "synthetic test", "reviewed_at_utc": "fixture"},
                   "commands": commands, "freeze_checks": [
                       {"label": label, "sha256": self.inputs}
                       for label in ["initial", *[f"{name}:{suffix}" for name in command_names
                                                    for suffix in ("before", "after")], "final"]]}
        if gate == "G6":
            freeze_bootstrap = json.loads(self.oracle_freeze.read_text())["julia_call_bootstrap"]
            receipt["julia_call_bootstrap_run"] = {"initial_sha256": {
                "Project.toml": freeze_bootstrap["project_sha256"],
                "Manifest.toml": freeze_bootstrap["manifest_sha256"]}}
            live = commands[-1]
            live["julia_call_bootstrap_before_sha256"] = receipt["julia_call_bootstrap_run"]["initial_sha256"]
            live["julia_call_bootstrap_after_sha256"] = receipt["julia_call_bootstrap_run"]["initial_sha256"]
        return receipt, {"kind": "oracle", "adapter": self.oracle}

    def _package_receipt(self) -> tuple[dict[str, Any], dict[str, Any]]:
        self._clear_run()
        package_freeze = self.package_freeze
        commands = []
        names = ["julia-version", "rscript-version", "julia-pkg-test", "r-arc1-mandatory-live",
                 "r-cmd-check", "julia-local-docs"]
        for filename, contents in (("r-arc1-live-driver.R", self.package.R_DRIVER),
                                   ("r-package-check-driver.R", self.package.R_PACKAGE_DRIVER)):
            (self.run_dir / filename).write_text(contents)
        for i, name in enumerate(names, 1):
            content = {
                "julia-version": "julia test version\n",
                "rscript-version": "R test version\n",
                "julia-pkg-test": "ARC1_TEST_SANDBOX_VERIFIED\nARC1_PACKAGE_JULIA_COMPONENT_PASS\n",
                "r-arc1-mandatory-live": "ARC1_TESTTHAT_COUNTS four files assertions positive\n",
                "r-cmd-check": "ARC1_PACKAGE_R_CHECK_COMPONENT_PASS\n",
                "julia-local-docs": "ARC1_PACKAGE_DOCS_HTML_BUILT\nARC1_PACKAGE_DOCS_COMPONENT_PASS\n",
            }[name]
            log, digest = self._log(f"{i:02d}-{name}.log", content)
            run = str(self.run_dir.resolve())
            argv = {
                "julia-version": ["julia", "--startup-file=no", "--version"],
                "rscript-version": ["Rscript", "--version"],
                "julia-pkg-test": ["julia", "--startup-file=no", "--project=.", "-e", "synthetic-pkg-test"],
                "r-arc1-mandatory-live": ["Rscript", "--vanilla", f"{run}/r-arc1-live-driver.R"],
                "r-cmd-check": ["Rscript", "--vanilla", f"{run}/r-package-check-driver.R"],
                "julia-local-docs": ["julia", "--startup-file=no", f"--project={run}/docs-environment", f"{run}/local-docs-make.jl"],
            }[name]
            commands.append({"name": name, "process_status": 0, "timed_out": False, "interrupted": False,
                             "log": log, "log_sha256": digest, "before_sha256": self.inputs,
                             "after_sha256": self.inputs, "argv": argv,
                             "cwd": self.package.roots["r"] if name.startswith("r-") or name == "rscript-version" else self.package.roots["julia"]})
        for rel in ("arc1-live-results.csv", "arc1-live-results.rds"):
            if rel.endswith(".csv"):
                rows = [{"file": x, "assertions": 3, "successes": 3, "failures": 0,
                         "errors": 0, "skips": 0, "warnings": 0} for x in verify.REQUIRED_R_TESTS]
                with (self.run_dir / rel).open("w", newline="") as stream:
                    writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
                    writer.writeheader(); writer.writerows(rows)
            else:
                (self.run_dir / rel).write_bytes(b"synthetic opaque RDS bytes")
        check_log = self.run_dir / "r-check" / "hsquared.Rcheck" / "00check.log"
        check_log.parent.mkdir(parents=True, exist_ok=True)
        check_log.write_text("* checking package ...\nStatus: OK\n")
        result = self.run_dir / "r-check-result.json"
        result.write_text(json.dumps({"errors": 0, "warnings": 0, "notes": 0, "status_ok": True}) + "\n")
        scratch = self.run_dir / "scratch-docs"
        scratch.mkdir(exist_ok=True)
        (scratch / "package.json").write_text('{"name":"synthetic"}\n')
        (scratch / "package-lock.json").write_text('{"lockfileVersion":3}\n')
        modules = scratch / "node_modules" / "synthetic"
        modules.mkdir(parents=True)
        (modules / "index.js").write_text("// synthetic frontend tree\n")
        docs = scratch / "build"
        (docs / "1").mkdir(parents=True)
        html = docs / "1" / "validation-status.html"
        html.write_text("<h1>Validation Status</h1>")
        docs_tree = self.package.tree_hash(docs)
        docs_env = self.run_dir / "docs-environment"
        docs_env.mkdir(exist_ok=True)
        (docs_env / "Project.toml").write_text("# synthetic docs project\n")
        (docs_env / "Manifest.toml").write_text("# synthetic docs manifest\n")
        sandbox_spec = json.loads(package_freeze.read_text())["julia_test_sandbox"]
        capture = self.run_dir / "julia-test-sandbox"
        capture.mkdir()
        shutil.copyfile(sandbox_spec["project_path"], capture / "Project.toml")
        shutil.copyfile(sandbox_spec["manifest_path"], capture / "Manifest.toml")
        (capture / "sha256.txt").write_text(sandbox_spec["project_sha256"] + "\n" + sandbox_spec["manifest_sha256"] + "\n")
        bootstrap_spec = json.loads(package_freeze.read_text())["julia_call_bootstrap"]
        bootstrap = self.run_dir / "julia-call-bootstrap"
        bootstrap.mkdir()
        shutil.copyfile(bootstrap_spec["project_path"], bootstrap / "Project.toml")
        shutil.copyfile(bootstrap_spec["manifest_path"], bootstrap / "Manifest.toml")
        docs_script = self.package.make_local_docs_script("", repo=Path(self.package.roots["julia"]),
            scratch_docs=scratch, output_docs=scratch, redirect_probe=self.run_dir / "legacy-redirect-contract",
            frontend=json.loads(package_freeze.read_text())["docs_frontend"])
        (self.run_dir / "local-docs-make.jl").write_text(docs_script)
        commands[3]["env_overrides"] = {
            "ARC1_ORACLE_PACKAGE_ROOT": self.package.roots["r"],
            "ARC1_ORACLE_RESULTS_CSV": str((self.run_dir / "arc1-live-results.csv").resolve()),
            "ARC1_ORACLE_RESULTS_RDS": str((self.run_dir / "arc1-live-results.rds").resolve()),
            "HSQUARED_ARC1_REQUIRE_LIVE": "true", "JULIA_NUM_THREADS": "1",
            "OPENBLAS_NUM_THREADS": "1"}
        commands[2]["env_overrides"] = {
            "ARC1_TEST_SANDBOX_CAPTURE_DIR": str(capture.resolve()),
            "ARC1_TEST_SANDBOX_PROJECT_SHA256": sandbox_spec["project_sha256"],
            "ARC1_TEST_SANDBOX_MANIFEST_SHA256": sandbox_spec["manifest_sha256"],
            "JULIA_NUM_THREADS": "1", "OPENBLAS_NUM_THREADS": "1"}
        commands[4]["env_overrides"] = {"ARC1_R_CHECK_DIR": str((self.run_dir / "r-check").resolve()),
            "ARC1_R_RESULT_FILE": str((self.run_dir / "r-check-result.json").resolve())}
        fre_doc = json.loads(package_freeze.read_text())
        frontend = fre_doc["docs_frontend"]
        frontend.update({"package_json_sha256": sha(scratch / "package.json"),
                         "package_lock_sha256": sha(scratch / "package-lock.json"),
                         "node_modules_tree_sha256": self.package.tree_hash(scratch / "node_modules")})
        frontend["node_version"] = "v20.synthetic"
        frontend["npm_version"] = "10.synthetic"
        frontend["package_json_path"] = str(self.external / "package.json")
        frontend["package_lock_path"] = str(self.external / "package-lock.json")
        frontend["node_modules_path"] = str(self.external / "node_modules")
        frontend["node_path"] = str(self.external / "node")
        frontend["npm_cli_path"] = str(self.external / "npm-cli.js")
        frontend["node_sha256"] = "d"*64
        frontend["npm_cli_sha256"] = "e"*64
        package_freeze.write_text(json.dumps(fre_doc, sort_keys=True) + "\n")
        recs = {
            "julia": {"status": "passed", "log": commands[2]["log"], "log_sha256": commands[2]["log_sha256"],
                      "test_summary": {"summary_records": [{"testset": x, "pass": 1, "total": 1,
                                                               "fail": 0, "error": 0, "broken": 0}
                                                              for x in SYNTHETIC_JULIA_TESTSETS],
                                       "required_arc1_testsets": list(SYNTHETIC_JULIA_TESTSETS)},
                      "test_sandbox": {"project_sha256": sandbox_spec["project_sha256"],
                                       "manifest_sha256": sandbox_spec["manifest_sha256"],
                                       "capture_dir": str(capture.resolve())}},
            "r": {"status": "passed", "live_log": commands[3]["log"], "live_log_sha256": commands[3]["log_sha256"],
                  "check_log": commands[4]["log"], "check_log_sha256": commands[4]["log_sha256"],
                  "result_sha256": sha(result), "check_tree_sha256": self.package.tree_hash(check_log.parents[1])},
            "docs": {"status": "passed", "log": commands[5]["log"], "log_sha256": commands[5]["log_sha256"],
                      "script": "local-docs-make.jl", "script_sha256": sha(self.run_dir / "local-docs-make.jl"),
                     "output_tree_sha256": docs_tree},
        }
        receipt = {"schema": verify.PACKAGE_RUN_SCHEMA, "gate_selection": "all", "status": "passed",
                   "run_dir": str(self.run_dir.resolve()), "freeze_path": str(package_freeze),
                   "freeze_sha256": sha(package_freeze), "runner_sha256": sha(self.runner),
                   "review": fre_doc["review"], "review_receipt_sha256": fre_doc["review"]["review_receipt_sha256"],
                   "runtime_expected": {"julia": "julia test version", "rscript": "R test version"},
                   "runtime_observed": {"julia": "julia test version", "rscript": "R test version"},
                   "input_counts": {key: len(value) for key, value in self.inputs.items()},
                   "passed_components": ["julia", "r", "docs"], "commands": commands,
                   "component_receipts": recs,
                   "julia_test_summary": recs["julia"]["test_summary"],
                   "julia_test_sandbox_expected": {"project_sha256": sandbox_spec["project_sha256"],
                                                    "manifest_sha256": sandbox_spec["manifest_sha256"]},
                   "julia_call_bootstrap_expected": bootstrap_spec,
                   "julia_call_bootstrap_run": {"path": str(bootstrap.resolve()),
                       "initial_sha256": {"Project.toml": bootstrap_spec["project_sha256"],
                                           "Manifest.toml": bootstrap_spec["manifest_sha256"]}},
                   "docs_frontend_expected": {key: frontend[key] for key in
                       ("package_json_sha256", "package_lock_sha256", "node_modules_tree_sha256",
                        "node_version", "npm_version")},
                   "r_live_result_sha256": {"csv": sha(self.run_dir / "arc1-live-results.csv"),
                                             "rds": sha(self.run_dir / "arc1-live-results.rds")},
                   "r_result_sha256": sha(result), "r_check_log_sha256": sha(check_log),
                   "r_check_tree_sha256": self.package.tree_hash(check_log.parents[1]),
                   "docs_output_tree_hash": docs_tree,
                   "docs_rendered_status_pages": [{"path": "1/validation-status.html", "sha256": sha(html)}],
                   "docs_source_status_sha256": self.inputs["julia"]["docs/src/validation-status.md"],
                   "docs_environment_sha256": {"Project.toml": sha(docs_env / "Project.toml"),
                                                "Manifest.toml": sha(docs_env / "Manifest.toml")},
                   "docs_environment_after_sha256": {"Project.toml": sha(docs_env / "Project.toml"),
                                                      "Manifest.toml": sha(docs_env / "Manifest.toml")},
                   "docs_frontend_scratch_sha256": {
                       key: frontend[key] for key in
                       ("package_json_sha256", "package_lock_sha256", "node_modules_tree_sha256")},
                   "hash_checks": [{"label": label, "sha256": self.inputs}
                                   for label in ["initial", *[f"{name}:{suffix}" for name in names
                                                               for suffix in ("before", "after")], "final"]]}
        return receipt, {"kind": "package", "adapter": self.package}

    def _store_and_verify(self, receipt: dict[str, Any], info: dict[str, Any], gate: str) -> str:
        path = self.run_dir / "run.json"
        path.write_text(json.dumps(receipt, sort_keys=True) + "\n")
        return verify.verify_retained(gate, path, sha(path), Path(receipt["freeze_path"]),
                                      receipt["freeze_sha256"], adapter=info["adapter"],
                                      artifact_kind=info["kind"])

    def test_synthetic_positive_fixtures_are_not_scientific_evidence(self) -> None:
        receipt, info = self._oracle_receipt("G1")
        self.assertEqual(self._store_and_verify(receipt, info, "G1"), "ARC1_G1_RETAINED_RECEIPT_VERIFIED")

    def test_synthetic_g6_oracle_and_g7_package_positive_transport(self) -> None:
        r6, a6 = self._oracle_receipt("G6")
        self.assertEqual(self._store_and_verify(r6, a6, "G6"), "ARC1_G6_RETAINED_RECEIPT_VERIFIED")
        r7, a7 = self._package_receipt()
        self.assertEqual(self._store_and_verify(r7, a7, "G7"), "ARC1_G7_RETAINED_RECEIPT_VERIFIED")

    def test_mutations_are_refused(self) -> None:
        receipt, info = self._oracle_receipt("G1")
        path = self.run_dir / "run.json"
        path.write_text(json.dumps(receipt) + "\n")
        args = ("G1", path, sha(path), self.oracle_freeze, sha(self.oracle_freeze))

        with self.subTest("explicit receipt hash"):
            with self.assertRaises(verify.ReceiptError):
                verify.verify_retained(*args[:2], "0"*64, *args[3:], adapter=info["adapter"], artifact_kind="oracle")
        with self.subTest("external freeze hash"):
            with self.assertRaises(verify.ReceiptError):
                verify.verify_retained("G1", path, sha(path), self.oracle_freeze, "0"*64,
                                       adapter=info["adapter"], artifact_kind="oracle")

        for label, mutation in (
            ("nonzero", lambda r: r["commands"][2].update(process_status=2)),
            ("timeout", lambda r: r["commands"][2].update(timed_out=True)),
            ("interrupted", lambda r: r["commands"][2].update(interrupted=True)),
            ("missing command", lambda r: r["commands"].pop()),
        ):
            with self.subTest(label):
                changed = json.loads(json.dumps(receipt)); mutation(changed)
                path.write_text(json.dumps(changed) + "\n")
                with self.assertRaises(verify.ReceiptError):
                    verify.verify_retained("G1", path, sha(path), self.oracle_freeze,
                                           sha(self.oracle_freeze), adapter=info["adapter"], artifact_kind="oracle")

        with self.subTest("profile wrapper cannot be skipped"):
            changed = json.loads(json.dumps(receipt))
            changed["commands"][2]["env_overrides"]["ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER"] = "1"
            path.write_text(json.dumps(changed) + "\n")
            with self.assertRaises(verify.ReceiptError):
                verify.verify_retained("G1", path, sha(path), self.oracle_freeze,
                                       sha(self.oracle_freeze), adapter=info["adapter"], artifact_kind="oracle")

    def test_exact_command_and_external_review_bindings_are_required(self) -> None:
        receipt, info = self._package_receipt()
        path = self.run_dir / "run.json"
        receipt["commands"][2]["argv"][-1] = "synthetic altered command"
        path.write_text(json.dumps(receipt) + "\n")
        with self.assertRaises(verify.ReceiptError):
            verify.verify_retained("G7", path, sha(path), self.package_freeze, sha(self.package_freeze),
                                   adapter=info["adapter"], artifact_kind="package")
        receipt, info = self._package_receipt()
        self.review.write_text('{"tampered":true}\n')
        path.write_text(json.dumps(receipt) + "\n")
        with self.assertRaises(verify.ReceiptError):
            verify.verify_retained("G7", path, sha(path), self.package_freeze, sha(self.package_freeze),
                                   adapter=info["adapter"], artifact_kind="package")

    def test_log_hash_and_current_source_pin_mutations_are_refused(self) -> None:
        receipt, info = self._oracle_receipt("G1")
        path = self.run_dir / "run.json"
        receipt["commands"][0]["log_sha256"] = "f" * 64
        path.write_text(json.dumps(receipt) + "\n")
        with self.assertRaises(verify.ReceiptError):
            verify.verify_retained("G1", path, sha(path), self.oracle_freeze, sha(self.oracle_freeze),
                                   adapter=info["adapter"], artifact_kind="oracle")
        receipt["commands"][0]["log_sha256"] = sha(self.run_dir / receipt["commands"][0]["log"])
        info["adapter"].freeze_files["julia"]["input.txt"] = "e" * 64
        path.write_text(json.dumps(receipt) + "\n")
        with self.assertRaises(verify.ReceiptError):
            verify.verify_retained("G1", path, sha(path), self.oracle_freeze, sha(self.oracle_freeze),
                                   adapter=info["adapter"], artifact_kind="oracle")

    def test_g7_rejects_missing_component_marker_html_or_current_source(self) -> None:
        for label, mutate in (
            ("missing docs", lambda r: r["passed_components"].remove("docs")),
            ("missing marker", lambda r: (self.run_dir / r["commands"][-1]["log"]).write_text("no marker\n")),
            ("no html", lambda r: (self.run_dir / "scratch-docs/build/1/validation-status.html").unlink()),
        ):
            with self.subTest(label):
                receipt, info = self._package_receipt()
                mutate(receipt)
                if label == "missing marker":
                    command = receipt["commands"][-1]
                    command["log_sha256"] = sha(self.run_dir / command["log"])
                    receipt["component_receipts"]["docs"]["log_sha256"] = command["log_sha256"]
                path = self.run_dir / "run.json"; path.write_text(json.dumps(receipt) + "\n")
                with self.assertRaises(verify.ReceiptError):
                    verify.verify_retained("G7", path, sha(path), self.package_freeze,
                                           sha(self.package_freeze), adapter=info["adapter"], artifact_kind="package")

    def test_current_historical_failed_package_receipt_never_qualifies(self) -> None:
        repo = Path(__file__).resolve().parents[4]
        path = repo / ".unlazy/arc1-gaussian-reliability/evidence/package-checks/20261003T023112Z-fd216a1d63/run.json"
        if not path.is_file():
            self.skipTest("historical failed G7 receipt not present in this checkout")
        d = json.loads(path.read_text())
        self.assertEqual(d.get("status"), "failed")
        self.assertNotEqual(d.get("passed_components"), ["julia", "r", "docs"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
