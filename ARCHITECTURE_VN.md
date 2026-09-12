# Encoder Project - Kiến Trúc & Framework (Tiếng Việt)

## 1. Tổng Quan Hệ Thống

Dự án MATLAB này triển khai một **Pipeline Xử Lý Tín Hiệu Encoder Quadrature** hoàn chỉnh bao gồm mô phỏng, giải mã, phát hiện lỗi, bù trừ vị trí, ước lượng vận tốc và đánh giá định lượng.

**Pipeline Cốt Lõi:**
```
Quỹ đạo → Mô hình Encoder → Tiêm Lỗi → Bộ Giải Mã X4 → Bù Trừ Vị Trí → Ước Lượng Vận Tốc (M/T/Hybrid) → Lọc → Chỉ Số
```

---

## 2. Cấu Trúc Thư Mục & Trách Nhiệm Module

```
Encoder_Project/
├── config/                    # Cấu Hình Hệ Thống
│   └── default_params.m       # Tham số tập trung + validation
├── models/                    # Mô Hình Vật Lý & Tín Hiệu
│   ├── trajectory_model.m     # Hồ sơ tốc độ/vị trí
│   ├── encoder_model.m        # Sinh tín hiệu A/B/Z lý tưởng
│   ├── inject_micro_noise.m   # Jitter, bounce, sai lệch pha
│   ├── inject_pulse_loss.m    # Mất xung ngẫu nhiên (đối xứng)
│   ├── inject_acquisition_saturation.m  # Bão hòa băng thông
│   ├── speed_estimator.m      # M-Method, T-Method, Hybrid
│   └── compare_estimators.m   # Tiện ích phân tích
├── decoder/                   # Thuật Toán Giải Mã
│   ├── quadrature_decoder_x4.m        # Máy trạng thái + phát hiện lỗi
│   ├── position_compensator.m         # Bù trừ bằng tích phân rò rỉ
│   └── encoder_calibration.m          # Hiệu chuẩn pha đa cạnh
├── analysis/                  # Đánh Giá & Chỉ Số
│   ├── compute_metrics.m      # RMSE, MAE, Max, Bias, Std, Delay
│   ├── analyze_scenarios.m    # Đánh giá kịch bản hàng loạt
│   ├── sensitivity_analysis.m # Độ nhạy Monte Carlo
│   ├── analyze_zero_crossing.m
│   ├── analyze_sampling_frequency.m
│   ├── analyze_pulse_loss.m
│   └── analyze_frequency_domain.m
├── experiments/               # Thử Nghiệm Mở Rộng
│   ├── main_day5.m            # So sánh IIR vs 1D Kalman
│   ├── main_rubric_scenarios.m # 5 kịch bản bắt buộc rubric
│   └── velocity_kf.m          # Triển khai Kalman 1D
├── results/                   # Kết Quả Đầu Ra
│   ├── tables/                # Bảng tóm tắt CSV
│   ├── figures/               # Đồ thị PNG (theo ngày/kịch bản)
│   └── *.mat                  # Dữ liệu thô cho hậu xử lý
├── main_day1.m                # Kiểm tra quỹ đạo & encoder lý tưởng
├── main_day2.m                # Kiểm tra tiêm nhiễu
├── main_day3.m                # Giải mã & ước lượng vận tốc
├── main_day4.m                # Bù trừ vị trí & lọc IIR
├── main_day7.m                # 5 kịch bản động học
├── run_sensitivity.m          # Quét độ nhạy mất xung
├── verify_manual.m            # Kiểm chứng toán học (ground-truth)
└── README.md                  # Hướng dẫn sử dụng
```

---

## 3. Kiến Trúc Luồng Dữ Liệu

### 3.1 Đối Tượng Tham Số (`params` struct)
Tất cả module nhận `params` thống nhất từ `default_params()`:

```matlab
params = struct(
    'rng_seed', 42,
    'Fs', 1e6,              % Tần số lấy mẫu
    'PPR', 1000,            % Xung/vòng (Pulses Per Revolution)
    'duration', 2.0,        % Thời gian mô phỏng
    'max_rpm', 600,         % Tốc độ tối đa
    'env.T_ref', 25,        % Nhiệt độ chuẩn (°C)
    'env.k_T', 0.005,       % Hệ số trôi nhiệt (rad/°C)
    'hw.max_event_freq', 50000,  % Giới hạn băng thông phần cứng
    'estimator.outlier_threshold', 40  % Ngưỡng outlier T-Method (rad/s)
);
```

### 3.2 Kiểu Dữ Liệu Cốt Lõi

