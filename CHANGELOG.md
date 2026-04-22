# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2026-04-22

### Added
- `CHANGELOG.md` to track project evolution.
- Formal verification infrastructure in `verification/formal/`.
- Integrated `tt` (TinyTapeout support tools) as a direct submodule.

### Changed
- **Submodule Consolidation**: Renamed `tt_tools` to `tt` and removed redundant symbolic links to unify the toolchain path and ensure compatibility with standard TinyTapeout scripts.
- **SDC Refactoring**: Completely refactored `synthesis/constraints/timing.sdc` for OpenROAD/OpenLane compatibility. Removed `remove_from_collection` and `set_operating_conditions` calls which were causing Static Timing Analysis (STA) failures in the modern toolchain.
- **Physical Design Hardening**: 
    - Updated root `config.json` with absolute paths for constraints.
    - Increased `DIE_AREA` to `1500x1500um` and lowered `PL_TARGET_DENSITY_PCT` to `40` to mitigate extreme routing congestion.
    - Updated `info.yaml` to specify `8x2` tiles for the TinyTapeout flow to accommodate the current core area.
- **Documentation Restructuring**: 
    - Moved `docs/TT_INSTALL.md` to `docs/INSTALL.md` for better discoverability.
    - Consolidated architectural and verification documentation.
- **Build System**: Updated `Makefile` to reflect new paths for formal verification and simulation stubs.
- **Project Metadata**: Updated `README.md` to reflect the latest build status and physical design metrics.

### Fixed
- Resolved `NoSuchPathError` in TinyTapeout tools by standardizing the `tt/` directory structure.
- Corrected Static Timing Analysis (STA) corner errors in OpenLane by using explicit port lists in SDC.
- Fixed `synthesis/constraints/timing.sdc` issues where `typical` operating conditions were not recognized by the current PDK/tool version.

### Removed
- Legacy physical design directories and scripts: `synthesis/scripts/`, `drc_lvs/`, `openlane/`, and `pnr/`.
- Redundant `tt` symbolic link.

### Verified
- Functional simulation with Verilator [PASS].
- Testbench verification with Cocotb/Iverilog [PASS].
- Formal verification of core properties with SBY [PASS].
- Synthesis for Sky130A target [PASS] (Cell count: ~26,030).

### Identified Issues
- **Area Bottleneck**: `sram_wrapper` register-based memory consumes ~88% of the total core area (~307k µm²), primarily due to 8,224 flip-flops. This is the primary driver of routing congestion and current tile-count requirements.
