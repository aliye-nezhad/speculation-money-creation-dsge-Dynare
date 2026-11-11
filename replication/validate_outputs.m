% Independently validate all generated IRFs and figures.
% Historical comparisons are limited to the impact values documented in the source note.

script_path = mfilename('fullpath');
repository_root = fileparts(fileparts(script_path));
generated_directory = fullfile(repository_root, 'outputs', 'replication');
historical_file = fullfile(repository_root, 'outputs', 'tables', 'historical_irf_summary.csv');
tolerance_pp = 0.02;

q_values = [0.2, 0.4, 0.6, 0.8];
q_tags = {'q02', 'q04', 'q06', 'q08'};
expected_variables = {
    'A', 'K', 'N', 'M', 'PPI', 'W', 'C', 'R', 'P', 'Y', ...
    'IS', 'IL', 'O', 'T', 'IIP', 'II', 'IP', 'B', 'G', 'IT'
};
expected_irf_columns = strcat(expected_variables, '_EEPSILONIS');
core_irf_names = {'M_EEPSILONIS', 'Y_EEPSILONIS', 'P_EEPSILONIS', 'PPI_EEPSILONIS'};
summary_names = {'impact_M_pct', 'impact_Y_pct', 'impact_P_pct', 'impact_PPI_pct'};
historical_names = {'money_liquidity_response_pct', 'output_response_pct', ...
    'price_response_pct', 'inflation_response_pct'};

summary_file = fullfile(generated_directory, 'irf_impact_summary.csv');
runtime_manifest_file = fullfile(generated_directory, 'runtime_manifest.txt');
environment_manifest_file = fullfile(generated_directory, 'environment_manifest.txt');
source_hash_file = fullfile(generated_directory, 'source_model_sha256.txt');

required_files = {historical_file, summary_file, runtime_manifest_file, ...
    environment_manifest_file, source_hash_file};
for file_index = 1:numel(required_files)
    if exist(required_files{file_index}, 'file') ~= 2
        error('Required reproducibility file is missing: %s', required_files{file_index});
    end
end

historical = readtable(historical_file);
summary = readtable(summary_file);

required_historical = [{'productive_loan_share'}, historical_names];
required_summary = [{'q'}, summary_names];
if ~all(ismember(required_historical, historical.Properties.VariableNames))
    error('Historical summary is missing one or more required columns.');
end
if ~all(ismember(required_summary, summary.Properties.VariableNames))
    error('Generated impact summary is missing one or more required columns.');
end

historical_q = round(historical.productive_loan_share(:) * 10) / 10;
summary_q = round(summary.q(:) * 10) / 10;
if numel(historical_q) ~= 4 || ~isequal(sort(historical_q), q_values(:))
    error('Historical table must contain exactly q = 0.2, 0.4, 0.6, and 0.8.');
end
if numel(summary_q) ~= 4 || ~isequal(sort(summary_q), q_values(:))
    error('Generated summary must contain exactly four unique q cases.');
end

source_hash_lines = readlines(source_hash_file);
source_hash_lines = source_hash_lines(strlength(strtrim(source_hash_lines)) > 0);
if numel(source_hash_lines) ~= 4
    error('Source SHA-256 manifest must contain exactly four model-file hashes.');
end

report_lines = cell(0, 1);
total_series_validated = 0;
total_historical_comparisons = 0;