| Biến | Mô Tả | Đơn Vị |
|------|-------|--------|
| `t` | Vector thời gian | giây |
| `theta` | Vị trí góc | radian |
| `omega` | Vận tốc góc | rad/s |
| `A, B, Z` | Kênh encoder | logic (0/1) |
| `pos_count` | Số đếm X4 decoder | counts |
| `missing_count` | Phát hiện lỗi: {0, ±2} | counts |
| `error_flag` | Cờ lỗi nhị phân | 0/1 |

### 3.3 Luồng Tín Hiệu

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│ trajectory_ │────▶│  encoder_   │────▶│  inject_*    │
│   model     │     │   model     │     │  (nhiễu,     │
└─────────────┘     └─────────────┘     │   mất, bão)  │
                                        └──────┬───────┘
                                               ▼
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│ speed_est   │◀────│ position_   │◀────│ quadrature_  │
│ (M/T/Hybrid)│     │ compensator │     │ decoder_x4   │
└──────┬──────┘     └─────────────┘     └──────────────┘
       ▼
┌─────────────┐
│  Filtering  │  (IIR / Kalman)
└──────┬──────┘
       ▼
┌─────────────┐
│  Metrics    │
└─────────────┘
```

---

## 4. Tài Liệu Tham Khảo API Module

### 4.1 Models (Mô Hình)

#### `trajectory_model(params)`
```matlab
[t, theta, omega] = trajectory_model(params)
```
Sinh hồ sơ tốc độ 5 giai đoạn: tăng tốc → không đổi → giảm tốc/đảo chiều → âm không đổi → dừng.

#### `encoder_model(theta, params, phase_offset)`
```matlab
[A, B, Z] = encoder_model(theta, params, phase_offset)
```
- `phase_offset`: trôi pha nhiệt (rad), mặc định 0
- Trả về tín hiệu quadrature lý tưởng với dịch pha 90°

#### `inject_micro_noise(A, B, jitter_range, bounce_prob)`
```matlab
[A_n, B_n] = inject_micro_noise(A, B, 2, 0.25)  % mặc định khớp code gốc
```
- Dịch pha tĩnh (5 mẫu trên kênh B)
- Jitter mỗi cạnh ±N mẫu ngẫu nhiên
- Bounce: glitch 3 mẫu ngẫu nhiên tại cạnh xung

#### `inject_pulse_loss(A, B, drop_rate)`
```matlab
[A_n, B_n, stats] = inject_pulse_loss(A, B, 0.01)
```
- Đối xứng: chọn ngẫu nhiên transition (bất kỳ pha), xóa 4 transition = 1 xung
- Trả về stats: `total_pulses`, `dropped_pulses`, `actual_drop_rate`

#### `inject_acquisition_saturation(A, B, Fs, params)`
```matlab
[A_sat, B_sat, missed] = inject_acquisition_saturation(A, B, Fs, params)
```
- Áp dụng giới hạn `params.hw.max_event_freq`
- Gộp các transition gần nhau hơn `1/max_event_freq`

### 4.2 Decoder (Bộ Giải Mã)

#### `quadrature_decoder_x4(A, B)`
```matlab
[pos_count, missing_count] = quadrature_decoder_x4(A, B)
```
- Máy trạng thái: mã transition 4-bit (prev*4 + curr)
- Thuận hợp lệ: {11,13,4,2} → +1
- Nghịch hợp lệ: {8,1,7,14} → -1
- Nhảy 2 trạng thái (lỗi): {3,6,9,12} → ±2 trong `missing_count`
- Trả về vector count + missing_count (0, +2, -2)

#### `position_compensator(theta_raw, missing_count, PPR)`
```matlab
theta_comp = position_compensator(theta_raw, missing_count, PPR)
```
- Tích phân rò rỉ: `correction(i) = 0.9995 * correction(i-1) + missing_count(i)`
- Ngăn chặn trôi tích lũy từ false positive

#### `encoder_calibration(A, B, Fs, omega_ref, PPR)`
```matlab
[cal_phase, uncertainty] = encoder_calibration(A, B, Fs, omega_ref, PPR)
```
- Yêu cầu `omega_ref` trạng thái ổn (assert `std < 1e-3`)
- Đo thời gian cạnh lên A→B qua nhiều chu kỳ
- Trả về sai số pha trung bình + sai số chuẩn

### 4.3 Speed Estimator (Bộ Ước Lượng Vận Tốc)

#### `speed_estimator(pos_count, t, PPR, error_flag, outlier_threshold)`
```matlab
[omega_M, omega_T, omega_Hybrid] = speed_estimator(pos_count, t, PPR, error_flag, 40)
```

**M-Method:** Cửa sổ cố định 10ms, ổn định tốc độ cao, độ trễ ~10ms
```matlab
Nm = round(0.01 / Ts);
omega_M(i) = (delta_count * dp_rad) / (Nm * Ts);
```

**T-Method:** Bắt sự kiện, timeout 5ms, loại outlier
```matlab
if error_flag(i)  % Bỏ qua khi decoder báo lỗi
    omega_T(i) = omega_T(i-1);
