FROM python:3.11-slim

WORKDIR /app

# Cài đặt các thư viện hệ thống cần thiết cho AI và database
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements và cài đặt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir bcrypt

# Tải model NLTK
RUN python -c "import nltk; nltk.download('punkt_tab', quiet=True); nltk.download('stopwords', quiet=True)"

# Copy toàn bộ code backend
COPY . .

# Chạy seed data để tạo database SQLite mẫu
RUN python seed_db.py && python seed_candidates.py && python seed_admin.py

# Expose port (Render sẽ tự map $PORT)
EXPOSE 8000

# Command chạy server (sử dụng $PORT do Render cấp phát, mặc định 8000)
CMD uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
