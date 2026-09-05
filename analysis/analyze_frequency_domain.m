% =========================================================================
% SCRIPT: analyze_frequency_domain.m
% MỤC TIÊU: Bổ sung phân tích miền tần số (FFT/PSD) theo yêu cầu chung của
% đề tài — "Phải có phân tích miền thời gian và miền tần số khi phù hợp;
% dùng FFT/PSD đúng cách".
%
% PHẦN 1 (FFT): Chứng minh tần số cơ bản của kênh A khớp lý thuyết
%               f_A = PPR * omega / (2*pi)  [Hz]
% PHẦN 2 (PSD): So sánh công suất nhiễu trong sai số ước lượng tốc độ
%               Hybrid giữa kịch bản S2 (nhiễu nhẹ) và S3 (nhiễu nặng),
%               dùng cùng cách tiêm nhiễu edge-domain như main_rubric_scenarios.m
% =========================================================================

clc; clear; close all;

addpath(fullfile(pwd, '..', 'decoder'));
addpath(fullfile(pwd, '..', 'config'));
addpath(fullfile(pwd, '..', 'models'));

params = default_params();
Fs  = params.Fs;
dt  = 1/Fs;
PPR = params.PPR;
CPR = PPR * 4;
dp_rad = 2*pi/CPR;

out_fig_dir = fullfile('..', 'results', 'figure', 'frequency_domain');
if ~exist(out_fig_dir, 'dir'), mkdir(out_fig_dir); end
out_tab_dir = fullfile('..', 'results', 'tables');
if ~exist(out_tab_dir, 'dir'), mkdir(out_tab_dir); end

fprintf('==========================================================================================\n');
fprintf('           PHÂN TÍCH MIỀN TẦN SỐ (FFT / PSD) - BỔ SUNG YÊU CẦU CHUNG CỦA ĐỀ TÀI\n');
fprintf('==========================================================================================\n\n');

%% ========================================================================
% PHẦN 1: FFT CỦA KÊNH A Ở TỐC ĐỘ HẰNG SỐ
% Kỳ vọng lý thuyết: kênh A là chuỗi xung vuông có PPR chu kỳ / vòng quay,
% nên tần số cơ bản f_A = PPR * (omega / 2*pi) Hz.
% ========================================================================
fprintf('--- PHẦN 1: FFT kênh A (kiểm chứng tần số xung cơ bản) ---\n\n');

omega_const = 10; % rad/s, cùng mức tốc độ dùng xuyên suốt Ngày 8 (S1-S4)
duration_fft = 0.2; % s - đủ dài để có độ phân giải tần số tốt, đủ ngắn để FFT nhanh
t_fft = 0:dt:duration_fft;
theta_fft = omega_const * t_fft;

[A_ideal, ~, ~] = encoder_model(theta_fft, params, 0);

% Loại DC offset trước khi biến đổi Fourier
A_ac = double(A_ideal) - mean(double(A_ideal));
N = length(A_ac);

Y = fft(A_ac);
P2 = abs(Y / N);
P1 = P2(1:floor(N/2)+1);
P1(2:end-1) = 2 * P1(2:end-1);
f_axis = Fs * (0:floor(N/2)) / N;

% Tìm đỉnh phổ chính (bỏ qua bin gần 0 Hz)
[~, peak_idx] = max(P1(2:end));
peak_idx = peak_idx + 1;
f_peak_measured = f_axis(peak_idx);
f_peak_theory = PPR * omega_const / (2*pi);

fprintf('Tốc độ không đổi              : %.3f rad/s\n', omega_const);
fprintf('Tần số xung cơ bản lý thuyết  : PPR*omega/(2*pi) = %.3f Hz\n', f_peak_theory);
fprintf('Tần số đỉnh phổ đo được (FFT) : %.3f Hz\n', f_peak_measured);
fprintf('Sai số tương đối              : %.4f %%\n\n', ...
    100 * abs(f_peak_measured - f_peak_theory) / f_peak_theory);

fig1 = figure('Name', 'FFT kenh A', 'Position', [100 100 1000 500]);
plot(f_axis, P1, 'LineWidth', 1.2);
hold on;
yl = ylim();
plot([f_peak_theory, f_peak_theory], yl, '--r', 'LineWidth', 1.5);
ylim(yl);
xlim([0, f_peak_theory * 4]);
title(sprintf('FFT kenh A tai omega = %.1f rad/s (dinh do = %.1f Hz, ly thuyet = %.1f Hz)', ...
    omega_const, f_peak_measured, f_peak_theory));
xlabel('Tan so (Hz)');
ylabel('Bien do |A(f)|');
legend('Pho FFT kenh A', 'f ly thuyet = PPR x omega / (2 pi)', 'Location', 'best');
grid on;

saveas(fig1, fullfile(out_fig_dir, 'fft_channel_A.png'));
fprintf('>> Đã lưu hình: %s\n\n', fullfile(out_fig_dir, 'fft_channel_A.png'));

