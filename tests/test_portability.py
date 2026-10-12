import tempfile
import unittest
from pathlib import Path

from tools.decompkit.portability import (
    load_portability_config,
    render_json,
    render_markdown,
    scan_portability,
)


class PortabilityInventoryTests(unittest.TestCase):
    def make_project(self):
        temporary = tempfile.TemporaryDirectory()
        root = Path(temporary.name)
        (root / "src").mkdir()
        (root / "src" / "plain.c").write_text("int add(int a, int b) { return a + b; }\n")
        (root / "src" / "pinned.c").write_text(
            'int f(void) { register int x __asm__("$2"); return x; }\n'
        )
        (root / "src" / "boot.s").write_text("jr $ra\n nop\n")
        config = root / "portability.toml"
        config.write_text(
            """[project]
root = "."
[[source_root]]
path = "src"
role = "test"
[[rule]]
glob = "src/*.s"
category = "native-assembly"
action = "replace"
reason = "test assembly"
[[detector]]
name = "pin"
category = "register-pin"
action = "rewrite"
pattern = 'register[^\\n]+__asm__\\s*\\('
reason = "test pin"
"""
        )
        return temporary, config

    def test_scanner_is_configured_and_ignores_plain_c(self):
        temporary, path = self.make_project()
        self.addCleanup(temporary.cleanup)
        findings = scan_portability(load_portability_config(path))
        self.assertEqual([item.path for item in findings], ["src/boot.s", "src/pinned.c"])
        self.assertEqual(findings[0].categories, ("native-assembly",))
        self.assertEqual(findings[1].actions, ("rewrite",))

    def test_renderers_are_deterministic_and_payload_free(self):
        temporary, path = self.make_project()
        self.addCleanup(temporary.cleanup)
        config = load_portability_config(path)
        findings = scan_portability(config)
        markdown = render_markdown(config, findings)
        payload = render_json(config, findings)
        self.assertIn("Files requiring review or target work: **2**", markdown)
        self.assertIn('"files_with_findings": 2', payload)
        self.assertNotIn("return x", markdown)

    def test_invalid_detector_fails_during_config_load(self):
        temporary, path = self.make_project()
        self.addCleanup(temporary.cleanup)
        text = path.read_text().replace("register[^\\n]+__asm__\\s*\\(", "(")
        path.write_text(text)
        with self.assertRaises(Exception):
            load_portability_config(path)

    def test_tracked_only_ignores_untracked_source(self):
        temporary, path = self.make_project()
        self.addCleanup(temporary.cleanup)
        root = path.parent
        import subprocess
        subprocess.run(("git", "init", "-q", str(root)), check=True)
        subprocess.run(("git", "-C", str(root), "add", "src/boot.s", "portability.toml"), check=True)
        path.write_text(path.read_text().replace('root = "."', 'root = "."\ntracked_only = true'))
        subprocess.run(("git", "-C", str(root), "add", "portability.toml"), check=True)
        findings = scan_portability(load_portability_config(path))
        self.assertEqual([item.path for item in findings], ["src/boot.s"])


if __name__ == "__main__":
    unittest.main()
