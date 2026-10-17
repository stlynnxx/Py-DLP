#!/usr/bin/env bash
# download.sh - Py-DLP Download Helper
# Cross-platform: Linux, macOS, Windows (WSL)
# Usage: ./download.sh  (or double-click if allowed)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv"

# Detect platform
OS_NAME="$(uname -s)"
case "$OS_NAME" in
    Linux*)  PLATFORM="linux" ;;
    Darwin*) PLATFORM="macos" ;;
    MINGW*|MSYS*|CYGWIN*) PLATFORM="windows_wsl" ;;
    *)       PLATFORM="unknown" ;;
esac

# Color codes
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'
NC=$'\033[0m'

info() { printf '%sℹ %s%s\n' "$BLUE" "$*" "$NC" >&2; }
ok()   { printf '%s✓ %s%s\n' "$GREEN" "$*" "$NC" >&2; }
err()  { printf '%s✗ %s%s\n' "$RED" "$*" "$NC" >&2; }
warn() { printf '%s⚠ %s%s\n' "$YELLOW" "$*" "$NC" >&2; }

# ------------------------------------------------------------------ GUI detection
has_zenity() { command -v zenity >/dev/null 2>&1; }
has_kdialog() { command -v kdialog >/dev/null 2>&1; }
has_osascript() { command -v osascript >/dev/null 2>&1; }

# ---------------------------------------------------------------- dialog functions
get_url_zenity() {
    zenity --entry --title="Py-DLP Download" \
        --text="Paste the YouTube URL:" \
        --entry-text="" \
        --width=500 --height=150
}

get_url_kdialog() {
    kdialog --inputbox "Paste the YouTube URL:" --title "Py-DLP Download"
}

get_url_applescript() {
    osascript -e "
        set userInput to display dialog \"Paste the YouTube URL:\" ¬
            default answer \"\" ¬
            with title \"Py-DLP Download\" ¬
            with icon note
        text returned of userInput
    "
}

get_url_terminal() {
    echo
    read -p "Paste the YouTube URL: " url
    echo "$url"
}

get_format_gui() {
    case "$PLATFORM" in
        linux)
            if has_zenity; then
                zenity --list --radiolist --title="Select Format" \
                    --column="Choose" --column="Format" --column="Description" \
                    FALSE "mp4" "Best quality video" \
                    TRUE  "mp3" "Audio only" \
                    FALSE "flac" "Lossless audio" \
                    FALSE "wav" "Uncompressed audio" \
                    FALSE "opus" "Efficient audio" \
                    --width=500 --height=200
            elif has_kdialog; then
                kdialog --combobox "Select format:" mp4 mp3 flac wav opus
            else
                get_format_terminal
            fi
            ;;
        macos)
            osascript -e "
                set formatList to {\"mp4\", \"mp3\", \"flac\", \"wav\", \"opus\"}
                set descList to {\"Best quality video\", \"Audio only\", \"Lossless audio\", \"Uncompressed audio\", \"Efficient audio\"}
                set selectedItem to choose from list formatList with prompt \"Select format:\" with title \"Py-DLP Download\" default items {\"mp3\"}
                if selectedItem is false then
                    return \"\"
                else
                    return selectedItem as text
                end if
            "
            ;;
        *)
            get_format_terminal
            ;;
    esac
}

get_format_terminal() {
    echo
    echo "Choose format:"
    echo "  [1] mp4  - Best quality video"
    echo "  [2] mp3  - Audio only"
    echo "  [3] flac - Lossless audio"
    echo "  [4] wav  - Uncompressed audio"
    echo "  [5] opus - Efficient audio"
    echo
    read -p "Choice [1-5]: " choice
    case "$choice" in
        1) echo "mp4" ;;
        2) echo "mp3" ;;
        3) echo "flac" ;;
        4) echo "wav" ;;
        5) echo "opus" ;;
        *) echo "mp3" ;;
    esac
}

# ------------------------------------------------------------------ main flow
clear
echo
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}       Py-DLP Download${NC}"
echo -e "${BLUE}=====================================${NC}"
echo

# Get URL
URL=""
if has_zenity; then
    URL=$(get_url_zenity 2>/dev/null) || URL=""
elif has_kdialog; then
    URL=$(get_url_kdialog 2>/dev/null) || URL=""
elif has_osascript; then
    URL=$(get_url_applescript 2>/dev/null | tr -d '\r') || URL=""
fi

if [[ -z "$URL" ]]; then
    # Fallback to terminal input
    URL=$(get_url_terminal)
fi

if [[ -z "$URL" || "$URL" == "cancel" ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

# Get format
FORMAT=""
if has_zenity; then
    FORMAT=$(get_format_gui 2>/dev/null) || FORMAT=""
elif has_osascript; then
    FORMAT=$(get_format_gui 2>/dev/null | tr -d '\r') || FORMAT=""
fi

if [[ -z "$FORMAT" ]]; then
    # Fallback to terminal input
    FORMAT=$(get_format_terminal)
fi

# Normalize format
FORMAT="${FORMAT,,}"  # lowercase
case "$FORMAT" in
    1) FORMAT="mp4" ;;
    2) FORMAT="mp3" ;;
    3) FORMAT="flac" ;;
    4) FORMAT="wav" ;;
    5) FORMAT="opus" ;;
    mp4|mp3|flac|wav|opus) : ;; # valid, keep as-is
    *) FORMAT="mp3" ;;
esac

echo
echo -e "${GREEN}Starting download...${NC}"
echo "URL: $URL"
echo "Format: $FORMAT"
echo
echo -e "${BLUE}─────────────────────────────────────${NC}"

# Activate venv and run
if [[ -x "$VENV_DIR/bin/python" ]]; then
    source "$VENV_DIR/bin/activate" 2>/dev/null || .venv/bin/activate
elif [[ -f "$VENV_DIR/bin/activate" ]]; then
    source "$VENV_DIR/bin/activate"
else
    err "Virtual environment not found. Run ./setup.sh first."
fi

# Run download
python py-dlp.py -single "$URL" -format "$FORMAT"

EXIT_CODE=$?

echo
echo -e "${BLUE}─────────────────────────────────────${NC}"

if [[ $EXIT_CODE -eq 0 ]]; then
    echo -e "${GREEN}✓ Download complete!${NC}"
    echo "Files saved to: $HOME/Downloads"
else
    echo -e "${RED}✗ Download failed (exit code: $EXIT_CODE)${NC}"
fi

echo
echo -e "${YELLOW}Press Enter to close...${NC}"
read -r

exit $EXIT_CODE