% ==========================================================================
% FILE: sensitivity_analysis.m
% MODULE: Monte Carlo Sensitivity Analysis (Jitter/Bounce Sweep)
% DESCRIPTION: True Monte Carlo Uncertainty Analysis with physical
%              edge-domain noise injection (inject_micro_noise).
%              Synchronized with Rubric Scenarios: Fs=1MHz, w=10rad/s.
% ==========================================================================

%% ==========================================================================
% 1. PATH CONFIGURATION
% ==========================================================================

clc; clear; close all;

project_root = fileparts(fileparts(mfilename('fullpath')));

addpath(fullfile(project_root, 'config'));
addpath(fullfile(project_root, 'models'));
addpath(fullfile(project_root, 'decoder'));
addpath(fullfile(project_root, 'analysis'));

%% ==========================================================================
% 2. SYSTEM PARAMETERS
% ==========================================================================

params = default_params();

PPR = params.PPR;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;

%% ==========================================================================
% 3. REPRODUCIBILITY
% ==========================================================================

rng(params.rng_seed);

%% ==========================================================================
% 4. MONTE CARLO CONFIGURATION (SYNC WITH RUBRIC)
% ==========================================================================

% BAT BUOC: Fs = 1 MHz de bao ton y nghia vat ly Jitter (1 sample = 1 us)
Fs_analysis = params.Fs;

noise_levels = [0, 0.002, 0.005, 0.01, 0.02, 0.05];
num_levels = length(noise_levels);

% Toi uu: duration=0.2s, N_trials=30 de tranh tran RAM o Fs=1MHz
N_trials = 30;
duration = 0.2;

t = (0:1/Fs_analysis:duration)';

omega_true = 10;     % DONG BO: Test o 10 rad/s giong S1-S4
theta_ideal = omega_true * t;

start_idx = max(1, round(0.05 * Fs_analysis));
valid_omega = omega_true * ones(length(t) - start_idx + 1, 1);

%% ==========================================================================
% 5. NOISE MAPPING (HIEU CHUAN VOI RUBRIC SCENARIOS)
% ==========================================================================

% Mapping: noise_amp (rad) -> {jitter_samples, bounce_prob}
% S2 Low Noise  -> jitter 1, bounce 5%  -> noise_amp ~ 0.002
% S3 High Noise -> jitter 2, bounce 25% -> noise_amp ~ 0.05
jitter_map = containers.Map( ...
    {0, 0.002, 0.005, 0.01, 0.02, 0.05}, ...
    {[0, 0], [1, 0.05], [1, 0.10], ...
     [2, 0.15], [2, 0.20], [3, 0.25]});

%% ==========================================================================
% 6. MONTE CARLO RESULTS STORAGE
% ==========================================================================

metrics_MC = struct( ...
    'H_mean', zeros(num_levels,1), ...
    'H_std',  zeros(num_levels,1), ...
    'H_p05',  zeros(num_levels,1), ...
    'H_p50',  zeros(num_levels,1), ...
    'H_p95',  zeros(num_levels,1), ...
    'H_max',  zeros(num_levels,1));

%% ==========================================================================
% 7. HEADER
% ==========================================================================

fprintf('=========================================================================================\n');
fprintf('     TRUE MONTE CARLO EDGE-DOMAIN NOISE SENSITIVITY ANALYSIS\n');
fprintf('     N = %d trials, Fs = %d Hz, omega = %.2f rad/s\n', ...
    N_trials, Fs_analysis, omega_true);
fprintf('=========================================================================================\n\n');

fprintf('| Noise Amp | Jitter | Bounce | H-P50  | [P05, P95]       | H-Mean | H-Std  | H-Max  |\n');
fprintf('-----------------------------------------------------------------------------------------\n');

%% ==========================================================================
% 8. MONTE CARLO LOOP
% ==========================================================================