%% ========================================================================
% PHẦN 2: PSD CỦA SAI SỐ ƯỚC LƯỢNG HYBRID - S2 (NHẸ) vs S3 (NẶNG)
% Dùng đúng cách tiêm nhiễu edge-domain của main_rubric_scenarios.m
% (jitter +-1 mau/bounce 5% cho S2, jitter +-2 mau/bounce 25% cho S3)
% ========================================================================
fprintf('--- PHẦN 2: PSD sai số ước lượng Hybrid - so sánh S2 (nhẹ) vs S3 (nặng) ---\n\n');

rng(params.rng_seed);

duration_psd = 1.0;
t1 = 0:dt:duration_psd;
omega_1 = 10;
theta_1 = omega_1 * t1;

[A1_edges, B1_edges] = encoder_model(theta_1, params, 0);

[A2, B2] = inject_micro_noise(A1_edges, B1_edges, 1, 0.05);  % S2: nhẹ
[A3, B3] = inject_micro_noise(A1_edges, B1_edges, 2, 0.25);  % S3: nặng

[pos_count_2, ~] = quadrature_decoder_x4(A2, B2);
[pos_count_3, ~] = quadrature_decoder_x4(A3, B3);

[~, ~, o_H2] = speed_estimator(pos_count_2, t1, PPR, zeros(size(t1)));
[~, ~, o_H3] = speed_estimator(pos_count_3, t1, PPR, zeros(size(t1)));

start_idx = max(1, round(0.05 * Fs)); % bỏ 50ms transient khởi động, đồng bộ quy ước với main_rubric_scenarios.m
err_S2 = o_H2(start_idx:end) - omega_1;
err_S3 = o_H3(start_idx:end) - omega_1;

% pwelch: chia đoạn 4096 mẫu, overlap 50%, cửa sổ Hamming
nfft = 4096;
window_len = 4096;
noverlap = window_len / 2;


[psd_S2, f_psd] = pwelch(err_S2 - mean(err_S2), hamming(window_len), noverlap, nfft, Fs);
[psd_S3, ~]      = pwelch(err_S3 - mean(err_S3), hamming(window_len), noverlap, nfft, Fs);

% Kiểm tra định lý Parseval (sanity check): tích phân PSD ~ phương sai tín hiệu
var_S2_time = var(err_S2);
var_S2_psd  = trapz(f_psd, psd_S2) * 2; % nhân 2 vì pwelch trả về phổ 1 phía
var_S3_time = var(err_S3);
var_S3_psd  = trapz(f_psd, psd_S3) * 2;

fprintf('Kiểm tra Parseval (đối chiếu miền thời gian vs miền tần số):\n');
fprintf('  S2: Var(err) miền thời gian = %.6f | Tích phân PSD = %.6f (rad/s)^2\n', var_S2_time, var_S2_psd);
fprintf('  S3: Var(err) miền thời gian = %.6f | Tích phân PSD = %.6f (rad/s)^2\n\n', var_S3_time, var_S3_psd);

fig2 = figure('Name', 'PSD sai so Hybrid S2 vs S3', 'Position', [100 100 1000 500]);
semilogy(f_psd, psd_S2, 'LineWidth', 1.1); hold on;
semilogy(f_psd, psd_S3, 'LineWidth', 1.1);
xlim([0, Fs/20]); % gioi han truc X de de so sanh 2 duong, tranh duoi dai it thong tin
title('PSD sai so uoc luong Hybrid: S2 (nhieu nhe) vs S3 (nhieu nang)');
xlabel('Tan so (Hz)');
ylabel('PSD ((rad/s)^2/Hz)');
legend('S2: Low Noise (jitter +-1, bounce 5%)', 'S3: High Noise (jitter +-2, bounce 25%)', 'Location', 'best');
grid on;

saveas(fig2, fullfile(out_fig_dir, 'psd_hybrid_error_S2_vs_S3.png'));
fprintf('>> Đã lưu hình: %s\n\n', fullfile(out_fig_dir, 'psd_hybrid_error_S2_vs_S3.png'));

%% ========================================================================
% XUẤT BẢNG TÓM TẮT
% ========================================================================
csv_path = fullfile(out_tab_dir, 'frequency_domain_summary.csv');
csv_data = {
    'Metric', 'Value';
    'f_peak_theory_Hz', f_peak_theory;
    'f_peak_measured_Hz', f_peak_measured;
    'f_peak_relative_error_pct', 100*abs(f_peak_measured-f_peak_theory)/f_peak_theory;
    'S2_var_time_domain', var_S2_time;
    'S2_var_from_PSD', var_S2_psd;
    'S3_var_time_domain', var_S3_time;
    'S3_var_from_PSD', var_S3_psd;
};
if exist('writecell', 'file') == 2 || exist('writecell', 'builtin')
    writecell(csv_data, csv_path);
else
    fid = fopen(csv_path, 'w');
    for r = 1:size(csv_data, 1)
        row = csv_data(r, :);
        row_str = cellfun(@(x) num2str(x), row, 'UniformOutput', false);
        fprintf(fid, '%s\n', strjoin(row_str, ','));
    end
    fclose(fid);
end
fprintf('>> Đã xuất bảng tóm tắt: %s\n', csv_path);
fprintf('==========================================================================================\n');