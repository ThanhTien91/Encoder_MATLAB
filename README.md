# ⚙️ Đồ án: Bộ ước lượng vị trí và vận tốc từ encoder quadrature có mất xung

[![MATLAB](https://img.shields.io/badge/MATLAB-2026a%2B-blue.svg)](https://www.mathworks.com/)
[![Status](https://img.shields.io/badge/Tiến_độ-Hoàn_thành-success.svg)]()

Repository này chứa mã nguồn MATLAB mô phỏng và xử lý tín hiệu cho Quadrature Encoder. Mục tiêu của dự án là thiết lập mô hình vật lý có chứa nhiễu, từ đó xây dựng và kiểm chứng các thuật toán giải mã, bù trừ vị trí, và ước lượng tốc độ khi tín hiệu bị mất xung ngẫu nhiên.

---

## 📂 Cấu trúc thư mục

```text
📦 Encoder_Project
 ┣ 📂 config              # File cấu hình tham số hệ thống (default_params.m)
 ┣ 📂 models              # Mô hình động học, sinh tín hiệu và chèn nhiễu
 ┣ 📂 decoder             # Chứa thuật toán giải mã, bù trừ và ước lượng vận tốc
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

**2. Nghiệm thu Ngày 3 & 4 (Giải mã, Ước lượng & Bù trừ):**

* Chạy `main_day3.m`: Kiểm tra thuật toán phát hiện sự kiện lỗi bằng State Machine và so sánh các bộ ước lượng tốc độ (M/T/Hybrid).
* Chạy `main_day4.m`: Đánh giá hiệu năng của bộ bù trừ vị trí (`position_compensator`) và bộ lọc IIR cho vận tốc.

**3. Kiểm chứng & Phân tích chuyên sâu (Tầng 2):**

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

### Ngày 4: Bù trừ vị trí và Lọc Vận tốc (Hoàn thành)

- **Position Compensation:** Cải thiện hơn 20% các chỉ số RMSE, MAE và Max Error. Phân tích được hiện tượng "over-compensation" tại điểm dừng và giới hạn của cơ chế bù dựa trên State Transition.

- **Velocity Filtering:** Áp dụng bộ lọc IIR với `alpha = 0.15` để làm mượt tín hiệu Hybrid. Độ trễ pha được kiểm soát ở mức 0.071%.

- **Verification & Sensitivity:** Kiểm chứng công thức vị trí bằng Sanity Check, đạt sai lệch `0.00e+00 rad`. Phân tích độ nhạy cho thấy hiệu quả của bộ bù lỗi bắt đầu suy giảm đáng kể khi tỷ lệ mất xung đạt `1.0%` hoặc cao hơn.

## 🧮 Cập nhật tiến độ & Lộ trình 10 ngày

### 🟢 Giai đoạn 1: Khởi tạo và Phân tích (Đã hoàn thành)

* **Ngày 1 & 2 (Mô hình hóa & Chèn nhiễu):** Xây dựng thành công hệ thống Encoder 1000 PPR. Giả lập chân thực các hiện tượng nhiễu phần cứng (Jitter, Bounce, Phase error) và rớt xung ngẫu nhiên ở mức vi mô.
* **Ngày 3 (Giải mã & Ước lượng):** Phát triển State Machine bắt thành công các sự kiện nhảy trạng thái kép. Hoàn thiện thuật toán Hybrid Estimator (Adaptive Fusion) khắc phục triệt để điểm yếu của cả M-Method và T-Method.
* **Ngày 4 (Bù trừ vị trí & Phân tích độ nhạy):** Áp dụng bộ lọc IIR (`alpha = 0.15`) với độ trễ pha chỉ 0.071%. Thuật toán Compensation cải thiện >20% sai số vị trí. Hoàn thành Sanity Check (sai lệch `0.00e+00 rad`) và xác định được điểm gục ngã của hệ thống ở ngưỡng mất xung 1.0%.

### 🟡 Giai đoạn 2: Tối ưu hóa và Đóng gói (Kế hoạch sắp tới)

* **Ngày 5 & 6 (Thuật toán Nâng cao):** Nghiên cứu tích hợp bộ lọc Kalman (Kalman Filter) để dự đoán quỹ đạo khi tỷ lệ rớt xung vượt ngưỡng bão hòa (>1.0%) và xử lý hiện tượng "over-compensation" tại điểm dừng.
* **Ngày 7 (Chuyển đổi mã nhúng):** Biên dịch các hàm giải mã và ước lượng cốt lõi (`quadrature_decoder_x4.m`, `speed_estimator.m`) sang mã Embedded C chuẩn bị cho môi trường vi điều khiển.
* **Ngày 8 (Mô phỏng HIL):** Thực hiện Hardware-in-the-Loop Simulation để đánh giá chi phí tính toán (Computational Cost) và độ trễ thực thi thuật toán.
* **Ngày 9 (Phát triển GUI):** Đóng gói toàn bộ hệ thống bằng MATLAB App Designer, tạo giao diện trực quan cho phép người dùng kéo thả thanh trượt để thay đổi mức độ nhiễu theo thời gian thực (Real-time).
* **Ngày 10 (Nghiệm thu cuối):** Xuất toàn bộ biểu đồ vector chất lượng cao, hoàn thiện tài liệu báo cáo kỹ thuật (Technical Report) và slide bảo vệ đồ án.

---
*Dự án đang trong quá trình phát triển (Lộ trình 10 ngày).*