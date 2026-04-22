# Physical Design Report (Sky130)

This document provides detailed metrics and analysis results from the physical implementation flow using OpenLane/OpenROAD for the SkyWater 130nm process.

## 1. Area Analysis
- **Total Chip Area:** 374,711 µm²
- **Sequential Area:** 192,427 µm² (51.35%)
- **Combinational Area:** 182,284 µm² (48.65%)
- **Total Cell Count:** 26,030 cells
- **Flip-Flop Count:** 8,224 (sky130_fd_sc_hd__dfxtp_2)

## 2. Timing Analysis (Preliminary)
*Note: Results are from pre-PnR STA. Final sign-off timing will be updated after routing completion.*

| Corner           | Worst Negative Slack (WNS) | Total Negative Slack (TNS) |
|------------------|----------------------------|----------------------------|
| Overall          | -94.30 ns                  | -410,259 ns                |
| nom_tt_025C_1v80 | -47.97 ns                  | -186,745 ns                |
| nom_ss_100C_1v60 | -94.30 ns                  | -410,259 ns                |
| nom_ff_n40C_1v95 | -26.01 ns                  | -87,041 ns                 |

## 3. Power Analysis
*Results from `nom_tt_025C_1v80` corner.*

| Component     | Internal Power (W) | Switching Power (W) | Leakage Power (W) | Total Power (W) | Percentage |
|---------------|--------------------|---------------------|-------------------|-----------------|------------|
| Sequential    | 3.58e-02           | 4.81e-04            | 7.85e-08          | 3.63e-02        | 71.8%      |
| Combinational | 6.04e-03           | 8.20e-03            | 8.81e-08          | 1.42e-02        | 28.2%      |
| **Total**     | **4.19e-02**       | **8.69e-03**        | **1.67e-07**      | **5.05e-02**    | **100.0%** |

**Summary Total Power:** 50.54 mW

## 4. PnR Status
The design is currently in the **Global Placement** stage of the OpenLane flow. 
- Flow ID: `RUN_2026-04-22_05-50-24`
- Target Utilization: 50%
- Target Density: 55%

## 5. GDS Layout
GDS generation is pending completion of the routing and sign-off stages. Once complete, high-resolution renders (PNG/SVG) will be added to the root directory.
