% ==========================================================================
% FILE: main_day5.m
% MODULE: Velocity Filter Comparison (IIR vs 1D Kalman)
% DESCRIPTION: Compares IIR (alpha=0.15) vs 1D Kalman Filter
%              post-filtering on Hybrid Estimator output.
%              Metrics: RMSE, MAE, Max Error, Phase Delay.
% ==========================================================================

%% ==========================================================================
% 1. ENVIRONMENT SETUP
% ==========================================================================

clear; clc; close all;

current_script_dir = fileparts(mfilename('fullpath'));
project_root_dir = fileparts(current_script_dir);

addpath(fullfile(project_root_dir, 'config'));
addpath(fullfile(project_root_dir, 'models'));
addpath(fullfile(project_root_dir, 'decoder'));

%% ==========================================================================
% 2. PIPELINE SETUP (FROZEN FROM DAY 4)
% ==========================================================================

params = default_params();
rng(params.rng_seed);

[t, theta_true, omega_true] = trajectory_model(params);
[A_ideal, B_ideal, ~] = encoder_model(theta_true, params);
[A_pre_noisy, B_pre_noisy] = inject_micro_noise(A_ideal, B_ideal);
[A_noisy, B_noisy, ~] = inject_pulse_loss(A_pre_noisy, B_pre_noisy, 0.01);

[pos_count, missing_count] = quadrature_decoder_x4(A_noisy, B_noisy);
error_flag = double(missing_count ~= 0);

%% ==========================================================================
% 2. RAW HYBRID ESTIMATION
% ==========================================================================

Ts = t(2) - t(1);
[~, ~, omega_Hybrid] = speed_estimator(pos_count, t, params.PPR, error_flag);

%% ==========================================================================
% 3. FILTER 1: IIR (Baseline, alpha=0.15)
% ==========================================================================

alpha_filter = 0.15;
omega_iir = zeros(size(omega_Hybrid));
omega_iir(1) = omega_Hybrid(1);

for k = 2:length(omega_Hybrid)
    omega_iir(k) = alpha_filter * omega_Hybrid(k) + (1 - alpha_filter) * omega_iir(k-1);
end

%% ==========================================================================
% 4. FILTER 2: 1D KALMAN (Post-Filter)
% ==========================================================================

q_acc = 500;  % Process Noise [rad^2/s^3]
r_var = 1.5;  % Measurement Noise Variance

omega_kf = velocity_kf(omega_Hybrid, Ts, q_acc, r_var);

%% ==========================================================================
% 5. METRICS & DELAY ANALYSIS
% ==========================================================================

err_iir = omega_true(:) - omega_iir(:);
err_kf  = omega_true(:) - omega_kf(:);

delay_iir_samples = finddelay(omega_true(:), omega_iir(:));
delay_kf_samples  = finddelay(omega_true(:), omega_kf(:));
delay_iir_ms = delay_iir_samples * Ts * 1000;
delay_kf_ms  = delay_kf_samples * Ts * 1000;

fprintf('\n==============================================\n');
fprintf('       DAY 5 - VELOCITY FILTER EVALUATION\n');
fprintf('==============================================\n');
fprintf('%-15s | %-12s | %-12s\n', 'Metric', 'IIR (a=0.15)', '1D Kalman');
fprintf('----------------------------------------------\n');
fprintf('%-15s | %12.5f | %12.5f rad/s\n', 'RMSE', sqrt(mean(err_iir.^2)), sqrt(mean(err_kf.^2)));
fprintf('%-15s | %12.5f | %12.5f rad/s\n', 'MAE', mean(abs(err_iir)), mean(abs(err_kf)));
fprintf('%-15s | %12.5f | %12.5f rad/s\n', 'Max Error', max(abs(err_iir)), max(abs(err_kf)));
fprintf('%-15s | %10.3f ms | %10.3f ms\n', 'Phase Delay', delay_iir_ms, delay_kf_ms);
fprintf('==============================================\n');

%% ==========================================================================
% 6. VISUALIZATION
% ==========================================================================

fig5 = figure('Name', 'Day 5: Velocity Filter Comparison', ...
    'Position', [100, 50, 1100, 800]);

% Global Tracking
ax1 = subplot(3,1,1);
plot(t, omega_true, 'g', 'LineWidth', 2, 'DisplayName', 'True'); hold on;
plot(t, omega_Hybrid, 'Color', [0.8 0.8 0.8], 'LineWidth', 1, 'DisplayName', 'Hybrid Raw');
plot(t, omega_iir, 'r--', 'LineWidth', 1.5, 'DisplayName', 'IIR');
plot(t, omega_kf, 'b', 'LineWidth', 1.5, 'DisplayName', 'Kalman 1D');
title('Global Velocity Tracking'); ylabel('rad/s'); legend('Location', 'best'); grid on;

% Zero-Crossing Zoom
ax2 = subplot(3,1,2);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_Hybrid, 'Color', [0.8 0.8 0.8], 'LineWidth', 1);
plot(t, omega_iir, 'r--', 'LineWidth', 1.5);
plot(t, omega_kf, 'b', 'LineWidth', 1.5);
yline(0, 'k-', 'LineWidth', 1.2);
title('Low-Speed & Zero-Crossing Behavior'); ylabel('rad/s');
ylim([-5, 5]); grid on;

% Error Signals
ax3 = subplot(3,1,3);
err_iir = omega_true(:) - omega_iir(:);
err_kf  = omega_true(:) - omega_kf(:);
plot(t, err_iir, 'r--', 'LineWidth', 1.5, 'DisplayName', 'IIR Error'); hold on;
plot(t, err_kf, 'b', 'LineWidth', 1.5, 'DisplayName', 'Kalman Error');
title('Velocity Estimation Error'); xlabel('Time (s)'); ylabel('Error (rad/s)');
legend('Location', 'best'); grid on;

linkaxes([ax1, ax2, ax3], 'x');

%% ==========================================================================
% 7. SAVE FIGURE
% ==========================================================================

result_dir = fullfile(fileparts(mfilename('fullpath')), 'figure');
if ~exist(result_dir, 'dir'), mkdir(result_dir); end
saveas(fig5, fullfile(result_dir, 'day5_velocity_filter_comparison.png'));
fprintf('\n>> Figure saved: %s\n', fullfile(result_dir, 'day5_velocity_filter_comparison.png'));