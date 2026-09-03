function [A_noisy, B_noisy] = inject_micro_noise(A, B, jitter_range, bounce_prob)
% INJECT_MICRO_NOISE
% Mô phỏng sai lệch pha, nhiễu Jitter và Dội xung (Bounce)
% Tương thích với tần số lấy mẫu Fs = 1 MHz
%
% jitter_range : biên độ jitter cạnh xung, tính bằng số mẫu (mặc định 2,
%                giữ đúng hành vi gốc nếu không truyền vào)
% bounce_prob  : xác suất xảy ra bounce tại mỗi cạnh xung (mặc định 0.25,
%                giữ đúng hành vi gốc nếu không truyền vào)

if nargin < 3 || isempty(jitter_range)
    jitter_range = 2;
end
if nargin < 4 || isempty(bounce_prob)
    bounce_prob = 0.25;
end

A_noisy = A;
B_noisy = B;
N = length(A);

% 1. Sai lệch pha tĩnh (Phase Error)
% Dịch vòng kênh B đi 5 mẫu (tương đương lệch pha thêm 5 micro-giây)
phase_shift = 5;
B_noisy = circshift(B_noisy, phase_shift);

% Tìm vị trí các sườn xung (cạnh lên và cạnh xuống)
edges_A = find(diff(A_noisy) ~= 0);
edges_B = find(diff(B_noisy) ~= 0);

% 2. Chèn Jitter và Bounce cho Kênh A
for i = 1:length(edges_A)
    idx = edges_A(i);

    % Jitter: Cạnh xung dịch chuyển ngẫu nhiên trong khoảng [-jitter_range, jitter_range] mẫu
    jitter = randi([-jitter_range, jitter_range]);

    if (idx + jitter > 1) && (idx + jitter < N-5)
        % Bounce: Xác suất bounce_prob xảy ra nảy trạng thái (0-1-0) ngay tại sườn xung
        if rand() < bounce_prob
            A_noisy(idx+jitter : idx+jitter+2) = randi([0 1], 1, 3);
        end
    end
end

% 3. Chèn Jitter và Bounce cho Kênh B
for i = 1:length(edges_B)
    idx = edges_B(i);
    jitter = randi([-jitter_range, jitter_range]);
    if (idx + jitter > 1) && (idx + jitter < N-5)
        if rand() < bounce_prob
            B_noisy(idx+jitter : idx+jitter+2) = randi([0 1], 1, 3);
        end
    end
end
end