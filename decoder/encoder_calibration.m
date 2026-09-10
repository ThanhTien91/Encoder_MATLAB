function [calibrated_phase, uncertainty] = encoder_calibration(A, B, Fs, omega_ref, PPR)

% =========================================================================
% ENCODER_CALIBRATION - Multi-edge phase calibration
%
% MỤC TIÊU:
%   Ước lượng systematic phase error giữa hai kênh quadrature A/B
%   bằng thống kê trên nhiều rising edge.
%
% LIMITATION:
%   Calibration requires a known reference angular velocity (omega_ref)
%   to convert measured edge timing into electrical phase.
%
%   In production, omega_ref could be obtained from the Hybrid estimator
%   at a steady-state operating point.
%
% =========================================================================

% =========================================================================
% 1. INPUT VALIDATION
% =========================================================================
assert( ...
    length(A) == length(B), ...
    'Tín hiệu A và B phải có cùng chiều dài.');

assert( ...
    mean(omega_ref) > 0, ...
    'Tốc độ hiệu chuẩn (omega_ref) phải lớn hơn 0.');

% --- VÁ LỖI: CHẶN HIỆU CHUẨN KHI ĐANG TĂNG/GIẢM TỐC ---
assert(std(omega_ref) < 1e-3, ...
    'Lỗi Động học: Tham chiếu omega_ref không ổn định. Thuật toán Calibration chỉ có giá trị xác thực tại điểm vận hành hằng tốc (steady-state).');
% =========================================================================
% 2. FIND RISING EDGES
% =========================================================================
rising_A = find(diff(A) == 1) + 1;

rising_B = find(diff(B) == 1) + 1;

% Cần đủ edge để thực hiện thống kê
assert( ...
    length(rising_A) > 10 && length(rising_B) > 10, ...
    'Không đủ số lượng xung để hiệu chuẩn. Hãy tăng thời gian chạy.');

% =========================================================================
% 3. INITIALIZE PHASE ERROR STORAGE
% =========================================================================
phase_errors = zeros( ...
    min(length(rising_A), length(rising_B)) - 1, ...
    1);

valid_pairs = 0;

% =========================================================================
% 4. THEORETICAL ELECTRICAL PERIOD
% =========================================================================
f_elec = ...
    (omega_ref / (2 * pi)) * PPR;

T_elec_samples = ...
    Fs / f_elec;

% =========================================================================
% 5. MULTI-EDGE PHASE ESTIMATION
% =========================================================================
for i = 1:length(rising_A)-1

    % Tìm rising edge đầu tiên của B sau rising edge A
    idx_B = find( ...
        rising_B > rising_A(i), ...
        1, ...
        'first');

    if ~isempty(idx_B)

        delta_samples = ...
            rising_B(idx_B) - rising_A(i);

        % -------------------------------------------------------------
        % Chuyển chênh lệch thời gian thành góc điện
        % -------------------------------------------------------------
        phi_measured = ...
            (delta_samples / T_elec_samples) * 2 * pi;

        % -------------------------------------------------------------
        % Lý tưởng: phase shift = +90 degrees = pi/2
        % -------------------------------------------------------------
        err = ...
            phi_measured - (pi/2);

        valid_pairs = valid_pairs + 1;

        phase_errors(valid_pairs) = err;

    end
end

% =========================================================================
% 6. REMOVE INVALID ENTRIES
% =========================================================================
phase_errors = ...
    phase_errors(1:valid_pairs);

% =========================================================================
% 7. FINAL CALIBRATION RESULT
% =========================================================================
calibrated_phase = ...
    mean(phase_errors);

% Standard error of mean
uncertainty = ...
    std(phase_errors) / sqrt(valid_pairs);

end