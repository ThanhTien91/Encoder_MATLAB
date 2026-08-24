# ⚙️ Đồ án: Bộ ước lượng vị trí và vận tốc từ encoder quadrature có mất xung

[![MATLAB](https://img.shields.io/badge/MATLAB-2026a%2B-blue.svg)](https://www.mathworks.com/)
[![Status](https://img.shields.io/badge/Tiến_độ-Ngày_3%2F10-yellow.svg)]()

Repository này chứa mã nguồn MATLAB mô phỏng và xử lý tín hiệu cho Quadrature Encoder. Mục tiêu của dự án là thiết lập mô hình vật lý có chứa nhiễu, từ đó xây dựng và kiểm chứng các thuật toán giải mã, ước lượng tốc độ và khôi phục tín hiệu khi bị mất xung ngẫu nhiên.

---

## 📂 Cấu trúc thư mục

```text
📦 Encoder_Project
 ┣ 📂 config           # File cấu hình tham số hệ thống (default_params.m)
 ┣ 📂 models           # Mô hình động học, sinh tín hiệu và chèn nhiễu
 ┣ 📂 decoder          # Chứa thuật toán giải mã và ước lượng vận tốc
 ┣ 📂 results          # Lưu trữ hình ảnh và số liệu xuất ra (thư mục figure/)
 ┣ 📜 main_day1.m      # Script chạy nghiệm thu Ngày 1 (Hệ lý tưởng)
 ┣ 📜 main_day2.m      # Script chạy nghiệm thu Ngày 2 (Hệ có nhiễu)
 ┣ 📜 main_day3.m      # Script chạy nghiệm thu Ngày 3 (Giải mã & Ước lượng)
 ┗ 📜 README.md        # Thông tin đồ án

```

---

## 🚀 Hướng dẫn chạy code

**1. Nghiệm thu Ngày 1 (Hệ thống lý tưởng):**
Chạy script `main_day1.m`. File này sẽ sinh quỹ đạo chuyển động (tăng tốc, đảo chiều, dừng) và xuất ra tín hiệu A, B, Z lệch pha 90 độ điện hoàn hảo.

**2. Nghiệm thu Ngày 2 (Tiêm lỗi phần cứng):**
Chạy script `main_day2.m`. File này lấy dữ liệu từ Ngày 1 và đưa thêm nhiễu vào.

* Theo dõi Command Window để xem số lượng xung bị đánh rớt.
* Dùng công cụ Zoom trên đồ thị để xem sự sai lệch pha, rung thời gian (jitter), dội xung (bounce) và các điểm tín hiệu bị mất hoàn toàn.

**3. Nghiệm thu Ngày 3 (Giải mã và Ước lượng vận tốc):**
Chạy script `main_day3.m`. File này kết hợp dữ liệu nhiễu từ Ngày 2 để đưa qua bộ giải mã và tính toán vận tốc.

* Quan sát đồ thị Position Drift để thấy sự sai lệch vị trí do rớt xung (đường ước lượng hụt so với thực tế).
* Phân tích đồ thị Speed Estimator để thấy đặc tính của M-Method (trễ pha nhẹ), T-Method (bị nhiễu nặng ở tốc độ cao) và Hybrid Method (thích ứng tốt). Hình ảnh tự động lưu vào `result/figure/`.

---

## 🧮 Cập nhật tiến độ & Kết quả

### Ngày 1: Mô hình toán học & Tín hiệu chuẩn

* **Thông số:** Thiết lập tần số lấy mẫu 1 MHz, độ phân giải 1000 PPR, tốc độ tối đa 600 RPM.
* **Kết quả:** Hoàn thiện `trajectory_model.m` (quỹ đạo 5 pha) và `encoder_model.m`. Tín hiệu đầu ra lý tưởng, đúng biên độ và quan hệ pha.

### Ngày 2: Mô phỏng nhiễu và lỗi phần cứng

* **Thông số chèn lỗi:** Rớt xung ngẫu nhiên tỷ lệ 1%, lệch pha tĩnh 5 mẫu, nhiễu Jitter ±2 mẫu, và nhiễu dội xung (Bounce) với xác suất 25%.
* **Kết quả:** Hoàn thiện `inject_micro_noise.m` và `inject_pulse_loss.m`. Thuật toán giả lập thành công các gai nhiễu phần cứng và hiện tượng mất xung (đánh rớt khoảng 130/13000 xung vật lý). Đồ thị phản ánh đúng sự biến dạng tín hiệu ở mức vi mô.

### Ngày 3: Giải mã Quadrature (X4) và Ước lượng vận tốc

* **Nhiệm vụ:** Xây dựng bộ giải mã tín hiệu A/B kết hợp bắt lỗi chuyển trạng thái phi logic, đồng thời ước lượng vận tốc thực tế từ tín hiệu nhiễu.
* **Thuật toán:**
* Xây dựng máy trạng thái (State Machine) bằng cấu trúc `switch-case` giám sát chiều chuyển động để đếm bước (`pos_count`) và cắm cờ lỗi (`error_flag`).
* Triển khai 3 phương pháp ước lượng vận tốc: M-Method (cửa sổ 10ms), T-Method (tích hợp Outlier Rejection chặn gai nhiễu) và Hybrid Estimator (Adaptive Fusion kết hợp điểm mạnh của cả M và T).


* **Kết quả:**
* Bộ giải mã phát hiện chính xác 97 sự kiện nhảy trạng thái kép do nhiễu dội xung gây ra.
* Trực quan hóa thành công hiện tượng "trôi vị trí" (Position Drift) khi đo bằng tín hiệu mất xung.
* Xác thực được điểm yếu vật lý của T-Method ở dải tốc độ cao và tính ưu việt của thuật toán lai Hybrid.

---
*Lộ trình phát triển dự kiến: 10 ngày.*