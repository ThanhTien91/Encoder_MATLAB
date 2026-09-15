% ==========================================================================
% FILE: encoder_model.m
% MODULE: Quadrature Encoder Signal Generation
% DESCRIPTION: Generates ideal A/B/Z quadrature signals from angular
%              position with optional thermal phase drift.
% ==========================================================================

function [A, B, Z] = encoder_model(theta, params, phase_offset)

% ==========================================================================
% 1. BACKWARD COMPATIBILITY
% ==========================================================================

if nargin < 3
    phase_offset = 0;
end

% ==========================================================================
% 2. ENCODER PARAMETERS
% ==========================================================================

N = params.PPR;

% ==========================================================================
% 3. QUADRATURE CHANNELS A/B GENERATION
% ==========================================================================

% --- Electrical Phase ---
phase = N * theta;
phase_mod = mod(phase, 2*pi);

% --- Channel A: 50% Duty Cycle ---
A = phase_mod < pi;

% --- Channel B: 90 deg Electrical Shift + Thermal Drift ---
phase_B_mod = mod(phase - pi/2 - phase_offset, 2*pi);
B = phase_B_mod < pi;

% ==========================================================================
% 4. INDEX CHANNEL Z GENERATION
% ==========================================================================

% --- Mechanical Angle (Single Revolution) ---
theta_mod = mod(theta, 2*pi);

% --- Index Pulse Width (1 X4 Count) ---
pulse_width_rad = (2*pi) / (N*4);

% --- Z Active at Mechanical Zero ---
Z = theta_mod < pulse_width_rad;

end