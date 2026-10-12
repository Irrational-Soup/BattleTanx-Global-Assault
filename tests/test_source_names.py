import subprocess
import tempfile
import unittest
from pathlib import Path

from tools.decompkit.source_names import audit_source_names, load_naming_policy, render_legacy


class SourceNamingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "src/code").mkdir(parents=True)
        (self.root / "config").mkdir()
        (self.root / "src/code/80001000_good_name.c").write_text("void f(void) {}\n")
        (self.root / "src/code/old_name.c").write_text("void g(void) {}\n")
        (self.root / "config/layout.yaml").write_text(
            "- [0x1000, c, code/80001000_good_name]\n- [0x1100, c, code/old_name]\n"
        )
        (self.root / "config/legacy.txt").write_text("src/code/old_name.c\n")
        (self.root / "config/naming.toml").write_text(
            """[project]
root = ".."
tracked_only = true
[naming]
source_root = "src/code"
layout = "config/layout.yaml"
legacy = "config/legacy.txt"
vram_delta = 0x80000000
preferred = '^[0-9A-F]{8}_[a-z0-9][a-z0-9_]*\\.c$'
exempt_globs = []
"""
        )
        subprocess.run(("git", "init", "-q", str(self.root)), check=True)
        subprocess.run(("git", "-C", str(self.root), "add", "."), check=True)

    def policy(self):
        return load_naming_policy(self.root / "config/naming.toml")

    def test_preferred_and_frozen_legacy_pass(self):
        audit = audit_source_names(self.policy())
        self.assertTrue(audit.clean)
        self.assertEqual(audit.legacy, ("src/code/old_name.c",))

    def test_new_nonconforming_file_fails(self):
        path = self.root / "src/code/new_bad.c"
        path.write_text("void h(void) {}\n")
        subprocess.run(("git", "-C", str(self.root), "add", str(path)), check=True)
        self.assertEqual(audit_source_names(self.policy()).violations, ("src/code/new_bad.c",))

    def test_address_must_match_layout(self):
        path = self.root / "src/code/80001000_good_name.c"
        wrong = self.root / "src/code/80001004_good_name.c"
        path.rename(wrong)
        text = (self.root / "config/layout.yaml").read_text().replace("80001000", "80001004")
        (self.root / "config/layout.yaml").write_text(text)
        subprocess.run(("git", "-C", str(self.root), "add", "-A"), check=True)
        mismatch = audit_source_names(self.policy()).address_mismatches
        self.assertIn("0x80001004 != layout 0x80001000", mismatch[0])

    def test_baseline_renderer_contains_only_nonpreferred(self):
        rendered = render_legacy(self.policy())
        self.assertIn("src/code/old_name.c", rendered)
        self.assertNotIn("80001000_good_name.c", rendered)


if __name__ == "__main__":
    unittest.main()
