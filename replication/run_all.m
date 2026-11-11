% Run all four historical loan-allocation calibrations and export every IRF.
% The committed DSGE model files are never edited by this runner.
% Dynare 6 compatibility is applied only to disposable runtime copies in MATLAB.

script_path = mfilename('fullpath');
repository_root = fileparts(fileparts(script_path));
models_directory = fullfile(repository_root, 'models');
outputs_directory = fullfile(repository_root, 'outputs', 'replication');
runtime_directory = fullfile(outputs_directory, 'runtime_workspace');
figure_directory = fullfile(outputs_directory, 'figures');
original_directory = pwd;

if exist(outputs_directory, 'dir') ~= 7
    mkdir(outputs_directory);
end

% Remove status and generated data from earlier executions. A failed run must
% never leave stale files that could be mistaken for current successful output.
stale_status_files = {
    'runtime_manifest.txt'
    'environment_manifest.txt'
    'source_model_sha256.txt'
    'validation_report.txt'
    'irf_impact_summary.csv'
};
for k = 1:numel(stale_status_files)
    stale_path = fullfile(outputs_directory, stale_status_files{k});
    if exist(stale_path, 'file') == 2
        delete(stale_path);
    end
end

stale_irf_files = dir(fullfile(outputs_directory, 'irfs_q*.csv'));
for k = 1:numel(stale_irf_files)
    delete(fullfile(outputs_directory, stale_irf_files(k).name));
end

if exist(figure_directory, 'dir') == 7
    rmdir(figure_directory, 's');
end

% Recreate the disposable runtime workspace to prevent stale Dynare output.
if exist(runtime_directory, 'dir') == 7
    rmdir(runtime_directory, 's');
end
[workspace_created, workspace_message] = mkdir(runtime_directory);
if ~workspace_created
    error('Could not create runtime workspace: %s', workspace_message);
end

model_files = {
    'speculation_money_creation_q02.mod'
    'speculation_money_creation_q04.mod'
    'speculation_money_creation_q06.mod'
    'speculation_money_creation_q08.mod'
};
q_values = [0.2, 0.4, 0.6, 0.8];
core_irf_names = {'M_EEPSILONIS', 'Y_EEPSILONIS', 'P_EEPSILONIS', 'PPI_EEPSILONIS'};
expected_endogenous_names = {
    'A', 'K', 'N', 'M', 'PPI', 'W', 'C', 'R', 'P', 'Y', ...
    'IS', 'IL', 'O', 'T', 'IIP', 'II', 'IP', 'B', 'G', 'IT'
};
expected_irf_names = strcat(expected_endogenous_names, '_EEPSILONIS');
irf_horizon = 40;

% Create runtime copies. The sole compatibility edit is to a diagnostic
% command removed from the Dynare 6 parser. No economic model statement,
% parameter, shock, or simulation option is edited.
legacy_diagnostic = 'resid(1);';
runtime_diagnostic = 'resid;';
source_manifest = fullfile(runtime_directory, 'RUNTIME_SOURCE_README.txt');
manifest_fid = fopen(source_manifest, 'w');
if manifest_fid < 0
    error('Could not create %s', source_manifest);
end
fprintf(manifest_fid, 'Disposable Dynare runtime copies\n');
fprintf(manifest_fid, '=================================\n');
fprintf(manifest_fid, 'Original committed files in models/ are not modified.\n');
fprintf(manifest_fid, 'For Dynare 6 parser compatibility only, each runtime copy replaces\n');
fprintf(manifest_fid, 'the diagnostic command resid(1); with resid;.\n');
fprintf(manifest_fid, 'No model equation, calibration, shock specification, or simulation\n');
fprintf(manifest_fid, 'setting is changed by this compatibility step.\n');
fclose(manifest_fid);

for model_index = 1:numel(model_files)
    model_file = model_files{model_index};
    source_file = fullfile(models_directory, model_file);
    runtime_file = fullfile(runtime_directory, model_file);
    source_text = fileread(source_file);
    diagnostic_positions = strfind(source_text, legacy_diagnostic);

    % Fail closed if the expected legacy diagnostic is absent or ambiguous.
    if numel(diagnostic_positions) ~= 1
        error('%s: expected exactly one legacy diagnostic command; found %d.', ...
            model_file, numel(diagnostic_positions));
    end

    runtime_text = strrep(source_text, legacy_diagnostic, runtime_diagnostic);
    if strcmp(runtime_text, source_text)
        error('%s: runtime compatibility substitution was not applied.', model_file);
    end

    fid = fopen(runtime_file, 'w');
    if fid < 0
        error('Could not create runtime copy %s', runtime_file);
    end
    fprintf(fid, '%s', runtime_text);
    fclose(fid);
end

summary_file = fullfile(outputs_directory, 'irf_impact_summary.csv');
summary_fid = fopen(summary_file, 'w');
if summary_fid < 0
    error('Could not create %s', summary_file);
end
fprintf(summary_fid, 'q,impact_M_pct,impact_Y_pct,impact_P_pct,impact_PPI_pct\n');
fclose(summary_fid);

try
    cd(runtime_directory);

    for model_index = 1:numel(model_files)
        model_file = model_files{model_index};
        fprintf('\n===== Running runtime copy of %s =====\n', model_file);

        % noclearall preserves this runner's loop variables between Dynare calls.
        dynare(model_file, 'noclearall');

        if ~exist('M_', 'var') || M_.endo_nbr ~= 20 || M_.eq_nbr ~= 20 || M_.exo_nbr ~= 2
            error('%s: expected 20 endogenous variables, 20 equations, and 2 shocks.', model_file);
        end
        if ~exist('oo_', 'var') || ~isfield(oo_, 'steady_state') || ...
                any(~isfinite(oo_.steady_state(:)))
            error('%s: steady-state output is missing or non-finite.', model_file);
        end
        if ~isfield(oo_, 'dr') || ~isfield(oo_.dr, 'eigval') || ...
                isempty(oo_.dr.eigval) || any(isnan(oo_.dr.eigval(:))) || ...
                ~any(isfinite(oo_.dr.eigval(:)))
            error('%s: decision-rule eigenvalues are missing or contain NaN values.', model_file);
        end
        % Infinite generalized eigenvalues can be valid when the denominator
        % of the generalized Schur pair is zero. Check the solved decision
        % rule itself for finite values instead of rejecting those roots.
        if ~isfield(oo_.dr, 'ghx') || ~isfield(oo_.dr, 'ghu') || ...
                any(~isfinite(oo_.dr.ghx(:))) || any(~isfinite(oo_.dr.ghu(:)))
            error('%s: decision-rule matrices are missing or non-finite.', model_file);
        end
        if ~isfield(oo_, 'irfs')
            error('%s: Dynare did not produce impulse responses.', model_file);
        end

        % Export all 20 endogenous responses to the speculative-return shock,
        % not just the four series used in the historical impact table.
        response_fields = fieldnames(oo_.irfs);
        response_fields = response_fields(endsWith(response_fields, '_EEPSILONIS'));
        response_fields = sort(response_fields);

        if numel(response_fields) ~= M_.endo_nbr || ...
                ~isequal(response_fields(:), sort(expected_irf_names(:)))
            error('%s: expected exactly the 20 endogenous EEPSILONIS responses.', model_file);
        end

        irf_matrix = zeros(irf_horizon, numel(response_fields));
        for j = 1:numel(response_fields)
            name = response_fields{j};
            response = oo_.irfs.(name);
            response = response(:);

            if numel(response) ~= irf_horizon || any(~isfinite(response))
                error('%s: IRF %s must have %d finite observations.', ...
                    model_file, name, irf_horizon);
            end

            irf_matrix(:, j) = response;
        end

        impact_pct = zeros(1, numel(core_irf_names));
        for j = 1:numel(core_irf_names)
            column_index = find(strcmp(response_fields, core_irf_names{j}), 1);
            if isempty(column_index)
                error('%s: required historical series %s is missing.', ...
                    model_file, core_irf_names{j});
            end
            % Historical source table reports first-period impact responses.
            impact_pct(j) = irf_matrix(1, column_index) * 100;
        end

        q_tag = sprintf('q%02d', round(10 * q_values(model_index)));
        irf_file = fullfile(outputs_directory, ['irfs_' q_tag '.csv']);
        fid = fopen(irf_file, 'w');
        if fid < 0
            error('Could not create %s', irf_file);
        end
        fprintf(fid, 'period');
        for j = 1:numel(response_fields)
            fprintf(fid, ',%s', response_fields{j});
        end
        fprintf(fid, '\n');
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

        fprintf(['PASS: q=%.1f, 20 equations, finite steady state, finite decision rules, ' ...
            'and 20 finite 40-period IRFs.\n'], q_values(model_index));
    end

    manifest_file = fullfile(outputs_directory, 'runtime_manifest.txt');
    fid = fopen(manifest_file, 'w');
    if fid < 0
        error('Could not create runtime manifest: %s', manifest_file);
    end

    dynare_version_text = getenv('DYNARE_VERSION');
    if exist('dynare_version', 'file') == 2
        try
            dynare_version_text = char(string(dynare_version()));
        catch
            % The pinned toolbox version remains recorded if this helper is absent.
        end
    end

    fprintf(fid, 'MATLAB version: %s\n', version);
    fprintf(fid, 'MATLAB release: %s\n', version('-release'));
    fprintf(fid, 'MATLAB platform: %s\n', computer);
    fprintf(fid, 'Dynare version: %s\n', dynare_version_text);
    fprintf(fid, 'Dynare MATLAB toolbox URL: %s\n', getenv('DYNARE_MLTBX_URL'));
    fprintf(fid, 'Dynare MATLAB toolbox SHA-256: %s\n', getenv('DYNARE_MLTBX_SHA256'));
    fprintf(fid, 'Git source commit: %s\n', getenv('GITHUB_SHA'));
    fprintf(fid, 'Runner OS: %s\n', getenv('RUNNER_OS'));
    fprintf(fid, 'Runner image: %s %s\n', getenv('ImageOS'), getenv('ImageVersion'));
    fprintf(fid, 'System C++ runtime preloaded: %s\n', getenv('SYSTEM_LIBSTDCXX'));
    fprintf(fid, 'Calibrations: q=0.2, 0.4, 0.6, 0.8\n');
    fprintf(fid, 'Endogenous responses exported per calibration: 20\n');
    fprintf(fid, 'IRF horizon: %d periods\n', irf_horizon);
    fprintf(fid, 'Simulation periods: 5000\n');
    fprintf(fid, 'Random seed: 12345 (specified in original model files)\n');
    fprintf(fid, 'Committed DSGE source files: unchanged and checked by Git blob IDs\n');
    fprintf(fid, 'Runtime-only diagnostic compatibility: resid(1); -> resid;\n');
    fprintf(fid, 'Octave: not installed; MATLAB is the only model execution engine\n');
    fprintf(fid, 'Project Python code: none; no Python command is used by the replication workflow\n');
    fclose(fid);

    cd(original_directory);
catch model_error
    cd(original_directory);
    rethrow(model_error);
end

fprintf('\nSUCCESS: all four model calibrations completed.\n');
