%% Code to analyze Action Potential Intrinsic Properties from cerebellar Purkinje cells.
% It analyzes Peak amplitude, Action potential threshold, after hyperpolarization, rate of change dV/dt. 
% Updated 07.15.2026 by Isaac Guillen

clear;clc;

%% 1.Select experiment, cell & spike number to analyze  
Experiment = num2str('Exp20.xlsx');     % Select experiment number (excel file)
Cell = num2str('Cell 2');               % Select cell number (spreadsheet)
Spike = 4;                              % Select spike to analyze from train of spikes
 
RecordedCells = sheetnames(Experiment); % Return recorded cells in the experiment
  disp(['Experiment: ',Experiment]);
  disp(RecordedCells);
  disp(['Analyzing Spike Properties: ', Cell]);
  disp(['Analyzing: Spike #',num2str(Spike)]);

%% 2.Import data from excel into matlab
CellData = readmatrix(Experiment,...
    'Sheet',Cell,'Range','');     % Import data from selected excel & spreadsheet 

%% 3. Finding mouse info (genotype & age)
GenoType= CellData(1,1);          % Return mouse genotype:'1= Wildtype' or '2= Knockout'
Age = CellData(1,2);              % Return mouse age (weeks)
if GenoType == 1
    disp('Genotype: WT mouse');
    disp(['Mouse age: ',num2str(Age),' weeks']);
    Mouse = ('WT');
elseif GenoType == 2
        disp('Genotype: KO mouse');
        disp(['Mouse Age:',num2str(Age),' weeks']);
        Mouse = ('KO');
end

