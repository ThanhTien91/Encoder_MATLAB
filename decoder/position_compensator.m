function theta_comp = position_compensator(theta_raw, missing_count, PPR)
    % ==========================================
    % POSITION COMPENSATOR
    % Position Error Compensation based on Decoder states
    % Perfect accumulation (cumsum) of detected missing pulses.
    % Matches analytical verification in verify_manual.m (Level 3).
    % ==========================================

    % --- 1. CHUẨN HÓA DỮ LIỆU ---
    theta_raw     = theta_raw(:);
    missing_count = missing_count(:);
    dp_rad        = 2 * pi / (PPR * 4);

    % --- PERFECT ACCUMULATION (CUMSUM) ---
    % Each detected missing_count event (±2) is a real physical pulse loss.
    % Accumulate without leak to maintain exact compensation.
    correction_count = cumsum(missing_count);
    
    theta_comp = theta_raw + correction_count * dp_rad;
end