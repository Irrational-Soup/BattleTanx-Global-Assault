PYTHON ?= python3
VENV := .venv
VENV_PYTHON := $(VENV)/bin/python
VENV_STAMP := $(VENV)/.installed
ROM := baseroms/us/baserom.z64

.PHONY: all setup toolchain symbols verify split build-code verify-code resources build-rom verify-assets progress-report portability-report check-source-names check clean-generated

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

resources: $(VENV_STAMP) verify
	$(VENV_PYTHON) tools/extract_resources.py $(ROM)

build-rom: verify-code resources
	$(VENV_PYTHON) tools/build_rom.py --require-original

verify-assets: verify
	$(PYTHON) tools/verify_asset_corpus.py --rom $(ROM)

progress-report:
	$(PYTHON) tools/generate_decomp_report.py --config config/decompkit.toml

portability-report:
	$(PYTHON) tools/portability_report.py --config config/portability.toml --check docs/PORTABILITY_INVENTORY.md

check-source-names:
	$(PYTHON) tools/audit_source_names.py --config config/source_naming.toml

verify-units:
	@test -n "$(UNITS)" || (echo "usage: make verify-units UNITS='unit_a unit_b'" >&2; exit 2)
	$(PYTHON) tools/verify_decomp_units.py --config config/decompkit.toml $(UNITS)

check-tools: $(VENV_STAMP)
	$(VENV_PYTHON) -m unittest tests.test_decompkit tests.test_decomp_report tests.test_verify_decomp_units tests.test_reproduction -v

check: $(VENV_STAMP)
	$(VENV_PYTHON) -m unittest discover -s tests -v
	$(VENV_PYTHON) tools/audit_source_names.py --config config/source_naming.toml
	$(VENV_PYTHON) tools/check_repository.py

clean-generated:
	rm -rf asm assets/extracted build .splache
