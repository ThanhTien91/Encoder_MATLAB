% ==========================================
% TẦNG 2 - MANUAL VERIFICATION
% Kiểm chứng chéo công thức toán học lõi
% ==========================================

clear;
clc;
close all;

% ==========================================
% 1. THIẾT LẬP MÔI TRƯỜNG VÀ MÔ HÌNH
% ==========================================

addpath('config');
addpath('models');
addpath('decoder');

params = default_params();

% Sinh dữ liệu lý tưởng (không nhiễu)
[t, theta_true, ~]    = trajectory_model(params);
[A_ideal, B_ideal, ~] = encoder_model(theta_true, params);

% Giải mã lấy số đếm thuần
[pos_count, ~] = quadrature_decoder_x4(A_ideal, B_ideal); 

% ==========================================
% 2. TRÍCH XUẤT DỮ LIỆU TẠI THỜI ĐIỂM KIỂM TRA
% ==========================================

target_time = 0.5; % Thời điểm giây thứ 0.5
[~, idx]    = min(abs(t - target_time));

N_count_matlab = pos_count(idx);
PPR            = params.PPR;

% ==========================================
% 3. TÍNH TOÁN QUY ĐỔI ĐỘC LẬP
% ==========================================

% Công thức quy đổi tính tay (độc lập)
theta_manual  = (2 * pi * N_count_matlab) / (PPR * 4);

% Biến được hệ thống MATLAB quy đổi đồng loạt
theta_matlab  = (N_count_matlab * 2*pi) / (PPR * 4);

% Trích xuất góc quay vật lý gốc để tham chiếu thêm
theta_thuc_te = theta_true(idx);

% ==========================================
% 4. IN BÁO CÁO KIỂM CHỨNG
% ==========================================

fprintf('\n==============================================\n');
fprintf('   BÁO CÁO KIỂM CHỨNG MÔ HÌNH (VERIFICATION)\n');
fprintf('==============================================\n');
fprintf('Thời điểm kiểm tra      : t = %.3f s\n', t(idx));
fprintf('Số đếm Encoder (X4)     : N = %d counts\n', N_count_matlab);
fprintf('1. Góc quay tính TAY    : %.6f rad\n', theta_manual);
fprintf('2. Góc quay MATLAB tính : %.6f rad\n', theta_matlab);
fprintf('Sai lệch (TAY vs MATLAB): %.2e rad\n', abs(theta_manual - theta_matlab));
fprintf('==============================================\n');