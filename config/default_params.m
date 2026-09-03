function params = default_params()
    % ==============================================================
    % SYSTEM PARAMETERS & CONFIGURATION
    % Đã tích hợp Yếu tố môi trường, Giới hạn băng thông và Validation
    % ==============================================================

    % --- 1. Thông số Cơ bản ---
    params.rng_seed = 42;
    params.Fs       = 1e6;       % Tần số lấy mẫu hệ thống (1 MHz)
    params.PPR      = 1000;      % Xung trên mỗi vòng (Pulses Per Revolution)
    params.duration = 2.0;       % Thời gian mô phỏng (s)
    params.max_rpm  = 600;       % Tốc độ danh định tối đa (RPM)

    % --- 2. Yếu tố Môi trường (Environmental Factors) ---
    params.env.T_ref = 25;       % Nhiệt độ chuẩn (độ C)
    params.env.k_T   = 0.005;    % Hệ số trôi pha theo nhiệt độ (rad/độ C)
                                 % Giả thiết mô hình: Độ giãn nở cơ nhiệt làm lệch khe quang học

    % --- 3. Giới hạn Phần cứng (Hardware Saturation Limits) ---
    params.hw.max_event_freq = 50000; % Băng thông tối đa của vi điều khiển/optocoupler (50 kHz)
                                      % Ở PPR=1000, 50kHz tương đương khoảng 750 RPM

    % --- 4. Cấu hình Speed Estimator (T-Method Outlier Rejection) ---
    % GIỮ NGUYÊN giá trị 40 rad/s như code gốc (không đổi hành vi hiện có).
    % Đưa ra config để dễ điều chỉnh/thử nghiệm theo dải tốc độ vận hành,
    % thay vì hard-code trong speed_estimator.m.
    params.estimator.outlier_threshold = 40; % rad/s

    % ==============================================================
    % INPUT VALIDATION (Kiểm tra tính hợp lệ của tham số)
    % ==============================================================
    assert(params.PPR > 0, 'Lỗi: PPR phải là số dương.');
    assert(params.Fs > 0, 'Lỗi: Tần số lấy mẫu Fs phải lớn hơn 0.');
    assert(params.max_rpm > 0, 'Lỗi: Tốc độ tối đa max_rpm phải lớn hơn 0.');
    assert(params.env.T_ref >= -50 && params.env.T_ref <= 150, 'Lỗi: Nhiệt độ chuẩn phi thực tế.');
    assert(params.hw.max_event_freq > 1000, 'Lỗi: Băng thông phần cứng quá thấp.');
    assert(params.estimator.outlier_threshold > 0, 'Lỗi: Ngưỡng outlier phải lớn hơn 0.');
end