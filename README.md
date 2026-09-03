# ⚙️ Đồ án: Bộ ước lượng vị trí và vận tốc từ encoder quadrature có mất xung

Repository này chứa mã nguồn MATLAB mô phỏng và xử lý tín hiệu cho Quadrature Encoder. Mục tiêu của dự án là thiết lập mô hình vật lý có chứa nhiễu, sai số môi trường, và bão hòa phần cứng, từ đó xây dựng các thuật toán giải mã, tự động hiệu chuẩn (calibration), bù trừ vị trí, và ước lượng tốc độ lai ghép (Hybrid Fusion).

Dự án bám sát 100% yêu cầu **Đề tài 06** và **Khung Yêu cầu Hệ thống (Rubric)**: Đánh giá định lượng qua 5 kịch bản chuẩn (Nominal, Noise, Parameter Drift, Hardware Fault) và phân tích độ bất định bằng Monte Carlo.

---

## 📂 Cấu trúc thư mục

```text
📦 Encoder_Project
 ┣ 📂 config              # Cấu hình tham số hệ thống, môi trường (nhiệt độ) và giới hạn phần cứng
 ┣ 📂 models              # Sinh tín hiệu Encoder, tiêm nhiễu ngẫu nhiên, trôi pha, bão hòa băng thông
 ┣ 📂 decoder             # Giải mã Quadrature X4, Bù trừ vị trí (Compensator), Hiệu chuẩn (Calibration)
 ┣ 📂 analysis            # Khung đánh giá định lượng (Metrics, Monte Carlo, Fs Sweep, Speed Sweep)
 ┣ 📂 experiments         # Chứa kịch bản động học (Day 7) và kịch bản nghiệm thu Rubric (Day 8)
 ┣ 📂 results             # Tự động lưu trữ số liệu (.csv, .mat) và biểu đồ phân tích (.png)
 ┃  ┣ 📂 tables           # Bảng tổng hợp kết quả (.csv)
 ┃  └ 📂 figure           # Biểu đồ theo ngày (day1 -> day8)
 ┣ 📜 main_day1.m         # Script chạy nghiệm thu Ngày 1 (Hệ lý tưởng)
 ┣ 📜 main_day2.m         # Script chạy nghiệm thu Ngày 2 (Hệ có nhiễu)
 ┣ 📜 main_day3.m         # Script chạy nghiệm thu Ngày 3 (Giải mã & Ước lượng)
 ┣ 📜 main_day4.m         # Script chạy nghiệm thu Ngày 4 (Bù trừ lỗi & Lọc IIR)
 ┣ 📜 main_day7.m         # Script chạy nghiệm thu Ngày 7 (Kịch bản động học)
 ┣ 📜 generate_scenario_data.m  # Sinh dữ liệu kịch bản
 ┣ 📜 verify_manual.m     # Kịch bản kiểm chứng chéo toán học (Manual Sanity Check)
 ┗ 📜 README.md           # Thông tin đồ án
```

---

## 🚀 Hướng dẫn chạy code

**1. Nghiệm thu Khung Hệ Thống (Rubric Scenarios - Quan trọng nhất):**

* Điều hướng vào `experiments/` và chạy `main_rubric_scenarios.m`.
* Script này sẽ tự động chạy 5 kịch bản bắt buộc: Lý tưởng (Nominal), Nhiễu Jitter (Noise), Sai số nhiệt độ (Parameter Drift), và Quá tải băng thông (Acquisition Saturation). Kết quả trả về bảng tổng hợp RMSE, chẩn đoán Calibration, và tự động lưu ra `results/tables/rubric_scenarios_summary.csv`.

**2. Phân tích Sức bền Thống kê (Uncertainty Analysis):**

