#!/bin/bash
echo "Downloading Flutter SDK..."
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
fi

export PATH="$PATH:$HOME/flutter/bin"
echo "Flutter version:"
flutter --version

echo "Installing dependencies..."
flutter pub get

echo "Building Flutter Web..."
flutter build web --release --dart-define=API_BASE_URL=https://web-production-403a9.up.railway.app
