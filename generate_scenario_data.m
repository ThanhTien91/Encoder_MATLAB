% ==========================================================================
% FILE: generate_scenario_data.m
% MODULE: Scenario Data Packaging (Day 8 - Phase 1)
% DESCRIPTION: Generates 2 scenarios (Low Speed, Zero Crossing) and
%              packages complete state/estimation data into .mat file.
% ==========================================================================

%% ==========================================================================
% 1. ENVIRONMENT SETUP
% ==========================================================================

clc; clear; close all;

addpath(fullfile(pwd, 'decoder'));
addpath(fullfile(pwd, 'config'));

if ~exist('results', 'dir'), mkdir('results'); end

params = default_params();
PPR = params.PPR;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;
Fs = params.Fs;

scenario_data = struct();

fprintf('Generating scenario data package...\n');

%% ==========================================================================
% SCENARIO 1: VERY LOW SPEED (2 rad/s CONSTANT)
% ==========================================================================

fprintf('>> Scenario 1: Low Speed (2 rad/s)...\n');

t_1 = (0:1/Fs:1)';
omega_true_1 = 2 * ones(size(t_1));
theta_true_1 = 2 * t_1;

N1 = length(t_1);
pos_count_1 = floor(theta_true_1 / dp_rad);
error_flag_1 = zeros(N1, 1);
missing_count_1 = zeros(N1, 1);

[omega_M_1, omega_T_1, omega_Hybrid_1] = ...
    speed_estimator(pos_count_1, t_1, PPR, error_flag_1);
theta_comp_1 = position_compensator(pos_count_1 * dp_rad, missing_count_1, PPR);

scenario_data.scenario1.name = 'Low_Speed_2_rad_s';
scenario_data.scenario1.t = t_1;
scenario_data.scenario1.params = params;
scenario_data.scenario1.position.true = theta_true_1;
scenario_data.scenario1.position.est = theta_comp_1;
scenario_data.scenario1.speed.true = omega_true_1;
scenario_data.scenario1.speed.M = omega_M_1(:);
scenario_data.scenario1.speed.T = omega_T_1(:);
scenario_data.scenario1.speed.Hybrid = omega_Hybrid_1(:);

%% ==========================================================================
% SCENARIO 2: ZERO CROSSING (+20 -> -20 rad/s)
% ==========================================================================

fprintf('>> Scenario 2: Zero Crossing (+20 -> -20 rad/s)...\n');

t_2 = (0:1/Fs:2)';
omega_true_2 = 20 - 20 * t_2;
theta_true_2 = 20 * t_2 - 10 * t_2.^2;

N2 = length(t_2);
pos_count_2 = floor(theta_true_2 / dp_rad);
error_flag_2 = zeros(N2, 1);
missing_count_2 = zeros(N2, 1);

[omega_M_2, omega_T_2, omega_Hybrid_2] = ...
    speed_estimator(pos_count_2, t_2, PPR, error_flag_2);
theta_comp_2 = position_compensator(pos_count_2 * dp_rad, missing_count_2, PPR);

scenario_data.scenario2.name = 'Zero_Crossing';
scenario_data.scenario2.t = t_2;
scenario_data.scenario2.params = params;
scenario_data.scenario2.position.true = theta_true_2;
scenario_data.scenario2.position.est = theta_comp_2;
scenario_data.scenario2.speed.true = omega_true_2;
scenario_data.scenario2.speed.M = omega_M_2(:);
scenario_data.scenario2.speed.T = omega_T_2(:);
scenario_data.scenario2.speed.Hybrid = omega_Hybrid_2(:);

%% ==========================================================================
% SAVE MAT FILE
% ==========================================================================

save_path = fullfile('results', 'scenario_results.mat');
save(save_path, 'scenario_data');

fprintf('======================================================\n');
fprintf('SUCCESS: %s\n', save_path);
fprintf('Data ready for analysis.\n');
fprintf('======================================================\n');