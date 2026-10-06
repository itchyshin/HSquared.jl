"""Synthetic adversaries for the retained-check verifier.

These fixtures exercise receipt integrity only. They are not Arc1 scientific
evidence and cannot qualify a G1, G6, or G7 gate.
"""

from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import re
import shutil
import tempfile
import tomllib
from types import SimpleNamespace
import unittest
from pathlib import Path
from typing import Any


SCRIPT = Path(__file__).resolve().parents[1] / "verify_retained_checks.py"
SPEC = importlib.util.spec_from_file_location("verify_retained_checks", SCRIPT)
assert SPEC and SPEC.loader
verify = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(verify)
ORACLE_RUNNER_SCRIPT = Path(__file__).resolve().parents[4] / "tools" / "arc1_oracles.py"
ORACLE_RUNNER_SPEC = importlib.util.spec_from_file_location("arc1_oracles", ORACLE_RUNNER_SCRIPT)
assert ORACLE_RUNNER_SPEC and ORACLE_RUNNER_SPEC.loader
oracle_runner = importlib.util.module_from_spec(ORACLE_RUNNER_SPEC)
ORACLE_RUNNER_SPEC.loader.exec_module(oracle_runner)
PACKAGE_RUNNER_SCRIPT = Path(__file__).resolve().parents[4] / "tools" / "arc1_package_checks.py"
PACKAGE_RUNNER_SPEC = importlib.util.spec_from_file_location("arc1_package_checks", PACKAGE_RUNNER_SCRIPT)
assert PACKAGE_RUNNER_SPEC and PACKAGE_RUNNER_SPEC.loader
package_runner = importlib.util.module_from_spec(PACKAGE_RUNNER_SPEC)
PACKAGE_RUNNER_SPEC.loader.exec_module(package_runner)
SYNTHETIC_JULIA_TESTSETS = ("synthetic Arc1 testset",)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixture_toml(document: dict[str, Any]) -> str:
    lines: list[str] = []

    def key(value: str) -> str:
        return value if re.fullmatch(r"[A-Za-z0-9_-]+", value) else json.dumps(value)

    def atom(value: Any) -> str:
        if isinstance(value, str):
            return json.dumps(value)
        if isinstance(value, bool):
            return "true" if value else "false"
        if isinstance(value, (int, float)):
            return str(value)
        if isinstance(value, list) and all(not isinstance(item, (dict, list)) for item in value):
            return "[" + ", ".join(atom(item) for item in value) + "]"
        raise TypeError(f"unsupported fixture TOML value: {value!r}")

    def table(values: dict[str, Any], path: tuple[str, ...], *, header: bool) -> None:
        if header:
            lines.append("[" + ".".join(key(part) for part in path) + "]")
        for name, value in values.items():
            if not isinstance(value, dict) and not (isinstance(value, list) and value and isinstance(value[0], dict)):
                lines.append(f"{key(name)} = {atom(value)}")
        for name, value in values.items():
            nested = path + (name,)
            if isinstance(value, dict):
                table(value, nested, header=True)
            elif isinstance(value, list) and value and isinstance(value[0], dict):
                for item in value:
                    lines.append("[[" + ".".join(key(part) for part in nested) + "]]" )
                    table(item, nested, header=False)

    table(document, (), header=False)
    return "\n".join(lines) + "\n"


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
        self._julia_command = lambda driver, sandbox: (
            [self.JULIA_BIN, "--startup-file=no", "--check-bounds=yes", "--threads=1",
            f"--project={Path(sandbox['project_path']).parent.resolve()}", str(driver.resolve())],
            {"JULIA_LOAD_PATH": "@:@stdlib", "JULIA_NUM_THREADS": "1",
             "JULIA_DEPOT_PATH": "/synthetic/depot",
             "JULIA_PKG_OFFLINE": "true", "OPENBLAS_NUM_THREADS": "1"})
        self.julia_test_driver_source = package_runner.julia_test_driver_source
        self._probe_julia_host_identity = lambda launcher, *, expected_version: {
            "julia_version": expected_version,
            "host_platform": "synthetic",
            "host_platform_tags": {"arch": "synthetic", "os": "synthetic"},
            "julia_runtime_executable": str(Path(launcher).resolve()),
            "julia_runtime_executable_sha256": sha(Path(launcher)),
        }
        self.validate_noinstall_preflight_receipt = self._validate_preflight

    def _validate_preflight(self, path: Path, digest: str, expected: dict[str, Any]) -> dict[str, Any]:
        if sha(path) != digest:
            raise ValueError("synthetic preflight receipt hash mismatch")
        report = tomllib.loads(path.read_text())
        for key, value in expected.items():
            if key == "host_identity":
                for identity_key, identity_value in value.items():
                    if report.get(identity_key) != identity_value:
                        raise ValueError(f"synthetic preflight host identity differs for {identity_key}")
                continue
            if report.get(key) != value:
                raise ValueError(f"synthetic preflight identity differs for {key}")
        return report

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
    def test_g1_inventory_matches_runner_and_includes_v2_contracts(self):
        self.assertEqual(tuple(self.oracle.JULIA_TESTS), tuple(oracle_runner.JULIA_TESTS))
        self.assertIn("test/arc1_fa_v2_contracts.jl", self.oracle.JULIA_TESTS)

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
        self.package.parse_julia_test_output = package_runner.parse_julia_test_output
        for adapter in (self.oracle, self.package):
            adapter.RUNNER = self.runner
            adapter.JULIA_ROOT = Path(adapter.roots["julia"])
            adapter.R_ROOT = Path(adapter.roots["r"])
            adapter.RUNS_ROOT = self.evidence_root
            adapter.EVIDENCE_ROOT = self.evidence_root
            adapter.JULIA_TESTS = (
                "test/arc1_exact_objectives.jl", "test/arc1_fa_v2_contracts.jl",
                "test/arc1_optimizer_contracts.jl",
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
            launcher = self.external / "synthetic-julia-launcher"
            launcher.write_text("synthetic launcher fixture\n")
            doc["runtime"].update({"julia_executable": str(launcher.resolve()),
                                   "rscript_executable": str(Path("/synthetic/Rscript").resolve())})
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
        tests = self.oracle.JULIA_TESTS if gate == "G1" else []
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
                output = "ARC1_TESTTHAT_COUNTS six files assertions positive\n"
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
        names = ["julia-version", "rscript-version", "julia-direct-test-suite", "r-arc1-mandatory-live",
                 "r-cmd-check", "julia-local-docs"]
        julia_summaries = "".join(
            "Test Summary: | Pass  Fail  Error  Broken  Total  Time\n"
            f"{testset} |    1     0     0      0     1  0.0s\n"
            for testset in SYNTHETIC_JULIA_TESTSETS)
        julia_log = ("ARC1_TEST_SANDBOX_VERIFIED\nARC1_LOADED_HSQUARED_SOURCE_VERIFIED\n" +
                     julia_summaries + "ARC1_PACKAGE_JULIA_COMPONENT_PASS\n")
        for filename, contents in (("r-arc1-live-driver.R", self.package.R_DRIVER),
                                   ("r-package-check-driver.R", self.package.R_PACKAGE_DRIVER)):
            (self.run_dir / filename).write_text(contents)
        for i, name in enumerate(names, 1):
            content = {
                "julia-version": "julia test version\n",
                "rscript-version": "R test version\n",
                "julia-direct-test-suite": julia_log,
                "r-arc1-mandatory-live": "ARC1_TESTTHAT_COUNTS six files assertions positive\n",
                "r-cmd-check": "ARC1_PACKAGE_R_CHECK_COMPONENT_PASS\n",
                "julia-local-docs": "ARC1_PACKAGE_DOCS_HTML_BUILT\nARC1_PACKAGE_DOCS_COMPONENT_PASS\n",
            }[name]
            log, digest = self._log(f"{i:02d}-{name}.log", content)
            run = str(self.run_dir.resolve())
            argv = {
                "julia-version": ["julia", "--startup-file=no", "--version"],
                "rscript-version": ["Rscript", "--version"],
                "julia-direct-test-suite": self.package._julia_command(
                    self.run_dir / "julia-test-driver.jl",
                    json.loads(package_freeze.read_text())["julia_test_sandbox"],
                )[0],
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
        driver = self.run_dir / "julia-test-driver.jl"
        driver.write_text(self.package.julia_test_driver_source(sandbox_spec, capture))
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
        commands[2]["env_overrides"] = self.package._julia_command(driver, sandbox_spec)[1]
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
        runtime = fre_doc["runtime"]
        driver.write_text(self.package.julia_test_driver_source(
            sandbox_spec, capture, freeze_sha256=sha(package_freeze),
            expected_julia_executable=runtime["julia_executable"],
            expected_julia_version=runtime["julia"].removeprefix("julia version "),
            source_file_inventory=self.inputs["julia"]))
        canonical = "0" * 64
        preflight_identity = {
            "schema": "arc1-julia-noinstall-preflight-v1", "status": "passed",
            "freeze_sha256": sha(package_freeze), "runner_sha256": sha(self.runner),
            "driver_sha256": sha(driver),
            "source_root": str(self.package.JULIA_ROOT.resolve()),
            "source_files": dict(self.inputs["julia"]),
            "sandbox": {"project_path": str(Path(sandbox_spec["project_path"]).resolve()),
                        "project_sha256": sandbox_spec["project_sha256"],
                        "manifest_path": str(Path(sandbox_spec["manifest_path"]).resolve()),
                        "manifest_sha256": sandbox_spec["manifest_sha256"]},
            "load_path": ["@", "@stdlib"], "depot_path": ["/synthetic/depot"],
            "julia_executable": runtime["julia_executable"],
            "julia_launcher_sha256": sha(Path(runtime["julia_executable"])),
            "julia_runtime_executable": runtime["julia_executable"],
            "julia_runtime_executable_sha256": sha(Path(runtime["julia_executable"])),
            "julia_version": runtime["julia"].removeprefix("julia version "),
            "host_platform": "synthetic",
            "host_platform_tags": {"arch": "synthetic", "os": "synthetic"},
            "depot_path": ["/synthetic/depot"],
            "registry_tarball_mode": True,
            "manifest_sources": [{"name": "Synthetic", "uuid": "synthetic-uuid",
                                  "kind": "git-tree", "source_path": "/synthetic/Synthetic",
                                  "project_path": "/synthetic/Synthetic/Project.toml",
                                  "git_tree_sha1": "1" * 40, "content_tree_sha256": "2" * 64}],
            "dependency_closure": [{"name": "Synthetic", "uuid": "synthetic-uuid",
                                    "kind": "git-tree"}],
            "artifact_sources": [{"package": "Synthetic", "package_uuid": "synthetic-uuid",
                                  "selected": [{"name": "data", "git_tree_sha1": "3" * 40,
                                                "lazy": False}]}],
            "artifacts": [{"package": "Synthetic", "package_uuid": "synthetic-uuid",
                           "name": "data", "git_tree_sha1": "3" * 40, "lazy": False}],
            "artifact_override_files": [{"path": "/synthetic/Overrides.toml", "present": False}],
            "effective_artifact_overrides": {"/synthetic/Overrides.toml": {}},
            "registries": [{"registry_path": "/synthetic/depot/registries/General.toml",
                            "descriptor_path": "/synthetic/depot/registries/General.toml",
                            "payload_path": "/synthetic/depot/registries/General.tar.gz",
                            "compressed": True, "descriptor_sha256": "4" * 64,
                            "payload_sha256": "5" * 64, "git_tree_sha1": "6" * 40,
                            "observed_tree_sha1": "6" * 40, "name": "General",
                            "uuid": "23338594-aafe-5451-b93e-139f81909106",
                            "repo": "https://example.invalid/General.git"}],
            "canonical_sha256": canonical,
        }
        before_doc = {**preflight_identity, "created_at_utc": "2026-10-05T00:00:00Z"}
        after_doc = {**preflight_identity, "created_at_utc": "2026-10-05T00:00:01Z"}
        before_path = capture / "julia-noinstall-preflight-before.toml"
        after_path = capture / "julia-noinstall-preflight-after.toml"
        before_path.write_text(fixture_toml(before_doc))
        after_path.write_text(fixture_toml(after_doc))
        canonical = verify._canonical_preflight_sha256(before_path)
        before_doc["canonical_sha256"] = canonical
        after_doc["canonical_sha256"] = canonical
        before_path.write_text(fixture_toml(before_doc))
        after_path.write_text(fixture_toml(after_doc))
        before_hash, after_hash = sha(before_path), sha(after_path)
        julia_log = ("ARC1_TEST_SANDBOX_VERIFIED\nARC1_LOADED_HSQUARED_SOURCE_VERIFIED\n" +
                     f"ARC1_NO_INSTALL_PREFLIGHT_BEFORE_SHA256={before_hash}\n" +
                     f"ARC1_NO_INSTALL_PREFLIGHT_AFTER_SHA256={after_hash}\n" +
                     f"ARC1_NO_INSTALL_PREFLIGHT_CANONICAL_SHA256={canonical}\n" +
                     "ARC1_NO_INSTALL_PREFLIGHT_IDENTICAL\n" + julia_summaries +
                     "ARC1_PACKAGE_JULIA_COMPONENT_PASS\n")
        julia_log_path = self.run_dir / commands[2]["log"]
        julia_log_path.write_text(julia_log)
        commands[2]["log_sha256"] = sha(julia_log_path)
        preflight_receipt = {
            "schema": "arc1-julia-noinstall-preflight-v1", "status": "passed",
            "created_at_utc": before_doc["created_at_utc"],
            "receipt_path": str(before_path.resolve()), "receipt_sha256": before_hash,
            "post_test_receipt_path": str(after_path.resolve()), "post_test_receipt_sha256": after_hash,
            "canonical_sha256": canonical, "canonical_equal": True,
            "log_marker": "ARC1_NO_INSTALL_PREFLIGHT_IDENTICAL",
        }
        recs = {
            "julia": {"status": "passed", "log": commands[2]["log"], "log_sha256": commands[2]["log_sha256"],
                      "test_summary": package_runner.parse_julia_test_output(
                          julia_log, required_arc1_testsets=SYNTHETIC_JULIA_TESTSETS),
                      "test_sandbox": {"project_sha256": sandbox_spec["project_sha256"],
                                       "manifest_sha256": sandbox_spec["manifest_sha256"],
                                       "capture_dir": str(capture.resolve())},
                      "test_sandbox_after_sha256": {
                          "project_sha256": sandbox_spec["project_sha256"],
                          "manifest_sha256": sandbox_spec["manifest_sha256"]},
                      "test_sandbox_capture_after_sha256": {
                          "project_sha256": sandbox_spec["project_sha256"],
                          "manifest_sha256": sandbox_spec["manifest_sha256"]},
                      "test_driver": {"path": driver.name, "sha256": sha(driver)},
                      "noinstall_preflight": preflight_receipt},
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
                   "runtime_expected": fre_doc["runtime"],
                   "runtime_observed": {"julia": "julia test version", "rscript": "R test version"},
                   "input_counts": {key: len(value) for key, value in self.inputs.items()},
                   "passed_components": ["julia", "r", "docs"], "commands": commands,
                   "component_receipts": recs,
                   "julia_noinstall_preflight": preflight_receipt,
                   "julia_test_driver": {"path": driver.name, "sha256": sha(driver)},
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

    def test_g7_requires_profile_v4_transport_isolation_in_live_inventory(self) -> None:
        expected = (
            "test-arc1-controls.R", "test-arc1-live-parity.R",
            "test-arc1-bootstrap-v2-live.R", "test-arc1-profile-v4-live.R",
            "test-arc1-profile-v4-transport-isolation.R",
            "test-arc1-uncertainty-controls.R", "test-arc1-uncertainty-live.R",
        )
        self.assertEqual(verify.REQUIRED_R_TESTS, expected)
        receipt, info = self._package_receipt()
        path = self.run_dir / "run.json"
        path.write_text(json.dumps(receipt) + "\n")
        verify.verify_retained("G7", path, sha(path), self.package_freeze, sha(self.package_freeze),
                               adapter=info["adapter"], artifact_kind="package")

    def test_g7_julia_receipt_summaries_are_reparsed_from_hashed_log(self) -> None:
        path = self.run_dir / "run.json"
        cases = ("missing summaries", "altered counts", "non-arc1 failure")
        for label in cases:
            with self.subTest(label):
                receipt, info = self._package_receipt()
                command = receipt["commands"][2]
                log = self.run_dir / command["log"]
                if label == "missing summaries":
                    log.write_text("ARC1_TEST_SANDBOX_VERIFIED\nARC1_LOADED_HSQUARED_SOURCE_VERIFIED\n"
                                   "ARC1_PACKAGE_JULIA_COMPONENT_PASS\n")
                    command["log_sha256"] = sha(log)
                    receipt["component_receipts"]["julia"]["log_sha256"] = command["log_sha256"]
                elif label == "altered counts":
                    receipt["julia_test_summary"]["summary_records"][0]["pass"] = 999
                    receipt["component_receipts"]["julia"]["test_summary"] = receipt["julia_test_summary"]
                else:
                    log.write_text(log.read_text() +
                                   "Test Summary: | Pass  Fail  Error  Broken  Total  Time\n"
                                   "unrelated non-Arc1 |    0     1     0      0     1  0.0s\n")
                    command["log_sha256"] = sha(log)
                    receipt["component_receipts"]["julia"]["log_sha256"] = command["log_sha256"]
                path.write_text(json.dumps(receipt) + "\n")
                with self.assertRaises(verify.ReceiptError):
                    verify.verify_retained("G7", path, sha(path), self.package_freeze,
                                           sha(self.package_freeze), adapter=info["adapter"], artifact_kind="package")
        receipt, info = self._package_receipt()
        receipt["commands"][2]["argv"] = ["julia", "--project=.", "-e", "Pkg.test()"]
        path.write_text(json.dumps(receipt) + "\n")
        with self.assertRaises(verify.ReceiptError):
            verify.verify_retained("G7", path, sha(path), self.package_freeze, sha(self.package_freeze),
                                   adapter=info["adapter"], artifact_kind="package")

    def test_g7_requires_bound_before_and_after_noinstall_preflight(self) -> None:
        path = self.run_dir / "run.json"
        for label in ("missing top-level pointer", "changed status", "tampered TOML"):
            with self.subTest(label):
                receipt, info = self._package_receipt()
                if label == "missing top-level pointer":
                    del receipt["julia_noinstall_preflight"]
                elif label == "changed status":
                    receipt["julia_noinstall_preflight"]["canonical_equal"] = False
                else:
                    after = self.run_dir / "julia-test-sandbox" / "julia-noinstall-preflight-after.toml"
                    after.write_text(after.read_text() + "# altered after-run evidence\n")
                path.write_text(json.dumps(receipt) + "\n")
                with self.assertRaises(verify.ReceiptError):
                    verify.verify_retained("G7", path, sha(path), self.package_freeze,
                                           sha(self.package_freeze), adapter=info["adapter"], artifact_kind="package")
        receipt, info = self._package_receipt()
        info["adapter"]._probe_julia_host_identity = lambda launcher, *, expected_version: {
            "julia_version": expected_version, "host_platform": "forged-platform",
            "host_platform_tags": {"arch": "forged", "os": "forged"},
            "julia_runtime_executable": str(Path(launcher).resolve()),
            "julia_runtime_executable_sha256": sha(Path(launcher)),
        }
        path.write_text(json.dumps(receipt) + "\n")
        with self.assertRaises(verify.ReceiptError):
            verify.verify_retained("G7", path, sha(path), self.package_freeze,
                                   sha(self.package_freeze), adapter=info["adapter"], artifact_kind="package")
        receipt, info = self._package_receipt()
        preflight = receipt["julia_noinstall_preflight"]
        old_before = preflight["receipt_sha256"]
        old_after = preflight["post_test_receipt_sha256"]
        old_canonical = preflight["canonical_sha256"]
        before_path = Path(preflight["receipt_path"])
        after_path = Path(preflight["post_test_receipt_path"])
        for report_path in (before_path, after_path):
            report = tomllib.loads(report_path.read_text())
            report["canonical_sha256"] = "f" * 64
            report_path.write_text(fixture_toml(report))
        new_before, new_after = sha(before_path), sha(after_path)
        preflight.update({"receipt_sha256": new_before, "post_test_receipt_sha256": new_after,
                          "canonical_sha256": "f" * 64})
        receipt["component_receipts"]["julia"]["noinstall_preflight"] = preflight
        command = receipt["commands"][2]
        log = self.run_dir / command["log"]
        log_text = log.read_text().replace(old_before, new_before).replace(old_after, new_after)
        log_text = log_text.replace(old_canonical, "f" * 64)
        log.write_text(log_text)
        command["log_sha256"] = sha(log)
        receipt["component_receipts"]["julia"]["log_sha256"] = command["log_sha256"]
        path.write_text(json.dumps(receipt) + "\n")
        with self.assertRaises(verify.ReceiptError):
            verify.verify_retained("G7", path, sha(path), self.package_freeze, sha(self.package_freeze),
                                   adapter=info["adapter"], artifact_kind="package")

    def test_g7_retained_preflight_is_stable_after_external_registry_drift(self) -> None:
        receipt, info = self._package_receipt()
        path = self.run_dir / "run.json"
        path.write_text(json.dumps(receipt) + "\n")

        def registry_changed_after_run(path: Path, expected_sha256: str,
                                       expected: dict[str, Any]) -> dict[str, Any]:
            report = verify.tomllib.loads(path.read_text())
            self.assertTrue(report["manifest_sources"])
            self.assertTrue(report["dependency_closure"])
            self.assertTrue(report["artifact_sources"])
            self.assertTrue(report["artifacts"])
            self.assertTrue(report["artifact_override_files"])
            self.assertTrue(report["registries"])
            raise ValueError("reachable registry descriptor content changed")

        info["adapter"].validate_noinstall_preflight_receipt = registry_changed_after_run
        info["adapter"]._registry_candidates = lambda depot, tarball: {
            "/synthetic/depot/registries/General.toml"}
        marker = verify.verify_retained("G7", path, sha(path), self.package_freeze,
                                        sha(self.package_freeze), adapter=info["adapter"],
                                        artifact_kind="package")
        self.assertEqual(marker, "ARC1_G7_RETAINED_RECEIPT_VERIFIED")

        # A matching outer hash never lets a source, registry, artifact or override
        # failure masquerade as a later registry update. These are errors the full
        # semantic validator can raise before it reaches live registry bytes.
        for failure in (
            "no-install preflight manifest source inventory is missing",
            "manifest source path or tree identity is missing: Synthetic",
            "no-install preflight reachable registry state is missing",
            "selected artifact inventory is incomplete or contains unexpected artifacts",
            "no-install preflight detected an effective artifact override",
        ):
            info["adapter"].validate_noinstall_preflight_receipt = (
                lambda *args, message=failure, **kwargs: (_ for _ in ()).throw(ValueError(message)))
            with self.assertRaises(verify.ReceiptError):
                verify.verify_retained("G7", path, sha(path), self.package_freeze,
                                       sha(self.package_freeze), adapter=info["adapter"],
                                       artifact_kind="package")
        receipt, info = self._package_receipt()
        driver = self.run_dir / "julia-test-driver.jl"
        driver.write_text("Pkg.resolve() # forbidden in the G7 test process\n")
        driver_record = {"path": driver.name, "sha256": sha(driver)}
        receipt["julia_test_driver"] = driver_record
        receipt["component_receipts"]["julia"]["test_driver"] = driver_record
        path.write_text(json.dumps(receipt) + "\n")
        with self.assertRaises(verify.ReceiptError):
            verify.verify_retained("G7", path, sha(path), self.package_freeze, sha(self.package_freeze),
                                   adapter=info["adapter"], artifact_kind="package")
        receipt, info = self._package_receipt()
        receipt["component_receipts"]["julia"]["test_sandbox_after_sha256"]["manifest_sha256"] = "0" * 64
        path.write_text(json.dumps(receipt) + "\n")
        with self.assertRaises(verify.ReceiptError):
            verify.verify_retained("G7", path, sha(path), self.package_freeze, sha(self.package_freeze),
                                   adapter=info["adapter"], artifact_kind="package")
        receipt, info = self._package_receipt()
        captured_manifest = self.run_dir / "julia-test-sandbox" / "Manifest.toml"
        captured_manifest.write_text("changed after direct test execution\n")
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
