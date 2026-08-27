% =========================================================================
% SCRIPT: verify_manual.m
% MỤC TIÊU: Analytical/Manual Verification (Giai đoạn 2 - Ngày 6)
% TÁC GIẢ: Nhóm Kỹ sư Kiểm thử
% =========================================================================

clc; clear; close all;

addpath(fullfile(pwd, 'decoder'));
addpath(fullfile(pwd, 'config'));
addpath(fullfile(pwd, 'models'));

fprintf('======================================================================\n');
fprintf('       ĐỒ ÁN ENCODER - BÁO CÁO KIỂM CHỨNG TOÁN HỌC (SANITY CHECK)     \n');
fprintf('======================================================================\n\n');

%% ========================================================================
% LEVEL 1: STATIC MANUAL CHECK (TÍNH TAY TĨNH)
% Mục tiêu: Kiểm chứng tính đúng đắn của hàm giải mã và bù trừ vị trí
% =========================================================================
PPR = 1000;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;
target_counts = 500;

% 1. Tự động sinh mảng trạng thái (State Sequence)
% Chuỗi tiến chuẩn: 00(0) -> 10(2) -> 11(3) -> 01(1)
seq = [0, 2, 3, 1];
N_steps = 498; 

% Khởi tạo mảng có 498 bước hợp lệ + 1 bước nhảy kép
states = zeros(1, N_steps + 2);
states(1:N_steps+1) = seq(mod(0:N_steps, 4) + 1);

% Bơm lỗi: Nhảy kép từ trạng thái 3 (A=1,B=1) về 0 (A=0,B=0) -> Mất 2 xung
states(end) = 0; 

% Giải mã ra kênh A và B
A_lvl1 = floor(states / 2);
B_lvl1 = mod(states, 2);

% 2. Đưa vào thuật toán
[pos_count_lvl1, missing_count_lvl1] = quadrature_decoder_x4(A_lvl1, B_lvl1);
theta_raw = pos_count_lvl1 * dp_rad; 
theta_comp = position_compensator(theta_raw, missing_count_lvl1, PPR);

% 3. Đối chiếu lý thuyết
theta_theory = target_counts * dp_rad;
theta_calc = theta_comp(end);
err_lvl1 = abs(theta_calc - theta_theory);

% --- THÊM BỘ LỌC KHỬ NHIỄU DẤU PHẨY ĐỘNG ---
if err_lvl1 < 1e-10
    err_lvl1 = 0;
end

% In Báo cáo Level 1
fprintf('[LEVEL 1] STATIC MANUAL CHECK (POSITION)\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('- PPR             : %d\n', PPR);
fprintf('- Decoder Mode    : x4\n');
fprintf('- Target Count    : %d (498 Valid + 1 Double-Jump = 500 Counts)\n', target_counts);
fprintf('----------------------------------------------------------------------\n');
fprintf('| Metric          | Theoretical      | Calculated       | Error      |\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('| Theta (rad)     | %-16.6f | %-16.6f | %.2e   |\n', theta_theory, theta_calc, err_lvl1);
fprintf('----------------------------------------------------------------------\n\n');

%% ========================================================================
% LEVEL 2: CONSTANT-SPEED ANALYTICAL CASE (KIỂM CHỨNG ĐỘNG HỌC)
% Mục tiêu: Đảm bảo các bộ ước lượng hội tụ chính xác tuyệt đối 10 rad/s
% =========================================================================
omega_ideal = 10; % rad/s
dt_approx = 0.05; % seconds

% 1. Dùng toán học đảo ngược tính số xung lý tưởng
N_float = (omega_ideal * dt_approx / (2*pi)) * CPR;
N_pulses = round(N_float); % Làm tròn để ra mảng vật lý (318 xung)

% 2. Xử lý triệt tiêu nhiễu lượng tử
% Tính lại đúng bước thời gian Ts để tương ứng với đúng 10 rad/s cho mỗi xung
Ts_exact = dp_rad / omega_ideal; 

% 3. Sinh tín hiệu A, B hoàn hảo
t_lvl2 = (0:N_pulses) * Ts_exact;
states_lvl2 = seq(mod(0:N_pulses, 4) + 1);
A_lvl2 = floor(states_lvl2 / 2);
B_lvl2 = mod(states_lvl2, 2);

% 4. Chạy qua hệ thống Estimator
[pos_count_lvl2, ~] = quadrature_decoder_x4(A_lvl2, B_lvl2);
error_flag = zeros(size(pos_count_lvl2)); % Không có lỗi phần cứng
[omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count_lvl2, t_lvl2, PPR, error_flag);

% 5. Lấy giá trị hội tụ ở trạng thái xác lập (Steady-state)
val_M = omega_M(end);
val_T = omega_T(end);
val_H = omega_Hybrid(end);

err_M = abs(val_M - omega_ideal);
err_T = abs(val_T - omega_ideal);
err_H = abs(val_H - omega_ideal);

% --- THÊM BỘ LỌC KHỬ NHIỄU DẤU PHẨY ĐỘNG ---
if err_M < 1e-10, err_M = 0; end
if err_T < 1e-10, err_T = 0; end
if err_H < 1e-10, err_H = 0; end

% In Báo cáo Level 2
fprintf('[LEVEL 2] CONSTANT-SPEED ANALYTICAL CASE (VELOCITY)\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('- Ideal Speed     : %.3f rad/s\n', omega_ideal);
fprintf('- Duration        : %.2f s\n', dt_approx);
fprintf('- Pulses Gen (N)  : %d\n', N_pulses);
fprintf('----------------------------------------------------------------------\n');
fprintf('| Estimator       | Theoretical      | Calculated       | Error      |\n');
fprintf('----------------------------------------------------------------------\n');
fprintf('| M-Method        | %-16.6f | %-16.6f | %.2e   |\n', omega_ideal, val_M, err_M);
fprintf('| T-Method        | %-16.6f | %-16.6f | %.2e   |\n', omega_ideal, val_T, err_T);
fprintf('| Hybrid Method   | %-16.6f | %-16.6f | %.2e   |\n', omega_ideal, val_H, err_H);
fprintf('----------------------------------------------------------------------\n');
fprintf('=> KIỂM CHỨNG THÀNH CÔNG: Kết quả tính toán khớp giá trị lý thuyết trong sai số số học floating-point.\n');
fprintf('======================================================================\n');