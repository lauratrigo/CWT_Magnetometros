%% --- Configuração ---
filename = 'vss_magnetometro.csv';  % caminho do arquivo original

%% --- Ler CSV ---
tbl = readtable(filename);

%% --- Converter células vazias para NaN ---
vars = tbl.Properties.VariableNames;  % nomes das colunas

for k = 1:numel(vars)
    col = tbl.(vars{k});
    
    if iscell(col)  % se a coluna é do tipo célula (possível espaço vazio)
        % str2double converte '' ou ' ' para NaN e números válidos para double
        tbl.(vars{k}) = str2double(col);
    end
end

%% --- Salvar arquivo novamente (sobrescrevendo) ---
writetable(tbl, filename);

disp(['Arquivo atualizado e salvo com NaN: ' filename]);
