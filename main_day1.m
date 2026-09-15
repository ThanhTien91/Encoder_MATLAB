% ==========================================================================
% FILE: main_day1.m
% MODULE: Day 1 - Ideal Encoder Simulation
% DESCRIPTION: Generates trajectory, ideal A/B/Z encoder signals,
%              and verification plots.
% ==========================================================================

%% ==========================================================================
% 1. ENVIRONMENT SETUP
% ==========================================================================

clear; clc; close all;

addpath('config');
addpath('models');

%% ==========================================================================
% 2. PARAMETER LOADING
% ==========================================================================

params = default_params();
rng(params.rng_seed);

%% ==========================================================================
% 3. TRAJECTORY GENERATION
% ==========================================================================

[t, theta, omega] = trajectory_model(params);

%% ==========================================================================
% 4. IDEAL ENCODER SIGNALS
% ==========================================================================

[A, B, Z] = encoder_model(theta, params);

%% ==========================================================================
% 5. VISUALIZATION - SYSTEM TRAJECTORY
% ==========================================================================

figure('Name', 'System Trajectory');

subplot(2,1,1);
plot(t, omega * 60/(2*pi), 'LineWidth', 1.5);
title('Motor Speed');
xlabel('Time (s)'); ylabel('Speed (RPM)');
grid on;

subplot(2,1,2);
plot(t, theta, 'LineWidth', 1.5);
title('Angular Position');
xlabel('Time (s)'); ylabel('\theta (rad)');
grid on;

%% ==========================================================================
% 6. ENCODER SIGNAL VERIFICATION (ZOOM @ 0.6s)
% ==========================================================================

figure('Name', 'Encoder A/B/Z Verification');

t_start = 0.6;
t_end   = 0.602;
idx = (t >= t_start) & (t <= t_end);

ax1 = subplot(3,1,1);
plot(t(idx), A(idx), 'LineWidth', 1.2);
title('Encoder Channel A');
ylim([-0.2 1.2]); grid on;

ax2 = subplot(3,1,2);
plot(t(idx), B(idx), 'LineWidth', 1.2);
title('Encoder Channel B');
ylim([-0.2 1.2]); grid on;

ax3 = subplot(3,1,3);
plot(t(idx), Z(idx), 'LineWidth', 1.2);
title('Encoder Index Channel Z');
ylim([-0.2 1.2]); grid on;
xlabel('Time (s)');

linkaxes([ax1, ax2, ax3], 'x');