%% ========================================================================
%  ltspice_vs_compact.m   (MATLAB Online friendly - no .cir needed)
%  Auto-import LTspice .meas logs and overlay vs. analytic compact model.
%% ========================================================================
clear; clc; close all;

%% ---------- nominal model constants (from 22nm_LP.txt, NMOS) ----------
C.q      = 1.602e-19;
C.kB     = 1.381e-23;
C.T      = 300;
C.vt_th  = C.kB*C.T/C.q;
C.eps0   = 8.854e-12;
C.epsrox = 3.9;
C.ln10   = log(10);

NOM = struct('vth0',0.68858,'u0',0.035,'toxe',1.4e-9, ...
             'eta0',0.0105,'nfactor',1.6,'vsat',170000);
GEO = struct('Vdd',0.95,'L',22e-9,'W',1e-6);

%% ---------- decks: { field, log file, [start stop step] } ----------
scriptDir = fileparts(mfilename('fullpath'));
logDir    = fullfile(scriptDir, '..', 'logs');

decks = {
    'vth0',    fullfile(logDir,'03_sweep_vth0.log'),    [0.55   0.82   0.03  ]
    'u0',      fullfile(logDir,'04_sweep_u0.log'),      [0.020  0.050  0.0025]
    'toxe',    fullfile(logDir,'05_sweep_toxe.log'),    [1.0e-9 2.0e-9 0.1e-9]
    'nfactor', fullfile(logDir,'07_sweep_nfactor.log'), [1.2    2.4    0.1   ]
};

xlabels = struct('vth0','Threshold V_{th0} (V)', ...
                 'u0','Mobility u_0 (m^2/Vs)', ...
                 'toxe','Oxide t_{oxe} (nm)', ...
                 'nfactor','Subthreshold nfactor');

%% ---------- loop ----------
for d = 1:size(decks,1)
    pname   = decks{d,1};
    logFile = decks{d,2};
    rng     = decks{d,3};

    if ~isfile(logFile)
        warning('Log not found: %s  (upload the .log to MATLAB Drive)', logFile);
        continue;
    end

    xvals = rng(1):rng(3):rng(2);
    if abs(xvals(end)-rng(2)) > 1e-12 && xvals(end)+rng(3) <= rng(2)+1e-9
        xvals(end+1) = rng(2);
    end

    M = parse_meas_log(logFile);
    n = numel(xvals);
    ion_s  = local_fit(M, 'ion',  n);
    ioff_s = local_fit(M, 'ioff', n);
    ss_s   = local_fit(M, 'ss',   n);
    vt_s   = local_fit(M, 'vt',   n);

    ion_c=zeros(n,1); ioff_c=zeros(n,1); ss_c=zeros(n,1); vt_c=zeros(n,1);
    for k = 1:n
        P = NOM;  P.(pname) = xvals(k);
        m = compact_metrics(P, GEO, C);
        ion_c(k)=m.Ion;  ioff_c(k)=m.Ioff;  ss_c(k)=m.SS;  vt_c(k)=m.Vt;
    end

    xp = xvals;  if strcmp(pname,'toxe'), xp = xvals*1e9; end
    figure('Name',['SPICE vs Compact: ' pname],'Color','w', ...
           'Position',[100 100 950 720]);

    subplot(2,2,1);
    plot(xp, ion_c*1e6,'b-','LineWidth',1.6); hold on;
    plot(xp, ion_s*1e6,'ro','MarkerSize',7,'LineWidth',1.4);
    grid on; xlabel(xlabels.(pname)); ylabel('I_{on} (\muA)');
    title('I_{on}'); legend('Compact model','LTspice','Location','best');

    subplot(2,2,2);
    semilogy(xp, ioff_c*1e9,'b-','LineWidth',1.6); hold on;
    semilogy(xp, ioff_s*1e9,'ro','MarkerSize',7,'LineWidth',1.4);
    grid on; xlabel(xlabels.(pname)); ylabel('I_{off} (nA)');
    title('I_{off}'); legend('Compact model','LTspice','Location','best');

    subplot(2,2,3);
    plot(xp, ss_c,'b-','LineWidth',1.6); hold on;
    plot(xp, ss_s,'ro','MarkerSize',7,'LineWidth',1.4);
    grid on; xlabel(xlabels.(pname)); ylabel('SS (mV/dec)');
    title('Subthreshold Swing'); legend('Compact','LTspice','Location','best');

    subplot(2,2,4);
    plot(xp, vt_c*1000,'b-','LineWidth',1.6); hold on;
    plot(xp, vt_s*1000,'ro','MarkerSize',7,'LineWidth',1.4);
    grid on; xlabel(xlabels.(pname)); ylabel('V_t (mV)');
    title('Threshold (constant-current)'); legend('Compact','LTspice','Location','best');

    sgtitle(sprintf('SPICE vs. Compact-Model  -  sweep of %s', pname), ...
            'FontWeight','bold','FontSize',13);

    saveas(gcf, sprintf('overlay_%s.png', pname));
    T = table(xvals(:), ion_s(:), ion_c(:), ioff_s(:), ioff_c(:), ...
              ss_s(:), ss_c(:), vt_s(:), vt_c(:), ...
        'VariableNames',{pname,'Ion_spice','Ion_cmp','Ioff_spice','Ioff_cmp', ...
                         'SS_spice','SS_cmp','Vt_spice','Vt_cmp'});
    writetable(T, sprintf('compare_%s.csv', pname));
    fprintf('Processed %-8s : %d points  -> overlay_%s.png , compare_%s.csv\n', ...
            pname, n, pname, pname);
