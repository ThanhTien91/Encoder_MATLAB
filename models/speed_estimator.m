function [omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count, t, PPR, error_flag)
    % =========================================================
    % SPEED ESTIMATOR
    % M-Method, T-Method & Adaptive Hybrid Fusion
    % =========================================================

    % --- 1. KHỞI TẠO VÀ ÉP KIỂU ---
    % Ép kiểu về vector hàng an toàn
    pos_count  = reshape(pos_count, 1, []);
    t          = reshape(t, 1, []);
    error_flag = reshape(error_flag, 1, []);
    
    N      = length(pos_count);
    Ts     = t(2) - t(1);
    CPR    = PPR * 4;
    dp_rad = 2 * pi / CPR; 
    
    omega_M          = zeros(1, N);
    omega_T          = zeros(1, N);
    omega_Hybrid_raw = zeros(1, N);

    % =========================================================
    % 2. M-METHOD (Bản gốc thô - Giữ nguyên đặc tính)
    % Thể hiện sự ổn định ở tốc độ cao nhưng có độ trễ do cửa sổ 10ms
    % =========================================================
    Nm = round(0.01 / Ts); 
    if Nm < 1
        Nm = 1; 
    end
    
    for i = Nm+1:N
        delta_count = pos_count(i) - pos_count(i-Nm);
        omega_M(i)  = (delta_count * dp_rad) / (Nm * Ts);
    end
    omega_M(1:Nm) = omega_M(Nm+1);

    % =========================================================
    % 3. T-METHOD (Từ chối mẫu lỗi + Chặn Outlier)
    % =========================================================
    last_time         = t(1);
    last_cnt          = pos_count(1);
    timeout_threshold = 0.005; % Giảm timeout xuống 5ms

    for i = 2:N
        % Từ chối cập nhật nếu Decoder báo cờ lỗi (Invalid Transition)
        if error_flag(i) == 1
            omega_T(i) = omega_T(i-1);
        else
            if pos_count(i) ~= last_cnt
                delta_t = t(i) - last_time;
                
                if delta_t >= Ts
                    tmp_omega = ((pos_count(i) - last_cnt) * dp_rad) / delta_t;
                    
                    % Outlier Rejection: Chặn gai khổng lồ do lỗi câm
                    if i > 1 && abs(tmp_omega - omega_T(i-1)) > 40
                        omega_T(i) = omega_T(i-1);
                        
                        % --- VÁ LỖI CỰC KỲ QUAN TRỌNG ---
                        % Cập nhật mốc thời gian để hệ thống không kẹt ở quá khứ
                        last_time = t(i);       
                        last_cnt  = pos_count(i);
                        
                    else
                        omega_T(i) = tmp_omega;
                        last_time  = t(i);
                        last_cnt   = pos_count(i);
                    end
                else
                    omega_T(i) = omega_T(i-1);
                end
            else
                % Xử lý dừng động cơ (Timeout 5ms)
                if (t(i) - last_time) > timeout_threshold
                    omega_T(i) = 0;
                else
                    omega_T(i) = omega_T(i-1);
                end
            end
        end
    end

    % =========================================================
    % 4. HYBRID ESTIMATOR (Adaptive Fusion)
    % =========================================================
    for i = 1:N
        abs_M = abs(omega_M(i));
        
        % Trọng số w nghiêng về M-Method khi tốc độ cao
        if abs_M > 15
            w = 1;       
        elseif abs_M < 5
            w = 0;       
        else
            w = (abs_M - 5) / 10; 
        end
        
        omega_Hybrid_raw(i) = w * omega_M(i) + (1 - w) * omega_T(i);
    end

    % =========================================================
    % 5. BỘ LỌC CUỐI (Chỉ áp dụng lọc nhẹ cho Hybrid)
    % =========================================================
    window_ma = round(0.005 / Ts); % Cửa sổ lọc nhẹ 5ms cho Hybrid
    if window_ma < 1
        window_ma = 1; 
    end
    
    omega_Hybrid = movmean(omega_Hybrid_raw, window_ma);
end