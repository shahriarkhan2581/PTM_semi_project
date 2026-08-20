# LTspice Validation Package — 22 nm PTM-LP BSIM4 Parameter Study

This package reproduces, in **real BSIM4 SPICE**, the compact-model sensitivity
study of your five parameters (**vth0, u0, toxe, eta0, nfactor**) and their impact
on **Vt, SS, DIBL, Ion, Ioff, and delay**. All decks call your exact model card via
`ptm22lp_param.lib`.

---

## 0. One-time setup
1. Put **all files in the same folder** (the `.cir` decks and `ptm22lp_param.lib`).
2. Open any `.cir` in LTspice → **Run** (the running-man icon).
3. After a run, open **View → SPICE Error Log** (or `Ctrl+L`) to see the `.meas`
   results table — one row per `.step` value. Right-click the log → **Plot .step'ed
   .meas data** to graph a metric vs. the swept parameter directly.

> **All LTspice compatibility fixes are now baked in — the decks run out-of-the-box:**
> - **`level=14`** — the model card is already set to LTspice's native BSIM4
>   (PTM ships as `level=54` for HSPICE; parameters are identical). Switch back to
>   `54` only if you port the card to HSPICE.
> - **`.probe` removed** — LTspice saves all node voltages / device currents
>   automatically. (Leftover `.probe` lines cause *"Expected device instantiation
>   or directive here."*)
> - **No duplicate `VDS`** — decks that `.step` VDS no longer also `.param` it
>   (avoids the "parameter already defined / stepped" conflict).
> - **VM gain measure** uses `MIN deriv(V(out))` instead of `abs(deriv(...))`
>   (LTspice `.meas` doesn't parse `abs()` around `deriv`).

---

## 1. File map

| File | Purpose | Key output |
|------|---------|-----------|
| `ptm22lp_param.lib` | Parameterized NMOS+PMOS model card | (include only) |
| `01_char_nominal.cir` | Baseline Id-Vg @ Vds=0.05 & 0.95 | Vt_lin, Vt_sat, SS, Ion, Ioff, **DIBL** |
| `02_IdVd.cir` | Output characteristics (Vgs stepped) | Id-Vd family, Ion |
| `03_sweep_vth0.cir` | Threshold sweep 0.55→0.82 V | Vt, SS, Ion, Ioff, Ion/Ioff |
| `04_sweep_u0.cir` | Mobility sweep 0.020→0.050 | Ion↑, delay↓ |
| `05_sweep_toxe.cir` | Oxide sweep 1.0→2.0 nm | Ion & Ioff co-move |
| `06_sweep_eta0.cir` | DIBL sweep + true DIBL extraction | DIBL vs eta0 |
| `07_sweep_nfactor.cir` | Subthreshold factor 1.2→2.4 | SS 1:1, Ioff huge swing |
| `08_inverter_delay.cir` | CMOS inverter transient | tpHL, tpLH, **tp** |
| `09_inverter_VM.cir` | Inverter VTC | **VM**, max gain |
| `10_optimized_design.cir` | Optimized low-power set | full metric comparison |

---

## 2. Metric extraction methods (what the `.meas` lines do)

- **Vt** — constant-current method: Vgs where `Id = 100 nA × (W/L) = 4.545 µA`.
- **SS** — `(V@10nA − V@1nA) × 1000` mV/decade (two subthreshold points, 1 decade apart).
- **Ion** — `Id` at `Vgs = Vds = 0.95 V`.
- **Ioff** — `Id` at `Vgs = 0, Vds = 0.95 V`.
- **DIBL** — run at Vds = 0.05 & 0.95 V (deck 01 or 06):
  `DIBL = (Vt_lin − Vt_sat)/(0.95 − 0.05) × 1000` mV/V.
- **Delay** — inverter `tp = (tpHL + tpLH)/2` (deck 08).
- **VM** — Vin where Vout = Vin (deck 09).

---

## 3. Expected trends to confirm (from the compact-model study)

| Parameter | Ion | Ioff | Delay | SS | DIBL | Vt |
|-----------|-----|------|-------|----|----- |----|
| vth0 ↑ | ↓↓ | ↓↓↓ | ↑↑ | – | – | ↑ (1:1) |
| u0 ↑ | ↑ | ↑ | ↓ | – | – | – |
| toxe ↑ | ↓ | ↓ | ~flat | – | – | – |
| eta0 ↑ | ↑(slight) | ↑ | ↓(slight) | – | ↑ (1:1) | ~– |
| nfactor ↑ | – | **↑↑↑ (largest)** | – | ↑ (1:1) | – | – |

Biggest low-power levers: **nfactor** (leakage), then **vth0** (leakage/speed balance).

---

## 4. Exporting for MATLAB/plots
- In the SPICE Error Log, right-click → **Plot .step'ed .meas data**, then
  **File → Export** the trace, OR
- copy the `.meas` table from the log into a `.csv` and load in MATLAB:
  ```matlab
  T = readtable('vth0_meas.csv');
  plot(T.p_vth0_n, T.ION*1e6); xlabel('vth0 (V)'); ylabel('Ion (\muA)');
  ```

---

## 5. Batch (command-line) run — optional
LTspice can run headless for all sweeps at once:
```
"C:\Program Files\ADI\LTspice\LTspice.exe" -b -Run 03_sweep_vth0.cir
```
The `.log` file next to each deck holds the `.meas` results for scripting.
