% ==========================================================================
% FILE: main_day4.m
% MODULE: Day 4 - Position Compensation & IIR Velocity Filtering
% DESCRIPTION: Applies position compensation (missing_count integration)
%              and IIR filtering (alpha=0.15) to Hybrid velocity.
%              Comprehensive error metrics reporting.
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
% 2. TRAJECTORY & NOISY ENCODER (INHERITED)
% ==========================================================================

[t, theta_true, omega_true] = trajectory_model(params);
[A_ideal, B_ideal, Z_ideal] = encoder_model(theta_true, params);

[A_pre_noisy, B_pre_noisy] = inject_micro_noise(A_ideal, B_ideal);
pulse_loss_rate = 0.01;
[A_noisy, B_noisy, stats] = inject_pulse_loss(A_pre_noisy, B_pre_noisy, pulse_loss_rate);

%% ==========================================================================
% 2. DECODER & POSITION COMPENSATION
% ==========================================================================

[pos_count, missing_count] = quadrature_decoder_x4(A_noisy, B_noisy);

theta_estimated_drift = (pos_count * 2*pi) / (params.PPR * 4);
error_flag = double(missing_count ~= 0);

theta_compensated = position_compensator(theta_estimated_drift, missing_count, params.PPR);

%% ==========================================================================
% 3. VELOCITY ESTIMATION & IIR FILTERING
% ==========================================================================

[omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count, t, params.PPR, error_flag);

alpha_filter = 0.15;
omega_filtered = zeros(size(omega_Hybrid));
omega_filtered(1) = omega_Hybrid(1);

for k = 2:length(omega_Hybrid)
    omega_filtered(k) = alpha_filter * omega_Hybrid(k) + (1 - alpha_filter) * omega_filtered(k-1);
end

%% ==========================================================================
% 3. ERROR METRICS COMPUTATION
% ==========================================================================

% Position
err_drift = theta_true(:) - theta_estimated_drift(:);
err_comp  = theta_true(:) - theta_compensated(:);

RMSE_drift  = sqrt(mean(err_drift.^2));
RMSE_comp   = sqrt(mean(err_comp.^2));
MAE_drift   = mean(abs(err_drift));
MAE_comp    = mean(abs(err_comp));
MAX_drift   = max(abs(err_drift));
MAX_comp    = max(abs(err_comp));
FINAL_drift = abs(err_drift(end));
FINAL_comp  = abs(err_comp(end));

improvement_rmse = 100 * (RMSE_drift - RMSE_comp) / RMSE_drift;
improvement_mae  = 100 * (MAE_drift - MAE_comp) / MAE_drift;
improvement_max  = 100 * (MAX_drift - MAX_comp) / MAX_drift;

% Velocity
err_omega_raw  = omega_true(:) - omega_Hybrid(:);
err_omega_iir  = omega_true(:) - omega_filtered(:);
RMSE_omega_raw = sqrt(mean(err_omega_raw.^2));
RMSE_omega_iir = sqrt(mean(err_omega_iir.^2));
omega_rmse_change = 100 * (RMSE_omega_iir - RMSE_omega_raw) / RMSE_omega_raw;

% Missing Count Statistics
num_plus2  = sum(missing_count == 2);
num_minus2 = sum(missing_count == -2);
num_total_events = sum(missing_count ~= 0);
net_correction   = sum(missing_count);

%% ==========================================================================
% 4. CONSOLE REPORT
% ==========================================================================

fprintf('\n==============================================\n');
fprintf('       DAY 4 - FINAL EVALUATION\n');
fprintf('==============================================\n');
fprintf('\n--- POSITION COMPENSATION ---\n');
fprintf('                BEFORE         AFTER\n');
fprintf('RMSE          : %10.5f | %10.5f rad\n', RMSE_drift, RMSE_comp);
fprintf('MAE           : %10.5f | %10.5f rad\n', MAE_drift, MAE_comp);
fprintf('Max Error     : %10.5f | %10.5f rad\n', MAX_drift, MAX_comp);
fprintf('Final Drift   : %10.5f | %10.5f rad\n', FINAL_drift, FINAL_comp);
fprintf('\nImprovement RMSE : %.2f %%\n', improvement_rmse);
fprintf('Improvement MAE  : %.2f %%\n', improvement_mae);
fprintf('Improvement Max  : %.2f %%\n', improvement_max);

fprintf('\n--- VELOCITY FILTERING (IIR, alpha=%.2f) ---\n', alpha_filter);
fprintf('RMSE omega Raw   : %.5f rad/s\n', RMSE_omega_raw);
fprintf('RMSE omega IIR   : %.5f rad/s\n', RMSE_omega_iir);
fprintf('RMSE change      : %.3f %%\n', omega_rmse_change);

fprintf('\n--- MISSING COUNT STATISTICS ---\n');
fprintf('+2 corrections   : %d events\n', num_plus2);
fprintf('-2 corrections   : %d events\n', num_minus2);
fprintf('Total events     : %d events\n', num_total_events);
fprintf('Net correction   : %d counts\n', net_correction);
fprintf('\n==============================================\n');

%% ==========================================================================
% 5. VISUALIZATION
% ==========================================================================

fig4 = figure('Name', 'Day 4: Fault Compensation & Filtering', ...
    'Position', [100, 50, 1000, 850]);

% Position Tracking
ax1 = subplot(3,1,1);
plot(t, theta_true, 'g', 'LineWidth', 3); hold on;
plot(t, theta_estimated_drift, 'r--', 'LineWidth', 1.5);
plot(t, theta_compensated, 'b-.', 'LineWidth', 2);
title('Position Tracking');
ylabel('\theta (rad)');
legend('True', 'Before Compensation', 'After Compensation', 'Location', 'best'); grid on;

% Position Error
ax2 = subplot(3,1,2);
plot(t, err_drift, 'r--', 'LineWidth', 1.2); hold on;
plot(t, err_comp, 'b', 'LineWidth', 1.5);
yline(0, 'k--', 'LineWidth', 1.2);
title('Position Error Before/After Compensation');
ylabel('Error (rad)');
legend('Error Before', 'Error After', 'Zero', 'Location', 'best'); grid on;

% Velocity Filtering
ax3 = subplot(3,1,3);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_Hybrid, 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
plot(t, omega_filtered, 'b', 'LineWidth', 1.5);
title(sprintf('Velocity Filtering (IIR, \alpha = %.2f)', alpha_filter));
xlabel('Time (s)'); ylabel('\omega (rad/s)');
legend('True', 'Hybrid Raw', 'Hybrid + IIR', 'Location', 'best'); grid on;

linkaxes([ax1, ax2, ax3], 'x');

%% ==========================================================================
% 5. SAVE FIGURE
% ==========================================================================

result_dir = 'results/figure/day4';
if ~exist(result_dir, 'dir'), mkdir(result_dir); end
saveas(fig4, fullfile(result_dir, 'day4_fault_compensation.png'));
fprintf('\nFigure saved: %s\n', fullfile(result_dir, 'day4_fault_compensation.png'));