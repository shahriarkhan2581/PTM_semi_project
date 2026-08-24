%% plot_inverter_results_pub.m
% Nominal vs. Optimized 22nm CMOS Inverter - JOURNAL-QUALITY figures
% Data source: ngspice runs of the BSIM4 PTM-LP model card (same card
% used in LTspice: 11_optimized_inverter.cir / 12_optimized_inverter_VM.cir
% and their nominal counterparts).
%
% Place this script in the same folder as:
%   tran_nominal.csv, tran_optimized.csv, dc_nominal.csv, dc_optimized.csv
% then just press Run. Figures are saved as vector PDF + 600dpi PNG into
% a "figures" subfolder, ready to drop into a manuscript.

clear; clc; close all;

%% ---- Publication style defaults ----
set(0,'defaultAxesFontName','Times New Roman');
set(0,'defaultTextFontName','Times New Roman');
set(0,'defaultAxesFontSize',10);
set(0,'defaultTextFontSize',10);
set(0,'defaultLineLineWidth',1.5);
set(0,'defaultAxesLineWidth',1);
set(0,'defaultAxesBox','on');
set(0,'defaultAxesTickDir','out');
set(0,'defaultAxesTickLength',[0.012 0.012]);
set(0,'defaultLegendBox','off');
set(0,'defaultFigureColor','w');

% Colorblind-safe palette (Wong 2011)
col_nom = [0.0000, 0.4470, 0.7410];   % blue
col_opt = [0.8500, 0.3250, 0.0980];   % vermillion/orange
col_ref = [0.4000, 0.4000, 0.4000];   % neutral gray

% Anchor the output folder to THIS script's location, not MATLAB's
% "Current Folder" (a mismatch between the two is the most common cause
% of exportgraphics failing to write files).
try
    scriptDir = fileparts(mfilename('fullpath'));
catch
    scriptDir = '';
end
if isempty(scriptDir)
    scriptDir = pwd;
end
dataDir = fullfile(scriptDir, '..', 'data');
outdir  = fullfile(scriptDir, '..', 'figures');

if exist(outdir,'file') == 2
    error(['A FILE (not a folder) named "figures" already exists at:\n  %s\n' ...
           'Rename or delete it, then re-run.'], outdir);
end
if ~exist(outdir,'dir')
    [ok, msg] = mkdir(outdir);
    if ~ok
        error(['Could not create output folder:\n  %s\nReason: %s\n' ...
               'Check that you have write permission to this location ' ...
               '(e.g. avoid running from a read-only or network drive).'], ...
               outdir, msg);
    end
end

% exportgraphics requires MATLAB R2020a+. On older releases, fall back
% to print() so the script doesn't error out on "Undefined function".
haveExportgraphics = exist('exportgraphics','file') == 2 || exist('exportgraphics','builtin') > 0;

%% ---- Load transient data (columns: t, Vin, t, Vout) ----
Tn = readmatrix(fullfile(dataDir,'inverter_transient','tran_nominal.csv'));
To = readmatrix(fullfile(dataDir,'inverter_transient','tran_optimized.csv'));

t_n   = Tn(:,1);  vin_n  = Tn(:,2);  vout_n = Tn(:,4);
t_o   = To(:,1);  vin_o  = To(:,2);  vout_o = To(:,4);

%% ---- Load DC VTC data (columns: Vin, Vin, Vin, Vout, Vin, I_VDDs) ----
Dn = readmatrix(fullfile(dataDir,'inverter_dc','dc_nominal.csv'));
Do = readmatrix(fullfile(dataDir,'inverter_dc','dc_optimized.csv'));

vin_dc_n = Dn(:,1); vout_dc_n = Dn(:,4); i_dc_n = Dn(:,6);
vin_dc_o = Do(:,1); vout_dc_o = Do(:,4); i_dc_o = Do(:,6);

VDD = 0.95;

%% ================= FIGURE 1: VTC ==================
fig1 = figure('Units','inches','Position',[1 1 3.45 2.9]);
ax = axes(fig1); hold(ax,'on');

plot(ax, vin_dc_n, vout_dc_n, '-',  'Color', col_nom, 'LineWidth', 1.8, ...
    'DisplayName','Nominal');
plot(ax, vin_dc_o, vout_dc_o, '--', 'Color', col_opt, 'LineWidth', 1.8, ...
    'DisplayName','Optimized');
