import re
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAME_NAME = re.compile(r"^[0-9A-F]{8}(?:_[a-z0-9][a-z0-9_]*)?\.c$")


class SourceTreeLayoutTests(unittest.TestCase):
    def tracked(self, pattern):
        result = subprocess.run(
            ("git", "-C", str(ROOT), "ls-files", pattern),
            check=True,
            capture_output=True,
            text=True,
        )
        return tuple(filter(None, result.stdout.splitlines()))

    def test_every_game_c_unit_is_catalogued_and_nested(self):
        sources = set(self.tracked("src/code/**/*.c"))
        rows = {
            line.split("\t")[2]
            for line in (ROOT / "config/source_layout.tsv").read_text().splitlines()[1:]
            if line.strip()
        }
        self.assertEqual(sources, rows)
        for source in sources:
            path = Path(source)
            self.assertGreater(len(path.parts), 3, source)
            self.assertRegex(path.name, GAME_NAME)

    def test_runtime_libraries_are_not_nested_under_game_code(self):
        self.assertFalse((ROOT / "src/code/libmus").exists())
        self.assertFalse((ROOT / "src/code/n_audio").exists())
        self.assertTrue(self.tracked("src/libmus/*"))
        self.assertTrue(self.tracked("src/n_audio/*"))

    def test_every_splat_c_path_exists(self):
        pattern = re.compile(r"\[\s*0x[0-9A-Fa-f]+\s*,\s*c\s*,\s*([^\],]+)")
        layout = (ROOT / "config/us/splat.yaml").read_text()
        missing = [
            str(Path("src") / (match.group(1).strip() + ".c"))
            for match in pattern.finditer(layout)
            if not (ROOT / "src" / (match.group(1).strip() + ".c")).is_file()
        ]
        self.assertEqual(missing, [])


if __name__ == "__main__":
    unittest.main()
