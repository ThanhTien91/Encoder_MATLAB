function [A, B, Z] = encoder_model(theta, params, phase_offset)

% Tương thích ngược: Nếu kịch bản cũ không truyền phase_offset, mặc định bằng 0
if nargin < 3
    phase_offset = 0;
end

% ==============================
% ENCODER PARAMETERS
% ==============================

N = params.PPR;

% ==============================
% QUADRATURE CHANNEL A/B
% ==============================

% Electrical phase
phase = N * theta;

% Convert phase to 0 -> 2*pi
phase_mod = mod(phase, 2*pi);

% Channel A: 50% duty cycle
A = phase_mod < pi;

% Channel B: shifted by 90 electrical degrees + thermal phase drift
% Đã cấu trúc lại để an toàn với hàm mod() khi phase_offset bị âm/dương
phase_B_mod = mod(phase - pi/2 - phase_offset, 2*pi);
B = phase_B_mod < pi;

% ==============================
% INDEX CHANNEL Z
% ==============================

% Mechanical angle within one revolution
theta_mod = mod(theta, 2*pi);

% Index pulse width
pulse_width_rad = (2*pi) / (N*4);

Z = theta_mod < pulse_width_rad;

end