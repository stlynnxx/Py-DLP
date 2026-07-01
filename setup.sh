#!/bin/bash

if [ -f ~/.config/yt-dlp/config ]; then
    echo "Existing yt-dlp config found, skipping to avoid overwriting."
    echo "Add '--js-runtimes node' to ~/.config/yt-dlp/config manually if needed."
else
    mkdir -p ~/.config/yt-dlp
    cp yt-dlp.conf ~/.config/yt-dlp/config
    echo "yt-dlp configured."
fi


if [ "$EUID" -ne 0 ]; then
    echo "Please run setup as root: sudo ./setup.sh"
    exit 1
fi

if command -v apt &> /dev/null; then
    apt install -y nodejs ffmpeg
elif command -v dnf &> /dev/null; then
    dnf install -y nodejs ffmpeg
elif command -v pacman &> /dev/null; then
    pacman -S --noconfirm nodejs ffmpeg
else
    echo "Could not detect package manager. Please install nodejs and ffmpeg manually."
fi

pip install yt-dlp --break-system-packages

echo "Setup complete. Run with: python main.py -single <url>"