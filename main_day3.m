% ==========================================
% MAIN DAY 3
% Giải mã Quadrature X4, Phát hiện lỗi & Ước lượng vận tốc
% ==========================================

clear;
clc;
close all;

% ==========================================
% 1. THIẾT LẬP MÔI TRƯỜNG
% ==========================================
addpath('config');
addpath('models');
addpath('decoder'); % Thêm đường dẫn chứa thuật toán Day 3

% Lấy tham số hệ thống và chốt random seed để tái lập kết quả
params = default_params();
rng(params.rng_seed); 

% ==========================================
% 2. QUỸ ĐẠO VÀ ENCODER LÝ TƯỞNG (Kế thừa Ngày 1)
% ==========================================
[t, theta_true, omega_true] = trajectory_model(params);
[A_ideal, B_ideal, Z_ideal] = encoder_model(theta_true, params);

% ==========================================
% 3. CHÈN NHIỄU PHẦN CỨNG (Kế thừa Ngày 2)
% ==========================================
% Bước 3.1: Tiêm nhiễu vi mô (Phase Error, Jitter, Bounce)
[A_pre_noisy, B_pre_noisy] = inject_micro_noise(A_ideal, B_ideal);

% Bước 3.2: Tiêm lỗi rớt xung ngẫu nhiên (Pulse Loss)
drop_rate = 0.01; % Tỷ lệ mất xung = 1%
[A_noisy, B_noisy, stats] = inject_pulse_loss(A_pre_noisy, B_pre_noisy, drop_rate);

% ==========================================
% 4. BỘ GIẢI MÃ QUADRATURE (X4 DECODER)
% ==========================================
[pos_count, missing_count] = quadrature_decoder_x4(A_noisy, B_noisy);

% Chuyển missing_count {-2, 0, +2} thành binary error flag {0, 1}
error_flag = double(missing_count ~= 0);

% Đếm lỗi và sự kiện lỗi (chuyển trạng thái từ 0 -> 1)
num_errors = sum(error_flag);
error_events = sum(diff([0; error_flag]) == 1);

% Phân tích theo chiều quay
forward_idx = (t >= 0) & (t < 0.8);
reverse_idx = (t >= 0.8) & (t < 1.8);

forward_events = sum(diff([0; error_flag(forward_idx)]) == 1);
reverse_events = sum(diff([0; error_flag(reverse_idx)]) == 1);

% ==========================================
% 5. IN THỐNG KÊ KẾT QUẢ DECODER
% ==========================================
fprintf('\n--- KẾT QUẢ BỘ GIẢI MÃ (DECODER) ---\n');
fprintf('Số mẫu phát hiện invalid transition : %d\n', num_errors);
fprintf('Số sự kiện invalid (tổng cộng)      : %d\n', error_events);
fprintf('  + Chiều thuận (0 - 0.8 s)         : %d sự kiện\n', forward_events);
fprintf('  + Chiều ngược (0.8 - 1.8 s)       : %d sự kiện\n', reverse_events);
fprintf('Tỷ lệ mẫu báo lỗi                   : %.4f %%\n', 100 * num_errors / length(error_flag));
fprintf('------------------------------------------\n');

% ==========================================
% 6. QUY ĐỔI VỊ TRÍ & ƯỚC LƯỢNG VẬN TỐC
% ==========================================
% Quy đổi số đếm sang góc quay (rad)
theta_estimated = (pos_count * 2*pi) / (params.PPR * 4);

% Chạy thuật toán ước lượng với cờ lỗi để bù đắp
[omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count, t, params.PPR, error_flag);

% ==========================================
% 7. HIỂN THỊ TÍN HIỆU NGHIỆM THU
% ==========================================
% Đồ thị 1: So sánh vị trí và Cờ báo lỗi
fig1 = figure('Name', 'Day 3: Encoder Fault Analysis & Decoding', 'Position', [100, 100, 900, 650]);

ax1 = subplot(2,1,1);
plot(t, theta_true, 'LineWidth', 2, 'Color', 'g'); hold on;
plot(t, theta_estimated, '--', 'LineWidth', 1.5, 'Color', 'r');
title('True Position vs Estimated Position (Bị trôi do nhiễu)');
ylabel('\theta (rad)');
legend('True Position', 'Estimated Position', 'Location', 'best');
grid on;

ax2 = subplot(2,1,2);
plot(t, error_flag, 'LineWidth', 1.2, 'Color', 'k');
title('Quadrature Decoder Error Flag (Phát hiện lỗi trạng thái)');
xlabel('Time (s)'); ylabel('Error');
ylim([-0.2 1.2]);
grid on;

linkaxes([ax1, ax2], 'x');

% Đồ thị 2: Ước lượng vận tốc
fig2 = figure('Name', 'Day 3: Speed Estimator (M/T/Hybrid)', 'Position', [150, 150, 1000, 600]);

ax3 = subplot(3,1,1);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_M, 'b--', 'LineWidth', 1.5);
title('M-Method (Cửa sổ 10ms - Ít nhiễu nhưng trễ)'); ylabel('rad/s'); grid on;

ax4 = subplot(3,1,2);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_T, 'r--', 'LineWidth', 1.5);
title('T-Method (Nhạy ở tốc độ thấp nhưng dễ nhảy vọt)'); ylabel('rad/s'); grid on;

ax5 = subplot(3,1,3);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_Hybrid, 'k--', 'LineWidth', 1.5);
title('Hybrid M/T Estimator (Adaptive Fusion)'); ylabel('rad/s'); grid on;

linkaxes([ax3, ax4, ax5], 'x');

% ==========================================
% 8. TỰ ĐỘNG LƯU HÌNH ẢNH VÀO THƯ MỤC RESULTS
% ==========================================
if ~exist('results/figures', 'dir')
    mkdir('results/figures');
end

saveas(fig1, 'results/figure/day3/position error flag.png');
saveas(fig2, 'results/figure/day3/speed estimation comparison.png');
fprintf('\nĐã lưu thành công các hình ảnh vào thư mục results/figure/\n');