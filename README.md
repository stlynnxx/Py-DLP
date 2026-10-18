# dwnloaderr - A Python Media Downloader

A command-line media downloader built with `yt-dlp`, with cross-platform GUI helpers for beginners. Download videos, audio, and playlists from YouTube and many other platforms in multiple formats.



# Installation

## Windows
### 1. Download the latest release
```
curl.exe -L https://eclecticelectronics.fly.dev/api/download/dlp/1.0.1 -o py-dlp.tar.gz
```

### 2. Verify the checksum (replace with current hash)
```
certutil -hashfile py-dlp.tar.gz SHA256
```
### Compare output with EXPECTED_HASH_HERE

## 3. Extract (requires 7-Zip or similar)
```
7z x py-dlp.tar.gz
7z x py-dlp.tar
```
## 4. Run
```
python py-dlp.py -single "https://example.com/video"
```
## Using the Self-Update Command
Once installed, check for updates without manual downloads:
```
python3 py-dlp.py -update\
```

This fetches the manifest from the server, verifies the checksum, and replaces your local files automatically.


## Linux / macOS
### Prerequisites
- Python 3.8 or higher
- Node.js or Deno (recommended for YouTube compatibility)
- curl (Linux/macOS) or PowerShell (Windows)
- Linux / macOS
### 1. Download the latest release
```bash
curl -L https://eclecticelectronics.fly.dev/api/download/dlp/1.0.1 -o py-dlp.tar.gz
```
### 2. Verify the checksum (replace with current hash)
```bash
echo "EXPECTED_HASH_HERE  py-dlp.tar.gz" | sha256sum -c -
```
### 3. Extract
```bash
tar xzf py-dlp.tar.gz
```
### 4. Run
```bash
python3 py-dlp.py -single "https://example.com/video"
```

## Quick Start

### First Time Setup

| Platform | Command |
|----------|---------|
| **Windows** | Double-click `setup.bat` |
| **Linux/macOS** | `setup.sh` |

This installs Python, Node.js, FFmpeg, and creates a virtual environment automatically.

### Download a Video

| Platform | Command |
|----------|---------|
| **Windows** | Double-click `download.bat` or `run.bat` |
| **Linux/macOS** | `download.sh` |

Both open a dialog box where you paste the URL and choose the format.

### Advanced (Command Line)

```bash
# Single video
python py-dlp.py -single "https://www.youtube.com/watch?v=iupPG8x_Zfo&list=PL_vkVwrwck3NJ9ajMQv7Y-DfX9gVAk5in&index=8"

# Audio only
python py-dlp.py -single "URL" -format mp3

# Lossless audio
python py-dlp.py -single "URL" -format flac

# Playlist (max 50 items by default)
python py-dlp.py -playlist "URL" -max 100

# Custom output folder
python py-dlp.py -single "URL" -savedir ~/Music/Songs
```
### Windows Console Access

Console Access (Windows)
Double-click activate.bat to open a terminal window with the virtual environment already activated. From there you can run any python py-dlp.py command directly.

### Command Reference
#### Flags
| Flag	| Description |	Default |
|-------|-------------|---------|
|-single |	Single video download mode |	Required with URL |
| -playlist |	Playlist download mode |	Required with URL |
| url |	Input URL (positional argument) |	Required |
| -format |	Output format: flac, wav, mp3, mp4, opus | best |
| -retry |	Number of retry attempts | 4 |
| -timeout |	Socket timeout (seconds) | 20 |
| -ratelim |	Rate limit (bytes/sec) | unlimited |
| -username	|Login username	| None |
| -pswd	| Login password |	None |
| -max |	Max items from playlist |	25 |
| -thumbnail |	Write thumbnail to file	| enabled |
|-nosubs |	Disable subtitle download |	disabled |
|-noembed	| Disable embedded subtitles |	disabled |
|-nometa | Disable metadata embedding |	disabled |
|-savedir, -sd |	Custom output directory |	~/Downloads |
|-cf, --cookiefile |	Path to cookie file |	None |
|-nocs | Extract cookies from browser |	disabled |
|-setup |	Run installer script | false |


## Donations
I am physically disabled and do this and hardware repair to support myself; if you feel generous and 
can afford to do so, every penny helps out! 

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/H5F5269IH4)



# Common workflows

## High-quality music (lossless)
python py-dlp.py -single "URL" -format flac

## Small video file
python py-dlp.py -single "URL" -format opus

## Podcast from YouTube channel (playlist)
python py-dlp.py -playlist "CHANNEL/videos" -max 20 -format mp3

## Fast download (skip thumbnails/metadata)
python py-dlp.py -single "URL" -nosubs -noembed -nometa -thumbnail

## Nightly backup of favorite channel
python py-dlp.py -playlist "URL" -max 10 -savedir ~/Backups/ChannelName

# Troubleshooting
## No JavaScript Runtime Found
Error: WARNING: [youtube] No supported JavaScript runtime could be found.

## Fix:

### Fedora/RHEL
sudo dnf install nodejs

### Debian/Ubuntu
sudo apt install nodejs

### Arch
sudo pacman -S nodejs npm

### macOS
brew install node

### Format Is Not Available
Error: Requested format is not available

## Fix: List available formats first:

python py-dlp.py -single "URL" --list-formats

# YouTube Challenge Page
Error: YouTube served a challenge page

## Fix:

Update yt-dlp: pip install --upgrade yt-dlp
Use cookies: -cf ~/.cookies.txt
Ensure Node.js is installed

# Virtual Environment Issues
Error: No module named yt_dlp

## Fix:

### Linux/macOS
rm -rf .venv
./setup.sh

### Windows
Remove-Item -Recurse -Force .venv
.\setup.bat

# Security Notes
Passwords: Never store passwords in plain text in scripts. Use environment variables:
  export PY_DLP_PASSWORD="your_password"
  python py-dlp.py -single "URL" -username user -pswd "$PY_DLP_PASSWORD"

# Cookies
Keep cookie files secure. Anyone with your cookies can access private content.

# Permissions
Never sudo the virtual environment creation. System-wide Python packages should remain separate from user projects.
Contributing
Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

# Areas Needing Attention
- Improve Windows GUI reliability
- Add support for more streaming sites
- CI/CD pipeline for automated testing
- Docker container for easy deployment
- Unit test coverage for edge cases

## FAQ
Q: Can I download entire channels?\
A: Yes, use the playlist URL with -max set to desired count. Example: python py-dlp.py -playlist "CHANNEL/videos" -max 100.

Q: Does this violate YouTube's Terms of Service?\
A: This is a tool for extracting publicly available content. Use responsibly and respect copyright laws in your jurisdiction.

Q: Why do I need Node.js?\
A: Recent yt-dlp versions require a JavaScript runtime to parse YouTube's encrypted signatures. Node.js, Deno, or undici work.

Q: Where do files get saved?\
A: By default to ~/Downloads. Change with -savedir ~/Custom/Path.


