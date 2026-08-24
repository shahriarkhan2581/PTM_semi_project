%% plot_tunnel.m - gate tunnelling figure (22nm PTM-LP, from deck-19 data)
clear; clc; close all;
scriptDir = fileparts(mfilename('fullpath'));
plotDir   = fullfile(scriptDir, '..', 'plots');
toxe = 0.8:0.1:2.0;   % nm
ig_n = [2.1805e-6 5.8282e-7 1.6195e-7 4.6453e-8 1.3682e-8 4.1213e-9 ...
        1.2657e-9 3.9527e-10 1.2528e-10 4.0228e-11 1.3069e-11 4.2911e-12 1.4225e-12];
ig_p = [2.7665e-6 7.1472e-7 1.9194e-7 5.3206e-8 1.5143e-8 4.4070e-9 ...
        1.3074e-9 3.9436e-10 1.2070e-10 3.7419e-11 1.1734e-11 3.7174e-12 1.1885e-12];
id_n = [553.25 563.03 562.88 555.44 542.56 525.56 505.46 483.02 458.80 ...
        433.26 406.75 379.55 351.92]*1e-6;
id_p = [605.39 622.77 630.40 630.47 624.47 613.50 598.46 580.05 558.85 ...
        535.33 509.90 482.89 454.61]*1e-6;

igid_n = abs(ig_n)./abs(id_n)*100;
igid_p = abs(ig_p)./abs(id_p)*100;
pN = polyfit(toxe, log10(abs(ig_n)), 1);
pP = polyfit(toxe, log10(abs(ig_p)), 1);
tf = linspace(0.8,2.0,100);

figure('Color','w','Position',[60 60 1500 480]);

% (a) Ig vs toxe
subplot(1,3,1);
semilogy(toxe,abs(ig_n)*1e9,'o','Color',[.12 .31 .61],'MarkerFaceColor',[.12 .31 .61],'MarkerSize',7); hold on;
semilogy(toxe,abs(ig_p)*1e9,'s','Color',[.75 .23 .17],'MarkerSize',7,'LineWidth',1.6);
semilogy(tf,10.^polyval(pN,tf)*1e9,'-','Color',[.12 .31 .61],'LineWidth',1.3);
semilogy(tf,10.^polyval(pP,tf)*1e9,'--','Color',[.75 .23 .17],'LineWidth',1.3);
xline(1.4,':','Color',[.5 .5 .5],'LineWidth',1.5);
grid on; xlabel('t_{oxe} (nm)'); ylabel('|I_g| (nA)');
title(sprintf('(a) I_g vs oxide\nslope N %.2f, P %.2f dec/nm',pN(1),pP(1)));
legend('NMOS','PMOS','Location','northeast');

% (b) Ig/Id severity
subplot(1,3,2);
semilogy(toxe,igid_n,'o-','Color',[.12 .31 .61],'MarkerFaceColor',[.12 .31 .61],'MarkerSize',6); hold on;
semilogy(toxe,igid_p,'s--','Color',[.75 .23 .17],'MarkerSize',6,'LineWidth',1.6);
yline(1,'k--','1% of drive'); yline(0.1,':','Color',[.5 .5 .5]);
xline(1.4,':','Color',[.5 .5 .5],'LineWidth',1.5);
grid on; xlabel('t_{oxe} (nm)'); ylabel('I_g / I_d (%)');
title('(b) Gate leak as % of drive'); legend('NMOS','PMOS','Location','northeast');

% (c) N/P crossover
subplot(1,3,3);
ratio = abs(ig_n)./abs(ig_p);
plot(toxe,ratio,'D-','Color',[.17 .48 .17],'MarkerFaceColor',[.17 .48 .17],'MarkerSize',6,'LineWidth',1.5); hold on;
yline(1,'k--'); xline(1.4,':','Color',[.5 .5 .5],'LineWidth',1.5);
grid on; xlabel('t_{oxe} (nm)'); ylabel('I_g(NMOS)/I_g(PMOS)');
title('(c) N/P leakage crossover');
text(1.55,1.12,'NMOS leaks more','Color',[.12 .31 .61],'FontSize',9);
text(0.85,0.85,'PMOS leaks more','Color',[.75 .23 .17],'FontSize',9);

sgtitle('Gate Tunnelling: NMOS vs PMOS (22 nm PTM-LP, BSIM4)','FontWeight','bold');
saveas(gcf, fullfile(plotDir,'tunnel_plot.svg'));