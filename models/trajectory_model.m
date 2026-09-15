% ==========================================================================
% FILE: trajectory_model.m
% MODULE: Motion Trajectory Generation
% DESCRIPTION: Generates standard test trajectory with 5 phases:
%              Acceleration -> Constant Positive -> Decel/Reversal ->
%              Constant Negative -> Stop. Outputs time, position, velocity.
% ==========================================================================

function [t, theta, omega] = trajectory_model(params)

% ==========================================================================
% 1. TIME VECTOR
% ==========================================================================

t = (0:1/params.Fs:params.duration)';

% ==========================================================================
% 2. SPEED PROFILE (5 PHASES)
% ==========================================================================

omega_rpm = zeros(size(t));

for i = 1:length(t)
    ti = t(i);
    
    if ti < 0.4
        % Phase 1: Acceleration (0 -> max_rpm)
        omega_rpm(i) = (params.max_rpm / 0.4) * ti;
    elseif ti < 0.8
        % Phase 2: Constant Positive Speed
        omega_rpm(i) = params.max_rpm;
    elseif ti < 1.4
        % Phase 3: Deceleration + Direction Reversal
        slope = (-2 * params.max_rpm) / 0.6;
        omega_rpm(i) = params.max_rpm + slope * (ti - 0.8);
    elseif ti < 1.8
        % Phase 4: Constant Negative Speed
        omega_rpm(i) = -params.max_rpm;
    else
        % Phase 5: Stop
        omega_rpm(i) = 0;
    end
end

% ==========================================================================
% 3. UNIT CONVERSION & INTEGRATION
% ==========================================================================

% RPM -> rad/s
omega = omega_rpm * (2*pi/60);

% Integrate Velocity -> Position
theta = cumtrapz(t, omega);

end