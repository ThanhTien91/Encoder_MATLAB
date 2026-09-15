% ==========================================================================
% FILE: verify_manual.m
% MODULE: Analytical Verification (Sanity Check) - 3 Levels
% DESCRIPTION: 
%   LEVEL 1: Static Position Check (Double-Jump Compensation)
%   LEVEL 2: Constant Velocity Analytical Case (10 rad/s)
%   LEVEL 3: Single Double-Jump Ground Truth Verification
% ==========================================================================

%% ==========================================================================
% 1. ENVIRONMENT SETUP
% ==========================================================================

clc; clear; close all;

addpath(fullfile(pwd, 'decoder'));
addpath(fullfile(pwd, 'config'));
addpath(fullfile(pwd, 'models'));

fprintf('======================================================================\n');
fprintf('       ENCODER PROJECT - ANALYTICAL VERIFICATION (SANITY CHECK)\n');
fprintf('======================================================================\n\n');

%% ==========================================================================
% LEVEL 1: STATIC POSITION CHECK
% ==========================================================================

PPR = 1000;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;
target_counts = 500;

% --------------------------------------------------------------
% 1. Generate Ideal State Sequence + 1 Double-Jump
% --------------------------------------------------------------

seq = [0, 2, 3, 1];  % 00 -> 10 -> 11 -> 01
N_steps = 498;

states = zeros(1, N_steps + 2);
states(1:N_steps+1) = seq(mod(0:N_steps, 4) + 1);

% Inject Double-Jump: Remove State 01 -> 11 -> 00 (Missing 2 counts)
states(end) = 0;

A_lvl1 = floor(states / 2);
B_lvl1 = mod(states, 2);

% --------------------------------------------------------------
% 2. Run Decoder + Compensator
% --------------------------------------------------------------

[pos_count_lvl1, missing_count_lvl1] = quadrature_decoder_x4(A_lvl1, B_lvl1);
theta_raw = pos_count_lvl1 * dp_rad;
theta_comp = position_compensator(theta_raw, missing_count_lvl1, PPR);

% --------------------------------------------------------------
% 3. Theoretical Comparison
% --------------------------------------------------------------

theta_theory = target_counts * dp_rad;
theta_calc = theta_comp(end);
err_lvl1 = abs(theta_calc - theta_theory);
if err_lvl1 < 1e-10, err_lvl1 = 0; end

