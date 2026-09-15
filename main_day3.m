% ==========================================================================
% FILE: main_day3.m
% MODULE: Day 3 - X4 Decoder & Speed Estimation
% DESCRIPTION: Runs X4 quadrature decoder with invalid transition
%              detection. Computes M/T/Hybrid speed estimates.
% ==========================================================================

%% ==========================================================================
% 1. ENVIRONMENT SETUP
% ==========================================================================

clear; clc; close all;

addpath('config');
addpath('models');
addpath('decoder');

params = default_params();
rng(params.rng_seed);

%% ==========================================================================
% 2. TRAJECTORY & NOISY ENCODER (INHERITED FROM DAY 1-2)
% ==========================================================================

[t, theta_true, omega_true] = trajectory_model(params);
[A_ideal, B_ideal, Z_ideal] = encoder_model(theta_true, params);

[A_pre_noisy, B_pre_noisy] = inject_micro_noise(A_ideal, B_ideal);
drop_rate = 0.01;
[A_noisy, B_noisy, stats] = inject_pulse_loss(A_pre_noisy, B_pre_noisy, drop_rate);

%% ==========================================================================
% 2. X4 QUADRATURE DECODER
% ==========================================================================

[pos_count, missing_count] = quadrature_decoder_x4(A_noisy, B_noisy);
error_flag = double(missing_count ~= 0);

% Error Statistics
num_errors = sum(error_flag);
error_events = sum(diff([0; error_flag]) == 1);

forward_idx = (t >= 0) & (t < 0.8);
reverse_idx = (t >= 0.8) & (t < 1.8);

forward_events = sum(diff([0; error_flag(forward_idx)]) == 1);
reverse_events = sum(diff([0; error_flag(reverse_idx)]) == 1);

fprintf('\n--- DECODER STATISTICS ---\n');
fprintf('Invalid Transition Samples : %d\n', num_errors);
fprintf('Invalid Transition Events  : %d\n', error_events);
fprintf('  Forward (0-0.8s)         : %d\n', forward_events);
fprintf('  Reverse (0.8-1.8s)       : %d\n', reverse_events);
fprintf('Error Sample Rate          : %.4f %%\n', 100 * num_errors / length(error_flag));
fprintf('------------------------------------------\n');

%% ==========================================================================
% 3. POSITION & SPEED ESTIMATION
% ==========================================================================

theta_estimated = (pos_count * 2*pi) / (params.PPR * 4);
[omega_M, omega_T, omega_Hybrid] = ...
    speed_estimator(pos_count, t, params.PPR, error_flag);

%% ==========================================================================
% 4. VISUALIZATION
% ==========================================================================

% Position & Error Flag
fig1 = figure('Name', 'Day 3: Encoder Fault Analysis & Decoding', ...
    'Position', [100, 100, 900, 650]);

ax1 = subplot(2,1,1);
plot(t, theta_true, 'LineWidth', 2, 'Color', 'g'); hold on;
plot(t, theta_estimated, '--', 'LineWidth', 1.5, 'Color', 'r');
title('True vs Estimated Position (Drift from Noise)');
ylabel('\theta (rad)');
legend('True', 'Estimated', 'Location', 'best'); grid on;

ax2 = subplot(2,1,2);
plot(t, error_flag, 'LineWidth', 1.2, 'Color', 'k');
title('Quadrature Decoder Error Flag');
xlabel('Time (s)'); ylabel('Error');
ylim([-0.2 1.2]); grid on;
linkaxes([ax1, ax2], 'x');

% Speed Estimators
fig2 = figure('Name', 'Day 3: Speed Estimators (M/T/Hybrid)', ...
    'Position', [150, 150, 1000, 600]);

ax3 = subplot(3,1,1);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_M, 'b--', 'LineWidth', 1.5);
title('M-Method (10ms Window - Stable but Lagged)'); ylabel('rad/s'); grid on;

ax4 = subplot(3,1,2);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_T, 'r--', 'LineWidth', 1.5);
title('T-Method (Sensitive at Low Speed, Noisy)'); ylabel('rad/s'); grid on;

ax5 = subplot(3,1,3);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_Hybrid, 'k--', 'LineWidth', 1.5);
title('Hybrid M/T (Adaptive Fusion)'); ylabel('rad/s'); grid on;

linkaxes([ax3, ax4, ax5], 'x');

%% ==========================================================================
% 5. SAVE FIGURES
% ==========================================================================

if ~exist('results/figures', 'dir')
    mkdir('results/figures');
end

saveas(fig1, 'results/figure/day3/position error flag.png');
saveas(fig2, 'results/figure/day3/speed estimation comparison.png');
fprintf('\nFigures saved to results/figure/\n');