function metrics = compute_metrics(true_signal, est_signal)
    % =========================================================
    % MODULE ĐÁNH GIÁ ĐỊNH LƯỢNG (Chuẩn hóa)
    % =========================================================
    true_signal = true_signal(:);
    est_signal  = est_signal(:);
    
    if length(true_signal) ~= length(est_signal)
        error('Lỗi: Chiều dài vector không khớp!');
    end

    e = est_signal - true_signal;
    
    metrics.rmse      = sqrt(mean(e.^2));
    metrics.mae       = mean(abs(e));
    metrics.max_error = max(abs(e));
    metrics.bias      = mean(e);
    metrics.std_error = std(e);
    
    % --- Đo Delay bằng Cross-Correlation (Auxiliary metric) ---
    % Chỉ chạy xcorr nếu tín hiệu có sự biến thiên (không phải DC/Constant speed)
    if var(true_signal) > 1e-6 
        true_ac = true_signal - mean(true_signal);
        est_ac  = est_signal - mean(est_signal);
        [R, lags] = xcorr(est_ac, true_ac);
        [~, max_idx] = max(abs(R));
        metrics.delay_samples = lags(max_idx);
    else
        % Với tín hiệu vận tốc hằng, xcorr không có ý nghĩa vật lý
        metrics.delay_samples = NaN; 
    end
end