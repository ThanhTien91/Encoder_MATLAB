% ==========================================================================
% FILE: velocity_kf.m
% MODULE: 1D Velocity Kalman Filter (Post-Filter)
% DESCRIPTION: Scalar Kalman filter for smoothing Hybrid Estimator output.
%              State: velocity. Model: Random Walk (x_k = x_{k-1} + w_k).
%              Tuning: q_acc (process noise), r_var (measurement noise).
% ==========================================================================

function omega_kf = velocity_kf(omega_raw, Ts, q_acc, r_var)

% ==========================================================================
% 1. INITIALIZATION
% ==========================================================================

N = length(omega_raw);
omega_kf = zeros(1, N);

x = omega_raw(1);  % Initial State
P = 1.0;           % Initial Covariance

Q = (q_acc * Ts)^2;  % Process Noise Covariance
R = r_var;           % Measurement Noise Covariance

omega_kf(1) = x;

%% ==========================================================================
% 2. KALMAN FILTER LOOP
% ==========================================================================

for k = 2:N
    % PREDICTION
    x_pred = x;
    P_pred = P + Q;
    
    % UPDATE
    z = omega_raw(k);
    
    K = P_pred / (P_pred + R);       % Kalman Gain
    x = x_pred + K * (z - x_pred);   % State Update
    P = (1 - K) * P_pred;            % Covariance Update
    
    omega_kf(k) = x;
end

end