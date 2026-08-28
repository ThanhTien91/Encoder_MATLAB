function [A_sat, B_sat, total_missed] = inject_acquisition_saturation(A, B, Fs, params)
% =====================================================================
% SCRIPT: inject_acquisition_saturation.m
% MỤC TIÊU: Mô phỏng giới hạn băng thông số (Bandwidth Saturation).
% Cơ chế: Nếu khoảng thời gian giữa 2 sự kiện (cạnh A hoặc B) nhỏ hơn 
% giới hạn chu kỳ phản hồi của phần cứng, sự kiện đó sẽ bị hệ thống bỏ qua.
% =====================================================================

% Kiểm tra Input
assert(length(A) == length(B), 'Tín hiệu A và B phải có cùng chiều dài.');

% Lấy giới hạn tần số sự kiện từ config
max_freq = params.hw.max_event_freq;

% Số mẫu tối thiểu vi điều khiển cần để xử lý 1 sự kiện
min_samples_between_events = Fs / max_freq;

N = length(A);
A_sat = zeros(N, 1);
B_sat = zeros(N, 1);

% Khởi tạo trạng thái ban đầu
A_sat(1) = A(1);
B_sat(1) = B(1);

last_event_idx = 1;
total_missed = 0;

% Chạy State-Machine quét qua từng mẫu thời gian
for i = 2:N
    % Phát hiện có sự thay đổi cạnh (Edge Transition)
    if A(i) ~= A(i-1) || B(i) ~= B(i-1)
        delta_samples = i - last_event_idx;

        % Kiểm tra băng thông
        if delta_samples >= min_samples_between_events
            % Hệ thống đủ thời gian phản hồi -> Chốt trạng thái mới
            A_sat(i) = A(i);
            B_sat(i) = B(i);
            last_event_idx = i;
        else
            % Bão hòa băng thông! Hệ thống không kịp phản hồi ngắt.
            % -> Giữ nguyên trạng thái cũ (Bỏ lỡ sự kiện)
            A_sat(i) = A_sat(i-1);
            B_sat(i) = B_sat(i-1);
            total_missed = total_missed + 1;
        end
    else
        % Không có sự kiện, duy trì trạng thái
        A_sat(i) = A_sat(i-1);
        B_sat(i) = B_sat(i-1);
    end
end
end