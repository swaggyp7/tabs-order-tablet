"""Exercise installer rollback and preservation with isolated temporary files."""
import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("vehicle_recorder_installer", ROOT / "tools/deploy_vehicle_recorder.py")
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)

BASE = (b"\xef\xbb\xbf-- Existing native source\r\nTABSVehicles = {}\r\n"
        b"function ShootWeapon(vInfo, Weapon, dt, shellInfoOverride) end\r\n"
        b"function tick(dt) end\r\nfunction update(dt) end\r\n"
        b"-- Existing Hit Replay integration\r\nlocal previous=tick\r\n"
        b"function tick(dt) previous(dt) end")


class InstallationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="tvr-install-test-")
        self.addCleanup(self.directory.cleanup)
        root = Path(self.directory.name)
        self.target, self.destination, self.backup, self.source = [root / name for name in ("tabs", "addon", "backup", "source")]
        self.target.mkdir()
        self.source.mkdir()
        (self.target / "main.lua").write_bytes(BASE)
        (self.target / "ballistics.lua").write_bytes(b"MUST REMAIN UNCHANGED")
        for name in installer.BRIDGE_FILES:
            (self.source / name).write_bytes(("-- " + name + "\nlocal test = true\n").encode())
        for name in installer.ADDON_FILES:
            (self.source / name).write_bytes(("addon " + name).encode())
        self.silence = contextlib.redirect_stdout(io.StringIO())
        self.silence.__enter__()
        self.addCleanup(self.silence.__exit__, None, None, None)

    def install(self, **kwargs):
        return installer.deploy(self.destination, self.target, self.backup, source=self.source, **kwargs)

    def uninstall(self, **kwargs):
        return installer.uninstall(self.destination, self.target, self.backup, **kwargs)

    def snapshots(self):
        return {path.relative_to(Path(self.directory.name)).as_posix(): path.read_bytes()
                for path in Path(self.directory.name).rglob("*") if path.is_file()}

    def test_roundtrip_and_idempotence_preserve_existing_integration(self):
        self.install()
        installed = (self.target / "main.lua").read_bytes()
        self.assertTrue(installed.startswith(BASE + b"\r\n"))
        self.assertEqual(installed.count(installer.BEGIN), 1)
        self.assertEqual(installed.count(installer.END), 1)
        self.assertLess(installed.index(b"Recorder module: core.lua"), installed.index(b"Recorder module: weapons.lua"))
        self.assertLess(installed.index(b"Recorder module: weapons.lua"), installed.index(b"Recorder module: bridge.lua"))
        self.assertEqual((self.backup / "main.lua").read_bytes(), BASE)
        self.assertEqual((self.target / "ballistics.lua").read_bytes(), b"MUST REMAIN UNCHANGED")
        self.install()
        self.assertEqual((self.target / "main.lua").read_bytes(), installed)
        self.uninstall()
        self.assertEqual((self.target / "main.lua").read_bytes(), BASE)
        self.assertTrue((self.destination / "main.lua").exists())
        self.uninstall()
        self.install()
        self.assertEqual((self.target / "main.lua").read_bytes(), installed)

    def test_update_changes_our_block_only(self):
        self.install()
        (self.source / "core.lua").write_bytes(b"-- revised recorder\n")
        self.install()
        main = (self.target / "main.lua").read_bytes()
        self.assertTrue(main.startswith(BASE))
        self.assertIn(b"-- revised recorder", main)
        self.assertEqual(main.count(installer.BEGIN), 1)
        self.assertEqual((self.backup / "main.lua").read_bytes(), BASE)

    def test_check_is_read_only_install_and_uninstall(self):
        before = self.snapshots()
        self.install(check=True)
        self.assertEqual(before, self.snapshots())
        self.assertFalse(self.backup.exists())
        self.assertFalse(self.destination.exists())
        self.install()
        before = self.snapshots()
        self.uninstall(check=True)
        self.assertEqual(before, self.snapshots())

    def test_modified_framework_refuses_install_and_restore(self):
        self.install()
        (self.target / "main.lua").write_bytes(BASE + b"\n-- Workshop changed file")
        before = self.snapshots()
        with self.assertRaisesRegex(RuntimeError, "changed"):
            self.install()
        with self.assertRaisesRegex(RuntimeError, "changed"):
            self.uninstall()
        self.assertEqual(before, self.snapshots())

    def test_modified_backup_refuses_restore(self):
        self.install()
        (self.backup / "main.lua").write_bytes(b"corrupt")
        before = self.snapshots()
        with self.assertRaisesRegex(RuntimeError, "Backup verification"):
            self.uninstall()
        self.assertEqual(before, self.snapshots())

    def test_modified_addon_refuses_update(self):
        self.install()
        (self.destination / "options.lua").write_bytes(b"user changes")
        before = self.snapshots()
        with self.assertRaisesRegex(RuntimeError, "changed or removed"):
            self.install()
        self.assertEqual(before, self.snapshots())

    def test_unmanaged_addon_and_bridge_refused(self):
        self.destination.mkdir()
        (self.destination / "main.lua").write_bytes(b"someone else's mod")
        with self.assertRaisesRegex(RuntimeError, "unmanaged addon"):
            self.install()
        (self.destination / "main.lua").unlink()
        (self.target / "main.lua").write_bytes(BASE + b"\n" + installer.BEGIN)
        with self.assertRaisesRegex(RuntimeError, "unmanaged vehicle"):
            self.install()

    def test_unsupported_source_refused_without_writes(self):
        (self.target / "main.lua").write_bytes(b"function tick(dt) end")
        before = self.snapshots()
        with self.assertRaisesRegex(RuntimeError, "Unsupported TABS"):
            self.install()
        self.assertEqual(before, self.snapshots())

    def test_wrong_target_backup_refused(self):
        self.install()
        state = json.loads((self.backup / "manifest.json").read_text())
        state["target"] += "-different"
        (self.backup / "manifest.json").write_text(json.dumps(state))
        with self.assertRaisesRegex(RuntimeError, "different installation"):
            self.install()

    def test_partial_write_rolls_back_every_file(self):
        before = self.snapshots()
        actual_write = installer._atomic_write
        failed = False

        def fail_once(path, data):
            nonlocal failed
            if path == (self.backup / "manifest.json").resolve() and not failed:
                failed = True
                raise OSError("simulated disk write failure")
            return actual_write(path, data)

        with patch.object(installer, "_atomic_write", fail_once):
            with self.assertRaisesRegex(OSError, "simulated"):
                self.install()
        self.assertEqual(before, self.snapshots())

    def test_paths_must_not_overlap(self):
        with self.assertRaisesRegex(RuntimeError, "must be separate"):
            installer.deploy(self.target / "addon", self.target, self.backup, source=self.source)

    def test_failed_managed_update_preserves_previous_version(self):
        self.install()
        (self.source / "core.lua").write_bytes(b"-- new implementation\n")
        before = self.snapshots()
        actual_write = installer._atomic_write
        failed = False

        def fail_once(path, data):
            nonlocal failed
            if path == (self.backup / "manifest.json").resolve() and not failed:
                failed = True
                raise OSError("simulated update failure")
            return actual_write(path, data)

        with patch.object(installer, "_atomic_write", fail_once):
            with self.assertRaisesRegex(OSError, "simulated"):
                self.install()
        self.assertEqual(before, self.snapshots())

    def test_failed_restore_preserves_installed_version(self):
        self.install()
        before = self.snapshots()
        actual_write = installer._atomic_write
        failed = False

        def fail_once(path, data):
            nonlocal failed
            if path == (self.backup / "manifest.json").resolve() and not failed:
                failed = True
                raise OSError("simulated restore failure")
            return actual_write(path, data)

        with patch.object(installer, "_atomic_write", fail_once):
            with self.assertRaisesRegex(OSError, "simulated"):
                self.uninstall()
        self.assertEqual(before, self.snapshots())

    def test_transaction_rechecks_changed_inputs(self):
        path = self.target / "main.lua"
        with self.assertRaisesRegex(RuntimeError, "changed while preparing"):
            installer.transaction({path: b"new"}, {path: b"outdated"})
        self.assertEqual(path.read_bytes(), BASE)


if __name__ == "__main__":
    unittest.main()
