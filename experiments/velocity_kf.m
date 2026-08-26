function omega_kf = velocity_kf(omega_raw, Ts, q_acc, r_var)
    % ==========================================
    % 1D VELOCITY KALMAN FILTER
    % Đầu vào: Vận tốc thô (Hybrid Estimator)
    % Tham số:
    %   - q_acc: Phương sai gia tốc (Process Noise tuning)
    %   - r_var: Phương sai nhiễu đo lường
    % ==========================================
    N = length(omega_raw);
    omega_kf = zeros(1, N);
    
    % Khởi tạo trạng thái ban đầu
    x = omega_raw(1);
    P = 1.0; 
    
    % Tính toán nhiễu hệ thống (Q) dựa trên gia tốc tối đa kỳ vọng
    Q = (q_acc * Ts)^2; 
    R = r_var;
    
    omega_kf(1) = x;
    
    for k = 2:N
        % 1. DỰ ĐOÁN (PREDICTION)
        x_pred = x; 
        P_pred = P + Q;
        
        % 2. CẬP NHẬT (UPDATE)
        z = omega_raw(k);
        
        K = P_pred / (P_pred + R);
        x = x_pred + K * (z - x_pred);
        P = (1 - K) * P_pred;
        
        omega_kf(k) = x;
    end
end