% ==========================================
% MAIN DAY 4
% Bù trừ lỗi vị trí (Position Compensation) 
% và Lọc vận tốc (Velocity Filtering)
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

% Lấy tham số hệ thống và chốt random seed
params = default_params();
rng(params.rng_seed);

% ==========================================
% 2. QUỸ ĐẠO VÀ ENCODER LÝ TƯỞNG (Kế thừa)
% ==========================================

[t, theta_true, omega_true] = trajectory_model(params);
[A_ideal, B_ideal, Z_ideal] = encoder_model(theta_true, params);

% ==========================================
% 3. CHÈN NHIỄU PHẦN CỨNG (Kế thừa)
% ==========================================

[A_pre_noisy, B_pre_noisy] = inject_micro_noise(A_ideal, B_ideal);

pulse_loss_rate = 0.01; % Tỷ lệ rớt xung 1%
[A_noisy, B_noisy, stats] = inject_pulse_loss(A_pre_noisy, B_pre_noisy, pulse_loss_rate);

% ==========================================
% 4. GIẢI MÃ VÀ BÙ TRỪ LỖI VỊ TRÍ
% ==========================================

% Giải mã lấy số đếm và mảng cắm cờ các lỗi nhảy trạng thái
[pos_count, missing_count] = quadrature_decoder_x4(A_noisy, B_noisy);

% Tính góc quay bị trôi (chưa bù trừ)
theta_estimated_drift = (pos_count * 2*pi) / (params.PPR * 4);
error_flag = double(missing_count ~= 0);

% Chạy thuật toán bù trừ vị trí bằng mảng missing_count
theta_compensated = position_compensator(theta_estimated_drift, missing_count, params.PPR);

% ==========================================
% 5. ƯỚC LƯỢNG VÀ LỌC VẬN TỐC (IIR FILTER)
% ==========================================

% Ước lượng vận tốc (sử dụng Hybrid)
[omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count, t, params.PPR, error_flag);

% Bộ lọc IIR làm mượt tín hiệu Hybrid
alpha_filter = 0.15;
omega_filtered = zeros(size(omega_Hybrid));
omega_filtered(1) = omega_Hybrid(1);

for k = 2:length(omega_Hybrid)
    omega_filtered(k) = alpha_filter * omega_Hybrid(k) + (1 - alpha_filter) * omega_filtered(k-1);
end

% ==========================================
% 6. ĐÁNH GIÁ SAI SỐ (EVALUATION)
% ==========================================

% --- Tính toán sai số Vị trí ---
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

% --- Tính toán sai số Vận tốc ---
err_omega_raw  = omega_true(:) - omega_Hybrid(:);
err_omega_iir  = omega_true(:) - omega_filtered(:);
RMSE_omega_raw = sqrt(mean(err_omega_raw.^2));
RMSE_omega_iir = sqrt(mean(err_omega_iir.^2));
omega_rmse_change = 100 * (RMSE_omega_iir - RMSE_omega_raw) / RMSE_omega_raw;

% --- Thống kê sự kiện lỗi ---
num_plus2  = sum(missing_count == 2);
num_minus2 = sum(missing_count == -2);
num_total_events = sum(missing_count ~= 0);
net_correction   = sum(missing_count);

% In báo cáo ra Command Window
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

fprintf('\n--- VELOCITY FILTERING ---\n');
fprintf('Alpha            : %.2f\n', alpha_filter);
fprintf('RMSE omega Raw   : %.5f rad/s\n', RMSE_omega_raw);
fprintf('RMSE omega IIR   : %.5f rad/s\n', RMSE_omega_iir);
fprintf('RMSE change      : %.3f %%\n', omega_rmse_change);

fprintf('\n--- MISSING COUNT STATISTICS ---\n');
fprintf('+2 corrections   : %d events\n', num_plus2);
fprintf('-2 corrections   : %d events\n', num_minus2);
fprintf('Total events     : %d events\n', num_total_events);
fprintf('Net correction   : %d counts\n', net_correction);
fprintf('\n==============================================\n');

% ==========================================
% 7. HIỂN THỊ TÍN HIỆU NGHIỆM THU
% ==========================================

fig4 = figure('Name', 'Day 4: Fault Compensation and Filtering', 'Position', [100, 50, 1000, 850]);

% Đồ thị 1: Tracking Vị trí
ax1 = subplot(3,1,1);
plot(t, theta_true, 'g', 'LineWidth', 3); hold on;
plot(t, theta_estimated_drift, 'r--', 'LineWidth', 1.5);
plot(t, theta_compensated, 'b-.', 'LineWidth', 2);
title('Position Tracking'); 
ylabel('\theta (rad)');
legend('True', 'Before Compensation', 'After Compensation', 'Location', 'best'); 
grid on;

% Đồ thị 2: So sánh Sai số Vị trí
ax2 = subplot(3,1,2);
plot(t, err_drift, 'r--', 'LineWidth', 1.2); hold on;
plot(t, err_comp, 'b', 'LineWidth', 1.5);
yline(0, 'k--', 'LineWidth', 1.2);
title('Position Error Before and After Compensation'); 
ylabel('Error (rad)');
legend('Error Before', 'Error After', 'Zero Error', 'Location', 'best'); 
grid on;

% Đồ thị 3: Lọc Vận Tốc
ax3 = subplot(3,1,3);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_Hybrid, 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
plot(t, omega_filtered, 'b', 'LineWidth', 1.5);
title(sprintf('Velocity Filtering (IIR, \\alpha = %.2f)', alpha_filter));
xlabel('Time (s)'); 
ylabel('\omega (rad/s)');
legend('True Velocity', 'Hybrid Raw', 'Hybrid + IIR', 'Location', 'best'); 
grid on;

linkaxes([ax1, ax2, ax3], 'x');

% ==========================================
% 8. TỰ ĐỘNG LƯU HÌNH ẢNH VÀO THƯ MỤC RESULTS
% ==========================================

result_dir = 'results/figure/day4';
if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end

saveas(fig4, fullfile(result_dir, 'day4_fault_compensation.png'));
fprintf('\nĐã lưu thành công hình ảnh vào thư mục %s\n', result_dir);