%% 4.Parameters to analyze spike properties
TimeT= 0.75;            % Set up time in ms before action potential 
stdx= 6;                % Number use to multiply the STD in dVdt baseline mean (6 for protocol#4) (4 for protocol #5)
baseline= 0;            % Baseline in y-axis (mV)to count action potentials

%% 5. Full traces
x= CellData(3:65000,58);  % x = time(ms)            
y1= CellData(3:65000,59); % y1= sweep from cell       

%% 6.Cell- Finding selected peak,peak row and peak time
[FindPks,Rows] = findpeaks(y1,...
    'MinPeakHeight',baseline);       % Find peaks voltages and rows 
AP_Peak =FindPks(Spike);                % Indexing AP peak (Peak number selected from trace)
PeakRow =Rows(Spike);                % Indexing AP peakrow
PeakTime = x(PeakRow);               % Indexing AP peak time

T=table(PeakRow, PeakTime, AP_Peak);    % Table results for peak info

ind1= find(x == PeakTime);           % (1) Logical Indexing to search peak time. 
Xtime= x(ind1);                      % Indexing time value of AP threshold
PeakBef= Xtime-3.5;                  % (5.5ms @ 300pA) & (3.5ms @500pA)
PeakAft= Xtime+3;                    % (6ms @300pA) & (3ms @500pA)

% Isolate selected spike from trace & find newx & newy values for analysis 
Isolated_AP= x>PeakBef & x<PeakAft;  % Logical index of selected spike
AP_ms= x(Isolated_AP);               % Indexing time values of selected spike
AP_mV= y1(Isolated_AP);              % Indexing mV values of selected spike

% FIGURE 1: Plotting voltage trace with number of peaks
figure;                              
findpeaks(y1,'MinPeakHeight',baseline);       
text(Rows+.02,FindPks,num2str((1:numel(FindPks))'));
legend(Cell);
ylabel('mV');
xlabel('Time');
title('Spike Count');
grid off; box off;


%% 7.Finding dVdt: Curve fitting & differentiating selected spike from selected voltage trace
[fit1, gof1, output1] = fit(AP_ms,AP_mV,...
    'smoothingspline');                       %Curve fitting & goodness of fit from selected spike
[AP_dVdt, d2]= differentiate(fit1,AP_ms);     % Finding 1st & 2nd derivatives of the fit on selected spike

AP_Table= table(AP_ms,AP_mV,AP_dVdt);               

%Finding and subtracting time "BEFORE AP"
NewTimeBefAP= Xtime - TimeT;                  % Subtracting time before peak voltage

%Extracting time, mV and 1st dVdt "BEFORE AP"
X1 = NewTimeBefAP - 4;

ValuesBef_AP= AP_ms>X1 & AP_ms<NewTimeBefAP;  % Logical index of time values before AP
Newx1= AP_ms(ValuesBef_AP);                   % Indexing time values before AP
Newy1= AP_mV(ValuesBef_AP);                   % Indexing mV values before AP
NewdVdt1= AP_dVdt(ValuesBef_AP);              % Indexing dV/dt values before AP

%% 8. Finding the mean(dVdt) & std(dVdt) "BEFORE AP"
meanBefAP= mean(NewdVdt1);                         % find mean(spike dV/dt)
SD1BefAP= std(NewdVdt1);                           % Find std(spike dV/dt)
dVdtRealThresholdVal= meanBefAP +(stdx*SD1BefAP);  % dVdtThreshold reached after this value

% Find nearest value
Min_dVdt = min(AP_dVdt);                        % Find min dVdt value
Max_dVdt = max(AP_dVdt);                        % Find max dVdt value
ValuesPeak_dVdt= AP_dVdt == Max_dVdt;           % Logical index from for max dVdt                  
xx = AP_ms(ValuesPeak_dVdt);                    % find time for max dVdt

Index_dVdt = AP_ms>= NewTimeBefAP & AP_ms<=xx;  % Logical index from Set up time in ms before action potential and before dVdtPeak
d1_x= AP_ms(Index_dVdt);
d1_mV= AP_mV(Index_dVdt);
d1_dVdt= AP_dVdt(Index_dVdt);                   % Find values for previous max dVdt

Stats1= table(meanBefAP, SD1BefAP, dVdtRealThresholdVal); % Table results

[val,idx1] = min(abs(d1_dVdt-dVdtRealThresholdVal));  % Finding nearest dVdtThreshold value in AP_dVdt trace before AP
dVdtThreshold = d1_dVdt(idx1);                        % Exact dVdtThreshold value in AP_dVdt trace before AP

%% 9.Results AP threshold
%Finding the deviation of the mean(dVdt) in d1a full TRACE. Also,indexing time and mV values. 
idx2 = find((AP_dVdt) == dVdtThreshold);   % Idx= row info of deviation in 1st dVdt (Before code: idx2 = find((AP_dVdt) >= dVdtThreshold,1); )
d1Threshold= AP_dVdt(idx2);                  % dV/dt
y1Threshold= AP_mV(idx2);                    % mV
x1Threshold= AP_ms(idx2);                    % time

idx = table(idx2, x1Threshold, y1Threshold, d1Threshold);

%% 10. Finding segment from Peak to AHP  

% Isolating segment from Peak-Voltage to end values
Isolated_AHP= AP_ms>=Xtime & AP_ms<=PeakAft;    % Logical index of all time values after spike peak-voltage
AHP_ms= AP_ms(Isolated_AHP);                    % Indexing all time values before AP
AHP_mV= AP_mV(Isolated_AHP);                    % Indexing all mV values before AP

% Finding AHP min peak after Spike
[AHP,RowsAHP] = min(AHP_mV);                    % Find AHP-peak voltage and row
ind2= find(AHP_mV == AHP,1);                    % (1) Logical Indexing of desire value(Use this line only when analysis pulls out 2 or more values) 
Time_AHP= AHP_ms(ind2);                         % Indexing time value of AHP min peak-voltage

[row,col] = find(x == Time_AHP);

% Isolating segment from peak-voltsge to AHP min peak
Isolated_AHP2= AP_ms>=Xtime & AP_ms<=Time_AHP;    % Logical index of all time values after spike peak-voltage
AHP_ms1= AP_ms(Isolated_AHP2);                    % Indexing all time values before AP
AHP_mV1= AP_mV(Isolated_AHP2);                    % Indexing all mV values before AP

% Nearest value in AHP onset
[val1,idx3]=min(abs(AHP_mV1-y1Threshold));
minVal= AHP_mV1(idx3);

% Finding the After-hyperpolarization (AHP)segment
ind_AHP = AHP_mV1<=minVal & AHP_mV1>=AHP;         % Index AHP segment after first spike
x_AHP= AHP_ms1(ind_AHP);                          % Indexing all time values in AHP (ms)
y_AHP= AHP_mV1(ind_AHP);                          % Indexing all mV values in AHP (mV)

%% 11. Calculating AHP amplitude & AHP time (from AP threshold to AHP)

AHP_Amplitude = abs(y1Threshold - AHP);
AHP_Time = Time_AHP - x1Threshold;

% Table Results
A_Table1= table(AP_Peak, y1Threshold, AHP, AHP_Amplitude, AHP_Time, Max_dVdt, Min_dVdt)
A_Table2 = table(RowsAHP,Time_AHP,AHP);

%% 12. Final figure

figure;
subplot(3,4,[11 12]);
plot(AP_ms,AP_mV,'Color',[0.5 0.5 0.5],'LineWidth',2);
hold on;
plot(AP_ms(idx2), y1Threshold,'ro','MarkerfaceColor','r');
hold on;
plot(x_AHP,y_AHP,'r-','LineWidth',2.5);
yline(y1Threshold,'--k','AP threshold','LineWidth',1.5,...
    'LabelHorizontalAlignment','left');
% xline(Time_AHP,'--k','AHP','LineWidth',1.5,...
%     'Labelorientation','horizontal','LabelVerticalAlignment','bottom');
xlabel('ms');
ylabel('mV');
xlim padded
ylim ([-75 22]);

% legend
apstr1= sprintf('AP threshold: %.2f mV',y1Threshold);
apstr2= sprintf('AHP Amp: %.1f mV',AHP_Amplitude);
legend(Cell,apstr1,apstr2,'Location','northeast','box','off');
box off;

%% 13. Data Vizualization
subplot(3,4,[7 8]);
plot(AP_ms,AP_mV,'Color',[0.5 0.5 0.5],'LineWidth',2);
hold on;
plot(Newx1,Newy1,'g','LineWidth',2);
hold on;
plot(AHP_ms,AHP_mV,'g-','LineWidth',2);
hold on;
plot(AHP_ms1,AHP_mV1,'k*');
hold on;
plot(AP_ms(idx2), y1Threshold,'ro','MarkerfaceColor','r');
hold on;
plot(x_AHP,y_AHP,'r-','LineWidth',3);
yline(y1Threshold,'--b','AP threshold','LineWidth',1.5,...
    'LabelHorizontalAlignment','left');
yline(AHP,'--b','AHP','LineWidth',1.5,...
    'Labelorientation','horizontal','LabelHorizontalAlignment','Left');
xline(x1Threshold,'b','LineWidth',1.5,...
    'Labelorientation','horizontal','LabelVerticalAlignment','bottom');
xlabel('ms');
ylabel('mV');
xlim padded
ylim ([-75 22]);
grid off

% legend
legend('Data Vizualization','Location','northeast','box','off');
box off;

%% 14. Full voltage trace showing PeakV & AHP 
subplot(3,4,[1 2 3 4]);
plot(x,y1,'Color',[0.5 0.5 0.5],'LineStyle',':');
hold on;
plot(AP_ms,AP_mV,'Color',[0.5 0.5 0.5],'linewidth',1);
hold on;
plot(x(PeakRow), AP_Peak,'rv', 'MarkerFaceColor','r','MarkerSize',8);
hold on
plot(x(row), AHP,'ro');
yline(0,'k:');

% Legends
xlabel('ms');
ylabel('mV');
xlim padded;
ylim ([-75 22]);
apstr3= sprintf('Spike# %.0f',Spike);
lgd=legend('',Cell,apstr3,'AHP','Location','northeast','box','off');
title(lgd,'Evoke firing @300pA');
box off;

%% 15. Phase plane plot
subplot(3,4,[5 6 9 10]);
plot(AP_mV,AP_dVdt,'Color',[0.5 0.5 0.5],'linewidth',2);
hold on;
plot(AP_mV(idx2), d1Threshold,'ro','MarkerfaceColor','r');
xlim([-75 30]);
ax = gca;                       % axis crosses zero
ax.XAxisLocation = 'origin';    % x-axis crosses zero
ax.YAxisLocation = 'origin';    % y-axis Crosses Zero
xlabel('mV');
ylabel('dV/dt (mV/ms)');
% str3= sprintf('AP threshold');
% str4= sprintf('AP Peak');
% str5= sprintf('dV/dt Max');
% text(-48,20,str3,'Color','b');
% text(18,20,str4,'Color','b');
% text(-15,200,str5,'Color','b');
apstr4= sprintf('AP threshold: %.2f mV',y1Threshold);
legend(Cell, apstr4, 'Location','northwest','box','off');
grid off
box off
%
sgtitle([Experiment,'  /  ',Mouse,'  /  ', Cell, '  /  ', num2str(Age),' weeks']);
set(findall(gcf,'-property','FontSize'),'FontSize',10);


%% 16. Testing Figure to show the nearest value selection  9/15/2023

figure
subplot(2,1,2);
plot(AP_ms,AP_mV,'Color',[0.5 0.5 0.5],'linewidth',1.5);
ylim padded;
hold on;
plot(AP_ms(idx2), y1Threshold,'ro','MarkerfaceColor','r');
hold on;
xline(x1Threshold, '--k', {x1Threshold});
xlabel('ms');
ylabel('mV');
apstr7= sprintf('Time: %.2f ms',x1Threshold);
legend('Action Potential',apstr1,apstr7,'Location','northeast','box','off');
box off;

subplot(2,1,1);
plot(AP_ms,AP_dVdt,'Color',[0.5 0.5 0.5],'linewidth',1.5);
hold on;
plot(Newx1,NewdVdt1,'r','linewidth',2);
hold on;
plot(AP_ms(idx2), d1Threshold,'ro','MarkerfaceColor','r');
xline(x1Threshold, '--k', {x1Threshold},'LabelVerticalAlignment', 'bottom');
% yline(meanBefAP,'--r',' mean(dV/dt) + (6*SD(dV/dt))','LineWidth',1.5,...
%      'LabelHorizontalAlignment','left','LabelVerticalAlignment', 'bottom');
yline(dVdtRealThresholdVal,'--b','Real dVdt threshold','LineWidth',1.5,...
     'LabelHorizontalAlignment','left','LabelVerticalAlignment', 'bottom');
yline(dVdtThreshold,'-r','Nearest data point value to "Real dVdt threshold"','LineWidth',1.5,...
    'LabelHorizontalAlignment','left');
ylim([-10 15]);
xlabel('ms');
ylabel('dV/dt (mV/ms)');
apstr5= sprintf('dVdt threshold: %.2f mV/ms',dVdtThreshold);
legend('dV/dt','Threshold= mean(dV/dt)+(6*SD(dV/dt))',apstr5,apstr7,'Location','northeast','box','off');
grid on;

sgtitle([Experiment,'  /  ',Mouse,'  /  ', Cell, '  /  ',apstr3,' / ','Action Potential Threshold']);
set(findall(gcf,'-property','FontSize'),'FontSize',10);

%% 17. Finding Max & Min dVdt (24/01/2025)

Ylim_2= [-400 500];                                 % PPP y-axis
Xlim_2= [-80 30];                                   % PPP x-axis

idx2a = find((AP_dVdt) == Min_dVdt);   
MIN_dVdt= AP_dVdt(idx2a);                  % Min dV/dt

idx2b = find((AP_dVdt) == Max_dVdt);   
MAX_dVdt= AP_dVdt(idx2b);                  % Max dV/dt

figure
plot(AP_mV,AP_dVdt,'Color',[0.5 0.5 0.5],'linewidth',2);
hold on;
plot(AP_mV(idx2a), Max_dVdt,'r^','MarkerfaceColor','r');
hold on;
plot(AP_mV(idx2b), Min_dVdt,'ro','MarkerfaceColor','r');
ylim(Ylim_2);
xlim(Xlim_2);
ax = gca;                       % axis crosses zero
ax.XAxisLocation = 'origin';    % x-axis crosses zero
ax.YAxisLocation = 'origin';    % y-axis Crosses Zero
box off;

% Legend
apstr5= sprintf('Max dVdt: %.2f mV',Max_dVdt);
apstr6= sprintf('Min dVdt: %.2f mV',Min_dVdt);
legend(Cell, apstr5,apstr6, 'Location','northwest','box','off');

sgtitle([Experiment,'  /  ',Mouse,'  /  ', Cell, '  /  ',apstr3,' / ','Max & Min dVdt']);
set(findall(gcf,'-property','FontSize'),'FontSize',10);

% Displaying table pointing out the eow with AP Threshold result.
RR= [AP_mV(:,1),AP_dVdt(:,1)];
SearchingForAPThreshold= table((linspace(1,height(RR),height(RR))'),AP_mV(:,1),AP_dVdt(:,1), 'VariableNames', {'Rows','mV', 'dV/dt'});
SearchingForAPThreshold.Rows = string(SearchingForAPThreshold.Rows);
SearchingForAPThreshold.Rows(idx2) = "AP Threshold"

disp('Finished!');