% ==========================================================================
% FILE: inject_acquisition_saturation.m
% MODULE: Hardware Bandwidth Saturation Injection
% DESCRIPTION: Models acquisition hardware bandwidth limit. Drops events
%              occurring faster than max_event_freq. Implements phase-
%              preserving lock mechanism (locks 4 edges = 1 pulse).
% ==========================================================================

function [A_sat, B_sat, total_missed] = inject_acquisition_saturation( ...
    A, B, Fs, params)

% ==========================================================================
% 1. INPUT VALIDATION
% ==========================================================================

assert(length(A) == length(B), 'A and B must have same length.');

% ==========================================================================
% 2. BANDWIDTH CONFIGURATION
% ==========================================================================

max_freq = params.hw.max_event_freq;
min_samples_between_events = Fs / max_freq;

% ==========================================================================
% 2. INITIALIZATION
% ==========================================================================

N = length(A);
A_sat = zeros(N, 1);
B_sat = zeros(N, 1);

A_sat(1) = A(1);
B_sat(1) = B(1);

last_event_idx = 1;
total_missed = 0;

% Phase-Preserving Lock Counter (Locks 4 edges = 1 pulse)
lock_counter = 0;

% ==========================================================================
% 3. ACQUISITION STATE MACHINE
% ==========================================================================

for i = 2:N
    is_transition = (A(i) ~= A(i-1)) || (B(i) ~= B(i-1));
    
    if is_transition
        if lock_counter > 0
            % In Lock Window: Force Hold to Preserve Phase
            A_sat(i) = A_sat(i-1);
            B_sat(i) = B_sat(i-1);
            lock_counter = lock_counter - 1;
            total_missed = total_missed + 1;
            last_event_idx = i;  % Slide Time Reference
        else
            delta_samples = i - last_event_idx;
            
            if delta_samples >= min_samples_between_events
                % Accept Event
                A_sat(i) = A(i);
                B_sat(i) = B(i);
                last_event_idx = i;
            else
                % Saturation: Lock 4 Edges (1 Full Pulse)
                A_sat(i) = A_sat(i-1);
                B_sat(i) = B_sat(i-1);
                lock_counter = 3;  % 1 dropped + 3 locked
                total_missed = total_missed + 1;
                last_event_idx = i;
            end
        end
    else
        A_sat(i) = A_sat(i-1);
        B_sat(i) = B_sat(i-1);
    end
end

end