plot(ax, [0 VDD],[0 VDD], ':', 'Color', col_ref, 'LineWidth', 1, ...
    'HandleVisibility','off');

[~,idx_n] = min(abs(vout_dc_n - vin_dc_n));
[~,idx_o] = min(abs(vout_dc_o - vin_dc_o));
plot(ax, vin_dc_n(idx_n), vout_dc_n(idx_n), 'o', 'MarkerFaceColor', col_nom, ...
    'MarkerEdgeColor','k', 'MarkerSize', 5, 'HandleVisibility','off');
plot(ax, vin_dc_o(idx_o), vout_dc_o(idx_o), 's', 'MarkerFaceColor', col_opt, ...
    'MarkerEdgeColor','k', 'MarkerSize', 5, 'HandleVisibility','off');

text(ax, vin_dc_n(idx_n)+0.03, vout_dc_n(idx_n)-0.07, ...
    sprintf('V_{M}=%.3f V', vin_dc_n(idx_n)), 'Color', col_nom, 'FontSize', 8);
text(ax, vin_dc_o(idx_o)+0.03, vout_dc_o(idx_o)+0.07, ...
    sprintf('V_{M}=%.3f V', vin_dc_o(idx_o)), 'Color', col_opt, 'FontSize', 8);

xlabel(ax,'V_{in} (V)'); ylabel(ax,'V_{out} (V)');
axis(ax,[0 VDD 0 VDD]); axis(ax,'square');
legend(ax,'Location','southwest');
title(ax,'Voltage Transfer Characteristic','FontWeight','normal');

savefig_pub(fig1, outdir, 'fig1_VTC', haveExportgraphics);

%% ================= FIGURE 2: Transient response (2-panel) ==================
fig2 = figure('Units','inches','Position',[1 1 3.45 4.2]);

ax1 = subplot(2,1,1); hold(ax1,'on');
plot(ax1, t_n*1e9, vin_n, '-', 'Color', col_ref, 'LineWidth', 1.3, ...
    'DisplayName','V_{in}');
plot(ax1, t_n*1e9, vout_n, '-',  'Color', col_nom, 'LineWidth', 1.6, ...
    'DisplayName','V_{out}, nominal');
plot(ax1, t_o*1e9, vout_o, '--', 'Color', col_opt, 'LineWidth', 1.6, ...
    'DisplayName','V_{out}, optimized');
xlabel(ax1,'Time (ns)'); ylabel(ax1,'Voltage (V)');
xlim(ax1,[0 3]); ylim(ax1,[-0.05 1.0]);
legend(ax1,'Location','east','FontSize',7.5);
title(ax1,'(a) Full transient response','FontWeight','normal');

ax2 = subplot(2,1,2); hold(ax2,'on');
plot(ax2, t_n*1e9, vout_n, '-',  'Color', col_nom, 'LineWidth', 1.8, ...
    'DisplayName','Nominal');
plot(ax2, t_o*1e9, vout_o, '--', 'Color', col_opt, 'LineWidth', 1.8, ...
    'DisplayName','Optimized');
line(ax2, xlim(ax2), [VDD/2 VDD/2], 'LineStyle',':', 'Color', col_ref, 'LineWidth', 1, ...
    'HandleVisibility','off');
xlabel(ax2,'Time (ns)'); ylabel(ax2,'V_{out} (V)');
xlim(ax2,[0.95 1.10]);
legend(ax2,'Location','southwest','FontSize',7.5);
title(ax2,'(b) High-to-low switching edge (zoom)','FontWeight','normal');

savefig_pub(fig2, outdir, 'fig2_transient', haveExportgraphics);

%% ================= FIGURE 3: Leakage current ==================
fig3 = figure('Units','inches','Position',[1 1 3.45 2.9]);
ax = axes(fig3); hold(ax,'on');

semilogy(ax, vin_dc_n, abs(i_dc_n)*1e9, '-',  'Color', col_nom, 'LineWidth', 1.8, ...
    'DisplayName','Nominal');
semilogy(ax, vin_dc_o, abs(i_dc_o)*1e9, '--', 'Color', col_opt, 'LineWidth', 1.8, ...
    'DisplayName','Optimized');

xlabel(ax,'V_{in} (V)'); ylabel(ax,'|I_{DD}| (nA)');
xlim(ax,[0 VDD]);
legend(ax,'Location','south');
title(ax,'Static Supply Current','FontWeight','normal');

