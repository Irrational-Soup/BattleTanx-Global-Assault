import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "check_repository", ROOT / "tools/check_repository.py"
)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class RepositorySafetyTests(unittest.TestCase):
    def test_rejects_vita_port_repository_as_decomp_origin(self):
        for remote in (
            "https://github.com/TheGh0stShip/VitaTanxGA.git",
            "https://github.com/TheGh0stShip/VitaTanxGA/",
            "git@github.com:TheGh0stShip/VitaTanxGA.git",
            "ssh://git@github.com/TheGh0stShip/VitaTanxGA.git",
        ):
            with self.subTest(remote=remote):
                self.assertIn("forbidden origin", MODULE.remote_failure(remote))
        self.assertIsNone(
            MODULE.remote_failure(
                "https://github.com/TheGh0stShip/BattleTanx-Global-Assault.git"
            )
        )


if __name__ == "__main__":
    unittest.main()
