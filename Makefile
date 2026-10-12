PYTHON ?= python3
VENV := .venv
VENV_PYTHON := $(VENV)/bin/python
VENV_STAMP := $(VENV)/.installed
ROM := baseroms/us/baserom.z64

.PHONY: all setup toolchain symbols verify split build-code verify-code verify-assets progress-report check clean-generated vita-assets vita vita-check

all: split

$(VENV_STAMP): requirements.txt
	$(PYTHON) -m venv $(VENV)
	$(VENV_PYTHON) -m pip install --upgrade pip
	$(VENV_PYTHON) -m pip install -r requirements.txt
	touch $(VENV_STAMP)

setup: $(VENV_STAMP)
	$(VENV_PYTHON) tools/prepare_rom.py --output $(ROM)

toolchain:
	tools/bootstrap_mips_binutils.sh
	tools/bootstrap_ido.sh
	tools/bootstrap_kmc_gcc.sh

verify:
	$(PYTHON) tools/verify_rom.py $(ROM)

symbols:
	$(PYTHON) tools/import_recomp_symbols.py \
		config/us/recomp_function_boundaries.toml \
		config/us/recomp_symbol_seed.txt \
		config/us/symbol_addrs.txt \
		--manual config/us/manual_symbols.toml

split: $(VENV_STAMP) verify symbols
	$(VENV_PYTHON) -m splat split config/us/splat.yaml

build-code: split
	tools/build_code.sh

verify-code: build-code
	cmp -s -n 1052672 $(ROM) build/us/battletanx_ga.code.bin
	@echo "Verified reconstructed ROM 0x000000-0x101000 matches the retail dump"

verify-assets: verify
	$(PYTHON) tools/verify_asset_corpus.py --rom $(ROM)

progress-report:
	$(PYTHON) tools/generate_decomp_report.py --config config/decompkit.toml

verify-units:
	@test -n "$(UNITS)" || (echo "usage: make verify-units UNITS='unit_a unit_b'" >&2; exit 2)
	$(PYTHON) tools/verify_decomp_units.py --config config/decompkit.toml $(UNITS)

check-tools: $(VENV_STAMP)
	$(VENV_PYTHON) -m unittest tests.test_decompkit tests.test_decomp_report tests.test_verify_decomp_units -v

check: $(VENV_STAMP)
	$(VENV_PYTHON) -m unittest discover -s tests -v
	$(VENV_PYTHON) tools/check_repository.py

clean-generated:
	rm -rf asm assets/extracted build .splache

vita-assets: verify
	$(PYTHON) tools/inventory_lzari_assets.py --rom $(ROM) --output assets/extracted/us/vita/lzari_manifest.json --extract-dir assets/extracted/us/vita/lzari --split-bundles
	$(PYTHON) tools/extract_lzari_images.py assets/extracted/us/vita/images --rom $(ROM)
	$(PYTHON) tools/extract_lzari_worlds.py assets/extracted/us/vita/worlds --rom $(ROM)
	$(PYTHON) tools/inventory_script_assets.py --rom $(ROM) --output assets/extracted/us/vita/scripts_manifest.json --extract-dir assets/extracted/us/vita/scripts
	$(PYTHON) tools/inventory_libmus_assets.py --rom $(ROM) --output assets/extracted/us/vita/libmus_manifest.json --extract-dir assets/extracted/us/vita/libmus

vita: vita-assets
	@test -n "$(VITASDK)" || (echo "Set VITASDK to your VitaSDK installation" >&2; exit 2)
	cmake -S port/vita -B port/vita/build -DCMAKE_BUILD_TYPE=Release
	cmake --build port/vita/build

vita-check: vita
	port/vita/verify_elf.sh port/vita/build/vitatanxga \
		$(VITASDK)/arm-vita-eabi/lib/libvita2d.a \
		$(VITASDK)/arm-vita-eabi/lib/libpng.a \
		$(VITASDK)/arm-vita-eabi/lib/libjpeg.a \
		$(VITASDK)/arm-vita-eabi/lib/libfreetype.a \
		$(VITASDK)/arm-vita-eabi/lib/libz.a
