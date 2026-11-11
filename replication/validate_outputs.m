% Independently validate generated Dynare IRFs against historical impact responses.
% This script checks exported results; it does not alter any DSGE model file.

script_path = mfilename('fullpath');
repository_root = fileparts(fileparts(script_path));
generated_directory = fullfile(repository_root, 'outputs', 'replication');
historical_file = fullfile(repository_root, 'outputs', 'tables', 'historical_irf_summary.csv');
tolerance_pp = 0.02;

q_values = [0.2, 0.4, 0.6, 0.8];
q_tags = {'q02', 'q04', 'q06', 'q08'};
series_names = {'M_EEPSILONIS', 'Y_EEPSILONIS', 'P_EEPSILONIS', 'PPI_EEPSILONIS'};
summary_names = {'impact_M_pct', 'impact_Y_pct', 'impact_P_pct', 'impact_PPI_pct'};
historical_names = {'money_liquidity_response_pct', 'output_response_pct', ...
    'price_response_pct', 'inflation_response_pct'};

summary_file = fullfile(generated_directory, 'irf_impact_summary.csv');
if exist(historical_file, 'file') ~= 2
    error('Missing historical benchmark file: %s', historical_file);
end
if exist(summary_file, 'file') ~= 2
    error('Missing generated impact summary: %s', summary_file);
end

historical = readtable(historical_file);
summary = readtable(summary_file);

required_historical = [{'productive_loan_share'}, historical_names];
required_summary = [{'q'}, summary_names};
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

report_lines = cell(0, 1);
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
    if height(irf) ~= 40 || ~ismember('period', irf.Properties.VariableNames)
        error('%s must contain exactly 40 observations and a period column.', q_tags{model_index});
    end
    periods = irf.period(:);
    if any(~isfinite(periods)) || ~isequal(periods, (1:40)')
        error('%s periods must be exactly 1 through 40.', q_tags{model_index});
    end

    for series_index = 1:numel(series_names)
        series_name = series_names{series_index};
        if ~ismember(series_name, irf.Properties.VariableNames)
            error('%s is missing required IRF series %s.', q_tags{model_index}, series_name);
        end

        values = irf.(series_name);
        if ~isnumeric(values) || numel(values) ~= 40 || any(~isfinite(values(:)))
            error('%s %s must contain 40 finite numeric observations.', q_tags{model_index}, series_name);
        end

        impact = values(1) * 100;
        stored_values = summary.(summary_names{series_index});
        stored_impact = stored_values(summary_index);
        if ~isfinite(stored_impact) || abs(impact - stored_impact) > 1e-7
            error('%s %s: runner summary does not match the recomputed period-1 impact.', ...
                q_tags{model_index}, summary_names{series_index});
        end

        historical_values = historical.(historical_names{series_index});
        benchmark = historical_values(historical_index);
        difference = abs(impact - benchmark);
        report_lines{end + 1, 1} = sprintf( ...
            'q=%.1f %s: period-1 impact=%.4f%%, historical=%.4f%%, difference=%.4f pp', ...
            q, series_name, impact, benchmark, difference); %#ok<SAGROW>

        if difference > tolerance_pp
            error(['Impact-response mismatch for q=%.1f, %s: %.4f%% vs %.4f%% ' ...
                '(tolerance %.4f pp).'], ...
                q, series_name, impact, benchmark, tolerance_pp);
        end
    end
end

report_lines{end + 1, 1} = sprintf( ...
    ['PASS: four calibrations; four finite 40-period IRFs per case; ' ...
    'runner summaries independently checked; historical period-1 impact ' ...
    'responses within %.2f percentage points.'], tolerance_pp);

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
