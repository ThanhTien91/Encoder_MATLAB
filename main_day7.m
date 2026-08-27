% =========================================================================
% SCRIPT: main_day7.m (Bản cập nhật Định lượng)
% MỤC TIÊU: Kịch bản thử nghiệm (Scenario Testing - Ngày 7)
% ĐÁNH GIÁ: Định lượng RMSE, MAE, Max Error, Latency và Timeout Behavior
% =========================================================================

clc; clear; close all;

% Thêm đường dẫn (giả định cấu trúc thư mục hiện tại)
addpath(fullfile(pwd, 'decoder'));
addpath(fullfile(pwd, 'config'));
addpath(fullfile(pwd, 'models'));

fprintf('======================================================================\n');
fprintf('    ĐỒ ÁN ENCODER - NGÀY 7: KỊCH BẢN THỬ NGHIỆM (ĐÁNH GIÁ ĐỊNH LƯỢNG) \n');
fprintf('======================================================================\n\n');

% Lấy thông số hệ thống mặc định
params = default_params();
Fs = params.Fs;
dt = 1 / Fs;
t = 0 : dt : params.duration;
N_samples = length(t);

% Khởi tạo mảng chứa 5 kịch bản
omega_scenarios = zeros(5, N_samples);

% --- THIẾT KẾ 5 QUỸ ĐẠO VẬN TỐC ---
% Scenario 1: Tốc độ rất thấp không đổi (2 rad/s)
omega_scenarios(1, :) = 2 * ones(1, N_samples);

% Scenario 2: Giao điểm Zero & Đảo chiều (Sine wave, max 10 rad/s)
omega_scenarios(2, :) = 10 * sin(2 * pi * 0.5 * t);

% Scenario 3: Tăng tốc nhanh đến Max RPM
max_rad_s = params.max_rpm * (2*pi/60); 
ramp_profile = max_rad_s * (t - 0.5) * 2; % Bắt đầu từ 0.5s
ramp_profile(t < 0.5) = 0;
ramp_profile(ramp_profile > max_rad_s) = max_rad_s;
omega_scenarios(3, :) = ramp_profile;

% Scenario 4: Phanh gấp từ tốc độ cao về tốc độ thấp
brake_profile = max_rad_s * ones(1, N_samples);
brake_profile(t > 1.0) = 2; % Drop tại t = 1.0s
omega_scenarios(4, :) = brake_profile;

% Scenario 5: Rung lắc vi mô (Dao động quanh điểm 0)
omega_scenarios(5, :) = 1 * sin(2 * pi * 5 * t);

titles = {
    'Scenario 1: Very Low Constant Speed (2 rad/s)',
    'Scenario 2: Zero-Crossing & Direction Reversal',
    'Scenario 3: Fast Acceleration to Max RPM',
    'Scenario 4: Hard Brake to Low Speed',
    'Scenario 5: Micro-Vibrations (Timeout Testing)'
};

% Tên file ảnh sử dụng dấu cách (đồng bộ với các ngày trước)
file_names = {
    'very low speed.png',
    'zero crossing.png',
    'fast acceleration.png',
    'hard brake.png',
    'micro vibrations.png'
};

% Khởi tạo thư mục lưu ảnh
result_dir = 'results/figure/day7';
if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end

