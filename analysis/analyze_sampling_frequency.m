% =========================================================================
% SCRIPT: analyze_sampling_frequency.m
% MỤC TIÊU: Đánh giá ảnh hưởng của Tần số lấy mẫu (Fs) đến Sai số (DAY 8)
% =========================================================================

clc; clear; close all;
addpath(fullfile(pwd, '..', 'decoder'));
addpath(fullfile(pwd, '..', 'config'));
addpath(fullfile(pwd, '..', 'models'));


params = default_params();
PPR = params.PPR;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;

% Tập hợp các tần số lấy mẫu cần test (Hz)
Fs_list = [1000, 2000, 5000, 10000, 20000, 50000];
num_Fs = length(Fs_list);

% Cố định một tốc độ trung bình để kiểm tra (ví dụ 10 rad/s)
omega_test = 10; 
duration = 1.0; 

rmse_M_fs = zeros(num_Fs, 1);
rmse_T_fs = zeros(num_Fs, 1);
rmse_H_fs = zeros(num_Fs, 1);

fprintf('====================================================================\n');
fprintf('     PHÂN TÍCH ẢNH HƯỞNG TẦN SỐ LẤY MẪU (TIMER) ĐẾN SAI SỐ\n');
fprintf('====================================================================\n');
fprintf('| Fs (Hz) | M-Method RMSE | T-Method RMSE | Hybrid RMSE  |\n');
fprintf('--------------------------------------------------------------------\n');

for i = 1:num_Fs
    current_Fs = Fs_list(i);
    t_fs = (0:1/current_Fs:duration)';
    N_samples = length(t_fs);

    % Sinh tín hiệu
    theta_true = omega_test * t_fs;
    pos_count = floor(theta_true / dp_rad);
    error_flag = zeros(N_samples, 1);

    % Ước lượng
    [omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count, t_fs, PPR, error_flag);

    % Cắt 10% dữ liệu đầu để bỏ qua transient
    start_idx = round(0.1 * current_Fs);
    if start_idx < 1, start_idx = 1; end
    valid_omega = omega_test * ones(N_samples - start_idx + 1, 1);

    % Tính Metrics
    mM = compute_metrics(valid_omega, omega_M(start_idx:end)');
    mT = compute_metrics(valid_omega, omega_T(start_idx:end)');
    mH = compute_metrics(valid_omega, omega_Hybrid(start_idx:end)');

    rmse_M_fs(i) = mM.rmse;
    rmse_T_fs(i) = mT.rmse;
    rmse_H_fs(i) = mH.rmse;

    fprintf('| %-7d | %-13.4f | %-13.4f | %-12.4f |\n', ...
        current_Fs, rmse_M_fs(i), rmse_T_fs(i), rmse_H_fs(i));
end
fprintf('====================================================================\n');

% --- Vẽ Đồ thị ---
figure('Name', 'RMSE vs Sampling Frequency', 'Position', [200, 200, 800, 450], 'Color', 'w');
plot(Fs_list/1000, rmse_M_fs, '-o', 'LineWidth', 2, 'MarkerSize', 6); hold on; grid on;
plot(Fs_list/1000, rmse_T_fs, '-s', 'LineWidth', 2, 'MarkerSize', 6);
plot(Fs_list/1000, rmse_H_fs, '-^', 'LineWidth', 2, 'MarkerSize', 7);

xlabel('Sampling Frequency Fs (kHz)', 'FontWeight', 'bold');
ylabel('RMSE (rad/s)', 'FontWeight', 'bold');
title(sprintf('Ảnh hưởng của Timer (Fs) đến Sai số đo lường (Tốc độ %d rad/s)', omega_test), 'FontSize', 14);
legend('M-Method', 'T-Method', 'Hybrid Fusion', 'Location', 'best');
set(gca, 'FontSize', 11);

% Xuất file ảnh
out_fig_dir = fullfile('..', 'results',  'figure', 'day8');
save_path = fullfile(out_fig_dir, 'rmse vs fs.png');
saveas(gcf, save_path);
fprintf('>> Đã lưu đồ thị Fs tại: %s\n', save_path);