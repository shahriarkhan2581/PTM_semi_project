# PTM-LP 22 nm BSIM4 — Post-Processing Results

Analysis outputs (logs, extracted data, figures) for the 22 nm PTM-LP BSIM4
parameter study. Pairs with the `.cir` / `.lib` simulation decks in the main
`new_simu/` folder of `shahriarkhan2581/PTM_semi_project`.

## Layout

```
├── logs/                    LTspice .meas logs (decks 01–19, NMOS + PMOS)
├── data/
│   ├── inverter_dc/         DC VTC sweeps, nominal vs. optimized inverter
│   ├── inverter_transient/  Transient waveforms, nominal vs. optimized inverter
│   ├── spice_vs_compact/    LTspice vs. analytic compact-model comparison per parameter
│   ├── nmos_vs_pmos/        NMOS vs. PMOS sensitivity comparison per parameter
│   └── gate_tunneling/      Ig vs. toxe gate-tunneling data
├── figures/                 Publication-ready figures (vector PDF + 600 dpi PNG)
│   ├── fig1_VTC             Voltage transfer characteristic
│   ├── fig2_transient       Transient response (2-panel)
│   ├── fig3_leakage         Static supply current, log scale
│   └── fig4_summary         Percent-change summary
├── plots/                   Exploratory/intermediate plots (deck screenshots, SVG overlays)
└── scripts/                 MATLAB analysis scripts (see below)
```

## Scripts

| Script | Reads | Writes |
|---|---|---|
| `plot_inverter_results.m` | `data/inverter_{dc,transient}/` | figures to screen only |
| `plot_inverter_results_new.m` | `data/inverter_{dc,transient}/` | `figures/fig1–fig4.{pdf,png}` |
| `ltspice_vs_compact.m` | `logs/03,04,05,07*.log` | figures to screen only |
| `nmos_vs_pmos_overlay.m` | `logs/{03,04,05,07}*.log`, `logs/{13,14,15,17}*_pmos.log` | `plots/nvp_*.svg` |
| `tunnel_analysis.m` | inline data (from deck 19) | `plots/tunnel_plot.svg` |

All scripts anchor paths to their own location via
`fileparts(mfilename('fullpath'))`, so they run correctly regardless of
MATLAB's current working directory — just open and press Run.

## Notes

- The original export had a `files/` subfolder duplicating five files
  (`plot_inverter_results.m`, `dc_nominal.csv`, `dc_optimized.csv`,
  `tran_nominal.csv`, `tran_optimized.csv`) byte-for-byte identical to the
  top-level copies; it has been dropped here.
- `data/spice_vs_compact/compare_*.csv` and `data/nmos_vs_pmos/nvp_compare_*.csv`
  are **not** duplicates despite similar names — the former is SPICE vs.
  analytic-model, the latter is NMOS vs. PMOS device comparison.
