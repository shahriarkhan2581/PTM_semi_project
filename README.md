# PTM_semi_project

BSIM4 parameter sensitivity study and CMOS inverter validation on the 22 nm
PTM-LP (Predictive Technology Model, Low Power) node. Five compact-model
parameters — **vth0, u0, toxe, eta0, nfactor** — are swept in real LTspice
BSIM4 SPICE for both NMOS and PMOS, cross-checked against an analytic compact
model, and used to derive an optimized low-power device/inverter design.

## Repository layout

```
├── circuit_component/    LTspice simulation decks (.cir), parameterized model
│                          card (ptm22lp_param.lib), and deck-by-deck how-to
├── PTM_results/           Post-processing: .meas logs, extracted data (CSV),
│                          publication figures, and MATLAB analysis scripts
└── README.md              (this file)
```

### `circuit_component/` — simulation decks

All decks share `ptm22lp_param.lib`, a parameterized BSIM4 (level=14) model
card for a 22 nm PTM-LP NMOS/PMOS pair (Vdd = 0.95 V), with the five studied
parameters exposed as `.param` overrides.

| Deck | Purpose |
|---|---|
| `01_char_nominal.cir` | Baseline Id–Vg at Vds = 0.05 & 0.95 V → Vt, SS, Ion, Ioff, DIBL |
| `02_IdVd.cir` | Id–Vd output family, Vgs stepped |
| `03–07_sweep_*.cir` | NMOS sweeps: vth0, u0, toxe, eta0, nfactor |
| `08_inverter_delay.cir` | CMOS inverter transient — tpHL, tpLH, tp |
| `09_inverter_VM.cir` | Inverter VTC and switching threshold VM |
| `10_optimized_design.cir` | Validation deck for the optimized low-power parameter set |
| `13–17_sweep_*_pmos.cir` | PMOS counterparts of the vth0/u0/toxe/eta0/nfactor sweeps |
| `18_gate_tunneling.cir`, `19_tunneling_vs_toxe.cir` | Gate leakage Ig vs. bias and vs. oxide thickness |

**Circuit components used across the decks:**

| Component | Role |
|---|---|
| `M1` / `MN`, `MP` | Device under test — single NMOS or PMOS, `L=22n` |
| `MP1`/`MN1` (deck 08, 09) | CMOS inverter pair, `WP=2u`, `WN=1u` (~2× PMOS width for symmetric drive) |
| `MPL`/`MNL` (deck 08) | Fan-out-1 load inverter (gate-cap loading only) |
| `Vg` | Gate bias / sweep source |
| `Vd`, `VdN`, `VdP` | Drain bias source |
| `Vin` | Inverter input — DC ramp (deck 09) or `PULSE(...)` (deck 08) |
| `VDDs`, `Vsup` | Supply rail, 0.95 V |

See `circuit_component/README.md` for run instructions, metric-extraction
formulas, and expected parameter-sensitivity trends.

### `PTM_results/` — post-processing

```
├── logs/                LTspice .meas output for every deck above
├── data/
│   ├── inverter_dc/          DC VTC, nominal vs. optimized inverter
│   ├── inverter_transient/   Transient waveforms, nominal vs. optimized
│   ├── spice_vs_compact/     LTspice vs. analytic compact-model comparison
│   ├── nmos_vs_pmos/         NMOS vs. PMOS sensitivity comparison
│   └── gate_tunneling/       Ig vs. toxe data
├── figures/              Publication figures (vector PDF + 600 dpi PNG):
│                          fig1_VTC, fig2_transient, fig3_leakage, fig4_summary
├── plots/                Exploratory plots and SVG overlays
└── scripts/              MATLAB analysis (plot_inverter_results*.m,
                           ltspice_vs_compact.m, nmos_vs_pmos_overlay.m,
                           tunnel_analysis.m)
```

Scripts anchor all file paths to their own location via
`fileparts(mfilename('fullpath'))`, so they run correctly regardless of
MATLAB's current working directory.

## Key results

- **Optimized design** (`10_optimized_design.cir`): vth0 lowered 0.689 → 0.600 V,
  toxe increased 1.40 → 1.50 nm, nfactor lowered 1.60 → 1.20, eta0 unchanged —
  meeting Ioff ≤ 1 nA and Ion ≥ 85% of nominal.
- **Sensitivity ranking (leakage impact)**: nfactor > vth0 > toxe ≈ eta0 > u0.
- **SPICE vs. compact model**: trends agree qualitatively across all five
  parameters; absolute Ioff differs by orders of magnitude in the
  subthreshold region (see `PTM_results/data/spice_vs_compact/`).
- **NMOS vs. PMOS**: PMOS shows systematically higher SS and lower Ion/Ioff
  ratio at matched parameter values, consistent with its ~3× lower mobility.

## Requirements

- LTspice 26.0.2+ (or ngspice) to re-run the `.cir` decks
- MATLAB (R2020a+ recommended for `exportgraphics`) to regenerate figures
  from the logged/extracted data

## Reproducing figures

```matlab
cd PTM_results/scripts
plot_inverter_results_new   % writes figures/fig1–fig4.{pdf,png}
ltspice_vs_compact           % SPICE vs. compact-model overlay (screen only)
nmos_vs_pmos_overlay         % writes plots/nvp_*.svg
tunnel_analysis               % writes plots/tunnel_plot.svg
```
