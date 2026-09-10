% ==========================================
% MAIN DAY 2
% Encoder Fault Injection + X4 Decoder
% ==========================================

clear;
clc;
close all;


% ==========================================
% 1. PROJECT PATH
% ==========================================

addpath('config');
addpath('models');
addpath('decoder');


% ==========================================
% 2. PARAMETERS
% ==========================================

params = default_params();

% Reproducible experiment
rng(params.rng_seed);


% ==========================================
% 3. GENERATE TRUE TRAJECTORY
% ==========================================

[t, theta_true, omega_true] = ...
    trajectory_model(params);


% ==========================================
% 4. IDEAL ENCODER
% ==========================================

[A_ideal, B_ideal, Z_ideal] = ...
    encoder_model(theta_true, params);


% ==========================================
% 5. INJECT PULSE LOSS
% ==========================================

drop_rate = 0.01;     % Tỷ lệ mất xung = 1%

[A_noisy, B_noisy, stats] = ...
    inject_pulse_loss(A_ideal, B_ideal, drop_rate);


% In thống kê Fault Injection
fprintf('\n');
fprintf('--- KẾT QUẢ CHÈN LỖI (FAULT INJECTION) ---\n');

fprintf('Tổng số xung vật lý      : %d pulses\n', ...
    stats.total_pulses);

fprintf('Số xung bị làm mất       : %d pulses\n', ...
    stats.dropped_pulses);

fprintf('Tỷ lệ rớt xung thực tế   : %.2f %%\n', ...
    stats.actual_drop_rate);

fprintf('------------------------------------------\n');


% ==========================================
% 6. QUADRATURE DECODER X4
% ==========================================

[pos_count, error_flag] = ...
    quadrature_decoder_x4(A_noisy, B_noisy);


% Tổng số sample báo lỗi
num_errors = sum(error_flag);


% Đếm số sự kiện invalid transition
% Một sự kiện = chuyển từ error_flag = 0 sang 1
error_events = ...
    sum(diff([0; error_flag]) == 1);


% In kết quả Decoder
fprintf('\n');
fprintf('--- KẾT QUẢ DECODER ---\n');

fprintf('Số mẫu phát hiện invalid transition : %d\n', ...
    num_errors);

fprintf('Số sự kiện invalid                  : %d\n', ...
    error_events);

fprintf('Tỷ lệ mẫu báo lỗi                   : %.4f %%\n', ...
    100 * num_errors / length(error_flag));


% ==========================================
% 7. PHÂN TÍCH LỖI THEO CHIỀU QUAY
% ==========================================

% ------------------------------------------
% Chiều thuận
% 0 -> 0.8 s
% ------------------------------------------

forward_idx = ...
    (t >= 0) & (t < 0.8);


% ------------------------------------------
% Chiều ngược
% 0.8 -> 1.8 s
% ------------------------------------------

reverse_idx = ...
    (t >= 0.8) & (t < 1.8);


% ------------------------------------------
% Lấy error_flag theo từng chiều
% ------------------------------------------

forward_flag = ...
    error_flag(forward_idx);

reverse_flag = ...
    error_flag(reverse_idx);


% ------------------------------------------
% Số sample báo lỗi
% ------------------------------------------

forward_errors = ...
    sum(forward_flag);

reverse_errors = ...
    sum(reverse_flag);


% ------------------------------------------
% Số sự kiện invalid transition
% ------------------------------------------

forward_events = ...
    sum(diff([0; forward_flag]) == 1);

reverse_events = ...
    sum(diff([0; reverse_flag]) == 1);


% ------------------------------------------
% In kết quả
% ------------------------------------------

fprintf('\n');
fprintf('--- PHÂN TÍCH THEO CHIỀU QUAY ---\n');

fprintf('Chiều thuận (0 - 0.8 s):\n');

fprintf('  Error samples : %d\n', ...
    forward_errors);

fprintf('  Error events  : %d\n', ...
    forward_events);


fprintf('Chiều ngược (0.8 - 1.8 s):\n');

fprintf('  Error samples : %d\n', ...
    reverse_errors);

fprintf('  Error events  : %d\n', ...
    reverse_events);


% ==========================================
% 8. COUNT -> ANGLE
% ==========================================

theta_estimated = ...
    (pos_count * 2*pi) / ...
    (params.PPR * 4);


% ==========================================
% 9. POSITION COMPARISON
% ==========================================

figure( ...
    'Name', 'Encoder Fault Analysis', ...
    'Position', [100 100 900 650]);


% ------------------------------------------
% Đồ thị vị trí
% ------------------------------------------

ax1 = subplot(2,1,1);

plot( ...
    t, ...
    theta_true, ...
    'LineWidth', 2);

hold on;

plot( ...
    t, ...
    theta_estimated, ...
    '--', ...
    'LineWidth', 1.5);

title('True Position vs Estimated Position');

ylabel('\theta (rad)');

legend( ...
    'True Position', ...
    'Estimated Position');

grid on;


% ==========================================
% 10. ERROR FLAG
% ==========================================

ax2 = subplot(2,1,2);

plot( ...
    t, ...
    error_flag, ...
    'LineWidth', 1.2);

title('Quadrature Decoder Error Flag');

ylabel('Error');

xlabel('Time (s)');

ylim([-0.2 1.2]);

grid on;


% ------------------------------------------
% Đồng bộ trục thời gian
% ------------------------------------------

linkaxes([ax1 ax2], 'x');

% ==========================================
% 10. ƯỚC LƯỢNG TỐC ĐỘ (M-METHOD, T-METHOD & HYBRID)
% ==========================================
% Đưa thêm error_flag vào để bộ ước lượng biết đường bù lỗi!
[omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count, t, params.PPR, error_flag);

% KẾT XUẤT ĐỒ THỊ
figure('Name', 'Vận tốc: M-Method vs T-Method vs Hybrid', 'Position', [100 100 1000 600]);

ax1 = subplot(3,1,1);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_M, 'b--', 'LineWidth', 1.5);
title('M-Method'); ylabel('rad/s'); grid on;

ax2 = subplot(3,1,2);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_T, 'r--', 'LineWidth', 1.5);
title('T-Method'); ylabel('rad/s'); grid on;

ax3 = subplot(3,1,3);
plot(t, omega_true, 'g', 'LineWidth', 2); hold on;
plot(t, omega_Hybrid, 'k--', 'LineWidth', 1.5);
title('Hybrid M/T Estimator'); ylabel('rad/s'); grid on;

linkaxes([ax1, ax2, ax3], 'x');