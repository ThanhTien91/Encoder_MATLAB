function [pos_count, missing_count] = quadrature_decoder_x4(A, B)
    % ==========================================
    % QUADRATURE DECODER X4
    % State Transition Based Decoder & Fault Detection
    % ==========================================

    % --- 1. KHỞI TẠO HỆ THỐNG ---
    A = A(:);
    B = B(:);
    N = length(A);
    
    pos_count     = zeros(N, 1);
    missing_count = zeros(N, 1);

    % Initial states
    s1          = A(1) * 2 + B(1);
    s2          = s1;
    count       = 0;
    current_dir = 1;
    last_miss   = 0;

    % --- 2. VÒNG LẶP MÁY TRẠNG THÁI (STATE MACHINE) ---
    for k = 2:N
        curr_state = A(k) * 2 + B(k);

        % Bỏ qua nếu không có sự chuyển trạng thái
        if curr_state == s1
            pos_count(k) = count;
            continue;
        end

        % Mã hóa bước nhảy
        transition = s1 * 4 + curr_state;

        switch transition
            % --- VALID FORWARD TRANSITIONS (+1) ---
            case {11, 13, 4, 2} 
                count       = count + 1;
                current_dir = 1;
                last_miss   = 0;

            % --- VALID REVERSE TRANSITIONS (-1) ---
            case {8, 1, 7, 14} 
                count       = count - 1;
                current_dir = -1;
                last_miss   = 0;

            % --- TWO-STATE JUMP (FAULT DETECTION) ---
            case {3, 6, 9, 12} 
                if curr_state == s2 && last_miss ~= 0
                    missing_count(k) = -last_miss;
                    last_miss        = 0;
                else
                    missing_count(k) = 2 * current_dir;
                    last_miss        = missing_count(k);
                end

            % --- OTHER INVALID TRANSITIONS ---
            otherwise 
                missing_count(k) = 0;
        end

        % Cập nhật kết quả và lùi trạng thái
        pos_count(k) = count;
        s2           = s1;
        s1           = curr_state;
    end
end