% =========================================================================
% SCRIPT: analyze_pulse_loss.m
% MỤC TIÊU: Đánh giá xác suất rớt xung với Monte Carlo (N=50 trials)
% =========================================================================
clc; clear; close all;
addpath(fullfile(pwd, '..', 'decoder'));
addpath(fullfile(pwd, '..', 'config'));

params = default_params();
PPR = params.PPR; CPR = PPR * 4; dp_rad = 2 * pi / CPR;

rng(params.rng_seed); % Đảm bảo tính lặp lại

loss_list = [0, 0.1, 0.5, 1.0, 1.5, 2.0]; 
N_pulses = 10000; 
N_trials = 50; % Số lượng thử nghiệm MC

fprintf('=========================================================================\n');
fprintf('    PULSE LOSS MONTE CARLO ANALYSIS (N = %d trials) \n', N_trials);
fprintf('=========================================================================\n');
fprintf('| Loss(%%) | RMSE OFF (Mean) | RMSE ON (Mean) | Improvement(%%) | Max Err(ON)|\n');
fprintf('-------------------------------------------------------------------------\n');

for i = 1:length(loss_list)
    loss_rate = loss_list(i) / 100;
    
    temp_rmse_off = zeros(N_trials, 1);
    temp_rmse_on  = zeros(N_trials, 1);
    temp_max_on   = zeros(N_trials, 1);
    
    for k = 1:N_trials
        seq = [0, 2, 3, 1];
        states = seq(mod(0:N_pulses-1, 4) + 1);
        
        % Tiêm lỗi
        fault_idx = rand(1, N_pulses) < loss_rate;
        states_faulty = states;
        for j = 2:N_pulses
            if fault_idx(j)
                states_faulty(j) = seq(mod(j-1+1, 4) + 1); % Double jump
            end
        end
        
        A_in = floor(states_faulty / 2); B_in = mod(states_faulty, 2);
        [pos_count, missing_count] = quadrature_decoder_x4(A_in, B_in);
        
        theta_true = (0:N_pulses-1)' * dp_rad;
        theta_off  = pos_count * dp_rad;
        theta_on   = position_compensator(theta_off, missing_count, PPR);
        
        m_off = compute_metrics(theta_true, theta_off);
        m_on  = compute_metrics(theta_true, theta_on);
        
        temp_rmse_off(k) = m_off.rmse;
        temp_rmse_on(k)  = m_on.rmse;
        temp_max_on(k)   = m_on.max_error;
    end
    
    % Trung bình thống kê
    mean_off = mean(temp_rmse_off);
    mean_on  = mean(temp_rmse_on);
    max_on   = max(temp_max_on); % Worst-case max error
    
    if mean_off > 0
        improvement = ((mean_off - mean_on) / mean_off) * 100;
    else
        improvement = 0;
    end
    
    fprintf('| %-7.1f | %-15.4f | %-14.4f | %-14.2f | %-10.4f |\n', ...
            loss_list(i), mean_off, mean_on, improvement, max_on);
end
fprintf('=========================================================================\n');