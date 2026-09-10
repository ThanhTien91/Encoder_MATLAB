function [A_sat, B_sat, total_missed] = inject_acquisition_saturation(A, B, Fs, params)

% =========================================================================
% FUNCTION: inject_acquisition_saturation.m
% MỤC TIÊU:
%   Mô phỏng giới hạn băng thông của tầng acquisition phần cứng.
%
% CƠ CHẾ:
%   Nếu khoảng thời gian giữa hai transition liên tiếp nhỏ hơn thời gian
%   phần cứng cần để xử lý một event, transition mới sẽ bị bỏ qua.
%
% OUTPUT:
%   A_sat          : tín hiệu A sau saturation
%   B_sat          : tín hiệu B sau saturation
%   total_missed   : số transition bị acquisition bỏ qua
% =========================================================================

% =========================================================================
% 1. INPUT VALIDATION
% =========================================================================
assert( ...
    length(A) == length(B), ...
    'Tín hiệu A và B phải có cùng chiều dài.');

% =========================================================================
% 2. BANDWIDTH CONFIGURATION
% =========================================================================
max_freq = params.hw.max_event_freq;

% Số sample tối thiểu giữa hai transition để phần cứng xử lý được
min_samples_between_events = Fs / max_freq;

% =========================================================================
% 3. INITIALIZATION
% =========================================================================
N = length(A);

A_sat = zeros(N, 1);
B_sat = zeros(N, 1);

% Trạng thái ban đầu
A_sat(1) = A(1);
B_sat(1) = B(1);

% Index của transition gần nhất đã được chấp nhận
last_event_idx = 1;

% Số transition thực sự bị bỏ qua
total_missed = 0;

% =========================================================================
% 4. ACQUISITION STATE MACHINE (ĐÃ VÁ LỖI PHASE CORRUPTION)
% =========================================================================
lock_counter = 0; % Đếm số cạnh cần bỏ qua để giữ nguyên pha (bội số của 4)

for i = 2:N
    is_transition = (A(i) ~= A(i-1)) || (B(i) ~= B(i-1));

    if is_transition
        if lock_counter > 0
            % Đang trong chu kỳ xả bão hòa, bắt buộc bỏ qua để giữ đúng pha
            A_sat(i) = A_sat(i-1);
            B_sat(i) = B_sat(i-1);
            lock_counter = lock_counter - 1;
            total_missed = total_missed + 1;
            last_event_idx = i; % Trượt mốc thời gian theo
        else
            delta_samples = i - last_event_idx;
            if delta_samples >= min_samples_between_events
                % Chấp nhận sự kiện
                A_sat(i) = A(i);
                B_sat(i) = B(i);
                last_event_idx = i;
            else
                % Xảy ra bão hòa! Khóa 4 cạnh (1 full pulse) để chống dội pha
                A_sat(i) = A_sat(i-1);
                B_sat(i) = B_sat(i-1);
                lock_counter = 3; % Đã rớt 1 cạnh, khóa 3 cạnh tiếp theo
                total_missed = total_missed + 1;
                last_event_idx = i;
            end
        end
    else
        A_sat(i) = A_sat(i-1);
        B_sat(i) = B_sat(i-1);
    end
end

end