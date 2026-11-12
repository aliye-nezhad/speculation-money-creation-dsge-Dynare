% Plot the 40-period impulse responses for each calibration.

script_path = mfilename('fullpath');
repository_root = fileparts(fileparts(script_path));
generated_directory = fullfile(repository_root, 'outputs', 'replication');
figure_directory = fullfile(generated_directory, 'figures');

q_values = [0.2, 0.4, 0.6, 0.8];
q_tags = {'q02', 'q04', 'q06', 'q08'};
expected_variables = {
    'A', 'K', 'N', 'M', 'PPI', 'W', 'C', 'R', 'P', 'Y', ...
    'IS', 'IL', 'O', 'T', 'IIP', 'II', 'IP', 'B', 'G', 'IT'
};
core_variables = {'M', 'Y', 'P', 'PPI'};

if exist(figure_directory, 'dir') == 7
    rmdir(figure_directory, 's');
end
[figures_created, figures_message] = mkdir(figure_directory);
if ~figures_created
    error('Could not create figure directory: %s', figures_message);
end

for model_index = 1:numel(q_values)
    q_tag = q_tags{model_index};
    irf_file = fullfile(generated_directory, ['irfs_' q_tag '.csv']);
    if exist(irf_file, 'file') ~= 2
        error('Missing IRF input for plotting: %s', irf_file);
    end

    irf = readtable(irf_file);
    if height(irf) ~= 40 || ~ismember('period', irf.Properties.VariableNames)
        error('%s must contain exactly 40 periods.', q_tag);
    end

    expected_columns = strcat(expected_variables, '_EEPSILONIS');
    if width(irf) ~= 21 || ~all(ismember(expected_columns, irf.Properties.VariableNames))
        error('%s must contain all 20 endogenous responses and the period column.', q_tag);
    end

    periods = irf.period(:);

    % Plot all 20 variables in model declaration order.
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [80, 80, 1800, 1100]);
    layout = tiledlayout(fig, 4, 5, 'TileSpacing', 'compact', 'Padding', 'compact');

    for variable_index = 1:numel(expected_variables)
        variable_name = expected_variables{variable_index};
        series_name = [variable_name '_EEPSILONIS'];
        response = irf.(series_name);

        if ~isnumeric(response) || numel(response) ~= 40 || any(~isfinite(response))
            close(fig);
            error('%s %s is not a finite 40-period response.', q_tag, series_name);
        end

        ax = nexttile(layout);
        plot(ax, periods, 100 .* response(:), 'LineWidth', 1.4);
        yline(ax, 0, ':');
        grid(ax, 'on');
        box(ax, 'on');
        title(ax, variable_name, 'Interpreter', 'none');
        xlabel(ax, 'Periods');
        ylabel(ax, '% deviation');
        set(ax, 'FontSize', 9);
    end

    title(layout, sprintf( ...
        'All endogenous responses to the speculative-return shock (q = %.1f)', ...
        q_values(model_index)));
    drawnow;
    all_variables_file = fullfile(figure_directory, ...
        ['irfs_' q_tag '_all_variables.png']);
    exportgraphics(fig, all_variables_file, 'Resolution', 200);
    close(fig);

    % Plot the four variables in the historical impact table.
    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100, 100, 1400, 900]);
    layout = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    for variable_index = 1:numel(core_variables)
        variable_name = core_variables{variable_index};
        series_name = [variable_name '_EEPSILONIS'];
        response = irf.(series_name);

        ax = nexttile(layout);
        plot(ax, periods, 100 .* response(:), 'LineWidth', 1.8);
        yline(ax, 0, ':');
        grid(ax, 'on');
        box(ax, 'on');
        title(ax, variable_name, 'Interpreter', 'none');
        xlabel(ax, 'Periods');
        ylabel(ax, '% deviation');
    end

    title(layout, sprintf( ...
        'Core monetary and real responses to the speculative-return shock (q = %.1f)', ...
        q_values(model_index)));
    drawnow;
    core_file = fullfile(figure_directory, ...
        ['irfs_' q_tag '_core_variables.png']);
    exportgraphics(fig, core_file, 'Resolution', 200);
    close(fig);

    fprintf('Saved two figures for q = %.1f.\n', q_values(model_index));
end
