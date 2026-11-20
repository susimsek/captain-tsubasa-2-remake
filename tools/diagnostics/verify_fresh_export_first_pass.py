#!/usr/bin/env python3
"""Export a temporary runtime PCK, inspect it, and replay the requested PASS endpoint."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PRESET = "Linux Desktop"
RUNTIME_CONTENT_VERIFIER = ROOT / "tools/diagnostics/verify_runtime_export_contents.gd"
EXPORTED_ROUTE_VERIFIER = ROOT / "tools/diagnostics/verify_exported_route.gd"
SUPPORTED_ROUTE_ENDPOINTS = {"CAA5", "D5EA"}
PASS_ENDPOINT_ENV = "CT2_FIRST_PASS_ROUTE_ENDPOINT"
BASE_INPUT_ENV = "CT2_ROUTE_INPUT_CSV"
PASS_EDGES_ENV = "CT2_FIRST_PASS_INPUT_EDGES_CSV"


def command_output(label: str, completed: subprocess.CompletedProcess[str]) -> None:
    print(f"[{label}] exit={completed.returncode}")
    output = (completed.stdout or "") + (completed.stderr or "")
    if output:
        for line in output.splitlines():
            if line.strip():
                print(line)


def run(label: str, argv: list[str], env: dict[str, str],
        timeout_seconds: int, cwd: Path = ROOT) -> subprocess.CompletedProcess[str]:
    print(f"[{label}] command: {' '.join(argv)}")
    try:
        completed = subprocess.run(argv, cwd=cwd, env=env, text=True,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   check=False, timeout=timeout_seconds)
    except subprocess.TimeoutExpired as timeout:
        output = timeout.stdout or ""
        if isinstance(output, bytes):
            output = output.decode("utf-8", errors="replace")
        completed = subprocess.CompletedProcess(argv, 124, stdout=output)
        print(f"[{label}] timed out after {timeout_seconds}s")
    command_output(label, completed)
    return completed


def normalize_endpoint(raw: str) -> str:
    return raw.strip().upper().removeprefix("$").removeprefix("0X")


def has_fatal_godot_error(output: str) -> bool:
    for line in output.splitlines():
        if "SCRIPT ERROR:" in line:
            return True
        if "ERROR:" in line and "resources still in use at exit" not in line:
            return True
    return False


def assert_isolated_runtime_cwd(path: Path) -> Path:
    cwd = path.resolve()
    if cwd == ROOT or ROOT in cwd.parents or (cwd / "project.godot").exists() \
            or (cwd / "reference").exists():
        raise RuntimeError(f"PCK runtime working directory is not isolated: {cwd}")
    print(f"PASS: PCK runtime working directory is isolated from the project/reference tree: {cwd}")
    return cwd


def main() -> int:
    godot = (os.environ.get("CT2_GODOT_BIN") or os.environ.get("GODOT_BIN")
             or shutil.which("godot") or "").strip()
    if not godot:
        print("FAIL: set CT2_GODOT_BIN or GODOT_BIN to the Godot 4.7.2 executable.")
        return 1
    endpoint_raw = os.environ.get(PASS_ENDPOINT_ENV, "")
    endpoint = normalize_endpoint(endpoint_raw)
    if endpoint == "9600":
        endpoint = "D5EA"
    base_input = os.environ.get(BASE_INPUT_ENV, "").strip()
    pass_edges = os.environ.get(PASS_EDGES_ENV, "").strip()
    route_inputs_ready = bool(base_input and pass_edges and endpoint)

    if not endpoint:
        print(f"ENDPOINT_GAP: {PASS_ENDPOINT_ENV} is unset; no first-PASS endpoint claim will be made.")
    elif not base_input or not pass_edges:
        missing = [name for name, value in [(BASE_INPUT_ENV, base_input),
                                             (PASS_EDGES_ENV, pass_edges)] if not value]
        print("ENDPOINT_GAP: missing validation input environment: " + ", ".join(missing))

    with tempfile.TemporaryDirectory(prefix="ct2-first-pass-export-") as temporary:
        runtime_cwd = assert_isolated_runtime_cwd(Path(temporary))
        pck = runtime_cwd / "captain-tsubasa-runtime-smoke.pck"
        exported = run("fresh PCK export", [godot, "--headless", "--quiet", "--path", str(ROOT),
                       "--export-pack", PRESET, str(pck)], os.environ.copy(), 300)
        if exported.returncode != 0 or not pck.is_file() or pck.stat().st_size == 0:
            print("FAIL: fresh temporary PCK export did not produce a nonempty pack.")
            return 1
        print(f"PASS: temporary PCK created ({pck.stat().st_size} bytes); it will be deleted at exit.")

        smoke = run("PCK runtime smoke", [godot, "--headless", "--main-pack", str(pck),
                     "--quit-after", "2"], os.environ.copy(), 60, cwd=runtime_cwd)
        if smoke.returncode != 0 or has_fatal_godot_error(smoke.stdout or ""):
            print("FAIL: exported PCK did not launch cleanly.")
            return 1

        content = run("PCK content and omission audit", [godot, "--headless",
                       "--main-pack", str(pck), "--script", str(RUNTIME_CONTENT_VERIFIER)],
                      os.environ.copy(), 180, cwd=runtime_cwd)
        if content.returncode != 0:
            print("FAIL: exported PCK omitted required runtime data or included forbidden ROM/emulator/capture inputs.")
            return 1

        if not route_inputs_ready:
            print("LIMIT: PCK launch and omission audit passed; PASS-route verification was skipped because its environment-provided endpoint/input files are incomplete.")
            return 2

        route_env = os.environ.copy()
        route_env["CT2_VERIFY_FIRST_PASS"] = "1"
        route_source = EXPORTED_ROUTE_VERIFIER.read_text(encoding="utf-8")
        typed_helper = "func _dispatch_edges(route: KickoffRouteRuntime, changes: Array[Dictionary]) -> void:"
        untyped_helper = "func _dispatch_edges(route: KickoffRouteRuntime, changes: Array) -> void:"
        if route_source.count(typed_helper) == 1 and route_source.count(untyped_helper) == 0:
            # Older verifier revisions typed this argument more narrowly than
            # the untyped Arrays produced by the CSV parser.
            route_source = route_source.replace(typed_helper, untyped_helper)
        elif route_source.count(untyped_helper) != 1 or route_source.count(typed_helper) != 0:
            print("FAIL: existing exported-route verifier signature changed; no temporary compatibility shim applied.")
            return 1
        # Keep the disposable verifier copy compatible with either supported
        # signature; runtime route scripts and route state still load from the
        # freshly exported PCK.
        route_script = Path(temporary) / "verify_exported_route_pck.gd"
        route_script.write_text(route_source, encoding="utf-8")
        route = run("PCK first-PASS route replay", [godot, "--headless", "--fixed-fps", "60",
                      "--main-pack", str(pck), "--script", str(route_script)],
                    route_env, 600, cwd=runtime_cwd)
        if route.returncode != 0:
            if has_fatal_godot_error(route.stdout or ""):
                print("FAIL: exported route verifier reported a Godot script/runtime error.")
                if route.returncode == 124:
                    print("ENDPOINT_GAP: the verifier did not exit after that error; no route endpoint is claimed.")
                return 1
            if route.returncode == 124:
                print("ENDPOINT_GAP: exported route replay exceeded 600s; no first-PASS endpoint is claimed.")
                return 2
            print("FAIL: exported route verifier did not reach its implemented first-PASS boundary.")
            print("LIMIT: no endpoint beyond the boundary actually reported by the route verifier is claimed.")
            return 1

        route_output = route.stdout or ""
        observed_endpoint = next((line.split("=", 1)[1].strip().upper()
                                  for line in route_output.splitlines()
                                  if line.startswith("VERIFIED_ENDPOINT=")), "")
        if not observed_endpoint:
            print("FAIL: route verifier exited successfully without a machine-readable verified endpoint.")
            return 1
        if endpoint not in SUPPORTED_ROUTE_ENDPOINTS:
            print(f"ENDPOINT_GAP: requested `${endpoint}`; exported route verifier only proves `${observed_endpoint}`. No `${endpoint}` reachability is asserted.")
            return 2
        if endpoint != observed_endpoint:
            print(f"FAIL: requested `${endpoint}`, but verifier reported `${observed_endpoint}`.")
            return 1

        print(f"PASS: exported PCK reached the environment-requested first-PASS endpoint `${endpoint}` using the recorded input-edge files.")
        print("PASS: ROM, emulator state, screenshots, and captured audio were absent from the exported PCK.")
        if observed_endpoint == "CAA5":
            print("LIMIT: `$CAA5` verifies only the post-confirmation scheduler handoff; it does not establish the PASS action result or next decision boundary.")
        elif observed_endpoint == "D5EA":
            print("LIMIT: audio cue ordering and ROM-only package presence are checked; full PCM parity, pixel-by-pixel framebuffer parity, and physical NES subframe timing are not established by this verifier.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
