% ==========================================================================
% FILE: position_compensator.m
% MODULE: Position Error Compensation (Leaky Integrator)
% DESCRIPTION: Compensates position drift from missing pulses using
%              leaky integration of missing_count to prevent over-
%              compensation drift at standstill.
% ==========================================================================

function theta_comp = position_compensator(theta_raw, missing_count, PPR)

% ==========================================================================
% 1. INPUT NORMALIZATION
% ==========================================================================

theta_raw     = theta_raw(:);
missing_count = missing_count(:);
dp_rad        = 2 * pi / (PPR * 4);

N = length(missing_count);

% ==========================================================================
% 2. LEAKY INTEGRATOR COMPENSATION
% ==========================================================================

correction_count = zeros(N, 1);
leak_factor = 0.9995;  % Retain 99.95%, Slowly Decay to Prevent Drift

for i = 2:N
    correction_count(i) = ...
        correction_count(i-1) * leak_factor + missing_count(i);
end

theta_comp = theta_raw + correction_count * dp_rad;

end