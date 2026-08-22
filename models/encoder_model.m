function [A, B, Z] = encoder_model(theta, params)

% ==============================
% ENCODER PARAMETERS
% ==============================

N = params.PPR;

% ==============================
% QUADRATURE CHANNEL A/B
% ==============================

% Electrical phase
phase = N * theta;

% Channel A
A = phase >= 0;

% Convert phase to 0 -> 2*pi
phase_mod = mod(phase, 2*pi);

% Channel A: 50% duty cycle
A = phase_mod < pi;

% Channel B: shifted by 90 electrical degrees
B = phase_mod >= pi/2 & phase_mod < 3*pi/2;

% ==============================
% INDEX CHANNEL Z
% ==============================

% Mechanical angle within one revolution
theta_mod = mod(theta, 2*pi);

% Index pulse width
pulse_width_rad = (2*pi) / (N*4);

Z = theta_mod < pulse_width_rad;

end