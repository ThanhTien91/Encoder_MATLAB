% ==========================================================================
% FILE: quadrature_decoder_x4.m
% MODULE: X4 Quadrature Decoder with Fault Detection
% DESCRIPTION: State-machine decoder implementing X4 quadrature decoding
%              with invalid transition detection and missing pulse
%              identification (double-jump detection).
% ==========================================================================

function [pos_count, missing_count] = quadrature_decoder_x4(A, B)

% ==========================================================================
% 1. INITIALIZATION
% ==========================================================================

A = A(:);
B = B(:);
N = length(A);

pos_count     = zeros(N, 1);
missing_count = zeros(N, 1);

% --- State Encoding: s = 2*A + B ---
s1 = A(1) * 2 + B(1);  % Current State
s2 = s1;               % Previous State
count       = 0;
current_dir = 1;
last_miss   = 0;

% ==========================================================================
% 2. STATE MACHINE LOOP
% ==========================================================================

for k = 2:N
    curr_state = A(k) * 2 + B(k);
    
    % No Transition
    if curr_state == s1
        pos_count(k) = count;
        continue;
    end
    
    % Transition Encoding: 4*s1 + curr_state
    transition = s1 * 4 + curr_state;
    
    switch transition
        % --------------------------------------------------------------
        % VALID FORWARD TRANSITIONS (+1 count)
        % 00->10 (2), 10->11 (3), 11->01 (1), 01->00 (0)
        % Encoded: 11, 13, 4, 2
        % --------------------------------------------------------------
        case {11, 13, 4, 2}
            count       = count + 1;
            current_dir = 1;
            last_miss   = 0;
        
        % --------------------------------------------------------------
        % VALID REVERSE TRANSITIONS (-1 count)
        % 00->01 (1), 01->11 (3), 11->10 (2), 10->00 (0)
        % Encoded: 8, 1, 7, 14
        % --------------------------------------------------------------
        case {8, 1, 7, 14}
            count       = count - 1;
            current_dir = -1;
            last_miss   = 0;
        
        % --------------------------------------------------------------
        % TWO-STATE JUMP (INVALID TRANSITION / MISSING PULSE)
        % Encoded: 3, 6, 9, 12
        % --------------------------------------------------------------
        case {3, 6, 9, 12}
            if curr_state == s2 && last_miss ~= 0
                % Double-Jump Confirmation: Correct Previous Miss
                missing_count(k) = -last_miss;
                last_miss        = 0;
            else
                % First Detection of Double-Jump
                missing_count(k) = 2 * current_dir;
                last_miss        = missing_count(k);
            end
        
        % --------------------------------------------------------------
        % OTHER INVALID TRANSITIONS
        % --------------------------------------------------------------
        otherwise
            missing_count(k) = 0;
    end
    
    % Update Outputs & State History
    pos_count(k) = count;
    s2 = s1;
    s1 = curr_state;
end

end