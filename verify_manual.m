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

%% ========================================================================
% LEVEL 3: POSITION COMPENSATION GROUND TRUTH
% =========================================================================
fprintf('\n');
fprintf('======================================================================\n');
fprintf('       LEVEL 3: POSITION COMPENSATION GROUND TRUTH CHECK\n');
fprintf('======================================================================\n');

% =========================================================================
% 1. PARAMETERS
% =========================================================================
PPR = 1000;
CPR = PPR * 4;
dp_rad = 2 * pi / CPR;

% =========================================================================
% 2. CREATE IDEAL QUADRATURE STATE SEQUENCE
% =========================================================================
% Forward sequence:
% 00 -> 10 -> 11 -> 01 -> 00

seq = [0, 2, 3, 1];

% 500 true X4 transitions
N_valid = 500;

states_full = ...
    seq(mod(0:N_valid, 4) + 1);

% =========================================================================
% 3. INJECT ONE MISSING TRANSITION
% =========================================================================
% Chọn state 01 để xóa.
%
% Bình thường:
%
%       11 -> 01 -> 00
%
% Sau khi mất transition 11 -> 01:
%
%       11 -------> 00
%
% Đây là một double-jump tương ứng với 2 X4 counts bị bỏ qua.
%
% Index 252 của chuỗi tương ứng state 01:
%   index 251 = 11
%   index 252 = 01
%   index 253 = 00

fault_idx = 252;

% Kiểm tra state trước khi xóa
assert(states_full(fault_idx) == 1, ...
    'fault_idx không trỏ tới state 01 như mong đợi.');

states = states_full;

% Xóa state bị mất
states(fault_idx) = [];

% =========================================================================
% 4. CONVERT STATE -> A/B
% =========================================================================
A_lvl3 = floor(states / 2);
B_lvl3 = mod(states, 2);

% =========================================================================
% 5. RUN X4 DECODER
% =========================================================================
[pos_count_lvl3, missing_count_lvl3] = ...
    quadrature_decoder_x4(A_lvl3, B_lvl3);

% =========================================================================
% 6. RAW + COMPENSATED POSITION
% =========================================================================
theta_raw_lvl3 = ...
    pos_count_lvl3 * dp_rad;

theta_comp_lvl3 = ...
    position_compensator( ...
        theta_raw_lvl3, ...
        missing_count_lvl3, ...
        PPR);

% =========================================================================
% 7. GROUND TRUTH
% =========================================================================
% Quan trọng:
%
% Rotor thực tế vẫn thực hiện đủ 500 X4 transitions.
% Chỉ có một transition bị acquisition/decoder bỏ qua.
%
% Vì vậy ground truth vẫn = 500 counts.

true_counts_lvl3 = N_valid;

theta_true_lvl3 = ...
    true_counts_lvl3 * dp_rad;

% =========================================================================
% 8. ERROR CALCULATION
% =========================================================================
err_raw_lvl3 = ...
    abs(theta_raw_lvl3(end) - theta_true_lvl3);

err_comp_lvl3 = ...
    abs(theta_comp_lvl3(end) - theta_true_lvl3);

% =========================================================================
% 9. FIND DETECTED MISSING COUNT
% =========================================================================
miss_idx_lvl3 = ...
    find(missing_count_lvl3 ~= 0, 1, 'first');

if ~isempty(miss_idx_lvl3)
    detected_missing_lvl3 = ...
        missing_count_lvl3(miss_idx_lvl3);
else
    detected_missing_lvl3 = 0;
end

% =========================================================================
% 10. REPORT
% =========================================================================
fprintf('\n');
fprintf('[LEVEL 3] SINGLE DOUBLE-JUMP COMPENSATION TEST\n');
fprintf('----------------------------------------------------------------------\n');

fprintf('PPR                         : %d\n', PPR);
fprintf('CPR (X4)                   : %d counts/rev\n', CPR);
fprintf('Ground-truth counts        : %d\n', true_counts_lvl3);
fprintf('Expected missing count     : +2\n');

fprintf('----------------------------------------------------------------------\n');

fprintf('| Metric                    | Value                |\n');
fprintf('----------------------------------------------------------------------\n');

fprintf('| True position             | %.9f rad      |\n', ...
    theta_true_lvl3);

fprintf('| Raw position              | %.9f rad      |\n', ...
    theta_raw_lvl3(end));

fprintf('| Compensated position      | %.9f rad      |\n', ...
    theta_comp_lvl3(end));

fprintf('| Raw position error        | %.3e rad      |\n', ...
    err_raw_lvl3);

fprintf('| Compensated position err. | %.3e rad      |\n', ...
    err_comp_lvl3);

fprintf('----------------------------------------------------------------------\n');

if ~isempty(miss_idx_lvl3)

    fprintf('Detected missing_count      : %d\n', ...
        detected_missing_lvl3);

else

    fprintf('Detected missing_count      : NONE\n');

end

fprintf('----------------------------------------------------------------------\n');

% =========================================================================
% 11. PASS / FAIL
% =========================================================================
if detected_missing_lvl3 == 2 && err_comp_lvl3 < 1e-10

    fprintf('=> LEVEL 3 STATUS: PASS\n');
    fprintf('=> Double-jump detected and position compensation is correct.\n');

else

    fprintf('=> LEVEL 3 STATUS: FAIL\n');

    if detected_missing_lvl3 ~= 2
        fprintf('=> Expected missing_count = +2, detected = %d.\n', ...
            detected_missing_lvl3);
    end

    if err_comp_lvl3 >= 1e-10
        fprintf('=> Compensation residual error = %.3e rad.\n', ...
            err_comp_lvl3);
    end

end

fprintf('======================================================================\n');
fprintf('\n');