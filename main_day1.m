% ==========================================
% MAIN DAY 1
% Encoder Quadrature Simulation
% ==========================================

clear;
clc;
close all;

% ==========================================
% 1. ADD PROJECT PATHS
% ==========================================

addpath('config');
addpath('models');

% ==========================================
% 2. LOAD PARAMETERS
% ==========================================

params = default_params();

% Reproducible random seed
rng(params.rng_seed);

% ==========================================
% 3. GENERATE TRAJECTORY
% ==========================================

[t, theta, omega] = trajectory_model(params);

% ==========================================
% 4. GENERATE ENCODER SIGNALS
% ==========================================

[A, B, Z] = encoder_model(theta, params);

% ==========================================
% 5. PLOT TRAJECTORY
% ==========================================

figure('Name', 'System Trajectory');

subplot(2,1,1);

plot(t, omega * 60/(2*pi), 'LineWidth', 1.5);

title('Motor Speed');
xlabel('Time (s)');
ylabel('Speed (RPM)');

grid on;

subplot(2,1,2);

plot(t, theta, 'LineWidth', 1.5);

title('Angular Position');
xlabel('Time (s)');
ylabel('\theta (rad)');

grid on;

% ==========================================
% 6. ENCODER SIGNAL VERIFICATION
% ==========================================

figure('Name', 'Encoder A/B/Z Verification');

% Zoom around 0.6 s
t_start = 0.6;
t_end = 0.602;

idx = (t >= t_start) & (t <= t_end);

ax1 = subplot(3,1,1);

plot(t(idx), A(idx), 'LineWidth', 1.2);

title('Encoder Channel A');

ylim([-0.2 1.2]);
grid on;

ax2 = subplot(3,1,2);

plot(t(idx), B(idx), 'LineWidth', 1.2);

title('Encoder Channel B');

ylim([-0.2 1.2]);
grid on;

ax3 = subplot(3,1,3);

plot(t(idx), Z(idx), 'LineWidth', 1.2);

title('Encoder Index Channel Z');

ylim([-0.2 1.2]);

xlabel('Time (s)');
grid on;

linkaxes([ax1 ax2 ax3], 'x');