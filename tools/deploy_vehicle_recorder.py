"""Install the local TABS vehicle recorder without replacing existing integrations.

Only a bounded block is appended to TABS/main.lua. The exact pre-install file
(including any Hit Replay integration) is retained and hash checked on restore.
Remove this bridge before updating TABS through another patch installer, then
reinstall it with a new backup directory if that update changes the baseline.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tabs-vehicle-recorder"
DEFAULT_TARGET = Path("D:/Steam/steamapps/workshop/content/1167630/3148138736")
DEFAULT_DESTINATION = Path.home() / "Documents/Teardown/mods/tabs-vehicle-recorder"
DEFAULT_BACKUP = ROOT / ".local-backups/tabs-vehicle-recorder"
BEGIN = b"-- BEGIN TABS VEHICLE RECORDER v1"
END = b"-- END TABS VEHICLE RECORDER v1"
BRIDGE_FILES = ("core.lua", "weapons.lua", "bridge.lua")
ADDON_FILES = ("main.lua", "options.lua", "info.txt", "tool.xml", "preview.jpg")


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def json_bytes(value: dict) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True) + "\n").encode("utf-8")


def existing(path: Path) -> bytes | None:
    return path.read_bytes() if path.exists() else None


def _atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tvr-" + uuid.uuid4().hex + ".tmp")
    try:
        with temporary.open("xb") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def transaction(changes: dict[Path, bytes], before: dict[Path, bytes | None]) -> None:
    # Recheck every destination after preparing the plan, before the first write.
    for path, previous in before.items():
        if existing(path) != previous:
            raise RuntimeError(f"File changed while preparing installation: {path}")
    completed = []
    try:
        for path, data in changes.items():
            completed.append(path)
            _atomic_write(path, data)
    except Exception as error:
        failures = []
        for path in reversed(completed):
            try:
                if before[path] is None:
                    path.unlink(missing_ok=True)
                else:
                    _atomic_write(path, before[path])
            except Exception as rollback_error:
                failures.append(f"{path}: {rollback_error}")
        if failures:
            raise RuntimeError("Installation failed and rollback needs attention: " + "; ".join(failures)) from error
        raise


def _paths(destination: Path, target: Path, backup: Path, source: Path | None = None):
    paths = [Path(destination).resolve(), Path(target).resolve(), Path(backup).resolve()]
    if source is not None:
        paths.append(Path(source).resolve())
    for index, path in enumerate(paths):
        for other in paths[index + 1:]:
            if path == other or path in other.parents or other in path.parents:
                raise RuntimeError(f"Source, addon, framework and backup folders must be separate: {path}, {other}")
    return paths


def patched(original: bytes, sources: list[bytes]) -> bytes:
    if len(sources) != len(BRIDGE_FILES):
        raise RuntimeError("All three recorder bridge modules are required")
    if b"TABS VEHICLE RECORDER" in original or b"TVRCore =" in original:
        raise RuntimeError("An unmanaged vehicle recorder patch is already present")
    signatures = (
        rb"function\s+ShootWeapon\(vInfo,\s*Weapon,\s*dt,\s*shellInfoOverride\)",
        rb"function\s+tick\(dt\)",
        rb"function\s+update\(dt\)",
        rb"\bTABSVehicles\b",
    )
    if any(re.search(signature, original) is None for signature in signatures):
        raise RuntimeError("Unsupported TABS source: required vehicle/weapon callbacks are missing")
    newline = b"\r\n" if b"\r\n" in original else b"\n"
    pieces = [BEGIN]
    for name, source in zip(BRIDGE_FILES, sources):
        if not source.strip() or BEGIN in source or END in source:
            raise RuntimeError(f"Invalid recorder source: {name}")
        pieces.append(b"-- Recorder module: " + name.encode("ascii"))
        pieces.append(source.replace(b"\r\n", b"\n").replace(b"\n", newline))
    pieces.append(END)
    # Preserve every original byte, including its final newline and BOM.
    return original + newline + newline.join(pieces) + newline


def _baseline(target: Path, backup: Path):
    main = target / "main.lua"
    manifest = backup / "manifest.json"
    current = main.read_bytes()
    previous = existing(manifest)
    if previous is None:
        if (backup / "main.lua").exists():
            raise RuntimeError("Unmanaged backup exists; choose an empty --backup folder")
        return current, current, None
    state = json.loads(previous)
    if state.get("version") != 1 or state.get("target") != str(target):
        raise RuntimeError("Backup belongs to a different installation or version")
    if state.get("status") not in ("installed", "uninstalled"):
        raise RuntimeError("Invalid backup manifest status")
    original = (backup / "main.lua").read_bytes()
    if digest(original) != state.get("original"):
        raise RuntimeError("Backup verification failed; refusing to overwrite framework")
    expected = state["installed"] if state["status"] == "installed" else state["original"]
    if digest(current) != expected:
        raise RuntimeError("TABS main.lua changed after installation/restore; refusing to overwrite edits or a Workshop update")
    return original, current, state


def _addon_files(destination: Path, source: Path) -> dict[Path, bytes]:
    marker = destination / ".managed-files.json"
    previous = json.loads(marker.read_text(encoding="utf-8")) if marker.exists() else {}
    if not isinstance(previous, dict):
        raise RuntimeError("Invalid addon manifest")
    # Check all previously managed files, including an optional README.
    for name, sha in previous.items():
        if name not in (*ADDON_FILES, "README.md"):
            raise RuntimeError(f"Unexpected addon manifest entry: {name}")
        data = existing(destination / name)
        if data is None or digest(data) != sha:
            raise RuntimeError(f"Managed addon file was changed or removed: {destination / name}")
    names = list(ADDON_FILES)
    if (source / "README.md").exists():
        names.append("README.md")
    output = {}
    hashes = dict(previous)
    for name in names:
        path = destination / name
        if path.exists() and name not in previous:
            raise RuntimeError(f"Refusing to overwrite unmanaged addon file: {path}")
        data = (source / name).read_bytes()
        output[path] = data
        hashes[name] = digest(data)
    output[marker] = json_bytes(hashes)
    return output


def deploy(destination=DEFAULT_DESTINATION, target=DEFAULT_TARGET,
           backup=DEFAULT_BACKUP, *, source=SOURCE, check=False):
    destination, target, backup, source = _paths(destination, target, backup, source)
    original, current, old_state = _baseline(target, backup)
    sources = [(source / name).read_bytes() for name in BRIDGE_FILES]
    output = patched(original, sources)
    addon = _addon_files(destination, source)
    state = {
        "version": 1, "status": "installed", "target": str(target),
        "destination": str(destination), "original": digest(original),
        "installed": digest(output),
        "bridge_sources": {name: digest(data) for name, data in zip(BRIDGE_FILES, sources)},
    }
    if old_state and old_state.get("destination") != str(destination):
        raise RuntimeError("Backup belongs to a different addon destination")
    changes = {}
    if old_state is None:
        changes[backup / "main.lua"] = original
    changes.update(addon)
    changes[target / "main.lua"] = output
    changes[backup / "manifest.json"] = json_bytes(state)
    before = {path: existing(path) for path in changes}
    if before[target / "main.lua"] != current:
        raise RuntimeError("TABS main.lua changed while preparing installation")
    if old_state is not None:
        before[backup / "main.lua"] = original
        if existing(backup / "manifest.json") != before[backup / "manifest.json"]:
            raise RuntimeError("Backup manifest changed while preparing installation")
    if not check:
        transaction(changes, before)
    print("CHECK OK; no files changed." if check else "Installed TABS Fusion.")
    print("Addon:", destination)
    print("Exact-byte framework backup:", backup / "main.lua")
    print("Enable TABS Fusion and TABS, then reload the level.")
    print("Before using another TABS patch updater, uninstall this bridge first.")
    return state


def uninstall(destination=DEFAULT_DESTINATION, target=DEFAULT_TARGET,
              backup=DEFAULT_BACKUP, *, check=False):
    destination, target, backup = _paths(destination, target, backup)
    original, current, state = _baseline(target, backup)
    if state is None:
        raise RuntimeError("No managed recorder installation was found")
    if state.get("destination") != str(destination):
        raise RuntimeError("Backup belongs to a different addon destination")
    state = dict(state)
    state["status"] = "uninstalled"
    changes = {target / "main.lua": original, backup / "manifest.json": json_bytes(state)}
    before = {path: existing(path) for path in changes}
    before[backup / "main.lua"] = original
    if before[target / "main.lua"] != current:
        raise RuntimeError("TABS main.lua changed while preparing restore")
    if not check:
        transaction(changes, before)
    print("CHECK OK; no files changed." if check else "Restored exact pre-recorder TABS main.lua.")
    print("Addon files and backups retained. Disable TABS Vehicle Recorder and reload the level.")
    return state


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--destination", type=Path, default=DEFAULT_DESTINATION)
    parser.add_argument("--target", type=Path, default=DEFAULT_TARGET)
    parser.add_argument("--backup", type=Path, default=DEFAULT_BACKUP)
    parser.add_argument("--check", action="store_true", help="Validate without writing any files")
    parser.add_argument("--uninstall", action="store_true", help="Restore framework; retain addon and backups")
    args = parser.parse_args()
    try:
        operation = uninstall if args.uninstall else deploy
        operation(args.destination, args.target, args.backup, check=args.check)
    except (OSError, ValueError, RuntimeError, KeyError) as error:
        parser.exit(1, f"Recorder installation stopped: {error}\n")


if __name__ == "__main__":
    main()

