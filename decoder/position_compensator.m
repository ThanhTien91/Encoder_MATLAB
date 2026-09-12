function theta_comp = position_compensator(theta_raw, missing_count, PPR)
    % ==========================================
    % POSITION COMPENSATOR
    % Position Error Compensation based on Decoder states
    % ==========================================

    % --- 1. CHUẨN HÓA DỮ LIỆU ---
    theta_raw     = theta_raw(:);
    missing_count = missing_count(:);
    dp_rad        = 2 * pi / (PPR * 4);

    % --- VÁ LỖI: ÁP DỤNG LEAKY INTEGRATOR ---
    N = length(missing_count);
    correction_count = zeros(N, 1);
    leak_factor = 0.9995; % Trữ 99.95% giá trị bù trừ, xả từ từ để chống trôi
    
    for i = 2:N
        correction_count(i) = correction_count(i-1) * leak_factor + missing_count(i);
    end
    
    theta_comp = theta_raw + correction_count * dp_rad;
end