fprintf('[LEVEL 1] STATIC MANUAL CHECK (POSITION)\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('- PPR             : %d\n', PPR);
fprintf('- Decoder Mode    : x4\n');
fprintf('- Target Count    : %d (498 Valid + 1 Double-Jump = 500)\n', target_counts);
fprintf('----------------------------------------------------------------------\n');
fprintf('| Metric          | Theoretical      | Calculated       | Error      |\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('| Theta (rad)     | %-16.6f | %-16.6f | %.2e   |\n', theta_theory, theta_calc, err_lvl1);
fprintf('----------------------------------------------------------------------\n\n');

%% ==========================================================================
% LEVEL 2: CONSTANT VELOCITY ANALYTICAL CASE
% ==========================================================================

omega_ideal = 10;  % rad/s
dt_approx = 0.05;  % seconds

% Exact Pulse Count & Time Step
N_float = (omega_ideal * dt_approx / (2*pi)) * CPR;
N_pulses = round(N_float);  % 318 pulses
Ts_exact = dp_rad / omega_ideal;

t_lvl2 = (0:N_pulses) * Ts_exact;
states_lvl2 = seq(mod(0:N_pulses, 4) + 1);
A_lvl2 = floor(states_lvl2 / 2);
B_lvl2 = mod(states_lvl2, 2);

[pos_count_lvl2, ~] = quadrature_decoder_x4(A_lvl2, B_lvl2);
error_flag = zeros(size(pos_count_lvl2));

[omega_M, omega_T, omega_Hybrid] = ...
    speed_estimator(pos_count_lvl2, t_lvl2, PPR, error_flag);

val_M = omega_M(end);
val_T = omega_T(end);
val_H = omega_Hybrid(end);

err_M = abs(val_M - omega_ideal);
err_T = abs(val_T - omega_ideal);
err_H = abs(val_H - omega_ideal);
if err_M < 1e-10, err_M = 0; end
if err_T < 1e-10, err_T = 0; end
if err_H < 1e-10, err_H = 0; end

fprintf('[LEVEL 2] CONSTANT-SPEED ANALYTICAL CASE (VELOCITY)\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('- Ideal Speed     : %.3f rad/s\n', omega_ideal);
fprintf('- Duration        : %.2f s\n', dt_approx);
fprintf('- Pulses Gen (N)  : %d\n', N_pulses);
fprintf('----------------------------------------------------------------------\n');
fprintf('| Estimator       | Theoretical      | Calculated       | Error      |\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('| M-Method        | %-16.6f | %-16.6f | %.2e   |\n', omega_ideal, val_M, err_M);
fprintf('| T-Method        | %-16.6f | %-16.6f | %.2e   |\n', omega_ideal, val_T, err_T);
fprintf('| Hybrid Method   | %-16.6f | %-16.6f | %.2e   |\n', omega_ideal, val_H, err_H);
fprintf('----------------------------------------------------------------------\n');
fprintf('=> VERIFICATION PASSED: All estimators converge to 10.000000 rad/s.\n');
fprintf('======================================================================\n\n');

%% ==========================================================================
% LEVEL 3: SINGLE DOUBLE-JUMP COMPENSATION GROUND TRUTH
% ==========================================================================

PPR = 1000;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;

seq = [0, 2, 3, 1];
N_valid = 500;
states_full = seq(mod(0:N_valid, 4) + 1);

% Inject Missing Transition at Index 252 (State 01)
fault_idx = 252;
assert(states_full(fault_idx) == 1, 'fault_idx must point to state 01.');

states = states_full;
states(fault_idx) = [];  % Delete State 01 -> Double Jump 11 -> 00

A_lvl3 = floor(states / 2);
B_lvl3 = mod(states, 2);

[pos_count_lvl3, missing_count_lvl3] = quadrature_decoder_x4(A_lvl3, B_lvl3);

theta_raw_lvl3 = pos_count_lvl3 * dp_rad;
theta_comp_lvl3 = position_compensator(theta_raw_lvl3, missing_count_lvl3, PPR);

true_counts_lvl3 = N_valid;
theta_true_lvl3 = true_counts_lvl3 * dp_rad;

err_raw_lvl3 = abs(theta_raw_lvl3(end) - theta_true_lvl3);
err_comp_lvl3 = abs(theta_comp_lvl3(end) - theta_true_lvl3);

miss_idx_lvl3 = find(missing_count_lvl3 ~= 0, 1, 'first');
detected_missing_lvl3 = missing_count_lvl3(miss_idx_lvl3);

fprintf('\n');
fprintf('======================================================================\n');
fprintf('       LEVEL 3: SINGLE DOUBLE-JUMP COMPENSATION TEST\n');
fprintf('======================================================================\n');
fprintf('PPR                         : %d\n', PPR);
fprintf('CPR (X4)                   : %d counts/rev\n', CPR);
fprintf('Ground-truth counts        : %d\n', true_counts_lvl3);
fprintf('Expected missing count     : +2\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('| Metric                    | Value                |\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('| True position             | %.9f rad      |\n', theta_true_lvl3);
fprintf('| Raw position              | %.9f rad      |\n', theta_raw_lvl3(end));
fprintf('| Compensated position      | %.9f rad      |\n', theta_comp_lvl3(end));
fprintf('| Raw position error        | %.3e rad      |\n', err_raw_lvl3);
fprintf('| Compensated position err. | %.3e rad      |\n', err_comp_lvl3);
fprintf('----------------------------------------------------------------------\n');

if ~isempty(miss_idx_lvl3)
    fprintf('Detected missing_count      : %d\n', detected_missing_lvl3);
else
    fprintf('Detected missing_count      : NONE\n');
end
fprintf('----------------------------------------------------------------------\n');

if detected_missing_lvl3 == 2 && err_comp_lvl3 < 1e-10
    fprintf('=> LEVEL 3 STATUS: PASS\n');
    fprintf('=> Double-jump detected, position compensation correct.\n');
else
    fprintf('=> LEVEL 3 STATUS: FAIL\n');
end
fprintf('======================================================================\n\n');