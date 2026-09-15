% ==========================================================================
% FILE: encoder_calibration.m
% MODULE: Multi-Edge Phase Calibration
% DESCRIPTION: Estimates systematic phase error between A/B channels
%              using multi-edge statistical averaging. Requires known
%              steady-state reference velocity (omega_ref).
% LIMITATION: Requires known omega_ref at steady-state operation.
% ==========================================================================

function [calibrated_phase, uncertainty] = encoder_calibration( ...
    A, B, Fs, omega_ref, PPR)

% ==========================================================================
% 1. INPUT VALIDATION
% ==========================================================================

assert(length(A) == length(B), 'A and B must have same length.');
assert(mean(omega_ref) > 0, 'Reference velocity must be positive.');

% --- Reject Calibration During Transient Operation ---
assert(std(omega_ref) < 1e-3, ...
    'KINEMATIC ERROR: omega_ref not steady-state. ' ...
    'Calibration only valid at constant velocity operating point.');

% ==========================================================================
% 2. RISING EDGE DETECTION
% ==========================================================================

rising_A = find(diff(A) == 1) + 1;
rising_B = find(diff(B) == 1) + 1;

assert(length(rising_A) > 10 && length(rising_B) > 10, ...
    'Insufficient edges for calibration. Increase run duration.');

% ==========================================================================
% 3. PHASE ERROR STORAGE INITIALIZATION
% ==========================================================================

phase_errors = zeros(min(length(rising_A), length(rising_B)) - 1, 1);
valid_pairs = 0;

% ==========================================================================
% 4. THEORETICAL ELECTRICAL PERIOD
% ==========================================================================

f_elec = (omega_ref / (2 * pi)) * PPR;
T_elec_samples = Fs / f_elec;

% ==========================================================================
% 5. MULTI-EDGE PHASE ESTIMATION
% ==========================================================================

for i = 1:length(rising_A)-1
    % Find First B Rising Edge After A Rising Edge
    idx_B = find(rising_B > rising_A(i), 1, 'first');
    
    if ~isempty(idx_B)
        delta_samples = rising_B(idx_B) - rising_A(i);
        
        % Convert Time Difference to Electrical Angle
        phi_measured = (delta_samples / T_elec_samples) * 2 * pi;
        
        % Ideal Phase Shift = +90 deg = pi/2
        err = phi_measured - (pi/2);
        
        valid_pairs = valid_pairs + 1;
        phase_errors(valid_pairs) = err;
    end
end

% ==========================================================================
% 6. CLEANUP & STATISTICS
% ==========================================================================

phase_errors = phase_errors(1:valid_pairs);
calibrated_phase = mean(phase_errors);
uncertainty = std(phase_errors) / sqrt(valid_pairs);  % Standard Error

end