for model_index = 1:numel(q_values)
    q = q_values(model_index);
    historical_index = find(abs(historical_q - q) < 1e-8);
    summary_index = find(abs(summary_q - q) < 1e-8);
    if numel(historical_index) ~= 1 || numel(summary_index) ~= 1
        error('Expected exactly one historical and generated summary row for q = %.1f.', q);
    end

    irf_file = fullfile(generated_directory, ['irfs_' q_tags{model_index} '.csv']);
    if exist(irf_file, 'file') ~= 2
        error('Missing generated impulse-response file: %s', irf_file);
    end

    irf = readtable(irf_file);
    if height(irf) ~= 40 || width(irf) ~= 21 || ...
            ~ismember('period', irf.Properties.VariableNames)
        error('%s must contain exactly 40 observations and 20 IRF columns.', q_tags{model_index});
    end
    if ~all(ismember(expected_irf_columns, irf.Properties.VariableNames))
        error('%s is missing one or more expected endogenous responses.', q_tags{model_index});
    end

    periods = irf.period(:);
    if any(~isfinite(periods)) || ~isequal(periods, (1:40)')
        error('%s periods must be exactly 1 through 40.', q_tags{model_index});
    end

    % Check all 20 endogenous responses over the complete 40-period horizon.
    for variable_index = 1:numel(expected_irf_columns)
        series_name = expected_irf_columns{variable_index};
        values = irf.(series_name);
        if ~isnumeric(values) || numel(values) ~= 40 || any(~isfinite(values(:)))
            error('%s %s must contain 40 finite numeric observations.', ...
                q_tags{model_index}, series_name);
        end
        total_series_validated = total_series_validated + 1;
    end

    % Independently recompute the four historical period-1 impact responses.
    for series_index = 1:numel(core_irf_names)
        series_name = core_irf_names{series_index};
        values = irf.(series_name);
        impact = values(1) * 100;

        stored_values = summary.(summary_names{series_index});
        stored_impact = stored_values(summary_index);
        if ~isfinite(stored_impact) || abs(impact - stored_impact) > 1e-7
            error('%s %s: runner summary does not match the recomputed period-1 impact.', ...
                q_tags{model_index}, summary_names{series_index});
        end

        historical_values = historical.(historical_names{series_index});
        benchmark = historical_values(historical_index);
        if ~isfinite(benchmark)
            error('Historical benchmark is non-finite for q=%.1f, %s.', q, series_name);
        end

        difference = abs(impact - benchmark);
        report_lines{end + 1, 1} = sprintf( ...
            'q=%.1f %s: period-1 impact=%.4f%%, historical=%.4f%%, difference=%.4f pp', ...
            q, series_name, impact, benchmark, difference); %#ok<SAGROW>

        if difference > tolerance_pp
            error(['Impact-response mismatch for q=%.1f, %s: %.4f%% vs %.4f%% ' ...
                '(tolerance %.4f pp).'], ...
                q, series_name, impact, benchmark, tolerance_pp);
        end
        total_historical_comparisons = total_historical_comparisons + 1;
    end
end

% Validate all eight generated PNG files, including image integrity and dimensions.
figure_directory = fullfile(generated_directory, 'figures');
figure_count = 0;
for model_index = 1:numel(q_tags)
    expected_figures = {
        ['irfs_' q_tags{model_index} '_all_variables.png']
        ['irfs_' q_tags{model_index} '_core_variables.png']
    };

    for figure_index = 1:numel(expected_figures)
        figure_file = fullfile(figure_directory, expected_figures{figure_index});
        if exist(figure_file, 'file') ~= 2
            error('Missing generated figure: %s', figure_file);
        end

        image_info = imfinfo(figure_file);
        if isempty(image_info) || image_info(1).Width < 1000 || image_info(1).Height < 600
            error('Generated figure has invalid or unexpectedly small dimensions: %s', figure_file);
        end
        figure_count = figure_count + 1;
    end
end

report_lines{end + 1, 1} = sprintf( ...
    'PASS: validated %d endogenous IRF series across four calibrations and 40 periods each.', ...
    total_series_validated);
report_lines{end + 1, 1} = sprintf( ...
    'PASS: %d historical impact-response comparisons within %.2f percentage points.', ...
    total_historical_comparisons, tolerance_pp);
report_lines{end + 1, 1} = sprintf( ...
    'PASS: %d generated MATLAB PNG figures exist and pass image-dimension checks.', ...
    figure_count);
report_lines{end + 1, 1} = ...
    'LIMITATION: historical source data provide impact benchmarks, not full 40-period reference paths.';

report_file = fullfile(generated_directory, 'validation_report.txt');
fid = fopen(report_file, 'w');
if fid < 0
    error('Could not create validation report: %s', report_file);
end
for line_index = 1:numel(report_lines)
    fprintf(fid, '%s\n', report_lines{line_index});
end
fclose(fid);

for line_index = 1:numel(report_lines)
    fprintf('%s\n', report_lines{line_index});
end

fprintf('\nSUCCESS: numerical outputs, historical impacts, and generated figures validated.\n');
