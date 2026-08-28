function [calibrated_phase, uncertainty] = encoder_calibration(A, B, Fs, omega_ref, PPR)
% =====================================================================
% ENCODER CALIBRATION MODULE
% Ước lượng Systematic Phase Error thông qua thống kê đa mẫu (Multi-edge)
% =====================================================================

% Input Validation
assert(length(A) == length(B), 'Tín hiệu A và B phải có cùng chiều dài.');
assert(omega_ref > 0, 'Tốc độ hiệu chuẩn (omega_ref) phải lớn hơn 0.');

% 1. Tìm các cạnh lên (Rising Edges)
rising_A = find(diff(A) == 1) + 1;
rising_B = find(diff(B) == 1) + 1;

% Đảm bảo có đủ cạnh để thống kê
assert(length(rising_A) > 10 && length(rising_B) > 10, ...
    'Không đủ số lượng xung để hiệu chuẩn. Hãy tăng thời gian chạy.');

% 2. Ghép cặp cạnh A và cạnh B liền kề
phase_errors = zeros(min(length(rising_A), length(rising_B)) - 1, 1);
valid_pairs = 0;

% Tần số điện lý tưởng (Hz)
f_elec = (omega_ref / (2 * pi)) * PPR;
T_elec_samples = Fs / f_elec; % Số mẫu lý tưởng cho 1 chu kỳ điện

for i = 1:length(rising_A)-1
    % Tìm cạnh B đầu tiên xuất hiện sau cạnh A
    idx_B = find(rising_B > rising_A(i), 1, 'first');
    if ~isempty(idx_B)
        delta_samples = rising_B(idx_B) - rising_A(i);

        % Góc đo được (rad)
        phi_measured = (delta_samples / T_elec_samples) * 2 * pi;

        % Góc lý tưởng là pi/2. Mọi sự sai khác là Phase Error.
        err = phi_measured - (pi/2);

        valid_pairs = valid_pairs + 1;
        phase_errors(valid_pairs) = err;
    end
end

phase_errors = phase_errors(1:valid_pairs);

% 3. Trả về giá trị Trung bình (Systematic) và Độ bất định (Uncertainty)
calibrated_phase = mean(phase_errors);
uncertainty = std(phase_errors) / sqrt(valid_pairs); % 1-sigma confidence interval
end