# AI Job Match - Danh Sách Chức Năng (Features List)

Dự án **AI Job Match** là một hệ thống tuyển dụng thông minh, kết nối ứng viên (Candidate) và nhà tuyển dụng (Recruiter/Employer) thông qua sự hỗ trợ của trí tuệ nhân tạo.

Hệ thống bao gồm hai phần chính:
- **Frontend:** Ứng dụng đa nền tảng viết bằng Flutter (hỗ trợ Web/Mobile).
- **Backend:** Hệ thống API hiệu năng cao viết bằng FastAPI (Python) cùng cơ sở dữ liệu.

Dưới đây là danh sách chi tiết tất cả các chức năng có trong dự án:

---

## 1. Hệ thống Tài khoản & Xác thực (Authentication)
- **Đăng ký / Đăng nhập bằng Email và Mật khẩu:** Quản lý bằng JWT token an toàn.
- **Đăng nhập bằng Google (Google Sign-In):** Tích hợp thông qua Firebase Authentication.
- **Phân quyền người dùng (Role-based Access Control):** Tách biệt quyền hạn rõ ràng giữa **Ứng viên (Candidate)** và **Nhà tuyển dụng (Recruiter)**.

---

## 2. Dành cho Ứng viên (Candidate)

### Quản lý Hồ sơ (Profile & CV)
- **Cập nhật thông tin cá nhân:** Tên, ảnh đại diện, vị trí, chức danh mong muốn.
- **Quản lý CV/Resume:**
  - Tải lên file CV (PDF/Word).
  - **Tự động trích xuất thông tin (AI CV Parsing):** Sử dụng AI để tự động đọc và trích xuất các kỹ năng (skills), kinh nghiệm từ CV để điền vào hồ sơ.
- **Quản lý Kỹ năng (Skills):** Thêm, sửa, xóa các kỹ năng chuyên môn.

### Tìm kiếm & Ứng tuyển Việc làm
- **Bảng điều khiển (Dashboard):** Giao diện tổng quan xem các việc làm nổi bật.
- **Khám phá Việc làm (Job Discovery):** Tìm kiếm và lọc việc làm theo danh mục, vị trí, mức lương.
- **Gợi ý việc làm thông minh (AI Recommendations):** Hệ thống AI phân tích hồ sơ/CV của ứng viên và đối chiếu với yêu cầu công việc để gợi ý các vị trí phù hợp nhất kèm theo **điểm số phù hợp (Match Score)**.
- **Ứng tuyển:** Gửi CV và thư giới thiệu (Cover Letter) trực tiếp tới nhà tuyển dụng.
- **Lịch sử Ứng tuyển:** Theo dõi trạng thái của các công việc đã ứng tuyển (Đang chờ, Phỏng vấn, Chấp nhận, Từ chối).

---

## 3. Dành cho Nhà tuyển dụng (Recruiter)

### Quản lý Công ty & Hồ sơ Nhà tuyển dụng
- **Cập nhật thông tin Công ty:** Tên công ty, logo, mô tả, quy mô, địa chỉ, website.
- **Hồ sơ Cá nhân:** Thông tin của nhân viên tuyển dụng (HR).

### Quản lý Việc làm (Job Management)
- **Bảng điều khiển (Dashboard):** Thống kê số lượng việc làm đang mở, số lượng hồ sơ ứng tuyển, v.v.
- **Tạo tin tuyển dụng (Create Job):** Đăng tin với đầy đủ mô tả, kỹ năng yêu cầu, mức lương, danh mục, loại hình (Full-time, Part-time, Remote).
- **Chỉnh sửa / Xóa tin tuyển dụng (Edit/Delete Job):** Quyền sở hữu chặt chẽ (chỉ người tạo mới có quyền xóa).

### Quản lý Ứng viên (Applicant Management)
- **Xem danh sách Ứng viên:** Liệt kê những người đã nộp CV vào từng vị trí.
- **Đánh giá AI (AI Matching):** Xem điểm số tương thích do AI đánh giá giữa CV của ứng viên và yêu cầu của công việc.
- **Xem chi tiết Hồ sơ/CV:** Tải xuống và xem CV gốc của ứng viên.
- **Cập nhật trạng thái:** Chuyển trạng thái ứng viên (Pending → Interview → Accepted / Rejected).

---

## 4. Các Chức năng Hệ thống / Kỹ thuật (Technical Features)
- **RESTful API Backend:** Cấu trúc API rõ ràng, dễ bảo trì với FastAPI và SQLAlchemy.
- **Bảo mật:** Băm mật khẩu (Bcrypt), bảo vệ API routes bằng JWT Bearer Token.
- **Fallback Demo Mode:** Tính năng tự động giả lập tài khoản Google trong trường hợp chạy nội bộ không có kết nối Firebase, phục vụ quá trình thuyết trình/bảo vệ đồ án dễ dàng.
- **Giao diện đáp ứng (Responsive UI):** Giao diện Flutter thay đổi linh hoạt, tương thích từ màn hình rộng (Web Desktop) tới màn hình nhỏ (Mobile).
- **Quản lý trạng thái (State Management):** Sử dụng Provider kết hợp ChangeNotifier trong Flutter để cập nhật UI mượt mà.

---

> *Tài liệu này được tạo tự động nhằm mục đích tổng hợp các tính năng phục vụ việc viết báo cáo / đồ án.*
