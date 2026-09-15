% ==========================================================================
% FILE: analyze_frequency_domain.m
% MODULE: Frequency Domain Analysis (FFT / PSD)
% DESCRIPTION: 
%   PART 1 (FFT): Verifies Channel A fundamental frequency matches
%                 theory: f_A = PPR * omega / (2*pi) [Hz]
%   PART 2 (PSD): Compares Hybrid estimation error PSD between
%                 S2 (Low Noise) and S3 (High Noise) using Welch
%                 method. Parseval's theorem validation included.
% ==========================================================================

%% ==========================================================================
% 1. ENVIRONMENT SETUP
% ==========================================================================

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
fprintf('           FREQUENCY DOMAIN ANALYSIS (FFT / PSD) - REQUIREMENT COMPLIANCE\n');
fprintf('==========================================================================================\n\n');

%% ==========================================================================
% PART 1: FFT VERIFICATION
% ==========================================================================

fprintf('--- PART 1: FFT Channel A (Fundamental Frequency Verification) ---\n\n');

omega_const = 10;          % rad/s (Matches S1-S4)
duration_fft = 0.2;        % s
t_fft = 0:dt:duration_fft;
theta_fft = omega_const * t_fft;

[A_ideal, ~, ~] = encoder_model(theta_fft, params, 0);

% Remove DC Offset
A_ac = double(A_ideal) - mean(double(A_ideal));
N = length(A_ac);

Y = fft(A_ac);
P2 = abs(Y / N);
P1 = P2(1:floor(N/2)+1);
P1(2:end-1) = 2 * P1(2:end-1);
f_axis = Fs * (0:floor(N/2)) / N;

% Peak Detection
[~, peak_idx] = max(P1(2:end));
peak_idx = peak_idx + 1;
f_peak_measured = f_axis(peak_idx);
f_peak_theory = PPR * omega_const / (2*pi);

fprintf('Constant Speed              : %.3f rad/s\n', omega_const);
fprintf('Theoretical Fundamental f_A : PPR*omega/(2*pi) = %.3f Hz\n', f_peak_theory);
fprintf('Measured Peak (FFT)         : %.3f Hz\n', f_peak_measured);
fprintf('Relative Error              : %.4f %%\n\n', ...
    100 * abs(f_peak_measured - f_peak_theory) / f_peak_theory);

% Plot FFT
fig1 = figure('Name', 'FFT Channel A', 'Position', [100, 100, 1000, 500]);
plot(f_axis, P1, 'LineWidth', 1.2); hold on;
yl = ylim();
plot([f_peak_theory, f_peak_theory], yl, '--r', 'LineWidth', 1.5);
ylim(yl); xlim([0, f_peak_theory * 4]);
title(sprintf('FFT Ch A @ omega=%.1f rad/s (Meas=%.1f Hz, Theory=%.1f Hz)', ...
    omega_const, f_peak_measured, f_peak_theory));
xlabel('Frequency (Hz)'); ylabel('|A(f)|');
legend('FFT Ch A', 'f_theory = PPR x omega / (2 pi)', 'Location', 'best');
grid on;

saveas(fig1, fullfile(out_fig_dir, 'fft_channel_A.png'));
fprintf('>> Figure saved: %s\n\n', fullfile(out_fig_dir, 'fft_channel_A.png'));

%% ==========================================================================
% PART 2: PSD OF HYBRID ESTIMATION ERROR (S2 vs S3)
% ==========================================================================

fprintf('--- PART 2: PSD of Hybrid Estimation Error (S2 vs S3) ---\n\n');

rng(params.rng_seed);

duration_psd = 1.0;
t1 = 0:dt:duration_psd;
omega_1 = 10;
theta_1 = omega_1 * t1;

[A1_edges, B1_edges] = encoder_model(theta_1, params, 0);
[A2, B2] = inject_micro_noise(A1_edges, B1_edges, 1, 0.05);   % S2: Low Noise
[A3, B3] = inject_micro_noise(A1_edges, B1_edges, 2, 0.25);   % S3: High Noise

[pos_count_2, ~] = quadrature_decoder_x4(A2, B2);
[pos_count_3, ~] = quadrature_decoder_x4(A3, B3);

[~, ~, o_H2] = speed_estimator(pos_count_2, t1, PPR, zeros(size(t1)));
[~, ~, o_H3] = speed_estimator(pos_count_3, t1, PPR, zeros(size(t1)));

start_idx = max(1, round(0.05 * Fs));  % 50ms Transient Removal
err_S2 = o_H2(start_idx:end) - omega_1;
err_S3 = o_H3(start_idx:end) - omega_1;

% Welch PSD
nfft = 4096;
window_len = 4096;
noverlap = window_len / 2;

[psd_S2, f_psd] = pwelch(err_S2 - mean(err_S2), hamming(window_len), ...
    noverlap, nfft, Fs);
[psd_S3, ~] = pwelch(err_S3 - mean(err_S3), hamming(window_len), ...
    noverlap, nfft, Fs);

% Parseval Validation
var_S2_time = var(err_S2);
var_S2_psd  = trapz(f_psd, psd_S2) * 2;
var_S3_time = var(err_S3);
var_S3_psd  = trapz(f_psd, psd_S3) * 2;

fprintf('Parseval Validation (Time vs Frequency Domain Variance):\n');
fprintf('  S2: Var(Time) = %.6f | Var(PSD) = %.6f (rad/s)^2\n', ...
    var_S2_time, var_S2_psd);
fprintf('  S3: Var(Time) = %.6f | Var(PSD) = %.6f (rad/s)^2\n\n', ...
    var_S3_time, var_S3_psd);

% Plot PSD
fig2 = figure('Name', 'PSD Hybrid Error S2 vs S3', 'Position', [100, 100, 1000, 500]);
semilogy(f_psd, psd_S2, 'LineWidth', 1.1); hold on;
semilogy(f_psd, psd_S3, 'LineWidth', 1.1);
xlim([0, Fs/20]);
title('PSD of Hybrid Estimation Error: S2 (Low Noise) vs S3 (High Noise)');
xlabel('Frequency (Hz)'); ylabel('PSD ((rad/s)^2/Hz)');
legend('S2: Low Noise (jitter ±1, bounce 5%)', ...
    'S3: High Noise (jitter ±2, bounce 25%)', 'Location', 'best');
grid on;

saveas(fig2, fullfile(out_fig_dir, 'psd_hybrid_error_S2_vs_S3.png'));
fprintf('>> Figure saved: %s\n\n', fullfile(out_fig_dir, 'psd_hybrid_error_S2_vs_S3.png'));

%% ==========================================================================
% PART 3: SUMMARY CSV EXPORT
% ==========================================================================

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
fprintf('>> Summary CSV: %s\n', csv_path);
fprintf('==========================================================================================\n');