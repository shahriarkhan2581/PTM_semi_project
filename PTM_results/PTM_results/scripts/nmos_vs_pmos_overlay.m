%% ========================================================================
%  nmos_vs_pmos_overlay.m   (MATLAB Online friendly - no .cir needed)
%  Overlay NMOS vs PMOS parameter sensitivities from LTspice .meas logs.
%    Run NMOS decks 03,04,05,07 and PMOS decks 13,14,15,17 in LTspice,
%    upload the 8 .log files, then run:  >> nmos_vs_pmos_overlay
%% ========================================================================
clear; clc; close all;

%% decks: {param, NMOS log, PMOS log, [start stop step] for NMOS}
scriptDir = fileparts(mfilename('fullpath'));
logDir    = fullfile(scriptDir, '..', 'logs');
plotDir   = fullfile(scriptDir, '..', 'plots');

decks = {
    'vth0',    fullfile(logDir,'03_sweep_vth0.log'),    fullfile(logDir,'13_sweep_vth0_pmos.log'),    [0.55   0.82   0.03  ]
    'u0',      fullfile(logDir,'04_sweep_u0.log'),      fullfile(logDir,'14_sweep_u0_pmos.log'),      [0.020  0.050  0.0025]
    'toxe',    fullfile(logDir,'05_sweep_toxe.log'),    fullfile(logDir,'15_sweep_toxe_pmos.log'),    [1.0e-9 2.0e-9 0.1e-9]
    'nfactor', fullfile(logDir,'07_sweep_nfactor.log'), fullfile(logDir,'17_sweep_nfactor_pmos.log'), [1.2    2.4    0.1   ]
};
pmos_range = struct('vth0',[-0.80 -0.55 0.03], 'u0',[0.006 0.018 0.001], ...
                    'toxe',[1.0e-9 2.0e-9 0.1e-9], 'nfactor',[1.2 2.4 0.1]);
xlabels = struct('vth0','|V_{th0}| (V)','u0','u_0 (m^2/Vs)', ...
                 'toxe','t_{oxe} (nm)','nfactor','nfactor');

fprintf('\n=== NMOS vs PMOS  Ioff sensitivity ===\n');
fprintf('%-8s | %-14s | %-14s\n','param','NMOS S(Ioff)','PMOS S(Ioff)');
fprintf('%s\n',repmat('-',1,42));

