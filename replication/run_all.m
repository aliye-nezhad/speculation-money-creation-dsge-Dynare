% Run all four historical loan-allocation calibrations and export IRFs.
% Run from the repository root, or call this script by its full path.

script_path = mfilename('fullpath');
repository_root = fileparts(fileparts(script_path));
models_directory = fullfile(repository_root, 'models');
outputs_directory = fullfile(repository_root, 'outputs', 'replication');
original_directory = pwd;

if exist(outputs_directory, 'dir') ~= 7
    mkdir(outputs_directory);
end

model_files = {
    'speculation_money_creation_q02.mod'
    'speculation_money_creation_q04.mod'
    'speculation_money_creation_q06.mod'
    'speculation_money_creation_q08.mod'
};
q_values = [0.2, 0.4, 0.6, 0.8];
irf_names = {'M_EEPSILONIS', 'Y_EEPSILONIS', 'P_EEPSILONIS', 'PPI_EEPSILONIS'};
irf_horizon = 40;

summary_file = fullfile(outputs_directory, 'irf_impact_summary.csv');
summary_fid = fopen(summary_file, 'w');
if summary_fid < 0
    error('Could not create %s', summary_file);
end
fprintf(summary_fid, 'q,impact_M_pct,impact_Y_pct,impact_P_pct,impact_PPI_pct\n');
fclose(summary_fid);

% Delete prior CSVs so failed runs cannot leave stale files that look current.
stale_files = dir(fullfile(outputs_directory, 'irfs_q*.csv'));
for k = 1:numel(stale_files)
    delete(fullfile(outputs_directory, stale_files(k).name));
end

try
    cd(models_directory);

    for model_index = 1:numel(model_files)
        model_file = model_files{model_index};
        fprintf('\n===== Running %s =====\n', model_file);

        % noclearall preserves this runner's loop variables between Dynare calls.
        dynare(model_file, 'noclearall');

        if ~exist('M_', 'var') || M_.endo_nbr ~= 20 || M_.eq_nbr ~= 20
            error('%s: expected 20 endogenous variables and 20 model equations.', model_file);
        end
        if ~exist('oo_', 'var') || ~isfield(oo_, 'steady_state') || ...
                any(~isfinite(oo_.steady_state(:)))
            error('%s: steady-state output is missing or non-finite.', model_file);
        end
        if ~isfield(oo_, 'dr') || ~isfield(oo_.dr, 'eigval') || ...
                isempty(oo_.dr.eigval) || any(~isfinite(oo_.dr.eigval(:)))
            error('%s: decision-rule eigenvalues are missing or non-finite.', model_file);
        end
        if ~isfield(oo_, 'irfs')
            error('%s: Dynare did not produce impulse responses.', model_file);
        end

        irf_matrix = zeros(irf_horizon, numel(irf_names));
        impact_pct = zeros(1, numel(irf_names));

        for j = 1:numel(irf_names)
            name = irf_names{j};
            if ~isfield(oo_.irfs, name)
                error('%s: required IRF %s is missing.', model_file, name);
            end
            response = oo_.irfs.(name);
            response = response(:);

            if numel(response) ~= irf_horizon || any(~isfinite(response))
                error('%s: IRF %s must have %d finite observations.', ...
                    model_file, name, irf_horizon);
            end

            irf_matrix(:, j) = response;
            % Historical source figures are first-period impact responses.
            impact_pct(j) = response(1) * 100;
        end

        q_tag = sprintf('q%02d', round(10 * q_values(model_index)));
        irf_file = fullfile(outputs_directory, ['irfs_' q_tag '.csv']);
        fid = fopen(irf_file, 'w');
        if fid < 0
            error('Could not create %s', irf_file);
        end
        fprintf(fid, 'period,M_EEPSILONIS,Y_EEPSILONIS,P_EEPSILONIS,PPI_EEPSILONIS\n');
        fclose(fid);
        dlmwrite(irf_file, [(1:irf_horizon)', irf_matrix], ...
            '-append', 'delimiter', ',', 'precision', '%.12g');

        fid = fopen(summary_file, 'a');
        if fid < 0
            error('Could not append %s', summary_file);
        end
        fprintf(fid, '%.1f,%.10f,%.10f,%.10f,%.10f\n', ...
            q_values(model_index), impact_pct(1), impact_pct(2), impact_pct(3), impact_pct(4));
        fclose(fid);

        fprintf('PASS: q=%.1f, 20 equations, finite steady state, and four 40-period IRFs.\n', ...
            q_values(model_index));
    end

    manifest_file = fullfile(outputs_directory, 'runtime_manifest.txt');
    fid = fopen(manifest_file, 'w');
    if fid >= 0
        fprintf(fid, 'Runtime: %s\n', version);
        if exist('dynare_version', 'file') == 2
            fprintf(fid, 'Dynare: %s\n', dynare_version());
        end
        fprintf(fid, 'Calibrations: q=0.2, 0.4, 0.6, 0.8\n');
        fprintf(fid, 'IRF horizon: %d periods\n', irf_horizon);
        fprintf(fid, 'Random seed: 12345 (specified in each model file)\n');
        fclose(fid);
    end

    cd(original_directory);
catch model_error
    cd(original_directory);
    rethrow(model_error);
end

fprintf('\nSUCCESS: all four model calibrations completed.\n');
