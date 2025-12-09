clc; clear; close all;

% Lista de estações
stations = {'ARA', 'CBA', 'CXP', 'EUS', 'SLZ', 'VSS'};

    
% --- Criar pasta 'images' dentro do diretório atual, se não existir
output_dir = fullfile(pwd, 'images');  % pwd retorna o diretório atual do MATLAB
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

for s = 1:length(stations)
    station = stations{s};
    
    % Definir nome do arquivo conforme o padrão correto
    if strcmp(station,'ARA')
        filename = 'arg_magnetometro.csv';
    else
        filename = [lower(station) '_magnetometro.csv'];
    end
    
    if ~isfile(filename)
        warning('Arquivo não encontrado: %s. Pulando esta estação.', filename);
        continue;
    end
    
    disp(['Lendo arquivo ' filename ' ...']);
    tbl = readtable(filename);
    Hour = tbl.Hour(:);
    dH   = tbl.dH(:);

    % --- Criar vetor de tempo completo para 31 dias
    start_time = datetime('01-Aug-2017 00:00','InputFormat','dd-MMM-yyyy HH:mm');
    mag_time = start_time + minutes(0:5:(length(dH)-1)*5);

    % --- Tratar NaNs
    mask_nan = isnan(dH);
    dH_clean = dH;
    dH_clean(mask_nan) = 0;

    % --- Preparar extensão do sinal para CWT
    n = length(dH_clean);
    left2 = flipud(dH_clean);
    sig_ext = [left2; left2; dH_clean; left2; left2];

    fs = 1/300;

    % --- Banco de filtros CWT
    fb = cwtfilterbank('SignalLength', length(sig_ext), ...
                       'SamplingFrequency', fs, ...
                       'FrequencyLimits', [1e-7 1e-4]);

    [cfs, freq] = cwt(sig_ext, 'FilterBank', fb);

    % --- Recortar a parte central
    cfs_central = cfs(:, 2*n+1 : 3*n);

    % --- Período em dias
    period_days = (1 ./ freq) / (60*60*24);
    period_lin = flipud(period_days);

    % --- Matriz para plotagem
    W = abs(cfs_central).^2;
    W(:, mask_nan) = NaN;
    W = flipud(W);

    % --- Plotagem
    figure('Name', ['CWT - (\Delta) ' station], 'NumberTitle', 'off');
    xnum = datenum(mag_time);

    h = pcolor(xnum, log2(period_lin), W ./ max(W(:)));
    set(h, 'EdgeColor', 'none', 'AlphaData', ~isnan(W));
        colormap jet;

        c = colorbar;
        c.Label.FontSize = 16;
        c.FontSize = 16;

        % Ajustar limites e ticks do colorbar
        c.Limits = [0 1];               % define limites de 0 a 1
        c.Ticks = 0.1:0.1:0.9;             % ticks de 0 a 1 a cada 0.1
        c.TickLabels = string(c.Ticks);% labels dos ticks

    ax = gca;

    % Eixo X
    xticks_dates = datetime(2017,8,1):days(2):datetime(2017,8,31);
    ax.XTick = datenum(xticks_dates);
    ax.XTickLabel = datestr(xticks_dates, 'dd');
    ax.XTickLabelRotation = 90;
    ax.XLim = [datenum(datetime(2017,8,1)), datenum(datetime(2017,8,31)) + 1 - eps];

    % Eixo Y
    desired_periods = [0.25 0.5 1 2 4 8 16 31];
    ax.YTick = log2(desired_periods);
    ax.YTickLabel = string(desired_periods);
    ylim(log2([0.25 31]));

    xlabel('Time (days)', 'FontWeight', 'bold');
    ylabel('Period (days)', 'FontWeight', 'bold');
    title(['CWT - \DeltaH - ' station]);

    grid on;
    ax.GridAlpha = 0.3;
    ax.GridColor = [0.5 0.5 0.5];
    ax.GridLineStyle = '-';
    ax.LineWidth = 1.5;
    ax.TickLength = [0.02 0.04];
    ax.FontSize = 16;

saveas(gcf, fullfile(output_dir, [station '.png']));
end
