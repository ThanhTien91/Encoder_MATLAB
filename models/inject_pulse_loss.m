function [A_noisy, B_noisy, stats] = inject_pulse_loss(A, B, drop_rate)
% INJECT_PULSE_LOSS (Symmetric Phase Version)
% Mô phỏng lỗi mất xung encoder đảm bảo tính đối xứng pha.
%
% Bằng cách chọn ngẫu nhiên một sự kiện chuyển trạng thái bất kỳ,
% lỗi sẽ bắt đầu ở một pha ngẫu nhiên (00, 01, 11, 10 với xác suất 25%).
% Điều này triệt tiêu sự thiên lệch (bias) giữa chiều thuận và chiều ngược.

    A_noisy = A;
    B_noisy = B;

    % 1. Gom A và B thành một mã trạng thái (0 đến 3)
    % Để tìm TẤT CẢ các sự kiện chuyển trạng thái một cách dễ dàng
    state = A * 2 + B;
    edges = find(diff(state) ~= 0) + 1;
    num_transitions = length(edges);

    % 2. Số lượng pulse tổng cộng (1 pulse = 4 transitions)
    num_total_pulses = floor(num_transitions / 4);
    num_dropped_pulses = round(drop_rate * num_total_pulses);

    stats.total_pulses = num_total_pulses;
    stats.dropped_pulses = num_dropped_pulses;
    stats.actual_drop_rate = (num_dropped_pulses / num_total_pulses) * 100;

    if num_dropped_pulses == 0
        return;
    end

    % 3. Chọn ngẫu nhiên vị trí bắt đầu lỗi
    % Bốc ngẫu nhiên một index chuyển trạng thái BẤT KỲ thay vì theo cụm 4
    valid_max_idx = max(1, num_transitions - 4);
    rand_trans_idx = randperm(valid_max_idx, num_dropped_pulses);

    % 4. Thực hiện xóa tín hiệu
    for i = 1:length(rand_trans_idx)
        start_trans = rand_trans_idx(i);
        
        % Lỗi kéo dài đúng 1 chu kỳ vật lý (4 lần chuyển trạng thái)
        end_trans = start_trans + 4; 

        start_sample = edges(start_trans);
        
        if end_trans <= num_transitions
            end_sample = edges(end_trans) - 1;
        else
            end_sample = length(A);
        end

        % Ép A và B về 0 (Mô phỏng rãnh quang bị che khuất)
        A_noisy(start_sample:end_sample) = 0;
        B_noisy(start_sample:end_sample) = 0;
    end
end