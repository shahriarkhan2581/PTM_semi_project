%% plot_inverter_results.m
% Nominal vs. Optimized 22nm CMOS Inverter - presentation figures
% Data source: ngspice runs of the same BSIM4 PTM-LP model card used in
% LTspice (11_optimized_inverter.cir / 12_optimized_inverter_VM.cir and
% their nominal counterparts).
%
% Place this script in the same folder as:
%   tran_nominal.csv, tran_optimized.csv, dc_nominal.csv, dc_optimized.csv
% then just press Run.

clear; clc; close all;

% Anchor to this script's location, not MATLAB's "Current Folder".
scriptDir = fileparts(mfilename('fullpath'));
dataDir   = fullfile(scriptDir, '..', 'data');

%% ---- Load transient data (columns: t, Vin, t, Vout) ----
Tn = readmatrix(fullfile(dataDir, 'inverter_transient', 'tran_nominal.csv'));
To = readmatrix(fullfile(dataDir, 'inverter_transient', 'tran_optimized.csv'));

t_n   = Tn(:,1);  vin_n  = Tn(:,2);  vout_n = Tn(:,4);
t_o   = To(:,1);  vin_o  = To(:,2);  vout_o = To(:,4);

%% ---- Load DC VTC data (columns: Vin, Vin, Vin, Vout, Vin, I_VDDs) ----
Dn = readmatrix(fullfile(dataDir, 'inverter_dc', 'dc_nominal.csv'));
Do = readmatrix(fullfile(dataDir, 'inverter_dc', 'dc_optimized.csv'));

vin_dc_n = Dn(:,1); vout_dc_n = Dn(:,4); i_dc_n = Dn(:,6);
vin_dc_o = Do(:,1); vout_dc_o = Do(:,4); i_dc_o = Do(:,6);

VDD = 0.95;

%% ---- Figure 1: Transient response overlay ----
figure('Name','Transient Response','Color','w','Position',[100 100 900 500]);
tiledlayout(2,1,'TileSpacing','compact');

nexttile;
plot(t_n*1e9, vin_n, 'k--', 'LineWidth', 1.3); hold on;
plot(t_n*1e9, vout_n, 'b-', 'LineWidth', 1.6);
plot(t_o*1e9, vout_o, 'r-', 'LineWidth', 1.6);
xlabel('Time (ns)'); ylabel('Voltage (V)');
title('Inverter Transient Response');
legend('V_{in}','V_{out} (Nominal)','V_{out} (Optimized)','Location','best');
grid on; xlim([0 3]);

nexttile;
plot(t_n*1e9, vout_n, 'b-', 'LineWidth', 1.6); hold on;
plot(t_o*1e9, vout_o, 'r-', 'LineWidth', 1.6);
xlabel('Time (ns)'); ylabel('V_{out} (V)');
title('Zoom: Output Switching Edges');
legend('Nominal','Optimized','Location','best');
grid on; xlim([0.95 1.10]);

%% ---- Figure 2: VTC (DC transfer characteristic) ----
figure('Name','VTC Comparison','Color','w','Position',[120 120 700 550]);
plot(vin_dc_n, vout_dc_n, 'b-', 'LineWidth', 2); hold on;
plot(vin_dc_o, vout_dc_o, 'r-', 'LineWidth', 2);
plot([0 VDD],[0 VDD],'k:','LineWidth',1);
xlabel('V_{in} (V)'); ylabel('V_{out} (V)');
title('CMOS Inverter VTC: Nominal vs Optimized');
legend('Nominal','Optimized','V_{out}=V_{in}','Location','southwest');
grid on; axis([0 VDD 0 VDD]);

% Mark VM (Vin = Vout crossing) for each curve
[~,idx_n] = min(abs(vout_dc_n - vin_dc_n));
[~,idx_o] = min(abs(vout_dc_o - vin_dc_o));
plot(vin_dc_n(idx_n), vout_dc_n(idx_n), 'bo', 'MarkerFaceColor','b', 'MarkerSize',7);
plot(vin_dc_o(idx_o), vout_dc_o(idx_o), 'ro', 'MarkerFaceColor','r', 'MarkerSize',7);
text(vin_dc_n(idx_n)+0.02, vout_dc_n(idx_n), sprintf('VM_{nom}=%.3fV', vin_dc_n(idx_n)), 'Color','b');
text(vin_dc_o(idx_o)+0.02, vout_dc_o(idx_o)+0.05, sprintf('VM_{opt}=%.3fV', vin_dc_o(idx_o)), 'Color','r');

%% ---- Figure 3: Leakage current vs Vin (log scale) ----
figure('Name','Leakage Current','Color','w','Position',[140 140 700 500]);
semilogy(vin_dc_n, abs(i_dc_n)*1e9, 'b-', 'LineWidth', 1.8); hold on;
semilogy(vin_dc_o, abs(i_dc_o)*1e9, 'r-', 'LineWidth', 1.8);
xlabel('V_{in} (V)'); ylabel('|I_{VDD}| (nA)');
title('Supply Current vs Input Voltage');
legend('Nominal','Optimized','Location','best');
grid on;

%% ---- Figure 4: Summary bar chart (measured .meas results) ----
% Values below are taken directly from the LTspice / ngspice .meas logs
% (nominal corner computed from the same model card with .lib defaults;
% optimized corner is your verified LTspice log output).
metrics   = {'tp (ps)','VM (V)','|Gain| (V/V)','I_{leak,low} (nA)','I_{leak,high} (pA)','E_{cycle} (fJ)'};

nominal_vals   = [13.04, 0.4800, 6.52, 1.26, 45.4, 9.34];
optimized_vals = [9.80,  0.4604, 6.99, 4.86, 43.8, 9.11];

figure('Name','Metric Summary','Color','w','Position',[160 160 900 450]);
b = bar([nominal_vals; optimized_vals]','grouped');
b(1).FaceColor = [0.2 0.4 0.8];
b(2).FaceColor = [0.8 0.2 0.2];
set(gca,'XTickLabel',metrics,'XTickLabelRotation',20);
ylabel('Value (see axis label per metric)');
legend('Nominal','Optimized','Location','best');
title('Nominal vs Optimized Inverter — Key Metrics');
grid on;

fprintf('Done. All 4 figures generated: transient overlay, VTC, leakage,\n');
fprintf('and nominal-vs-optimized metric summary.\n');
fprintf('Nominal values were computed independently via ngspice on the same\n');
fprintf('model card -- cross-check tp/VM against your own 08_/09_ LTspice runs\n');
fprintf('if you want a second confirmation.\n');
