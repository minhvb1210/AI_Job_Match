#!/bin/bash
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Building Flutter Web..."
# Lấy biến môi trường API_BASE_URL từ Vercel
flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL
