% Run all four historical loan-allocation calibrations and export IRFs.
% The committed DSGE model files are never edited by this runner.
% Dynare 6 compatibility is applied only to disposable runtime copies in MATLAB.

script_path = mfilename('fullpath');
repository_root = fileparts(fileparts(script_path));
models_directory = fullfile(repository_root, 'models');
outputs_directory = fullfile(repository_root, 'outputs', 'replication');
runtime_directory = fullfile(outputs_directory, 'runtime_workspace');
original_directory = pwd;

if exist(outputs_directory, 'dir') ~= 7
    mkdir(outputs_directory);
end

% Remove status files from earlier executions so a failed run cannot leave
% an old success manifest or validation report looking current.
stale_status_files = {'runtime_manifest.txt', 'validation_report.txt'};
for k = 1:numel(stale_status_files)
    stale_path = fullfile(outputs_directory, stale_status_files{k});
    if exist(stale_path, 'file') == 2
        delete(stale_path);
    end
end

% Recreate the disposable runtime workspace to prevent stale model output.
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
irf_names = {'M_EEPSILONIS', 'Y_EEPSILONIS', 'P_EEPSILONIS', 'PPI_EEPSILONIS'};
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

% Delete prior IRFs so failed runs cannot leave stale files that look current.
stale_files = dir(fullfile(outputs_directory, 'irfs_q*.csv'));
for k = 1:numel(stale_files)
    delete(fullfile(outputs_directory, stale_files(k).name));
end

try
    cd(runtime_directory);

    for model_index = 1:numel(model_files)
        model_file = model_files{model_index};
        fprintf('\n===== Running runtime copy of %s =====\n', model_file);

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
            % Historical source figures report first-period impact responses.
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
        fprintf(fid, 'MATLAB version: %s\n', version);
        fprintf(fid, 'MATLAB release: %s\n', version('-release'));
        if exist('dynare_version', 'file') == 2
            fprintf(fid, 'Dynare: %s\n', dynare_version());
        end
        system_libstdcxx = getenv('SYSTEM_LIBSTDCXX');
        if ~isempty(system_libstdcxx)
            fprintf(fid, 'Preloaded system C++ runtime: %s\n', system_libstdcxx);
        end
        fprintf(fid, 'Calibrations: q=0.2, 0.4, 0.6, 0.8\n');
        fprintf(fid, 'IRF horizon: %d periods\n', irf_horizon);
        fprintf(fid, 'Random seed: 12345 (specified in original model files)\n');
        fprintf(fid, 'Committed DSGE source files: unchanged\n');
        fprintf(fid, 'Runtime-only diagnostic compatibility: resid(1); -> resid;\n');
        fclose(fid);
    end

    cd(original_directory);
catch model_error
    cd(original_directory);
    rethrow(model_error);
end

fprintf('\nSUCCESS: all four model calibrations completed.\n');