elseif pos_count(i) ~= last_cnt
    tmp = ((pos_count(i) - last_cnt) * dp_rad) / delta_t;
    if abs(tmp - omega_T(i-1)) > outlier_threshold
        omega_T(i) = omega_T(i-1);  % Loại outlier
        last_time = t(i); last_cnt = pos_count(i);  % QUAN TRỌNG: tiến thời gian
    else
        omega_T(i) = tmp;
        last_time = t(i); last_cnt = pos_count(i);
    end
elseif (t(i) - last_time) > 0.005  % Timeout 5ms
    omega_T(i) = 0;
end
```

**Hybrid (Fusion Thích Nghi):**
```matlab
abs_M = abs(omega_M);
if abs_M > 15,       w = 1;      % Tin M
elseif abs_M < 5,    w = 0;      % Tin T
else                 w = (abs_M-5)/10;  % Pha trộn
omega_Hybrid = w*omega_M + (1-w)*omega_T;
% Lọc trung bình chạy 5ms
```

### 4.4 Analysis (Phân Tích)

#### `compute_metrics(true_signal, est_signal)`
```matlab
metrics = compute_metrics(true_sig, est_sig)
```
Trả về struct: `.rmse`, `.mae`, `.max_error`, `.bias`, `.std_error`, `.delay_samples`

---

## 5. Thứ Tự Thực Thi Các Script Thử Nghiệm

### Trình Tự Kiểm Chứng (theo README)
```matlab
% 1. Kiểm tra mô hình cơ sở
main_day1          % Quỹ đạo + A/B/Z lý tưởng

% 2. Tiêm nhiễu
main_day2          % Nhiễu vi mô + thống kê mất xung

% 3. Giải mã & ước lượng
main_day3          % X4 decoder, cờ lỗi, M/T/Hybrid

% 4. Bù trừ & lọc
main_day4          % Bù trừ vị trí + bộ lọc IIR

% 5. So sánh bộ lọc (trong experiments/)
cd experiments
main_day5          % IIR vs 1D Kalman

% 6. Kịch bản động học
main_day7          % 5 kịch bản với chỉ số định lượng

% 7. Kiểm chứng toán học
verify_manual      % Ground-truth vị trí & vận tốc

% 8. Kịch bản rubric (trong experiments/)
cd experiments
main_rubric_scenarios  % S1-S5: Nominal, Nhiễu Thấp/Cao, Nhiệt, Bão Hòa

% 9. Phân tích độ nhạy
run_sensitivity    % Mất xung 0.1% → 2.0%

% 10. Phân tích hàng loạt
cd analysis
analyze_scenarios  % Đọc scenario_results.mat → CSV
```

---

## 6. Các Mẫu Thiết Kế Quan Trọng

### 6.1 Tương Thích Ngược (Backward Compatibility)
Tất cả hàm dùng `nargin` cho tham số tùy chọn:
```matlab
if nargin < 3 || isempty(phase_offset)
    phase_offset = 0;
