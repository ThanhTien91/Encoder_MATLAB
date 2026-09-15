% ==========================================================================
% FILE: default_params.m
% MODULE: System Configuration
% DESCRIPTION: Centralized system parameters, environmental factors,
%              hardware limits, and input validation for the Encoder
%              Position & Velocity Estimation Pipeline.
% ==========================================================================

function params = default_params()

% ==========================================================================
% 1. SYSTEM PARAMETERS
% ==========================================================================

% --- Random Seed (Reproducibility) ---
params.rng_seed = 42;

% --- Sampling & Encoder ---
params.Fs       = 1e6;       % Sampling frequency [Hz] (1 MHz)
params.PPR      = 1000;      % Pulses Per Revolution
params.duration = 2.0;       % Simulation duration [s]
params.max_rpm  = 600;       % Maximum operating speed [RPM]

% ==========================================================================
% 2. ENVIRONMENTAL FACTORS
% ==========================================================================

params.env.T_ref = 25;       % Reference temperature [deg C]
params.env.k_T   = 0.005;    % Thermal phase drift coefficient [rad/deg C]
                             % Model: Optical grating thermal expansion

% ==========================================================================
% 3. HARDWARE LIMITS
% ==========================================================================

params.hw.max_event_freq = 50000; % Max acquisition bandwidth [Hz]
                                  % PPR=1000 -> CPR=4000 -> ~750 RPM limit

% ==========================================================================
% 4. ESTIMATOR CONFIGURATION
% ==========================================================================

params.estimator.outlier_threshold = 40; % T-Method outlier rejection [rad/s]

% ==========================================================================
% 5. INPUT VALIDATION
% ==========================================================================

assert(params.PPR > 0, 'ERROR: PPR must be positive.');
assert(params.Fs > 0, 'ERROR: Sampling frequency Fs must be positive.');
assert(params.max_rpm > 0, 'ERROR: Max RPM must be positive.');
assert(params.env.T_ref >= -50 && params.env.T_ref <= 150, ...
    'ERROR: Reference temperature out of realistic range.');
assert(params.hw.max_event_freq > 1000, ...
    'ERROR: Hardware bandwidth too low.');
assert(params.estimator.outlier_threshold > 0, ...
    'ERROR: Outlier threshold must be positive.');

end