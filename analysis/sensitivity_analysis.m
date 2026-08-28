% =========================================================================
% SCRIPT: sensitivity_analysis.m
% MỤC TIÊU: True Monte Carlo Uncertainty Analysis (Jitter Sweep)
% =========================================================================
clc; clear; close all;
addpath(fullfile(pwd, '..', 'decoder'));
addpath(fullfile(pwd, '..', 'config'));
addpath(fullfile(pwd, '..', 'models'));

params = default_params();
PPR = params.PPR;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;

% --- FIX 1: Reproducibility ---
rng(params.rng_seed); 

% --- FIX 2: Giảm tải tính toán ---
% Không dùng params.Fs (1MHz) để tránh tràn RAM khi chạy MC. 
% Dùng Analysis Sampling Rate: 50 kHz.
Fs_analysis = 50000; 

noise_levels = [0, 0.002, 0.005, 0.01, 0.02, 0.05]; 
num_levels = length(noise_levels);
N_trials = 100; % Monte Carlo Trials

duration = 1.0; 
t = (0:1/Fs_analysis:duration)';
omega_true = 5; 
theta_ideal = omega_true * t;
start_idx = max(1, round(0.05 * Fs_analysis));
valid_omega = omega_true * ones(length(t) - start_idx + 1, 1);

% Khởi tạo struct lưu Percentiles cho Hybrid (H)
metrics_MC = struct('H_mean', zeros(num_levels,1), 'H_std', zeros(num_levels,1), ...
                    'H_p05', zeros(num_levels,1), 'H_p50', zeros(num_levels,1), ...
                    'H_p95', zeros(num_levels,1), 'H_max', zeros(num_levels,1));

fprintf('=========================================================================================\n');
fprintf('     TRUE MONTE CARLO JITTER SENSITIVITY ANALYSIS (N = %d trials, Fs = %d Hz)\n', N_trials, Fs_analysis);
fprintf('=========================================================================================\n');
fprintf('| Noise | H-Median(P50) | Interval [P05, P95] | H-Mean  | H-Std  | H-Worst (Max)|\n');
fprintf('-----------------------------------------------------------------------------------------\n');

for i = 1:num_levels
    noise_amp = noise_levels(i);
    temp_H = zeros(N_trials, 1);
    
    for k = 1:N_trials
        theta_noisy = theta_ideal + noise_amp * randn(size(theta_ideal));
        pos_count = floor(theta_noisy / dp_rad);
        error_flag = zeros(length(t), 1);
        
        [~, ~, o_H] = speed_estimator(pos_count, t, PPR, error_flag);
        mH = compute_metrics(valid_omega, o_H(start_idx:end)');
        temp_H(k) = mH.rmse;
    end
    
    % --- FIX 3: Thống kê Percentile ---
    metrics_MC.H_mean(i) = mean(temp_H);
    metrics_MC.H_std(i)  = std(temp_H);
    metrics_MC.H_p05(i)  = prctile(temp_H, 5);
    metrics_MC.H_p50(i)  = prctile(temp_H, 50);
    metrics_MC.H_p95(i)  = prctile(temp_H, 95);
    metrics_MC.H_max(i)  = max(temp_H);
    
    fprintf('| %-5.3f | %-13.4f | [%.4f, %.4f] | %-7.4f | %-6.4f | %-12.4f |\n', ...
            noise_amp, metrics_MC.H_p50(i), metrics_MC.H_p05(i), metrics_MC.H_p95(i), ...
            metrics_MC.H_mean(i), metrics_MC.H_std(i), metrics_MC.H_max(i));
end

% --- Đồ thị ---
figure('Name', 'Monte Carlo Jitter', 'Position', [250, 250, 750, 450], 'Color', 'w');
% Plot Median
plot(noise_levels, metrics_MC.H_p50, '-^', 'LineWidth', 2, 'Color', '#EDB120', 'DisplayName', 'Hybrid Median (P50)'); hold on; grid on;
% Thêm error bars đại diện cho Std để dễ nhìn (hoặc dùng fill patch cho P05-P95 nếu cần)
errorbar(noise_levels, metrics_MC.H_mean, metrics_MC.H_std, 'k.', 'LineWidth', 1, 'DisplayName', 'Mean ± Std');

xlabel('Jitter Amplitude (rad)', 'FontWeight', 'bold'); ylabel('RMSE (rad/s)', 'FontWeight', 'bold');
title(sprintf('Hybrid Estimator Robustness (%d MC Trials)', N_trials), 'FontSize', 14);
legend('Location', 'northwest'); set(gca, 'FontSize', 11);

% --- FIX 4: Sửa đường dẫn chuẩn repo ---
out_fig_dir = fullfile('..', 'results', 'figure', 'day8');
if ~exist(out_fig_dir, 'dir'), mkdir(out_fig_dir); end
saveas(gcf, fullfile(out_fig_dir, 'mc_sensitivity.png'));