end
```

### 6.2 Validation Input & Assertions
```matlab
assert(params.PPR > 0, 'PPR phải là số dương');
assert(std(omega_ref) < 1e-3, 'Hiệu chuẩn cần trạng thái ổn định');
```

### 6.3 Tái Lập Kết Quả (Reproducibility)
Mọi script đặt `rng(params.rng_seed)` trước phép toán ngẫu nhiên.

### 6.4 An Toán Vector
```matlab
pos_count = reshape(pos_count, 1, []);  % Ép thành vector hàng
t = reshape(t, 1, []);
```

### 6.5 Tích Phân Rò Rỉ (Anti-drift)
```matlab
leak_factor = 0.9995;
correction(i) = correction(i-1) * leak_factor + missing_count(i);
```

### 6.6 T-Method Tiến Thời Gian Khi Loại Outlier
```matlab
% QUAN TRỌNG: Phải tiến thời gian/số đếm ngay cả khi loại outlier
last_time = t(i);  
last_cnt  = pos_count(i);
```

---

## 7. Chỉ Số & Tiêu Chí Đánh Giá

| Chỉ Số | Công Thức | Mục Đích |
|--------|-----------|----------|
| RMSE | `sqrt(mean((est-true).^2))` | Độ chính xác tổng thể |
| MAE | `mean(abs(est-true))` | Kháng outlier |
| Max Error | `max(abs(est-true))` | Tường trình xấu nhất |
| Bias | `mean(est-true)` | Độ lệch hệ thống |
| Std Error | `std(est-true)` | Độ chính xác |
| Delay | Lag tương quan chéo | Độ trễ pha |
| Final Drift | `abs(error(end))` | Tích lũy dài hạn |

**Thống Kê Monte Carlo:** Mean, Std, P05, P50, P95, Worst-case

---

## 8. Kịch Bản Rubric (S1-S5)

| Kịch Bản | Điều Kiện | Mục Đích |
|----------|-----------|----------|
| **S1** Nominal | 10 rad/s, 25°C, không nhiễu | Baseline |
| **S2** Low Noise | Jitter ±1, bounce 5% | Khả năng chịu đựng |
| **S3** High Noise | Jitter ±2, bounce 25% | Stress test |
| **S4** Param Deviation | 60°C (trôi pha nhiệt) | Hiệu chuẩn |
| **S5** HW Fault | Tăng tốc 800 RPM > 750 limit | Bão hòa |

---

## 9. Mở Rộng Framework

### Thêm Mô Hình Tiêm Lỗi Mới
1. Tạo `models/inject_new_fault.m`
2. Tuân thủ signature: `[A_out, B_out, stats] = inject_new_fault(A, B, params)`
3. Thêm vào `main_day2.m` và `main_rubric_scenarios.m`
4. Cập nhật `default_params.m` nếu cần config mới

### Thêm Bộ Ước Lượng Vận Tốc Mới
1. Thêm vào `speed_estimator.m` hoặc file mới
2. Trả về output thêm: `[..., omega_New]`
3. Cập nhật gọi `compute_metrics` trong analysis
4. Thêm vào logic Hybrid fusion nếu thích nghi

### Thêm Phân Tích Mới
1. Tạo `analysis/analyze_new.m`
2. Dùng `compute_metrics` để nhất quán
3. Xuất CSV đến `results/tables/`
4. Lưu đồ thị đến `results/figure/<name>/`

---

## 10. Cạm Bẫy Thường Gặp & Cách Khắc Phục

| Vấn Đề | Nguyên Nhân | Khắc Phục |
|--------|-------------|-----------|
| T-Method kẹt giá trị lớn | Loại outlier không tiến thời gian | Cập nhật `last_time`, `last_cnt` trong nhánh loại |
| Vị trí trôi sau bù trừ | Leak factor quá cao / dấu missing_count sai | Kiểm tra dấu `missing_count` khớp chiều |
| Hiệu chuẩn thất bại | omega_ref không ổn | Đảm bảo `std(omega_ref) < 1e-3` |
| RMSE không khớp giữa script | Xử lý transient khác nhau | Dùng cùng `start_idx = round(0.05*Fs)` |
| File .mat quá lớn | Lưu toàn bộ 1MHz | Downsample 100x (decim=100) trước khi save |

---

## 11. Mở Rộng Framework (Ví Dụ)

### Thêm Kịch Bản Mới
```matlab
% Trong main_day7.m hoặc experiment mới
omega_new = <custom_profile>(t);
theta_new = cumtrapz(t, omega_new);
[A, B] = encoder_model(theta_new, params);
[pos_count, missing_count] = quadrature_decoder_x4(A, B);
theta_comp = position_compensator(pos_count*dp_rad, missing_count, params.PPR);
[o_M, o_T, o_H] = speed_estimator(pos_count, t, params.PPR, double(missing_count~=0));
metrics = compute_metrics(omega_new, o_H);
```

### Thêm Biến Thể Kalman Filter
Sửa `experiments/velocity_kf.m`:
```matlab
function x = velocity_kf(z, Ts, q_acc, r_var)
    % State: [vận tốc; gia tốc]
    F = [1 Ts; 0 1];
    H = [1 0];
    Q = q_acc * [Ts^3/3 Ts^2/2; Ts^2/2 Ts];
    R = r_var;
    % ... phương trình KF chuẩn
end
```

---

## 12. Đồ Thị Phụ Thuộc File

```
default_params.m
    │
    ├── trajectory_model.m
    ├── encoder_model.m
    │       │
    │       ├── inject_micro_noise.m
    │       ├── inject_pulse_loss.m
    │       └── inject_acquisition_saturation.m
    │
    ├── quadrature_decoder_x4.m
    │       │
    │       ├── position_compensator.m
    │       └── encoder_calibration.m
    │
    └── speed_estimator.m
            │
            ├── velocity_kf.m (experiments)
            └── compare_estimators.m
```

Tất cả main scripts → `addpath` → gọi models → decoder → estimator → analysis → results

---

*Tạo từ phân tích codebase - cập nhật khi dự án phát triển*