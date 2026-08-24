function [pos_count, error_flag] = quadrature_decoder_x4(A, B)
    % QUADRATURE_DECODER_X4
    % Giải mã tín hiệu A, B bằng State Machine và xuất cờ lỗi
    
    N = length(A);
    pos_count = zeros(N, 1);
    error_flag = zeros(N, 1);

    % Khởi tạo trạng thái ban đầu (0, 1, 2, hoặc 3)
    prev_state = A(1) * 2 + B(1);
    count = 0;

    for k = 2:N
        curr_state = A(k) * 2 + B(k);
        % Tạo mã chuyển trạng thái duy nhất (từ 0 đến 15)
        transition = prev_state * 4 + curr_state;

        switch transition
            % ======================================
            % CHIỀU THUẬN (FORWARD): 10->11, 11->01, 01->00, 00->10
            % ======================================
            case {11, 13, 4, 2}
                count = count + 1;

            % ======================================
            % CHIỀU NGƯỢC (REVERSE): 10->00, 00->01, 01->11, 11->10
            % ======================================
            case {8, 1, 7, 14}
                count = count - 1;

            % ======================================
            % ĐỨNG YÊN (NO MOVEMENT)
            % ======================================
            case {0, 5, 10, 15}
                % Không làm gì cả

            % ======================================
            % TRẠNG THÁI LỖI (INVALID TRANSITION - Nhảy vọt 2 bước)
            % ======================================
            otherwise
                error_flag(k) = 1;
        end

        pos_count(k) = count;
        prev_state = curr_state;
    end
end