PYTHON ?= python3
VERILATOR ?= verilator
YOSYS ?= yosys
QUARTUS_SH ?= quartus_sh
SBY ?= sby
MAME ?= mame
MAME_SYNTHETIC_OUTPUT ?= build/mame_synthetic_stack_control

.PHONY: help test lint unit instruction-tests bus-tests differential formal
.PHONY: synth-yosys synth-quartus docs clean release-check
.PHONY: audit-release evidence-current mame-synthetic

help:
	@echo "tms32010-sv development targets"
	@echo "  test               available deterministic regression suite"
	@echo "  lint               Python and synthesizable RTL static checks"
	@echo "  unit               repository, tooling, model, and RTL unit tests"
	@echo "  instruction-tests  directed instruction behavior and cycle tests"
	@echo "  bus-tests          native program/data/I/O transaction tests"
	@echo "  differential       model/RTL/oracle trace comparisons"
	@echo "  mame-synthetic     ROM-free opt-in MAME/model boundary smoke"
	@echo "  formal             available bounded formal properties"
	@echo "  synth-yosys        portable synthesis smoke test"
	@echo "  synth-quartus      Cyclone V fitter and timing qualification"
	@echo "  docs               documentation/provenance consistency"
	@echo "  audit-release      tracked-file license/provenance boundary"
	@echo "  evidence-current   clean-revision logs for current-scope gates"
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

mame-synthetic:
	@command -v "$(MAME)" >/dev/null 2>&1 || { echo "ERROR: MAME is required"; exit 1; }
	$(PYTHON) -m tools.reference.mame_synthetic_oracle \
		--mame "$$(command -v "$(MAME)")" --output "$(MAME_SYNTHETIC_OUTPUT)"

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
	@configs="$$(find formal -maxdepth 1 -type f -name '*.sby' -print | sort)"; \
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
			synthesis/yosys/tms32010_sequential_pipeline.ys \
			synthesis/yosys/tms32010_mister.ys \
			synthesis/yosys/hard_drivin_main_address_decode.ys \
			synthesis/yosys/hard_drivin_main_bus_control.ys \
			synthesis/yosys/hard_drivin_main_dtack_decode.ys \
			synthesis/yosys/hard_drivin_main_rvas_timing.ys \
			synthesis/yosys/hard_drivin_main_sound_reset_decode.ys \
			synthesis/yosys/hard_drivin_sound_bus_decode.ys \
			synthesis/yosys/hard_drivin_sound_local_memory_decode.ys \
			synthesis/yosys/hard_drivin_sound_local_memory_bridge.ys \
			synthesis/yosys/hard_drivin_sound_direct_io.ys \
			synthesis/yosys/hard_drivin_sound_local_ram.ys \
			synthesis/yosys/hard_drivin_sound_local_reset_source.ys \
			synthesis/yosys/hard_drivin_sound_local_reset_interlock.ys \
			synthesis/yosys/hard_drivin_sound_program_ram.ys \
			synthesis/yosys/hard_drivin_sound_rom_path.ys \
			synthesis/yosys/hard_drivin_sound_dac_latch.ys \
			synthesis/yosys/hard_drivin_sound_320_port_latch.ys \
			synthesis/yosys/hard_drivin_sound_output_control.ys \
			synthesis/yosys/hard_drivin_sound_host_control.ys \
			synthesis/yosys/hard_drivin_mc68000_write_word.ys \
			synthesis/yosys/hard_drivin_sound_mailboxes.ys \
			synthesis/yosys/hard_drivin_sound_read_status.ys \
			synthesis/yosys/hard_drivin_sound_switches.ys \
			synthesis/yosys/hard_drivin_sound_host_read_mux.ys \
			synthesis/yosys/hard_drivin_sound_host_timing.ys \
			synthesis/yosys/hard_drivin_sound_mister.ys \
			synthesis/yosys/hard_drivin_sound_communication_path.ys \
			synthesis/yosys/hard_drivin_sound_bio_generator.ys \
			synthesis/yosys/tms32010_accumulator.ys \
			synthesis/yosys/tms32010_input_shifter.ys \
			synthesis/yosys/tms32010_output_shifter.ys \
			synthesis/yosys/tms32010_stack.ys \
			synthesis/yosys/tms32010_auxiliary_counter.ys \
			synthesis/yosys/tms32010_status_word.ys; do \
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

audit-release:
	$(PYTHON) scripts/audit_release.py
	$(PYTHON) scripts/check_release_evidence.py

evidence-current:
	VERILATOR="$(VERILATOR)" YOSYS="$(YOSYS)" QUARTUS_SH="$(QUARTUS_SH)" \
	  SBY="$(SBY)" $(PYTHON) scripts/run_release_checks.py

docs: audit-release
	$(PYTHON) scripts/check_documentation.py
	$(PYTHON) -m tools.generators.opcode_audit --check

clean:
	$(PYTHON) scripts/clean.py

release-check: audit-release docs lint test formal synth-yosys synth-quartus
	@echo "ERROR: release qualification is not implemented and cannot pass yet"
	@exit 1
