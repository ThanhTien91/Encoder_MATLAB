% =========================================================================
% SCRIPT: sensitivity_analysis.m
% MỤC TIÊU: True Monte Carlo Uncertainty Analysis (Jitter Sweep)
% =========================================================================

clc;
clear;
close all;

% =========================================================================
% 1. PATH
% =========================================================================
addpath(fullfile(pwd, '..', 'decoder'));
addpath(fullfile(pwd, '..', 'config'));
addpath(fullfile(pwd, '..', 'models'));
addpath(fullfile(pwd, '..', 'analysis'));

% =========================================================================
% 2. SYSTEM PARAMETERS
% =========================================================================
params = default_params();

PPR = params.PPR;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;

% =========================================================================
% 3. REPRODUCIBILITY
% =========================================================================
rng(params.rng_seed);

% =========================================================================
% 4. MONTE CARLO CONFIGURATION
% =========================================================================
% Không dùng trực tiếp Fs = 1 MHz để giảm RAM/thời gian chạy.
Fs_analysis = 50000;

noise_levels = [0, 0.002, 0.005, 0.01, 0.02, 0.05];

num_levels = length(noise_levels);

N_trials = 100;

duration = 1.0;

t = (0:1/Fs_analysis:duration)';

omega_true = 5;            % rad/s
theta_ideal = omega_true * t;

% Bỏ transient 50 ms đầu
start_idx = max(1, round(0.05 * Fs_analysis));

valid_omega = omega_true * ones(length(t) - start_idx + 1, 1);

% =========================================================================
% 5. NOISE MAPPING
% =========================================================================
% Mapping noise_amp (rad) -> edge-domain noise setting.
%
% Đây là mapping cấp độ mô phỏng dùng để quét độ nhạy,
% không phải phép quy đổi vật lý tuyệt đối giữa rad và sample jitter.

jitter_map = containers.Map( ...
    {0, 0.002, 0.005, 0.01, 0.02, 0.05}, ...
    {[0, 0], [1, 0.05], [1, 0.10], ...
     [2, 0.15], [2, 0.20], [3, 0.25]});

% =========================================================================
% 6. MONTE CARLO RESULTS
% =========================================================================
metrics_MC = struct( ...
    'H_mean', zeros(num_levels,1), ...
    'H_std',  zeros(num_levels,1), ...
    'H_p05',  zeros(num_levels,1), ...
    'H_p50',  zeros(num_levels,1), ...
    'H_p95',  zeros(num_levels,1), ...
    'H_max',  zeros(num_levels,1));

% =========================================================================
% 7. HEADER
% =========================================================================
fprintf('=========================================================================================\n');
fprintf('     TRUE MONTE CARLO EDGE-DOMAIN NOISE SENSITIVITY ANALYSIS\n');
fprintf('     N = %d trials, Fs = %d Hz, omega = %.2f rad/s\n', ...
    N_trials, Fs_analysis, omega_true);
fprintf('=========================================================================================\n');

fprintf('| Noise | Jitter | Bounce | H-Median(P50) | Interval [P05, P95] | H-Mean | H-Std | H-Max |\n');
fprintf('------------------------------------------------------------------------------------------------\n');

