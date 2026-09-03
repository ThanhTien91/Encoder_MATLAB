% ==========================================
% TẦNG 2 - SENSITIVITY ANALYSIS
% Đánh giá độ nhạy của hệ thống bù trừ vị trí
% ==========================================

clear;
clc;
close all;

% ==========================================
% 1. THIẾT LẬP MÔI TRƯỜNG
% ==========================================

addpath('config');
addpath('models');
addpath('decoder');

% Lấy tham số hệ thống
params = default_params();

% Đặt random seed ngay từ đầu để đảm bảo tái lập kết quả
rng(params.rng_seed);

% Cấu hình các mức tỷ lệ rớt xung
loss_rates = [0.001, 0.005, 0.010, 0.015, 0.020];
num_tests  = length(loss_rates);

% Khởi tạo mảng lưu kết quả
rmse_theta_list  = zeros(1, num_tests);
final_drift_list = zeros(1, num_tests);

% ==========================================
% 2. KHỞI TẠO QUỸ ĐẠO VÀ NHIỄU NỀN
% ==========================================

[t, theta_true, ~]         = trajectory_model(params);
[A_ideal, B_ideal, ~]      = encoder_model(theta_true, params);
[A_pre_noisy, B_pre_noisy] = inject_micro_noise(A_ideal, B_ideal);

fprintf('\nĐang chạy phân tích độ nhạy (Sensitivity Analysis)...\n');

% ==========================================
% 3. VÒNG LẶP KIỂM THỬ (TESTING LOOP)
% ==========================================

for i = 1:num_tests
    rate = loss_rates(i);

    [A_noisy, B_noisy, ~] = inject_pulse_loss( ...
        A_pre_noisy, B_pre_noisy, rate);

    % Giải mã và bù trừ
    [pos_count, missing_count] = quadrature_decoder_x4(A_noisy, B_noisy);

    theta_estimated = ...
        (pos_count * 2*pi) / (params.PPR * 4);

    theta_comp = position_compensator( ...
        theta_estimated, missing_count, params.PPR);

    % Tính toán sai số vị trí
    err_comp = theta_true(:) - theta_comp(:);

    rmse_theta_list(i)  = sqrt(mean(err_comp.^2));
    final_drift_list(i) = abs(err_comp(end));
end

% ==========================================
% 4. IN BÁO CÁO KẾT QUẢ
% ==========================================

fprintf('\n=======================================\n');
fprintf('Loss Rate | RMSE Theta | Final Drift\n');
fprintf('---------------------------------------\n');

for i = 1:num_tests
    fprintf('  %4.1f %%  |  %8.4f  |   %8.4f\n', ...
        loss_rates(i)*100, ...
        rmse_theta_list(i), ...
        final_drift_list(i));
end

fprintf('=======================================\n\n');

% ==========================================
% 5. HIỂN THỊ ĐỒ THỊ
% ==========================================

fig_sens = figure( ...
    'Name', 'Sensitivity Analysis', ...
    'Position', [150, 150, 950, 450]);

% Đồ thị RMSE
subplot(1,2,1);
plot(loss_rates * 100, rmse_theta_list, '-ob', ...
    'LineWidth', 2);
title('RMSE Vị trí vs. Tỷ lệ mất xung');
xlabel('Pulse Loss (%)');
ylabel('RMSE \theta (rad)');
grid on;

% Đồ thị Final Drift
subplot(1,2,2);
plot(loss_rates * 100, final_drift_list, '-or', ...
    'LineWidth', 2);
title('Final Drift vs. Tỷ lệ mất xung');
xlabel('Pulse Loss (%)');
ylabel('Final Drift (rad)');
grid on;

% ==========================================
% 6. TỰ ĐỘNG LƯU KẾT QUẢ
% ==========================================

if ~exist('results/figure/sensitivity', 'dir')
    mkdir('results/figure/sensitivity');
end

saveas(fig_sens, ...
    'results/figure/sensitivity/sensitivity analysis.png');

fprintf(['Đã lưu hình sensitivity analysis vào ' ...
         'results/figure/sensitivity/\n']);