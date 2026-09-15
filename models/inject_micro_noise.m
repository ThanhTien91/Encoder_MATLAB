% ==========================================================================
% FILE: inject_micro_noise.m
% MODULE: Micro-Noise Injection (Jitter, Bounce, Phase Error)
% DESCRIPTION: Injects physical-layer noise into A/B signals:
%              - Static Phase Error (B channel shift)
%              - Edge Jitter (sample-level timing variation)
%              - Bounce (logic oscillation at edges)
% ==========================================================================

function [A_noisy, B_noisy] = inject_micro_noise( ...
    A, B, jitter_range, bounce_prob)

% ==========================================================================
% 1. INPUT HANDLING & DEFAULTS
% ==========================================================================

if nargin < 3 || isempty(jitter_range)
    jitter_range = 2;
end
if nargin < 4 || isempty(bounce_prob)
    bounce_prob = 0.25;
end

A_noisy = A;
B_noisy = B;
N = length(A);

% ==========================================================================
% 1. STATIC PHASE ERROR
% ==========================================================================

phase_shift = 5;  % 5 samples @ 1 MHz = 5 us
B_noisy = circshift(B_noisy, phase_shift);

% ==========================================================================
% 2. EDGE DETECTION
% ==========================================================================

edges_A = find(diff(A_noisy) ~= 0);
edges_B = find(diff(B_noisy) ~= 0);

% ==========================================================================
% 2. CHANNEL A: JITTER + BOUNCE
% ==========================================================================

for i = 1:length(edges_A)
    idx = edges_A(i);
    
    % Jitter: Random Sample Shift
    jitter = randi([-jitter_range, jitter_range]);
    
    if (idx + jitter > 1) && (idx + jitter < N-5)
        % Bounce: Random Logic Oscillation
        if rand() < bounce_prob
            A_noisy(idx+jitter : idx+jitter+2) = randi([0 1], 1, 3);
        end
    end
end

% ==========================================================================
% 3. CHANNEL B: JITTER + BOUNCE
% ==========================================================================

for i = 1:length(edges_B)
    idx = edges_B(i);
    jitter = randi([-jitter_range, jitter_range]);
    
    if (idx + jitter > 1) && (idx + jitter < N-5)
        if rand() < bounce_prob
            B_noisy(idx+jitter : idx+jitter+2) = randi([0 1], 1, 3);
        end
    end
end

end