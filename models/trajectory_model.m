function [t, theta, omega] = trajectory_model(params)

% ==============================
% TIME VECTOR
% ==============================

t = (0:1/params.Fs:params.duration)';

% ==============================
% SPEED PROFILE
% ==============================

omega_rpm = zeros(size(t));

for i = 1:length(t)

    ti = t(i);

    if ti < 0.4

        % Phase 1: Acceleration
        omega_rpm(i) = ...
            (params.max_rpm / 0.4) * ti;

    elseif ti < 0.8

        % Phase 2: Constant positive speed
        omega_rpm(i) = params.max_rpm;

    elseif ti < 1.4

        % Phase 3: Deceleration + direction reversal
        slope = (-2 * params.max_rpm) / 0.6;

        omega_rpm(i) = ...
            params.max_rpm + slope * (ti - 0.8);

    elseif ti < 1.8

        % Phase 4: Constant negative speed
        omega_rpm(i) = -params.max_rpm;

    else

        % Phase 5: Stop
        omega_rpm(i) = 0;

    end

end

% ==============================
% RPM -> rad/s
% ==============================

omega = omega_rpm * (2*pi/60);

% ==============================
% Integrate speed -> position
% ==============================

theta = cumtrapz(t, omega);

end