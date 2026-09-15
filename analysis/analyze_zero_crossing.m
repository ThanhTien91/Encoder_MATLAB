% ==========================================================================
% FILE: analyze_zero_crossing.m
% MODULE: Zero-Crossing Behavior Analysis
% DESCRIPTION: Evaluates estimator behavior at low speed / zero velocity
%              crossing (+10 to -10 rad/s). Metrics computed in 0.8-1.2s window.
% ==========================================================================

%% ==========================================================================
% 1. ENVIRONMENT SETUP
% ==========================================================================

clc; clear; close all;
addpath(fullfile(pwd, 'decoder'));
addpath(fullfile(pwd, 'config'));
addpath(fullfile(pwd, 'models'));
addpath(fullfile(pwd, 'analysis'));

params = default_params();
PPR = params.PPR;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;
Fs = params.Fs;

%% ==========================================================================
% 1. TRAJECTORY GENERATION (ZERO CROSSING)
% ==========================================================================

duration = 2.0;
t = (0:1/Fs:duration)';
omega_true = 10 - 10 * t;  % +10 -> -10 rad/s, Zero at t=1.0s
theta_true = 10 * t - 5 * t.^2;

%% ==========================================================================
% 2. SIGNAL GENERATION & ESTIMATION
% ==========================================================================

pos_count = floor(theta_true / dp_rad);
error_flag = zeros(length(t), 1);

[omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count, t, PPR, error_flag);

%% ==========================================================================
% 3. ZERO-CROSSING REGION ANALYSIS (0.8s - 1.2s)
% ==========================================================================

idx_zc = (t >= 0.8) & (t <= 1.2);
t_zc = t(idx_zc);
omega_true_zc = omega_true(idx_zc);
omega_M_zc = omega_M(idx_zc)';
omega_T_zc = omega_T(idx_zc)';
omega_H_zc = omega_Hybrid(idx_zc)';

mM_zc = compute_metrics(omega_true_zc, omega_M_zc);
mT_zc = compute_metrics(omega_true_zc, omega_T_zc);
mH_zc = compute_metrics(omega_true_zc, omega_H_zc);

fprintf('====================================================================\n');
fprintf('   ZERO-CROSSING ANALYSIS | T = [0.8s, 1.2s]\n');
fprintf('====================================================================\n');
fprintf('| Metric        | M-Method    | T-Method    | Hybrid Fusion |\n');
fprintf('--------------------------------------------------------------------\n');
fprintf('| RMSE (rad/s)  | %-11.4f | %-11.4f | %-13.4f |\n', ...
    mM_zc.rmse, mT_zc.rmse, mH_zc.rmse);
fprintf('| MAE (rad/s)   | %-11.4f | %-11.4f | %-13.4f |\n', ...
    mM_zc.mae, mT_zc.mae, mH_zc.mae);
fprintf('| Max Err (rad/s)| %-11.4f | %-11.4f | %-13.4f |\n', ...
    mM_zc.max_error, mT_zc.max_error, mH_zc.max_error);
fprintf('====================================================================\n');

%% ==========================================================================
% 4. VISUALIZATION (ZOOM ON ZERO REGION)
% ==========================================================================

figure('Name', 'Zero-Crossing Analysis', 'Position', [150, 150, 850, 500], 'Color', 'w');

plot(t, omega_true, 'k--', 'LineWidth', 2, 'DisplayName', 'True Speed'); hold on; grid on;
plot(t, omega_M, 'b-', 'LineWidth', 1.5, 'DisplayName', 'M-Method');
plot(t, omega_T, 'r-.', 'LineWidth', 1.5, 'DisplayName', 'T-Method');
plot(t, omega_Hybrid, 'y-', 'LineWidth', 2.5, 'DisplayName', 'Hybrid Fusion');

xlim([0.8, 1.2]);
ylim([-3, 3]);

xlabel('Time t (s)', 'FontWeight', 'bold');
ylabel('Speed (rad/s)', 'FontWeight', 'bold');
title('Estimator Behavior at Zero-Crossing', 'FontSize', 14);
legend('Location', 'northeast', 'FontSize', 11);
set(gca, 'FontSize', 11);

%% ==========================================================================
% 4. SAVE FIGURE
% ==========================================================================

out_fig_dir = fullfile('..', 'results', 'figure', 'day8');
save_path = fullfile(out_fig_dir, 'zero_crossing.png');
saveas(gcf, save_path);
fprintf('>> Figure saved: %s\n', save_path);