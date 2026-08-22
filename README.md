# ⚙️ Bộ ước lượng vị trí và vận tốc từ encoder quadrature có mất xung

[![MATLAB](https://img.shields.io/badge/MATLAB-2023a%2B-blue.svg)](https://www.mathworks.com/)
[![Status](https://img.shields.io/badge/Trạng_thái-Ngày_1%2F10-orange.svg)]()

Đồ án phát triển thuật toán giải mã và ước lượng trạng thái (vị trí, vận tốc) từ tín hiệu Quadrature Encoder loại tăng (Incremental Encoder). Dự án tập trung vào việc mô phỏng phần cứng, xử lý nhiễu ngẫu nhiên và khôi phục dữ liệu khi xảy ra hiện tượng mất xung.

---

## 📂 Cấu trúc thư mục (Repository Structure)

Dự án được tổ chức theo chuẩn kiến trúc phần mềm MATLAB để đảm bảo tính module và dễ dàng tái sử dụng:

```text
📦 Encoder_Project
 ┣ 📂 config           # Thông số hệ thống (default_params.m)
 ┣ 📂 models           # Mô hình động học và sinh tín hiệu encoder (trajectory_model.m, encoder_model.m)
 ┣ 📜 main_day1.m      # Script chạy chính kiểm tra mô phỏng Ngày 1
 ┗ 📜 README.md        # File mô tả dự án
```

---

## 🚀 Hướng dẫn bắt đầu (Quick Start)

### Khởi chạy Ngày 1
Ngày 1 tập trung vào việc thiết lập các thông số cơ bản và xây dựng mô hình sinh quỹ đạo (Trajectory Model) và mô hình tạo tín hiệu từ Encoder (Encoder Model).

1. Clone repository này về máy:
   ```bash
   git clone <your-repo-url>
   ```
2. Mở MATLAB, điều hướng đến thư mục dự án `Encoder_Project`.
3. Chạy file `main_day1.m` để xem kết quả mô phỏng:
   ```matlab
   >> main_day1
   ```

---

## 🧮 Cấu trúc Code Ngày 1

*   **`config/default_params.m`**: Định nghĩa thông số gốc của hệ thống (PPR = 1000, Fs = 1MHz, Max RPM = 600).
*   **`models/trajectory_model.m`**: Sinh quỹ đạo vận tốc và vị trí chuẩn của động cơ.
*   **`models/encoder_model.m`**: Chuyển đổi vị trí cơ học sang tín hiệu điện (sóng vuông A, B, Z lệch pha 90 độ).
*   **`main_day1.m`**: Script điều phối gọi các hàm mô hình, hiển thị đồ thị quỹ đạo và sóng vuông thực tế.

---
*Dự án đang trong quá trình phát triển (Lộ trình 10 ngày).*