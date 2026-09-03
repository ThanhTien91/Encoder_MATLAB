# ⚙️ Đồ án: Bộ ước lượng vị trí và vận tốc từ Encoder Quadrature có mất xung

Repository này chứa mã nguồn MATLAB mô phỏng và đánh giá hệ thống Encoder Quadrature trong các điều kiện nhiễu, mất xung, sai lệch tham số môi trường và giới hạn băng thông phần cứng.

Mục tiêu của dự án là xây dựng một pipeline hoàn chỉnh gồm mô hình hóa quỹ đạo và encoder, giải mã Quadrature X4, phát hiện lỗi mất xung, bù trừ vị trí, hiệu chuẩn sai lệch pha và ước lượng vận tốc bằng M-Method, T-Method và Hybrid Fusion. Hệ thống được đánh giá định lượng thông qua các kịch bản vận hành và các phân tích Monte Carlo.

---

## 📂 Cấu trúc thư mục

```text
📦 Encoder_MATLAB
 ┣ 📂 config
 │  └── default_params.m
 ┣ 📂 models
 │  ├── trajectory_model.m
 │  ├── encoder_model.m
 │  ├── inject_micro_noise.m
 │  ├── inject_pulse_loss.m
 │  ├── inject_acquisition_saturation.m
    ├── compare_estimators.m
 │  └── speed_estimator.m
 ┣ 📂 decoder
 │  ├── quadrature_decoder_x4.m
 │  ├── position_compensator.m
 │  └── encoder_calibration.m
 ┣ 📂 analysis
 │  ├── compute_metrics.m
 │  ├── analyze_zero_crossing.m
 │  ├── analyze_sampling_frequency.m
 │  ├── analyze_pulse_loss.m
 │  ├── analyze_scenarios.m
 │  └── sensitivity_analysis.m
 ┣ 📂 experiments
 │  ├── main_day5.m
 │  ├── main_rubric_scenarios.m
 │  └── velocity_kf.m
 ┣ 📂 results
 │  ├── scenario_results.mat
 │  ├── tables
 │  └── figure
 ┣ 📜 main_day1.m
 ┣ 📜 main_day2.m
 ┣ 📜 main_day3.m
 ┣ 📜 main_day4.m
 ┣ 📜 main_day7.m
 ┣ 📜 run_sensitivity.m
 ┣ 📜 verify_manual.m
 ┗ 📜 README.md
```

---

## 🚀 Hướng dẫn nghiệm thu

### 1. Kiểm tra mô hình cơ sở

Từ thư mục gốc của repository, chạy:

```matlab
main_day1
```

Kiểm tra quỹ đạo tốc độ, vị trí và tín hiệu Encoder A/B/Z.

### 2. Kiểm tra mô hình nhiễu và mất xung

Chạy:

```matlab
main_day2
```

Kiểm tra thống kê nhiễu và tỷ lệ mất xung.

### 3. Kiểm tra bộ giải mã và bộ ước lượng

Chạy:

```matlab
main_day3
```

Kiểm tra Quadrature X4 Decoder, phát hiện invalid transition và so sánh M-Method, T-Method và Hybrid Estimator.

### 4. Kiểm tra bù trừ vị trí và lọc vận tốc

Chạy:

```matlab
main_day4
```

Kiểm tra RMSE, MAE, Max Error và Final Drift trước/sau bù trừ.

Để so sánh IIR với 1D Kalman Filter:

```matlab
cd experiments
main_day5
```

### 5. Kiểm tra các kịch bản động học

Từ thư mục gốc:

```matlab
main_day7
```

Các kịch bản gồm:

* Very Low Constant Speed
* Zero-Crossing & Direction Reversal
* Fast Acceleration
* Hard Brake
* Micro-Vibrations

### 6. Kiểm chứng toán học lõi

Chạy:

```matlab
verify_manual
```

Script kiểm tra độc lập vị trí sau bù trừ và độ chính xác của các bộ ước lượng trong trường hợp tốc độ không đổi.

### 7. Nghiệm thu theo kịch bản hệ thống

Chạy:

```matlab
cd experiments
main_rubric_scenarios
```

Script đánh giá 5 kịch bản:

* S1: Nominal
* S2: Low Noise
* S3: High Noise
* S4: Parameter Deviation
* S5: Hardware Fault / Acquisition Saturation

Kết quả được xuất ra:

```text
results/tables/rubric_scenarios_summary.csv
```

### 8. Phân tích Monte Carlo và độ nhạy

Trong thư mục `analysis`:

```matlab
analyze_pulse_loss
sensitivity_analysis
analyze_sampling_frequency
compare_estimators
analyze_zero_crossing
```

Các phân tích lần lượt đánh giá:

* độ bền đối với mất xung;
* độ nhạy đối với nhiễu ngẫu nhiên;
* ảnh hưởng của tần số lấy mẫu;
* sai số của M/T/Hybrid theo dải tốc độ;
* hành vi quanh vùng zero-crossing.

Ngoài ra:

```matlab
cd ..
run_sensitivity
```

thực hiện phân tích độ nhạy của sai số vị trí đối với tỷ lệ mất xung từ 0.1% đến 2.0%.

---

## 🔁 Tái lập kết quả

Hệ thống sử dụng:

```matlab
params.rng_seed = 42;
```

và các script có thành phần ngẫu nhiên cố định random seed trước khi sinh nhiễu hoặc lỗi.

Khi chạy cùng một script với cùng cấu hình tham số, kết quả phải được tái lập.

---

## 📊 Các chỉ số đánh giá

Hệ thống sử dụng các chỉ số:

* RMSE
* MAE
* Maximum Absolute Error
* Bias
* Standard Deviation
* Final Drift
* Estimation Delay / Latency

Đối với các phân tích Monte Carlo, các thống kê như Mean, Standard Deviation, P05, P50, P95 và Worst-case Error được sử dụng khi phù hợp với từng phép thử.

---

## 🧩 Các đặc tính chính của hệ thống

* Quadrature decoding X4
* Phát hiện two-state jump / invalid transition
* Bù trừ vị trí dựa trên trạng thái lỗi
* M-Method
* T-Method
* Adaptive Hybrid Fusion
* T-Method timeout và outlier rejection
* IIR và 1D Kalman velocity filtering
* Thermal phase drift
* Multi-edge phase calibration
* Acquisition bandwidth saturation
* Pulse-loss sensitivity analysis
* Monte Carlo uncertainty analysis
* Dynamic scenario testing
* Reproducible simulation with fixed random seed

---

## ✅ Trạng thái

Dự án đã hoàn thiện phần mô phỏng, thuật toán lõi và khung đánh giá định lượng. Các kết quả cuối cùng được sử dụng để tổng hợp báo cáo kỹ thuật và chuẩn bị nghiệm thu.
