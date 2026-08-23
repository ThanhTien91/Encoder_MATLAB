% ==========================================
% MAIN DAY 2
% Sinh Tín Hiệu Nhiễu (Jitter, Bounce, Sai Pha, Rớt Xung)
% ==========================================

clear;
clc;
close all;

% ==========================================
% 1. THIẾT LẬP MÔI TRƯỜNG
% ==========================================
addpath('config');
addpath('models');

% Lấy tham số hệ thống và chốt random seed để tái lập kết quả
params = default_params();
rng(params.rng_seed); 

% ==========================================
% 2. QUỸ ĐẠO VÀ ENCODER LÝ TƯỞNG
% ==========================================
[t, theta_true, omega_true] = trajectory_model(params);
[A_ideal, B_ideal, Z_ideal] = encoder_model(theta_true, params);

% ==========================================
% 3. CHÈN NHIỄU PHẦN CỨNG (HARDWARE FAULTS)
% ==========================================
% Bước 3.1: Tiêm nhiễu vi mô (Phase Error, Jitter, Bounce)
[A_pre_noisy, B_pre_noisy] = inject_micro_noise(A_ideal, B_ideal);

% Bước 3.2: Tiêm lỗi rớt xung ngẫu nhiên (Pulse Loss)
drop_rate = 0.01; % Tỷ lệ mất xung = 1%
[A_noisy, B_noisy, stats] = inject_pulse_loss(A_pre_noisy, B_pre_noisy, drop_rate);

% ==========================================
% 4. IN THỐNG KÊ KẾT QUẢ
% ==========================================
fprintf('\n--- KẾT QUẢ CHÈN LỖI (FAULT INJECTION) ---\n');
fprintf('Tổng số xung vật lý      : %d pulses\n', stats.total_pulses);
fprintf('Số xung bị làm mất       : %d pulses\n', stats.dropped_pulses);
fprintf('Tỷ lệ rớt xung thực tế   : %.2f %%\n', stats.actual_drop_rate);
fprintf('------------------------------------------\n');

% ==========================================
% 5. HIỂN THỊ TÍN HIỆU NGHIỆM THU
% ==========================================
figure('Name', 'Encoder Signals: Ideal vs Noisy', 'Position', [100, 100, 1000, 500]);

% Vẽ kênh A
ax1 = subplot(2,1,1);
stairs(t, A_ideal, 'LineWidth', 2, 'Color', [0.8 0.8 0.8]); hold on;
stairs(t, A_noisy, 'LineWidth', 1.5, 'Color', 'b');
title('Kênh A - Tín hiệu Lý tưởng (Xám) và Thực tế có nhiễu (Xanh)');
ylabel('Logic Level');
ylim([-0.2 1.2]);
grid on;

% Vẽ kênh B
ax2 = subplot(2,1,2);
stairs(t, B_ideal, 'LineWidth', 2, 'Color', [0.8 0.8 0.8]); hold on;
stairs(t, B_noisy, 'LineWidth', 1.5, 'Color', 'r');
title('Kênh B - Tín hiệu Lý tưởng (Xám) và Thực tế có nhiễu (Đỏ)');
xlabel('Time (s)'); ylabel('Logic Level');
ylim([-0.2 1.2]);
grid on;

% Đồng bộ trục X để hỗ trợ thao tác Zoom
linkaxes([ax1, ax2], 'x');