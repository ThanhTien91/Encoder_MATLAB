% ==========================================================================
% FILE: inject_pulse_loss.m
% MODULE: Pulse Loss Injection (Symmetric Phase)
% DESCRIPTION: Simulates random pulse loss by zeroing A/B channels over
%              a full physical cycle (4 transitions). Ensures phase
%              symmetry (25% probability per starting phase).
% ==========================================================================

function [A_noisy, B_noisy, stats] = inject_pulse_loss(A, B, drop_rate)

% ==========================================================================
% 1. INITIALIZATION
% ==========================================================================

A_noisy = A;
B_noisy = B;

% ==========================================================================
% 2. TRANSITION DETECTION
% ==========================================================================

state = A * 2 + B;
edges = find(diff(state) ~= 0) + 1;
num_transitions = length(edges);

% ==========================================================================
% 3. PULSE COUNT & DROP CALCULATION
% ==========================================================================

num_total_pulses = floor(num_transitions / 4);
num_dropped_pulses = round(drop_rate * num_total_pulses);

stats.total_pulses      = num_total_pulses;
stats.dropped_pulses    = num_dropped_pulses;
stats.actual_drop_rate  = (num_dropped_pulses / num_total_pulses) * 100;

if num_dropped_pulses == 0
    return;
end

% ==========================================================================
% 4. RANDOM TRANSITION SELECTION (SYMMETRIC PHASE)
% ==========================================================================

valid_max_idx = max(1, num_transitions - 4);
rand_trans_idx = randperm(valid_max_idx, num_dropped_pulses);

% ==========================================================================
% 5. SIGNAL CORRUPTION (ZEROING FULL PHYSICAL CYCLE)
% ==========================================================================

for i = 1:length(rand_trans_idx)
    start_trans = rand_trans_idx(i);
    end_trans   = start_trans + 4;  % Full Physical Cycle = 4 Transitions
    
    start_sample = edges(start_trans);
    
    if end_trans <= num_transitions
        end_sample = edges(end_trans) - 1;
    else
        end_sample = length(A);
    end
    
    % Zero Both Channels (Simulate Blocked Optical Slot)
    A_noisy(start_sample:end_sample) = 0;
    B_noisy(start_sample:end_sample) = 0;
end

end