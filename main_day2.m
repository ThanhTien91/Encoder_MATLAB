% ==========================================================================
% FILE: main_day2.m
% MODULE: Day 2 - Noise Injection & Fault Modeling
% DESCRIPTION: Injects micro-noise (jitter/bounce/phase) and pulse
%              loss into ideal encoder signals. Visualizes ideal vs noisy.
% ==========================================================================

%% ==========================================================================
% 1. ENVIRONMENT SETUP
% ==========================================================================

clear; clc; close all;

addpath('config');
addpath('models');

params = default_params();
rng(params.rng_seed);

%% ==========================================================================
% 2. IDEAL TRAJECTORY & ENCODER
% ==========================================================================

[t, theta_true, omega_true] = trajectory_model(params);
[A_ideal, B_ideal, Z_ideal] = encoder_model(theta_true, params);

%% ==========================================================================
% 3. FAULT INJECTION
% ==========================================================================

% Micro-Noise (Jitter, Bounce, Phase Error)
[A_pre_noisy, B_pre_noisy] = inject_micro_noise(A_ideal, B_ideal);

% Pulse Loss (1%)
drop_rate = 0.01;
[A_noisy, B_noisy, stats] = inject_pulse_loss(A_pre_noisy, B_pre_noisy, drop_rate);

%% ==========================================================================
% 4. STATISTICS REPORT
% ==========================================================================

fprintf('\n--- FAULT INJECTION STATISTICS ---\n');
fprintf('Total Physical Pulses : %d\n', stats.total_pulses);
fprintf('Dropped Pulses        : %d\n', stats.dropped_pulses);
fprintf('Actual Drop Rate      : %.2f %%\n', stats.actual_drop_rate);
fprintf('------------------------------------------\n');

%% ==========================================================================
% 5. SIGNAL VISUALIZATION
% ==========================================================================

figure('Name', 'Encoder Signals: Ideal vs Noisy', 'Position', [100, 100, 1000, 500]);

ax1 = subplot(2,1,1);
stairs(t, A_ideal, 'LineWidth', 2, 'Color', [0.8 0.8 0.8]); hold on;
stairs(t, A_noisy, 'LineWidth', 1.5, 'Color', 'b');
title('Channel A: Ideal (Gray) vs Noisy (Blue)');
ylabel('Logic Level'); ylim([-0.2 1.2]); grid on;

ax2 = subplot(2,1,2);
stairs(t, B_ideal, 'LineWidth', 2, 'Color', [0.8 0.8 0.8]); hold on;
stairs(t, B_noisy, 'LineWidth', 1.5, 'Color', 'r');
title('Channel B: Ideal (Gray) vs Noisy (Red)');
xlabel('Time (s)'); ylabel('Logic Level'); ylim([-0.2 1.2]); grid on;

linkaxes([ax1, ax2], 'x');