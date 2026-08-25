function theta_comp = position_compensator(theta_raw, missing_count, PPR)
    % ==========================================
    % POSITION COMPENSATOR
    % Position Error Compensation based on Decoder states
    % ==========================================

    % --- 1. CHUẨN HÓA DỮ LIỆU ---
    theta_raw     = theta_raw(:);
    missing_count = missing_count(:);

    % --- 2. TÍNH TOÁN BÙ TRỪ ---
    dp_rad           = 2 * pi / (PPR * 4);
    correction_count = cumsum(missing_count);
    
    theta_comp       = theta_raw + correction_count * dp_rad;
    
end