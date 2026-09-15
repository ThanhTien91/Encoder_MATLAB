% ==========================================================================
% FILE: analyze_scenarios.m
% MODULE: Scenario Post-Processing & CSV Export
% DESCRIPTION: Loads scenario_results.mat, computes comprehensive
%              metrics (Position + M/T/Hybrid Speed), exports CSV.
% ==========================================================================

%% ==========================================================================
% 1. DATA LOADING
% ==========================================================================

clc; clear; close all;

data_file = fullfile('..', 'results', 'scenario_results.mat');
if ~exist(data_file, 'file')
    error('scenario_results.mat not found. Run Day 7 first!');
end
load(data_file, 'scenario_data');

%% ==========================================================================
% 2. OUTPUT SETUP
% ==========================================================================

out_dir = fullfile('..', 'results', 'tables');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

scenarios = fieldnames(scenario_data);
num_scenarios = length(scenarios);

csv_data = cell(num_scenarios + 1, 6);
csv_data(1, :) = {'Scenario_Name', 'Position_RMSE', 'Speed_M_RMSE', ...
    'Speed_T_RMSE', 'Speed_Hybrid_RMSE', 'Delay_Approx'};

fprintf('==========================================================================================\n');
fprintf('                      SCENARIO METRICS SUMMARY (DAY 8)\n');
fprintf('==========================================================================================\n');
fprintf('| %-18s | %-12s | %-12s | %-12s | %-15s |\n', ...
    'Scenario', 'Pos RMSE', 'M RMSE', 'T RMSE', 'Hybrid RMSE');
fprintf('------------------------------------------------------------------------------------------\n');

%% ==========================================================================
% 3. METRICS COMPUTATION LOOP
% ==========================================================================

for i = 1:num_scenarios
    s_name = scenarios{i};
    data = scenario_data.(s_name);

    % Position Metrics
    m_pos = compute_metrics(data.position.true, data.position.est);

    % Speed Metrics (M / T / Hybrid)
    m_speed_M = compute_metrics(data.speed.true, data.speed.M);
    m_speed_T = compute_metrics(data.speed.true, data.speed.T);
    m_speed_H = compute_metrics(data.speed.true, data.speed.Hybrid);

    % Console Output
    fprintf('| %-18s | %-12.4f | %-12.4f | %-12.4f | %-15.4f |\n', ...
        data.name, m_pos.rmse, m_speed_M.rmse, m_speed_T.rmse, m_speed_H.rmse);

    % CSV Data
    csv_data(i+1, :) = {data.name, m_pos.rmse, m_speed_M.rmse, ...
        m_speed_T.rmse, m_speed_H.rmse, 'N/A'};
end
fprintf('==========================================================================================\n');

%% ==========================================================================
% 4. CSV EXPORT
% ==========================================================================

csv_path = fullfile(out_dir, 'scenario_summary.csv');
if exist('writecell', 'file') == 2 || exist('writecell', 'builtin')
    writecell(csv_data, csv_path);
else
    fid = fopen(csv_path, 'w');
    for r = 1:size(csv_data, 1)
        row_str = cellfun(@(x) num2str(x), csv_data(r,:), 'UniformOutput', false);
        fprintf(fid, '%s\n', strjoin(row_str, ','));
    end
    fclose(fid);
end
fprintf('>> CSV exported: %s\n', csv_path);