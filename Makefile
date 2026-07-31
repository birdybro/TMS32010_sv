PYTHON ?= python3
VERILATOR ?= verilator
YOSYS ?= yosys
QUARTUS_SH ?= quartus_sh
SBY ?= sby

.PHONY: help test lint unit instruction-tests bus-tests differential formal
.PHONY: synth-yosys synth-quartus docs clean release-check

help:
	@echo "tms32010-sv development targets"
	@echo "  test               available deterministic regression suite"
	@echo "  lint               Python and synthesizable RTL static checks"
	@echo "  unit               repository, tooling, model, and RTL unit tests"
	@echo "  instruction-tests  directed instruction behavior and cycle tests"
	@echo "  bus-tests          native program/data/I/O transaction tests"
	@echo "  differential       model/RTL/oracle trace comparisons"
	@echo "  formal             available bounded formal properties"
	@echo "  synth-yosys        portable synthesis smoke test"
	@echo "  synth-quartus      Cyclone V fitter and timing qualification"
	@echo "  docs               documentation/provenance consistency"
	@echo "  clean              remove generated products below build/"
	@echo "  release-check      all release evidence (intentionally strict)"

test: unit instruction-tests bus-tests differential
	@echo "PASS: available regression suite"

unit:
	$(PYTHON) -m unittest discover -s tests -p 'test_*.py' -v
	@$(PYTHON) scripts/run_optional_unittest.py sim/unit

instruction-tests:
	@$(PYTHON) scripts/run_optional_unittest.py sim/instruction

bus-tests:
	@$(PYTHON) scripts/run_optional_unittest.py sim/bus
	@$(PYTHON) scripts/run_optional_unittest.py sim/interrupt

differential:
	@$(PYTHON) scripts/run_optional_unittest.py sim/differential

lint: docs
	$(PYTHON) -m compileall -q scripts tests tools sim/reference_models
	@package_files="$$(find rtl/packages -type f -name '*.sv' -print | sort)"; \
	rtl_files="$$(find rtl/core rtl/wrappers -type f -name '*.sv' -print | sort)"; \
	if [ -n "$$rtl_files" ]; then \
	  command -v "$(VERILATOR)" >/dev/null 2>&1 || { echo "ERROR: Verilator is required for RTL lint"; exit 1; }; \
	  "$(VERILATOR)" --lint-only --Wall --Wno-MULTITOP $$package_files $$rtl_files; \
	else \
	  echo "SKIP-EVIDENCE: no RTL files exist yet"; \
	fi

formal:
	@configs="$$(find formal -type f -name '*.sby' -print)"; \
	if [ -n "$$configs" ]; then \
	  command -v "$(SBY)" >/dev/null 2>&1 || { echo "ERROR: SymbiYosys is required"; exit 1; }; \
	  mkdir -p build/formal; \
	  for config in $$configs; do \
	    name="$$(basename "$$config" .sby)"; \
	    "$(SBY)" -f --prefix "build/formal/$$name" "$$config" || exit 1; \
	  done; \
	else \
	  echo "SKIP-EVIDENCE: no formal configurations exist yet"; \
	fi

synth-yosys:
	@if [ -f synthesis/yosys/tms32010.ys ]; then \
		command -v "$(YOSYS)" >/dev/null 2>&1 || { echo "ERROR: Yosys is required"; exit 1; }; \
		mkdir -p build/yosys; \
		for script in \
			synthesis/yosys/tms32010.ys \
			synthesis/yosys/tms32010_sequential_pipeline.ys; do \
			"$(YOSYS)" -s "$$script" || exit 1; \
		done; \
	else \
		echo "SKIP-EVIDENCE: no Yosys synthesis script exists yet"; \
	fi

synth-quartus:
	@if [ -f synthesis/quartus/tms32010.qpf ]; then \
	  command -v "$(QUARTUS_SH)" >/dev/null 2>&1 || { echo "ERROR: Quartus is required"; exit 1; }; \
	  "$(QUARTUS_SH)" --flow compile synthesis/quartus/tms32010; \
	else \
	  echo "SKIP-EVIDENCE: no Quartus project exists yet"; \
	fi

docs:
	$(PYTHON) scripts/check_documentation.py
	$(PYTHON) -m tools.generators.opcode_audit --check

clean:
	$(PYTHON) scripts/clean.py

release-check: docs lint test formal synth-yosys synth-quartus
	@echo "ERROR: release qualification is not implemented and cannot pass yet"
	@exit 1
