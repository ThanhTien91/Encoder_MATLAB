% =========================================================================
% SCRIPT: compare_estimators.m
% MỤC TIÊU: So sánh M-Method, T-Method, Hybrid theo dải tốc độ (Speed Sweep)
% =========================================================================

clc; clear; close all;

% 1. Nạp đường dẫn thuật toán và module tính toán
addpath(fullfile(pwd, 'decoder'));
addpath(fullfile(pwd, 'config'));
addpath(fullfile(pwd, 'models'));
addpath(fullfile(pwd, 'analysis'));

% 2. Lấy tham số hệ thống
params = default_params();
PPR = params.PPR;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;
Fs = params.Fs;

duration = 1.0; % Mô phỏng 1 giây cho mỗi điểm tốc độ
t = (0:1/Fs:duration)';
N_samples = length(t);

% Dải tốc độ cần kiểm tra (rad/s)
speed_list = [0.5, 1, 2, 5, 10, 20, 50, 100];
num_speeds = length(speed_list);

% Khởi tạo mảng lưu kết quả RMSE
rmse_M = zeros(num_speeds, 1);
rmse_T = zeros(num_speeds, 1);
rmse_H = zeros(num_speeds, 1);

fprintf('====================================================================\n');
fprintf('     PHÂN TÍCH SO SÁNH BỘ ƯỚC LƯỢNG M / T / HYBRID (DAY 8)\n');
fprintf('====================================================================\n');
fprintf('| Speed (rad/s) | M-Method RMSE | T-Method RMSE | Hybrid RMSE  |\n');
fprintf('--------------------------------------------------------------------\n');

% 3. Vòng lặp quét tốc độ
for i = 1:num_speeds
    omega_true = speed_list(i);
    theta_true = omega_true * t;

    % Sinh tín hiệu giả lập (Quỹ đạo lý tưởng cộng nhiễu lượng tử)
    pos_count = floor(theta_true / dp_rad);
    error_flag = zeros(N_samples, 1); % Bỏ qua lỗi phần cứng để xét độ thuần túy của Estimator

    % Chạy thuật toán ước lượng
    [omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count, t, PPR, error_flag);

    % Lọc bỏ đoạn trễ khởi động (0.05s đầu tiên do cửa sổ filter/buffer)
    start_idx = round(0.05 * Fs); 
    if start_idx < 1, start_idx = 1; end

    valid_omega_true = omega_true * ones(N_samples - start_idx + 1, 1);

    % Tính metrics
    mM = compute_metrics(valid_omega_true, omega_M(start_idx:end)');
    mT = compute_metrics(valid_omega_true, omega_T(start_idx:end)');
    mH = compute_metrics(valid_omega_true, omega_Hybrid(start_idx:end)');

    rmse_M(i) = mM.rmse;
    rmse_T(i) = mT.rmse;
    rmse_H(i) = mH.rmse;

    fprintf('| %-13.1f | %-13.4f | %-13.4f | %-12.4f |\n', ...
        omega_true, rmse_M(i), rmse_T(i), rmse_H(i));
end
fprintf('====================================================================\n');

% 4. Vẽ Đồ thị Chứng minh (Đã tối ưu thang đo)
figure('Name', 'RMSE vs Speed', 'Position', [150, 150, 850, 500], 'Color', 'w');

% Sử dụng đồ thị Log-Log cho cả 2 trục để thấy rõ khác biệt vi mô
loglog(speed_list, rmse_M, '-o', 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', 'M-Method');
hold on; grid on;
loglog(speed_list, rmse_T, '-s', 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', 'T-Method');
loglog(speed_list, rmse_H, '-^', 'LineWidth', 2, 'MarkerSize', 7, 'DisplayName', 'Hybrid Fusion');

xlabel('True Speed (rad/s) [Log scale]', 'FontWeight', 'bold');
ylabel('RMSE (rad/s) [Log scale]', 'FontWeight', 'bold');
title('So sánh Sai số Ước lượng Vận tốc theo Dải Tốc độ', 'FontSize', 14);
legend('Location', 'northwest', 'FontSize', 11);
set(gca, 'FontSize', 11);

% Giới hạn lại trục Y để đồ thị không bị nhiễu do điểm 0 tuyệt đối
ylim([1e-4, 200]);

% 5. Tự động lưu Artifacts
out_fig_dir = fullfile('..', 'results', 'figure', 'day8');
if ~exist(out_fig_dir, 'dir'), mkdir(out_fig_dir); end
save_path = fullfile(out_fig_dir, 'rmse vs speed.png');

saveas(gcf, save_path);
fprintf('>> Đã lưu đồ thị thành công tại: %s\n', save_path);