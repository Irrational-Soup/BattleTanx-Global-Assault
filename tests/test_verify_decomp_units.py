import importlib.util
import os
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_module():
    path = os.path.join(ROOT, "tools", "verify_decomp_units.py")
    spec = importlib.util.spec_from_file_location("verify_decomp_units", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class VerifyDecompUnitsTests(unittest.TestCase):
    def test_pipeline_catalogue_has_unique_selected_units(self):
        module = load_module()
        entries = module.catalogue()
        self.assertEqual(entries["view_state_build"]["pipeline"], "asn64")
        self.assertEqual(entries["view_project_point"]["pipeline"], "production")

    def test_rodata_catalogue_uses_exact_owned_ranges(self):
        module = load_module()
        rodata = module.owned_rodata()
        self.assertEqual(rodata["vector_distance_normalize"], (0x800725DC, 0x20))
        self.assertEqual(rodata["grid_surface_height"], (0x80073150, 0x2C))


if __name__ == "__main__":
    unittest.main()