* Điều hướng vào `analysis/` và chạy `sensitivity_analysis.m`: Thực hiện True Monte Carlo (100 trials) để đo khoảng tin cậy (P05-P95) và sai số tồi tệ nhất (Worst-case RMSE) của hệ thống trước nhiễu Jitter.
* Chạy `analyze_pulse_loss.m`: Đánh giá Monte Carlo (50 trials) để đo phần trăm (%) hiệu quả của bộ bù trừ vị trí khi rớt xung từ 0.1% đến 2.0%.
* Chạy `analyze_sampling_frequency.m`: Quét dải tần số timer (Fs Sweep) để chứng minh hiện tượng nhiễu phách lượng tử (Quantization Beating) của T-Method.

**3. Thử nghiệm Động học Chuyên sâu (Dynamic Scenarios):**

* Chạy `main_day7.m`: Kiểm thử độ bám sát của hệ thống trong 5 điều kiện vận hành khắc nghiệt (Vận tốc rất thấp, Đảo chiều qua điểm 0, Tăng tốc nhanh, Phanh gấp, Rung lắc vi mô).

**4. Kiểm chứng Toán học Lõi (Sanity Check):**

* Chạy `verify_manual.m`: Bơm lỗi nhảy trạng thái kép thủ công và dùng thời gian đảo ngược để xác thực thuật toán lõi đạt sai số tuyệt đối `0.00e+00` rad/s.

---

## 🧮 Cập nhật tiến độ & Lộ trình 10 ngày

### 🟢 Giai đoạn 1: Khởi tạo và Thiết kế Thuật toán lõi (Ngày 1 - Ngày 5)

* **Mô hình hóa & Nhiễu:** Xây dựng Encoder 1000 PPR. Giả lập nhiễu vi mô (Jitter, Bounce).
* **Giải mã & Ước lượng:** Phát triển State Machine xử lý trạng thái kép. Hoàn thiện Hybrid Estimator (Adaptive Fusion) điều chỉnh trọng số tự động giữa M-Method và T-Method.
* **Bù trừ & Lọc tín hiệu:** Ứng dụng State-Transition Compensation (cải thiện >20% sai số vị trí khi mất xung). Chốt sử dụng IIR Filter (`alpha = 0.15`) cho vận tốc sau khi chứng minh Kalman 1D bị trễ pha.

### 🟢 Giai đoạn 2: Khung Đánh giá Định lượng & Toàn vẹn Hệ thống (Ngày 6 - Ngày 8)

* **Ngày 6 (Kiểm chứng mô hình):** Hoàn thành Manual Verification tính tay. Thuật toán cốt lõi hội tụ tuyệt đối.
* **Ngày 7 (Thử nghiệm Động học):** Đo lường RMSE và Tracking Delay trên 5 quỹ đạo vận hành (Dynamic Scenarios). Hybrid Estimator xử lý mượt mà vùng Zero-crossing nhờ cơ chế Software Timeout.
* **Ngày 8 (Khung Hệ thống & Monte Carlo):**
  * Tích hợp mô hình Sai lệch pha do nhiệt độ (Thermal Phase Drift) và Thuật toán Tự động Hiệu chuẩn (Multi-edge Calibration) đạt độ chính xác >99%.
  * Giả lập giới hạn bão hòa phần cứng (Hardware Bandwidth Saturation) khi tốc độ vượt quá ngưỡng ngắt (Interrupt).
  * Chuyển đổi toàn bộ kịch bản đo lường sang True Monte Carlo Uncertainty Analysis. Tính toán Mean, Std, P05, P95, và Worst-case Max Error. Xuất tự động toàn bộ dữ liệu ra `.csv` và `.png`.

### 🟡 Giai đoạn 3: Đóng gói và Báo cáo (Ngày 9 - Ngày 10)

* **Ngày 9 (Tổng hợp Báo cáo Kỹ thuật):** Lắp ghép các bảng số liệu CSV và đồ thị định lượng vào Báo cáo Kỹ thuật (Technical Report). Phân tích luận cứ về giao điểm tử thần của T-Method và hiện tượng "leo thang nhiễu".
* **Ngày 10 (Nghiệm thu cuối):** Thiết kế Slide bảo vệ đồ án, kiểm tra độ tương thích của cấu trúc thư mục và nộp mã nguồn cuối cùng.

```
Dự án đang trong quá trình phát triển (Lộ trình 10 ngày).
```