for i = 1:num_levels

    noise_amp = noise_levels(i);
    temp_H = zeros(N_trials, 1);

    map_val = jitter_map(noise_amp);
    jitter_s = map_val(1);
    bounce_p = map_val(2);

    % --------------------------------------------------------------
    % Monte Carlo Trials
    % --------------------------------------------------------------
    for k = 1:N_trials

        % Reproducible Seed
        rng(params.rng_seed + i*1000 + k);

        % 1. IDEAL ENCODER
        [A_ideal, B_ideal, ~] = encoder_model(theta_ideal, params);

        % 2. EDGE-DOMAIN MICRO NOISE
        if jitter_s > 0 || bounce_p > 0
            [A_noisy, B_noisy] = inject_micro_noise( ...
                A_ideal, B_ideal, jitter_s, bounce_p);
        else
            A_noisy = A_ideal; B_noisy = B_ideal;
        end

        % 3. X4 DECODER
        [pos_count, missing_count] = quadrature_decoder_x4(A_noisy, B_noisy);
        error_flag = double(missing_count ~= 0);

        % 4. HYBRID ESTIMATION
        [~, ~, o_H] = speed_estimator(pos_count, t, PPR, error_flag);

        % 5. METRICS
        mH = compute_metrics(valid_omega, o_H(start_idx:end)');
        temp_H(k) = mH.rmse;

    end

    % --------------------------------------------------------------
    % Statistics
    % --------------------------------------------------------------
    metrics_MC.H_mean(i) = mean(temp_H);
    metrics_MC.H_std(i)  = std(temp_H);
    metrics_MC.H_p05(i)  = prctile(temp_H, 5);
    metrics_MC.H_p50(i)  = prctile(temp_H, 50);
    metrics_MC.H_p95(i)  = prctile(temp_H, 95);
    metrics_MC.H_max(i)  = max(temp_H);

    % --------------------------------------------------------------
    % Console Output
    % --------------------------------------------------------------
    fprintf( ...
        '| %7.3f  | %6d | %5.0f%% | %6.4f | [%6.4f, %6.4f] | %6.4f | %6.4f | %6.4f |\n', ...
        noise_amp, jitter_s, bounce_p*100, ...
        metrics_MC.H_p50(i), metrics_MC.H_p05(i), metrics_MC.H_p95(i), ...
        metrics_MC.H_mean(i), metrics_MC.H_std(i), metrics_MC.H_max(i));

end

fprintf('\n=========================================================================================\n\n');

%% ==========================================================================
% 11. PLOT RESULTS
% ==========================================================================

figure('Name', 'Monte Carlo Jitter/Bounce Sensitivity', ...
    'Position', [200, 200, 900, 500], 'Color', 'w');

hold on; grid on;

% Ensure Row Vectors
x_vec = noise_levels(:)';
p05_vec = metrics_MC.H_p05(:)';
p95_vec = metrics_MC.H_p95(:)';
p50_vec = metrics_MC.H_p50(:)';
mean_vec = metrics_MC.H_mean(:)';
std_vec = metrics_MC.H_std(:)';

% P05-P95 Shaded Interval
x_fill = [x_vec, fliplr(x_vec)];
y_fill = [p05_vec, fliplr(p95_vec)];
h1 = fill(x_fill, y_fill, [0.9 0.9 0.9], 'EdgeColor', 'none', ...
    'DisplayName', 'P05-P95 Interval');

% Median (P50)
h2 = plot(x_vec, p50_vec, '-o', 'LineWidth', 2, ...
    'Color', '#EDB120', 'DisplayName', 'Median (P50)');

% Mean ± Std
h3 = errorbar(x_vec, mean_vec, std_vec, 'k.', ...
    'LineWidth', 1, 'DisplayName', 'Mean ± Std');

xlabel('Noise Amplitude (rad) — Mapped to Jitter/Bounce', 'FontWeight', 'bold');
ylabel('Hybrid Estimator RMSE (rad/s)', 'FontWeight', 'bold');
title(sprintf('Hybrid Robustness (%d MC Trials, Fs=1MHz, Edge-Domain Noise)', N_trials), ...
    'FontSize', 14);
legend('Location', 'northwest'); set(gca, 'FontSize', 11);
xlim([0, max(noise_levels)*1.1]);

%% ==========================================================================
% 12. SAVE RESULTS
% ==========================================================================

out_fig_dir = fullfile(project_root, 'results', 'figure', 'day8');
if ~exist(out_fig_dir, 'dir'), mkdir(out_fig_dir); end
saveas(gcf, fullfile(out_fig_dir, 'mc_sensitivity.png'));

% CSV
csv_path = fullfile(project_root, 'results', 'tables', 'mc_sensitivity.csv');
fid = fopen(csv_path, 'w');
fprintf(fid, 'NoiseAmp_rad,Jitter_samples,Bounce_prob,P50_RMSE,P05_RMSE,P95_RMSE,Mean_RMSE,Std_RMSE,Max_RMSE\n');
for i = 1:num_levels
    map_val = jitter_map(noise_levels(i));
    fprintf(fid, '%.3f,%d,%.2f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n', ...
        noise_levels(i), map_val(1), map_val(2), ...
        metrics_MC.H_p50(i), metrics_MC.H_p05(i), metrics_MC.H_p95(i), ...
        metrics_MC.H_mean(i), metrics_MC.H_std(i), metrics_MC.H_max(i));
end
fclose(fid);

% MAT
save(fullfile(project_root, 'results', 'mc_sensitivity.mat'), ...
    'metrics_MC', 'noise_levels', 'jitter_map');

fprintf('\n>> Figure: %s\n', fullfile(out_fig_dir, 'mc_sensitivity.png'));
fprintf('>> CSV: %s\n', csv_path);
fprintf('>> MAT: %s\n', fullfile(project_root, 'results', 'mc_sensitivity.mat'));
fprintf('=========================================================================================\n');