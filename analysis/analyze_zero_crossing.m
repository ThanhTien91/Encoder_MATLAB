% =========================================================================
% SCRIPT: analyze_zero_crossing.m
% MỤC TIÊU: Đánh giá hành vi tại vùng tốc độ rất thấp và giao điểm zero
% =========================================================================

clc; clear; close all;
addpath(fullfile(pwd, '..', 'decoder'));
addpath(fullfile(pwd, '..', 'config'));

params = default_params();
PPR = params.PPR;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;
Fs = params.Fs;

% 1. Sinh quỹ đạo phanh và đảo chiều (từ +10 rad/s xuống -10 rad/s)
duration = 2.0; % Chạy trong 2 giây
t = (0:1/Fs:duration)';
omega_true = 10 - 10 * t; % Vận tốc bằng 0 tại đúng t = 1.0s
theta_true = 10 * t - 5 * t.^2;

% 2. Giả lập tín hiệu vị trí
pos_count = floor(theta_true / dp_rad);
error_flag = zeros(length(t), 1);

% 3. Đưa qua Estimator
[omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count, t, PPR, error_flag);

% 4. Phân tích định lượng riêng Vùng Zero-crossing (từ 0.8s đến 1.2s)
idx_zc = (t >= 0.8) & (t <= 1.2);
t_zc = t(idx_zc);
omega_true_zc = omega_true(idx_zc);
omega_M_zc = omega_M(idx_zc)';
omega_T_zc = omega_T(idx_zc)';
omega_H_zc = omega_Hybrid(idx_zc)';

% Tính toán Metrics cho riêng vùng nhạy cảm này
mM_zc = compute_metrics(omega_true_zc, omega_M_zc);
mT_zc = compute_metrics(omega_true_zc, omega_T_zc);
mH_zc = compute_metrics(omega_true_zc, omega_H_zc);

fprintf('====================================================================\n');
fprintf('   BÁO CÁO HÀNH VI ĐẢO CHIỀU QUAY (ZERO-CROSSING) | T = [0.8s, 1.2s]\n');
fprintf('====================================================================\n');
fprintf('| Metric        | M-Method    | T-Method    | Hybrid Fusion |\n');
fprintf('--------------------------------------------------------------------\n');
fprintf('| RMSE (rad/s)  | %-11.4f | %-11.4f | %-13.4f |\n', mM_zc.rmse, mT_zc.rmse, mH_zc.rmse);
fprintf('| MAE (rad/s)   | %-11.4f | %-11.4f | %-13.4f |\n', mM_zc.mae, mT_zc.mae, mH_zc.mae);
fprintf('| Max Err (rad/s)| %-11.4f | %-11.4f | %-13.4f |\n', mM_zc.max_error, mT_zc.max_error, mH_zc.max_error);
fprintf('====================================================================\n');

% 5. Vẽ Đồ thị Cận cảnh
figure('Name', 'Zero-Crossing Analysis', 'Position', [150, 150, 850, 500], 'Color', 'w');

plot(t, omega_true, 'k--', 'LineWidth', 2, 'DisplayName', 'True Speed'); hold on; grid on;
% Thay đổi style một chút để làm nổi bật sự chồng lấp
plot(t, omega_M, 'b-', 'LineWidth', 1.5, 'DisplayName', 'M-Method');
plot(t, omega_T, 'r-.', 'LineWidth', 1.5, 'DisplayName', 'T-Method');
plot(t, omega_Hybrid, 'y-', 'LineWidth', 2.5, 'DisplayName', 'Hybrid Fusion');

% Ép giới hạn khung hình để zoom cực cận vào vùng xung quanh 0
xlim([0.8, 1.2]);
ylim([-3, 3]);

xlabel('Thời gian t (s)', 'FontWeight', 'bold');
ylabel('Vận tốc (rad/s)', 'FontWeight', 'bold');
title('Hành vi của Hệ thống Ước lượng tại Giao điểm Zero', 'FontSize', 14);
legend('Location', 'northeast', 'FontSize', 11);
set(gca, 'FontSize', 11);

% Tự động lưu Artifacts
out_fig_dir = fullfile('..', 'results', 'figure', 'day8');
save_path = fullfile(out_fig_dir, 'zero_crossing.png');
saveas(gcf, save_path);
fprintf('>> Đã lưu đồ thị Zero-crossing tại: %s\n', save_path);