end
fprintf('\nDone. Open the overlay_*.png figures and compare_*.csv tables.\n');

%% ======================= LOCAL FUNCTIONS =======================
function M = parse_meas_log(logFile)
    M = struct();
    txt = fileread(logFile);
    lines = regexp(txt, '\r\n|\r|\n', 'split');
    i = 1;
    while i <= numel(lines)
        tok = regexpi(lines{i}, '^\s*Measurement:\s*(\S+)', 'tokens', 'once');
        if ~isempty(tok)
            name = lower(tok{1});
            i = i + 2;
            col = [];
            while i <= numel(lines)
                ln = strtrim(lines{i});
                if isempty(ln) || ~isempty(regexpi(ln,'^Measurement:','once'))
                    break;
                end
                nums = str2double(regexp(ln, '[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', 'match'));
                if numel(nums) >= 2 && nums(1)==round(nums(1))
                    col(end+1,1) = nums(2);
                elseif numel(nums) == 1
                    col(end+1,1) = nums(1);
                end
                i = i + 1;
            end
            if ~isempty(col), M.(matlab.lang.makeValidName(name)) = col; end
        else
            i = i + 1;
        end
    end
end

function y = local_fit(M, f, n)
    if isfield(M, f), v = M.(f); else, v = nan(n,1); end
    y = nan(n,1);
    m = min(numel(v), n);
    y(1:m) = v(1:m);
end

function m = compact_metrics(P, G, C)
    Cox  = C.epsrox*C.eps0 / P.toxe;
    n    = P.nfactor;
    Vt_lin = P.vth0 - P.eta0*0.05;
    Vt_sat = P.vth0 - P.eta0*G.Vdd;
    m.Vt   = Vt_lin;
    m.DIBL = (Vt_lin - Vt_sat)/(G.Vdd-0.05)*1000;
    m.SS   = n*C.vt_th*C.ln10*1000;
    Esat = 2*P.vsat/P.u0;
    Vov  = G.Vdd - Vt_sat;
    m.Ion  = G.W*Cox*P.vsat*Vov^2 / (Vov + Esat*G.L);
    I0     = P.u0*Cox*(G.W/G.L)*(n-1)*C.vt_th^2;
    m.Ioff = I0*exp((0 - Vt_sat)/(n*C.vt_th))*(1 - exp(-G.Vdd/C.vt_th));
end