% =========================================================================
% 8. MONTE CARLO LOOP
% =========================================================================
for i = 1:num_levels

    noise_amp = noise_levels(i);

    temp_H = zeros(N_trials, 1);

    % Lấy cấu hình noise từ mapping
    map_val = jitter_map(noise_amp);

    jitter_s = map_val(1);
    bounce_p = map_val(2);

    % ---------------------------------------------------------------------
    % Monte Carlo trials
    % ---------------------------------------------------------------------
    for k = 1:N_trials

        % Reproducible seed cho từng noise level + trial
        rng(params.rng_seed + i*1000 + k);

        % ================================================================
        % 1. IDEAL ENCODER
        % ================================================================
        [A_ideal, B_ideal, ~] = encoder_model(theta_ideal, params);

        % ================================================================
        % 2. EDGE-DOMAIN MICRO NOISE
        % ================================================================
        [A_noisy, B_noisy] = inject_micro_noise( ...
            A_ideal, B_ideal, jitter_s, bounce_p);

        % ================================================================
        % 3. X4 DECODER
        % ================================================================
        [pos_count, missing_count] = ...
            quadrature_decoder_x4(A_noisy, B_noisy);

        % Fault flag:
        % chỉ đánh dấu những mẫu có missing transition được phát hiện
        error_flag = double(missing_count ~= 0);

        % ================================================================
        % 4. SPEED ESTIMATION
        % ================================================================
        [~, ~, o_H] = speed_estimator( ...
            pos_count, t, PPR, error_flag);

        % ================================================================
        % 5. QUANTITATIVE METRIC
        % ================================================================
        mH = compute_metrics( ...
            valid_omega, ...
            o_H(start_idx:end)');

        temp_H(k) = mH.rmse;

    end

    % =========================================================================
    % 6. MONTE CARLO STATISTICS
    % =========================================================================
    metrics_MC.H_mean(i) = mean(temp_H);

    metrics_MC.H_std(i) = std(temp_H);

    metrics_MC.H_p05(i) = prctile(temp_H, 5);

    metrics_MC.H_p50(i) = prctile(temp_H, 50);

    metrics_MC.H_p95(i) = prctile(temp_H, 95);

    metrics_MC.H_max(i) = max(temp_H);

    % =========================================================================
    % 7. PRINT RESULT
    % =========================================================================
    fprintf( ...
        '| %-5.3f | %-6d | %-6.2f | %-13.4f | [%.4f, %.4f] | %-6.4f | %-6.4f | %-6.4f |\n', ...
        noise_amp, ...
        jitter_s, ...
        bounce_p, ...
        metrics_MC.H_p50(i), ...
        metrics_MC.H_p05(i), ...
        metrics_MC.H_p95(i), ...
        metrics_MC.H_mean(i), ...
        metrics_MC.H_std(i), ...
        metrics_MC.H_max(i));

end

% =========================================================================
% 8. PLOT
% =========================================================================
figure( ...
    'Name', 'Monte Carlo Jitter', ...
    'Position', [250, 250, 800, 500], ...
    'Color', 'w');

% Median
plot( ...
    noise_levels, ...
    metrics_MC.H_p50, ...
    '-^', ...
    'LineWidth', 2, ...
    'Color', '#EDB120', ...
    'DisplayName', 'Hybrid Median (P50)');

hold on;
grid on;

% Mean +/- Std
errorbar( ...
    noise_levels, ...
    metrics_MC.H_mean, ...
    metrics_MC.H_std, ...
    'k.', ...
    'LineWidth', 1.2, ...
    'DisplayName', 'Mean +/- Std');

xlabel('Noise Level (rad)', 'FontWeight', 'bold');

ylabel('RMSE (rad/s)', 'FontWeight', 'bold');

title( ...
    sprintf('Hybrid Estimator Robustness (%d MC Trials)', N_trials), ...
    'FontSize', 14);

legend('Location', 'northwest');

set(gca, 'FontSize', 11);

% =========================================================================
% 9. SAVE FIGURE
% =========================================================================
out_fig_dir = fullfile('..', 'results', 'figure', 'day8');

if ~exist(out_fig_dir, 'dir')
    mkdir(out_fig_dir);
end

saveas( ...
    gcf, ...
    fullfile(out_fig_dir, 'mc_sensitivity.png'));

fprintf('\nMonte Carlo figure saved to:\n');
fprintf('%s\n', fullfile(out_fig_dir, 'mc_sensitivity.png'));

fprintf('\n=========================================================================================\n');
fprintf('TRUE MONTE CARLO ANALYSIS COMPLETED.\n');
fprintf('=========================================================================================\n');