savefig_pub(fig3, outdir, 'fig3_leakage', haveExportgraphics);

%% ================= FIGURE 4: Normalized metric comparison ==================
% A bar chart mixing ps, V, nA, and fJ on one axis is not publishable practice.
% Instead: report percent change relative to the nominal design for each
% metric -- this is the standard way design trade-offs are summarized.
metrics_raw = {'t_p','V_M','|A_v|','I_{leak,H}','I_{leak,L}','E_{cycle}'};

nominal_vals   = [13.04, 0.4800, 6.52, 1.26, 45.4, 9.34];  % ps, V, -, nA, pA, fJ
optimized_vals = [9.80,  0.4604, 6.99, 4.86, 43.8, 9.11];

pct_change = (optimized_vals - nominal_vals) ./ nominal_vals * 100;

fig4 = figure('Units','inches','Position',[1 1 3.6 3.0]);
ax = axes(fig4); hold(ax,'on');

bar_colors = repmat(col_opt, numel(pct_change), 1);
bar_colors(pct_change < 0, :) = repmat([0.0000, 0.6196, 0.4510], sum(pct_change<0), 1); % teal for reduction

b = barh(ax, pct_change);
b.FaceColor = 'flat';
b.CData = bar_colors;
b.EdgeColor = 'k';
b.LineWidth = 0.75;

line(ax, [0 0], ylim(ax), 'Color','k', 'LineWidth', 1, 'HandleVisibility','off');
set(ax,'YTick',1:numel(metrics_raw),'YTickLabel',metrics_raw);
xlabel(ax,'Change vs. nominal (%)');
title(ax,'Optimized Design: Relative Metric Change','FontWeight','normal');

for k = 1:numel(pct_change)
    xoff = sign(pct_change(k))*3;
    ha = 'left'; if pct_change(k) < 0; ha = 'right'; end
    text(ax, pct_change(k)+xoff, k, sprintf('%+.1f%%',pct_change(k)), ...
        'FontSize',8, 'HorizontalAlignment',ha, 'VerticalAlignment','middle');
end
xlim(ax, [min(pct_change)-25, max(pct_change)+25]);

% Explicit legend for the semantic color coding (increase vs decrease) --
% this differs from Figs 1-3's nominal/optimized identity coloring, so
% it needs its own key rather than relying on Wong palette convention alone.
hIncrease = bar(ax, NaN, NaN, 'FaceColor', col_opt, 'EdgeColor','k');
hDecrease = bar(ax, NaN, NaN, 'FaceColor', [0.0000, 0.6196, 0.4510], 'EdgeColor','k');
legend(ax, [hIncrease, hDecrease], {'Increase','Decrease'}, 'Location','southoutside', ...
    'Orientation','horizontal');

savefig_pub(fig4, outdir, 'fig4_summary', haveExportgraphics);

%% ---- Done ----
fprintf('Saved 4 publication figures (vector PDF + 600dpi PNG) to ./%s/\n', outdir);
fprintf('  fig1_VTC          - voltage transfer characteristic\n');
fprintf('  fig2_transient    - transient response (2-panel)\n');
fprintf('  fig3_leakage      - static supply current, log scale\n');
fprintf('  fig4_summary      - percent-change summary (recommended for abstract/results)\n');
fprintf('\nRaw absolute values (for a results table) are printed below:\n');
T = table(metrics_raw', nominal_vals', optimized_vals', pct_change', ...
    'VariableNames', {'Metric','Nominal','Optimized','PctChange'});
disp(T);

%% ---- Local helper function (must appear at end of script in MATLAB) ----
function savefig_pub(fig, outdir, basename, haveExportgraphics)
    pdfPath = fullfile(outdir, [basename '.pdf']);
    pngPath = fullfile(outdir, [basename '.png']);
    if haveExportgraphics
        exportgraphics(fig, pdfPath, 'ContentType','vector');
        exportgraphics(fig, pngPath, 'Resolution',600);
    else
        % Fallback for MATLAB releases older than R2020a (no exportgraphics).
        set(fig, 'PaperPositionMode', 'auto');
        print(fig, pdfPath(1:end-4), '-dpdf', '-painters');
        print(fig, pngPath(1:end-4), '-dpng', '-r600');
    end
end