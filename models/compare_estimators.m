% ==========================================================================
% FILE: compare_estimators.m
% MODULE: Speed Estimator Comparison (Speed Sweep)
% DESCRIPTION: Compares M-Method, T-Method, and Hybrid Fusion RMSE
%              across speed range 0.5-100 rad/s (log-log scale).
% ==========================================================================

%% ==========================================================================
% 1. ENVIRONMENT SETUP
% ==========================================================================

clc; clear; close all;

addpath(fullfile(pwd, 'decoder'));
addpath(fullfile(pwd, 'config'));
addpath(fullfile(pwd, 'models'));
addpath(fullfile(pwd, 'analysis'));

%% ==========================================================================
% 2. SYSTEM PARAMETERS
% ==========================================================================

params = default_params();
PPR = params.PPR;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;
Fs = params.Fs;

duration = 1.0;
t = (0:1/Fs:duration)';
N_samples = length(t);

speed_list = [0.5, 1, 2, 5, 10, 20, 50, 100];
num_speeds = length(speed_list);

rmse_M = zeros(num_speeds, 1);
rmse_T = zeros(num_speeds, 1);
rmse_H = zeros(num_speeds, 1);

fprintf('====================================================================\n');
fprintf('     M / T / HYBRID ESTIMATOR COMPARISON (SPEED SWEEP)\n');
fprintf('====================================================================\n');
fprintf('| Speed (rad/s) | M-Method RMSE | T-Method RMSE | Hybrid RMSE  |\n');
fprintf('--------------------------------------------------------------------\n');

%% ==========================================================================
% 3. SPEED SWEEP LOOP
% ==========================================================================

for i = 1:num_speeds
    omega_true = speed_list(i);
    theta_true = omega_true * t;
    
    % Ideal Signal + Quantization Noise Only
    pos_count = floor(theta_true / dp_rad);
    error_flag = zeros(N_samples, 1);
    
    [omega_M, omega_T, omega_Hybrid] = ...
        speed_estimator(pos_count, t, PPR, error_flag);
    
    % Remove Transient (50 ms)
    start_idx = round(0.05 * Fs);
    if start_idx < 1, start_idx = 1; end
    
    valid_omega = omega_true * ones(N_samples - start_idx + 1, 1);
    
    mM = compute_metrics(valid_omega, omega_M(start_idx:end)');
    mT = compute_metrics(valid_omega, omega_T(start_idx:end)');
    mH = compute_metrics(valid_omega, omega_Hybrid(start_idx:end)');
    
    rmse_M(i) = mM.rmse;
    rmse_T(i) = mT.rmse;
    rmse_H(i) = mH.rmse;
    
    fprintf('| %-13.1f | %-13.4f | %-13.4f | %-12.4f |\n', ...
        omega_true, rmse_M(i), rmse_T(i), rmse_H(i));
end
fprintf('====================================================================\n');

%% ==========================================================================
% 4. VISUALIZATION
% ==========================================================================

figure('Name', 'RMSE vs Speed', 'Position', [150, 150, 850, 500], 'Color', 'w');

loglog(speed_list, rmse_M, '-o', 'LineWidth', 2, 'MarkerSize', 6, ...
    'DisplayName', 'M-Method'); hold on; grid on;
loglog(speed_list, rmse_T, '-s', 'LineWidth', 2, 'MarkerSize', 6, ...
    'DisplayName', 'T-Method');
loglog(speed_list, rmse_H, '-^', 'LineWidth', 2, 'MarkerSize', 7, ...
    'DisplayName', 'Hybrid Fusion');

xlabel('True Speed (rad/s) [Log Scale]', 'FontWeight', 'bold');
ylabel('RMSE (rad/s) [Log Scale]', 'FontWeight', 'bold');
title('Velocity Estimator RMSE vs Speed (Log-Log)', 'FontSize', 14);
legend('Location', 'northwest', 'FontSize', 11);
set(gca, 'FontSize', 11);
ylim([1e-4, 200]);

%% ==========================================================================
% 5. SAVE ARTIFACTS
% ==========================================================================

out_fig_dir = fullfile('..', 'results', 'figure', 'day8');
if ~exist(out_fig_dir, 'dir'), mkdir(out_fig_dir); end
saveas(gcf, fullfile(out_fig_dir, 'rmse vs speed.png'));
fprintf('>> Figure saved: %s\n', fullfile(out_fig_dir, 'rmse vs speed.png'));