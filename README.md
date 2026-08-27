# ⚙️ Đồ án: Bộ ước lượng vị trí và vận tốc từ encoder quadrature có mất xung

[![MATLAB](https://img.shields.io/badge/MATLAB-2026a%2B-blue.svg)](https://www.mathworks.com/)
[![Status](https://img.shields.io/badge/Tiến_độ-Hoàn_thành-success.svg)]()

Repository này chứa mã nguồn MATLAB mô phỏng và xử lý tín hiệu cho Quadrature Encoder. Mục tiêu của dự án là thiết lập mô hình vật lý có chứa nhiễu, từ đó xây dựng và kiểm chứng các thuật toán giải mã, bù trừ vị trí, và ước lượng tốc độ khi tín hiệu bị mất xung ngẫu nhiên. Dự án bám sát yêu cầu Đề tài 06: Đánh giá độ trễ và hành vi của hệ thống tại vùng tốc độ rất thấp/giao điểm zero.

---

## 📂 Cấu trúc thư mục

```text
📦 Encoder_Project
 ┣ 📂 config              # File cấu hình tham số hệ thống (default_params.m)
 ┣ 📂 models              # Mô hình động học, sinh tín hiệu và chèn nhiễu
 ┣ 📂 decoder             # Chứa thuật toán giải mã, bù trừ và ước lượng vận tốc
 ┣ 📂 experiments         # Thư mục chứa các thử nghiệm
 ┣ 📂 results             # Lưu trữ hình ảnh và số liệu xuất ra (thư mục figure/)
 ┣ 📜 main_day1.m         # Script chạy nghiệm thu Ngày 1 (Hệ lý tưởng)
 ┣ 📜 main_day2.m         # Script chạy nghiệm thu Ngày 2 (Hệ có nhiễu)
 ┣ 📜 main_day3.m         # Script chạy nghiệm thu Ngày 3 (Giải mã & Ước lượng)
 ┣ 📜 main_day4.m         # Script chạy nghiệm thu Ngày 4 (Bù trừ lỗi & Lọc IIR)
 ┣ 📜 verify_manual.m     # Script kiểm chứng chéo toán học (Sanity Check)
 ┣ 📜 run_sensitivity.m   # Script phân tích độ nhạy (Sensitivity Analysis)
 ┣ 📜 .gitignore          # Cấu hình bỏ qua file rác MATLAB
 ┗ 📜 README.md           # Thông tin đồ án

```

---

## 🚀 Hướng dẫn chạy code

**1. Nghiệm thu Ngày 1 & 2 (Hệ thống cơ sở & Tiêm lỗi phần cứng):**

* Chạy `main_day1.m`: Sinh quỹ đạo chuyển động và xuất tín hiệu lý tưởng.
* Chạy `main_day2.m`: Đưa nhiễu vi mô (Jitter, Bounce, Phase error) và đánh rớt xung (Pulse Loss).

**2. Nghiệm thu Ngày 3 & 4 (Giải mã, Ước lượng & Bù trừ - Pipeline Chính):**

* Chạy `main_day3.m`: Kiểm tra thuật toán phát hiện sự kiện lỗi bằng State Machine và so sánh các bộ ước lượng tốc độ (M/T/Hybrid).
* Chạy `main_day4.m`: Đánh giá hiệu năng của bộ bù trừ vị trí (`position_compensator`) và bộ lọc IIR cho vận tốc.

**3. Kiểm chứng, Phân tích chuyên sâu & Thử nghiệm (Tầng 2):**

* Truy cập thư mục `experiments/day5_velocity_filter_comparison/` để xem kết quả so sánh định lượng (RMSE, MAE, Phase Delay) giữa bộ lọc IIR và 1D Kalman.
* Chạy `verify_manual.m`: Kiểm chứng độ chính xác tuyệt đối của toán học lõi.
* Chạy `run_sensitivity.m`: Ép xung hệ thống với các mức rớt xung tăng dần (0.1% -> 2.0%) để tìm điểm bão hòa của thuật toán. Hình ảnh tự động lưu vào `results/figure/`.

---

## 🧮 Cập nhật tiến độ & Kết quả

### Ngày 1 & 2: Mô hình cơ sở và Nhiễu

* Xây dựng thành công hệ thống Encoder 1000 PPR, tốc độ 600 RPM.
* Thuật toán giả lập thành công các gai nhiễu phần cứng và hiện tượng rớt xung ngẫu nhiên, phản ánh đúng sự biến dạng tín hiệu ở mức vi mô.

### Ngày 3: Giải mã và Ước lượng vận tốc

* Bộ giải mã Quadrature (X4) bắt thành công các sự kiện nhảy trạng thái kép.
* Xác thực được điểm yếu vật lý của T-Method (dễ bùng nổ do gai nhiễu câm) và hoàn thiện Hybrid Estimator (Adaptive Fusion) khắc phục được nhược điểm của cả M và T-Method.

### Ngày 4: Bù trừ vị trí (Hoàn thành pipeline vị trí)

* **Position Compensation:** Cải thiện hơn 20% các chỉ số RMSE, MAE và Max Error. Phân tích được hiện tượng "over-compensation" tại điểm dừng và giới hạn của cơ chế bù dựa trên State Transition.

### Ngày 5: So sánh Bộ lọc Vận tốc (IIR vs Kalman 1D)

* **Velocity Filtering:** Thực hiện kiểm chứng độc lập để chọn ra bộ lọc tối ưu nhất. Kết quả cho thấy IIR Filter (`alpha = 0.15`) đạt RMSE 2.73 rad/s và độ trễ 5.01 ms, vượt trội hơn so với 1D Kalman Filter (RMSE 3.41 rad/s, độ trễ 7.22 ms). Đã chính thức loại bỏ Kalman và giữ IIR làm bộ lọc vận tốc cuối cùng do cấu trúc đơn giản nhưng phù hợp hơn với động học hệ thống.

### Ngày 6: Kiểm chứng mô hình cốt lõi (Manual Verification)

* Xây dựng thành công kịch bản Sanity Check (`verify_manual.m`) để kiểm thử độc lập toán học lõi.
* **Level 1 (Kiểm chứng Tĩnh - Vị trí):** Bơm lỗi nhảy trạng thái kép (double-jump) thủ công. Thuật toán State Machine và `position_compensator` phát hiện và bù trừ chính xác 100%, đạt sai số tuyệt đối `0.00e+00` rad.
* **Level 2 (Kiểm chứng Động - Vận tốc):** Bằng kỹ thuật thời gian toán học đảo ngược và bộ lọc nhiễu dấu phẩy động (floating-point noise), cả 3 bộ ước lượng (M-Method, T-Method, Hybrid) đều hội tụ tuyệt đối về vận tốc lý tưởng với sai lệch `0.00e+00` rad/s. Nền tảng toán học lõi chính thức được nghiệm thu để chuẩn bị cho các thử nghiệm động học phức tạp.

## 🧮 Cập nhật tiến độ & Lộ trình 10 ngày (Bản cập nhật bám sát Đề tài 06)

### 🟢 Giai đoạn 1: Khởi tạo và Phân tích (Đã hoàn thành)

* **Ngày 1 & 2 (Mô hình hóa & Chèn nhiễu):** Xây dựng thành công hệ thống Encoder 1000 PPR. Giả lập chân thực các hiện tượng nhiễu phần cứng (Jitter, Bounce, Phase error) và rớt xung ngẫu nhiên ở mức vi mô.
* **Ngày 3 (Giải mã & Ước lượng):** Phát triển State Machine bắt thành công các sự kiện nhảy trạng thái kép. Hoàn thiện thuật toán Hybrid Estimator (Adaptive Fusion) khắc phục triệt để điểm yếu của cả M-Method và T-Method.
* **Ngày 4 & 5 (Bù trừ vị trí & Chốt bộ lọc vận tốc):** Áp dụng State-Transition Compensation và bộ lọc IIR (`alpha = 0.15`). Thuật toán Compensation cải thiện >20% sai số vị trí. Chốt hạ IIR sau khi chứng minh ước lượng Kalman bị trễ pha. Xác định được điểm gục ngã của hệ thống ở ngưỡng mất xung 1.0%.

### 🟡 Giai đoạn 2: Kiểm chứng và Đóng gói (Kế hoạch sắp tới)

### 🟡 Giai đoạn 2: Kiểm chứng và Đóng gói (Đang thực hiện)

* **🟢 Ngày 6 (Kiểm chứng mô hình - Verification):** Đã hoàn thành Manual Verification (Sanity Check) tính tay. Nền tảng toán học cốt lõi đạt sai số tuyệt đối `0.00e+00` ở cả vị trí và vận tốc.
* **Ngày 7 (Kịch bản thử nghiệm - Scenario Testing):** Thiết kế và chạy tối thiểu 5 kịch bản khác nhau bao gồm: tăng tốc nhanh, vùng tốc độ rất thấp, và đảo chiều quay (zero-crossing) để đánh giá hành vi của hệ thống.
* **Ngày 8 (Phân tích tính bất định - Uncertainty Analysis):** Chạy Uncertainty / Sensitivity Analysis bằng phương pháp Monte Carlo để đánh giá sai số theo biên độ nhiễu và tỷ lệ mất xung.
* **Ngày 9 (Tổng hợp Dữ liệu):** Tổng hợp các metric định lượng (RMSE, MAE, Delay) để chứng minh tính đúng đắn của toàn bộ pipeline qua các kịch bản thử nghiệm.
* **Ngày 10 (Nghiệm thu cuối):** Xuất toàn bộ biểu đồ vector chất lượng cao, hoàn thiện tài liệu báo cáo kỹ thuật (Technical Report) và slide bảo vệ đồ án.

---

*Dự án đang trong quá trình phát triển (Lộ trình 10 ngày).*

```