for d = 1:size(decks,1)
    pname = decks{d,1};
    nlog  = decks{d,2};  plog = decks{d,3};
    nrng  = decks{d,4};  prng = pmos_range.(pname);

    xn = nrng(1):nrng(3):nrng(2);
    xp = prng(1):prng(3):prng(2);

    haveN = isfile(nlog); haveP = isfile(plog);
    if ~haveN, warning('Missing %s',nlog); end
    if ~haveP, warning('Missing %s',plog); end
    if ~haveN && ~haveP, continue; end
    if haveN, MN=parse_meas_log(nlog); else, MN=struct(); end
    if haveP, MP=parse_meas_log(plog); else, MP=struct(); end

    ionN=abs(col(MN,'ion',numel(xn)));  ioffN=abs(col(MN,'ioff',numel(xn)));
    ssN =col(MN,'ss',numel(xn));        vtN =abs(col(MN,'vt',numel(xn)));
    ionP=abs(col(MP,'ion',numel(xp)));  ioffP=abs(col(MP,'ioff',numel(xp)));
    ssP =col(MP,'ss',numel(xp));        vtP =abs(col(MP,'vt',numel(xp)));

    xnp=xn; xpp=xp;
    if strcmp(pname,'vth0'), xpp=abs(xp); end
    if strcmp(pname,'toxe'), xnp=xn*1e9; xpp=xp*1e9; end

    figure('Name',['NMOS vs PMOS: ' pname],'Color','w','Position',[80 80 980 740]);
    subplot(2,2,1);
    plot(xnp,ionN*1e6,'bo-','LineWidth',1.5,'MarkerFaceColor','b'); hold on;
    plot(xpp,ionP*1e6,'rs--','LineWidth',1.5,'MarkerFaceColor','r');
    grid on; xlabel(xlabels.(pname)); ylabel('|I_{on}| (\muA)');
    title('I_{on}'); legend('NMOS','PMOS','Location','best');

    subplot(2,2,2);
    semilogy(xnp,ioffN*1e9,'bo-','LineWidth',1.5,'MarkerFaceColor','b'); hold on;
    semilogy(xpp,ioffP*1e9,'rs--','LineWidth',1.5,'MarkerFaceColor','r');
    grid on; xlabel(xlabels.(pname)); ylabel('|I_{off}| (nA)');
    title('I_{off}'); legend('NMOS','PMOS','Location','best');

    subplot(2,2,3);
    plot(xnp,ssN,'bo-','LineWidth',1.5,'MarkerFaceColor','b'); hold on;
    plot(xpp,ssP,'rs--','LineWidth',1.5,'MarkerFaceColor','r');
    grid on; xlabel(xlabels.(pname)); ylabel('SS (mV/dec)');
    title('Subthreshold Swing'); legend('NMOS','PMOS','Location','best');

    subplot(2,2,4);
    plot(xnp,vtN*1000,'bo-','LineWidth',1.5,'MarkerFaceColor','b'); hold on;
    plot(xpp,vtP*1000,'rs--','LineWidth',1.5,'MarkerFaceColor','r');
    grid on; xlabel(xlabels.(pname)); ylabel('|V_t| (mV)');
    title('Threshold'); legend('NMOS','PMOS','Location','best');

    sgtitle(sprintf('NMOS vs PMOS  -  sweep of %s', pname), ...
            'FontWeight','bold','FontSize',13);
    saveas(gcf, fullfile(plotDir, sprintf('nvp_%s.svg', pname)));

    sN = midpoint_sens(xn, ioffN);
    sP = midpoint_sens(xp, ioffP);
    fprintf('%-8s | %-14.2f | %-14.2f\n', pname, sN, sP);

    L = min(numel(xn),numel(xp));
    T = table(xn(1:L)', ionN(1:L), ionP(1:L), ioffN(1:L), ioffP(1:L), ...
              ssN(1:L), ssP(1:L), vtN(1:L), vtP(1:L), ...
        'VariableNames',{['n_' pname],'Ion_N','Ion_P','Ioff_N','Ioff_P', ...
                         'SS_N','SS_P','Vt_N','Vt_P'});
    writetable(T, sprintf('nvp_compare_%s.csv', pname));
end
fprintf('\nDone. See nvp_*.png figures and nvp_compare_*.csv tables.\n');

%% ================= LOCAL FUNCTIONS =================
function M = parse_meas_log(logFile)
    M = struct();
    txt = fileread(logFile);
    lines = regexp(txt, '\r\n|\r|\n', 'split');
    i = 1;
    while i <= numel(lines)
        tok = regexpi(lines{i}, '^\s*Measurement:\s*(\S+)', 'tokens', 'once');
        if ~isempty(tok)
            name = lower(tok{1});  i = i + 2;  c = [];
            while i <= numel(lines)
                ln = strtrim(lines{i});
                if isempty(ln) || ~isempty(regexpi(ln,'^Measurement:','once')), break; end
                nums = str2double(regexp(ln,'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?','match'));
                if numel(nums)>=2 && nums(1)==round(nums(1))
                    c(end+1,1) = nums(2); %#ok<AGROW>
                elseif isscalar(nums)
                    c(end+1,1) = nums(1); %#ok<AGROW>
                end
                i = i + 1;
            end
            if ~isempty(c), M.(matlab.lang.makeValidName(name)) = c; end
        else
            i = i + 1;
        end
    end
end

function y = col(M, f, n)
    if isfield(M, f), v = M.(f); else, v = nan(n,1); end
    y = nan(n,1); m = min(numel(v), n); y(1:m) = v(1:m);
end

function S = midpoint_sens(x, y)
    x = x(:); y = y(:);
    good = isfinite(y); x = x(good); y = y(good);
    if numel(x) < 3, S = NaN; return; end
    k = round(numel(x)/2);
    dydx = (y(k+1)-y(k-1)) / (x(k+1)-x(k-1));
    S = dydx * x(k) / y(k);
end