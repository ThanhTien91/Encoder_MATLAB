% =========================================================================
% SCRIPT: analyze_scenarios.m
% MỤC TIÊU: Quét toàn bộ kịch bản mô phỏng, tính toán Metrics và xuất CSV
% =========================================================================

clc; clear; close all;

% 1. Load dữ liệu (Đảm bảo file này đã được sinh ra từ Giai đoạn 1)
data_file = fullfile('..', 'results', 'scenario_results.mat');
if ~exist(data_file, 'file')
    error('Không tìm thấy scenario_results.mat. Hãy chạy script Ngày 7 để sinh dữ liệu trước!');
end
load(data_file, 'scenario_data');

% Khởi tạo thư mục chứa bảng nếu chưa có
out_dir = fullfile('..', 'results', 'tables');
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

scenarios = fieldnames(scenario_data);
num_scenarios = length(scenarios);

% Chuẩn bị cell array để lưu data xuất CSV
csv_data = cell(num_scenarios + 1, 6);
csv_data(1, :) = {'Scenario_Name', 'Position_RMSE', 'Speed_M_RMSE', 'Speed_T_RMSE', 'Speed_Hybrid_RMSE', 'Delay_Approx'};

fprintf('==========================================================================================\n');
fprintf('                      BẢNG TỔNG HỢP KẾT QUẢ CÁC KỊCH BẢN (DAY 8)\n');
fprintf('==========================================================================================\n');
fprintf('| %-18s | %-12s | %-12s | %-12s | %-15s |\n', 'Kịch bản', 'Pos RMSE', 'M RMSE', 'T RMSE', 'Hybrid RMSE');
fprintf('------------------------------------------------------------------------------------------\n');

% 2. Vòng lặp quét và tính toán
for i = 1:num_scenarios
    s_name = scenarios{i};
    data = scenario_data.(s_name);

    % Tính toán Position
    m_pos = compute_metrics(data.position.true, data.position.est);

    % Tính toán Speed cho 3 bộ
    m_speed_M = compute_metrics(data.speed.true, data.speed.M);
    m_speed_T = compute_metrics(data.speed.true, data.speed.T);
    m_speed_H = compute_metrics(data.speed.true, data.speed.Hybrid);

    % In ra Command Window
    fprintf('| %-18s | %-12.4f | %-12.4f | %-12.4f | %-15.4f |\n', ...
        data.name, m_pos.rmse, m_speed_M.rmse, m_speed_T.rmse, m_speed_H.rmse);

    % Ghi vào mảng xuất CSV
    csv_data(i+1, :) = {data.name, m_pos.rmse, m_speed_M.rmse, m_speed_T.rmse, m_speed_H.rmse, 'N/A'};
end
fprintf('==========================================================================================\n');

% 3. Xuất file CSV
csv_path = fullfile(out_dir, 'scenario_summary.csv');
writecell(csv_data, csv_path);
fprintf('>> Đã xuất bảng tổng hợp ra file: %s\n', csv_path);