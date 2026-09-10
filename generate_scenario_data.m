% =========================================================================
% SCRIPT: generate_scenario_data.m (GIAI ĐOẠN 1 - DAY 8)
% MỤC TIÊU: Chạy các kịch bản và đóng gói toàn bộ dữ liệu ra file .mat
% =========================================================================

clc; clear; close all;

% Nạp đường dẫn thuật toán
addpath(fullfile(pwd, 'decoder'));
addpath(fullfile(pwd, 'config'));

% Khởi tạo thư mục chứa kết quả nếu chưa có
if ~exist('results', 'dir')
    mkdir('results');
end

% Lấy tham số hệ thống
params = default_params();
PPR = params.PPR;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;
Fs = params.Fs;

% Biến lưu trữ tổng hợp
scenario_data = struct();

fprintf('Đang tiến hành mô phỏng và đóng gói dữ liệu kịch bản...\n');

%% --- KỊCH BẢN 1: VẬN TỐC RẤT THẤP (LOW SPEED) ---
fprintf('>> Chạy Kịch bản 1: Low Speed (2 rad/s)...\n');
% 1. Sinh quỹ đạo thực (True Motion)
t_1 = (0:1/Fs:1)'; % Chạy trong 1s
omega_true_1 = 2 * ones(size(t_1)); % Vận tốc 2 rad/s
theta_true_1 = 2 * t_1;

% 2. Sinh tín hiệu và giả lập mất xung (Mockup - bạn thay bằng hàm sinh vật lý của bạn)
% (Giả lập mảng pos_count và error_flag đã được giải mã)
N1 = length(t_1);
pos_count_1 = floor(theta_true_1 / dp_rad);
error_flag_1 = zeros(N1, 1); 
missing_count_1 = zeros(N1, 1);

% 3. Đưa qua Estimator
[omega_M_1, omega_T_1, omega_Hybrid_1] = speed_estimator(pos_count_1, t_1, PPR, error_flag_1);
theta_comp_1 = position_compensator(pos_count_1 * dp_rad, missing_count_1, PPR);

% 4. Đóng gói vào Struct
scenario_data.scenario1.name = 'Low_Speed_2_rad_s';
scenario_data.scenario1.t = t_1;
scenario_data.scenario1.params = params;
scenario_data.scenario1.position.true = theta_true_1;
scenario_data.scenario1.position.est = theta_comp_1;
scenario_data.scenario1.speed.true = omega_true_1;
scenario_data.scenario1.speed.M = omega_M_1(:);
scenario_data.scenario1.speed.T = omega_T_1(:);
scenario_data.scenario1.speed.Hybrid = omega_Hybrid_1(:);


%% --- KỊCH BẢN 2: ĐẢO CHIỀU QUAY (ZERO CROSSING) ---
fprintf('>> Chạy Kịch bản 2: Zero Crossing (+20 rad/s xuống -20 rad/s)...\n');
% 1. Sinh quỹ đạo thực (True Motion)
t_2 = (0:1/Fs:2)'; % Chạy trong 2s
omega_true_2 = 20 - 20 * t_2; % Giảm dần từ 20 xuống -20 (qua 0 tại t=1s)
theta_true_2 = 20 * t_2 - 10 * t_2.^2;

% 2. Sinh tín hiệu giả lập
N2 = length(t_2);
pos_count_2 = floor(theta_true_2 / dp_rad);
error_flag_2 = zeros(N2, 1);
missing_count_2 = zeros(N2, 1);

% 3. Đưa qua Estimator
[omega_M_2, omega_T_2, omega_Hybrid_2] = speed_estimator(pos_count_2, t_2, PPR, error_flag_2);
theta_comp_2 = position_compensator(pos_count_2 * dp_rad, missing_count_2, PPR);

% 4. Đóng gói vào Struct
scenario_data.scenario2.name = 'Zero_Crossing';
scenario_data.scenario2.t = t_2;
scenario_data.scenario2.params = params;
scenario_data.scenario2.position.true = theta_true_2;
scenario_data.scenario2.position.est = theta_comp_2;
scenario_data.scenario2.speed.true = omega_true_2;
scenario_data.scenario2.speed.M = omega_M_2(:);
scenario_data.scenario2.speed.T = omega_T_2(:);
scenario_data.scenario2.speed.Hybrid = omega_Hybrid_2(:);

%% --- LƯU TRỮ RA FILE .MAT ---
save_path = fullfile('results', 'scenario_results.mat');
save(save_path, 'scenario_data');

fprintf('======================================================\n');
fprintf('ĐÃ LƯU THÀNH CÔNG: %s\n', save_path);
fprintf('Giai đoạn 1 hoàn tất. Dữ liệu đã sẵn sàng cho phân tích!\n');
fprintf('======================================================\n');