% --- CHẠY VÒNG LẶP MÔ PHỎNG VÀ TRÍCH XUẤT ĐỊNH LƯỢNG ---
for i = 1:5
    omega_ref = omega_scenarios(i, :);
    theta_ref = cumtrapz(t, omega_ref);
    
    % Sinh tín hiệu Encoder
    [A, B, ~] = encoder_model(theta_ref, params);
    
    % Giải mã Quadrature
    [pos_count, missing_count] = quadrature_decoder_x4(A, B);
    
    % Tính toán Vị trí
    CPR = params.PPR * 4;
    dp_rad = 2 * pi / CPR;
    theta_raw = pos_count * dp_rad;
    theta_comp = position_compensator(theta_raw, missing_count, params.PPR);
    
    % Ước lượng Vận tốc
    error_flag = double(missing_count ~= 0);
    [omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count, t, params.PPR, error_flag);
    
    % =========================================================
    % TÍNH TOÁN CÁC CHỈ SỐ ĐỊNH LƯỢNG (METRICS)
    % =========================================================
    
    % 1. Sai số Vận tốc (M, T, Hybrid)
    err_M = omega_M - omega_ref;
    err_T = omega_T - omega_ref;
    err_H = omega_Hybrid - omega_ref;
    
    rmse_M = sqrt(mean(err_M.^2));
    rmse_T = sqrt(mean(err_T.^2));
    rmse_H = sqrt(mean(err_H.^2));
    
    mae_M = mean(abs(err_M));
    mae_T = mean(abs(err_T));
    mae_H = mean(abs(err_H));
    
    max_M = max(abs(err_M));
    max_T = max(abs(err_T));
    max_H = max(abs(err_H));
    
    % 2. Độ trễ (Latency) của Hybrid Estimator
    try
        delay_samples = finddelay(omega_ref, omega_Hybrid);
    catch
        [c, lags] = xcorr(omega_ref - mean(omega_ref), omega_Hybrid - mean(omega_Hybrid));
        [~, I] = max(abs(c));
        delay_samples = -lags(I);
    end
    latency_ms = (delay_samples * dt) * 1000;
    if latency_ms < 0, latency_ms = 0; end
    
    % 3. Timeout Count
    timeout_events = sum((omega_T(1:end-1) ~= 0) & (omega_T(2:end) == 0));
    
    % =========================================================
    % XUẤT BÁO CÁO CONSOLE
    % =========================================================
    fprintf('[%s]\n', titles{i});
    fprintf('----------------------------------------------------------------------\n');
    fprintf('| Estimator | RMSE (rad/s) | MAE (rad/s) | Max Error (rad/s) |\n');
    fprintf('----------------------------------------------------------------------\n');
    fprintf('| M-Method  | %-12.4f | %-11.4f | %-17.4f |\n', rmse_M, mae_M, max_M);
    fprintf('| T-Method  | %-12.4f | %-11.4f | %-17.4f |\n', rmse_T, mae_T, max_T);
    fprintf('| Hybrid    | %-12.4f | %-11.4f | %-17.4f |\n', rmse_H, mae_H, max_H);
    fprintf('----------------------------------------------------------------------\n');
    fprintf('=> System Latency (Hybrid Filter): %.2f ms\n', latency_ms);
    fprintf('=> T-Method Timeout Triggers     : %d events\n\n', timeout_events);
    
    % =========================================================
    % VẼ ĐỒ THỊ
    % =========================================================
    fig = figure('Name', titles{i}, 'NumberTitle', 'off', 'Position', [100, 100, 1200, 800], 'Visible', 'off');
    
    ax1 = subplot(2, 1, 1);
    plot(t, omega_ref, 'k', 'LineWidth', 2); hold on;
    plot(t, omega_M, 'r', 'LineWidth', 1);
    plot(t, omega_T, 'b', 'LineWidth', 1);
    plot(t, omega_Hybrid, 'g', 'LineWidth', 1.5);
    
    title(['Velocity Tracking: ', titles{i}]);
    xlabel('Time (s)');
    ylabel('Speed (rad/s)');
    legend('Reference', 'M-Method', 'T-Method', 'Hybrid Filter', 'Location', 'best');
    grid on;
    if i == 5, ylim([-2 2]); end
    
    ax2 = subplot(2, 1, 2);
    pos_error = theta_comp(:) - theta_ref(:);
    plot(t, pos_error, 'm', 'LineWidth', 1.5);
    title('Position Error (Compensated vs Reference)');
    xlabel('Time (s)');
    ylabel('Error (rad)');
    grid on;
    
    linkaxes([ax1, ax2], 'x');
    
    % Lưu ảnh
    saveas(fig, fullfile(result_dir, file_names{i}));
    close(fig);
end

fprintf('Đã hoàn thành xuất file ảnh vào thư mục %s.\n', result_dir);
fprintf('======================================================================\n');