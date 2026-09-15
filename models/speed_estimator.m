% ==========================================================================
% FILE: speed_estimator.m
% MODULE: Velocity Estimation Engine
% DESCRIPTION: Implements M-Method (Time-Fixed), T-Method (Pulse-Fixed),
%              Adaptive Hybrid Fusion, and Moving Average Post-Filter.
% ==========================================================================

function [omega_M, omega_T, omega_Hybrid] = speed_estimator( ...
    pos_count, t, PPR, error_flag, outlier_threshold)

% ==========================================================================
% 1. INPUT HANDLING & DEFAULTS
% ==========================================================================

if nargin < 5 || isempty(outlier_threshold)
    outlier_threshold = 40;  % Default T-Method outlier threshold [rad/s]
end

% --- Type Casting & Reshaping ---
pos_count  = reshape(pos_count, 1, []);
t          = reshape(t, 1, []);
error_flag = reshape(error_flag, 1, []);

% ==========================================================================
% 2. CONSTANTS
% ==========================================================================

N      = length(pos_count);
Ts     = t(2) - t(1);
CPR    = PPR * 4;
dp_rad = 2 * pi / CPR;

% Output Buffers
omega_M          = zeros(1, N);
omega_T          = zeros(1, N);
omega_Hybrid_raw = zeros(1, N);

% ==========================================================================
% 3. M-METHOD (Time-Fixed Window)
% ==========================================================================

Nm = round(0.01 / Ts);  % 10 ms Window
if Nm < 1
    Nm = 1;
end

for i = Nm+1:N
    delta_count = pos_count(i) - pos_count(i-Nm);
    omega_M(i)  = (delta_count * dp_rad) / (Nm * Ts);
end
omega_M(1:Nm) = omega_M(Nm+1);

% ==========================================================================
% 4. T-METHOD (Pulse-Fixed Timing)
% ==========================================================================

last_time         = t(1);
last_cnt          = pos_count(1);
timeout_threshold = 0.005;  % 5 ms Timeout

for i = 2:N
    % Skip on Decoder Error Flag
    if error_flag(i) == 1
        omega_T(i) = omega_T(i-1);
        continue;
    end
    
    if pos_count(i) ~= last_cnt
        delta_t = t(i) - last_time;
        
        if delta_t >= Ts
            tmp_omega = ((pos_count(i) - last_cnt) * dp_rad) / delta_t;
            
            % Outlier Rejection
            if i > 1 && abs(tmp_omega - omega_T(i-1)) > outlier_threshold
                omega_T(i) = omega_T(i-1);
                % Critical: Update Time Reference to Prevent Sticking
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
        % Motor Stop / Timeout Handling
        if (t(i) - last_time) > timeout_threshold
            omega_T(i) = 0;
        else
            omega_T(i) = omega_T(i-1);
        end
    end
end

% ==========================================================================
% 5. ADAPTIVE HYBRID FUSION
% ==========================================================================

for i = 1:N
    abs_M = abs(omega_M(i));
    
    % Weight Calculation
    if abs_M > 15
        w = 1;                      % High Speed -> M-Method
    elseif abs_M < 5
        w = 0;                      % Low Speed  -> T-Method
    else
        w = (abs_M - 5) / 10;       % Transition Region -> Linear Blend
    end
    
    omega_Hybrid_raw(i) = w * omega_M(i) + (1 - w) * omega_T(i);
end

% ==========================================================================
% 6. POST-FILTER (Moving Average)
% ==========================================================================

window_ma = round(0.005 / Ts);  % 5 ms Window
if window_ma < 1
    window_ma = 1;
end

omega_Hybrid = fast_movmean(omega_Hybrid_raw, window_ma);

end

% ==========================================================================
% 7. INTERNAL HELPER: FAST MOVING AVERAGE
% ==========================================================================

function y = fast_movmean(x, w)
    x = x(:)';
    N = length(x);
    half1 = floor((w-1)/2);
    half2 = ceil((w-1)/2);
    xpad = [zeros(1,half1), x, zeros(1,half2)];
    onespad = [zeros(1,half1), ones(1,N), zeros(1,half2)];
    kernel = ones(1,w);
    s = conv(xpad, kernel, 'valid');
    c = conv(onespad, kernel, 'valid');
    y = s ./ c;
end