function params = default_params()
% ==============================
% SYSTEM PARAMETERS
% ==============================

% Random seed - reproducibility
params.rng_seed = 42;

% Sampling frequency
params.Fs = 1e6;          % 1 MHz

% Encoder resolution
params.PPR = 1000;        % Pulses per revolution

% Simulation duration
params.duration = 2.0;    % seconds

% Maximum speed
params.max_rpm = 600;     % RPM
end