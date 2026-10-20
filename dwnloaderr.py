import argparse
import sys
import platform
from pathlib import Path

import yt_dlp
import os
import subprocess
import shutil
try:
    import updatehelpers
except ImportError:
    updatehelpers = None

# Version tracking
__version__ = "1.0.2"

# OS Discovery
os_name = platform.system()
if os_name == "Linux":
    print("Linux detected!")
    print("Excellent choice in OS, my friend.")

# Download path
down_path = os.path.join(os.path.expanduser('~'), 'Downloads')
output_dir = down_path

# argparse config
parser = argparse.ArgumentParser(prog="dwnloaderr", description=f'Python Media Downloader v{__version__}')
parser.add_argument("-setup",  help="Setup script for fresh installs", action="store_true")
parser.add_argument("-single", help='Single download', action='store_true')
parser.add_argument("-download", "-d", help='Output directory path', type=str, default=None)
parser.add_argument("-playlist", help='Playlist download', action='store_true')
parser.add_argument("url", type=str, nargs='?', help="Input URL (QUOTE IT if it has &)")
parser.add_argument("-format", choices=["flac", "wav", "mp3", "mp4", "opus"], help='Download Format')
parser.add_argument("-retry", help="Retry count", type=int, default=4)
parser.add_argument("-timeout", help="Timeout count", type=int, default=20)
parser.add_argument("-ratelim", help="Ratelimit value", type=int, default=100000000)
parser.add_argument("-username", help="Define Username", type=str)
parser.add_argument("-pswd", help="Define Password", type=str)
parser.add_argument("-max", help="Sets max download limit for playlist downloading", type=int, default=25)
parser.add_argument("-thumbnail", help="Write thumbnail to file (default: True)", action='store_true', default=True)
parser.add_argument("-nosubs", help="Disable subtitles (default: Enabled)", action='store_true', default=False)
parser.add_argument("-noembed", help="Disable embedded subtitles (default: Enabled)", action='store_true',
                    default=False)
parser.add_argument("-nometa", help="Disable metadata (default: Enabled)", action='store_true', default=False)
# parser.add_argument("-savedir", "-sd", help="Custom output directory", type=str, default=None)
parser.add_argument("-cf", "--cookiefile", help="Path to cookie file", type=str, default=None)
parser.add_argument("-nocs", "--no-cookies-from-browser", help="Enable cookie extraction from browser",
                    action='store_true', default=False)
parser.add_argument("-update", help="Check for and install updates", action="store_true")
args = parser.parse_args()

# Arg vals being saved
retry_val = args.retry
target_url = args.url
timeout_val = args.timeout
rate_val = args.ratelim
user_user = args.username
user_pass = args.pswd
max_val = args.max
cookie_file_path = args.cookiefile
meta_data = not args.nometa
thumbnail_enabled = args.thumbnail
subs_enabled = not args.nosubs
embed_enabled = not args.noembed
setup = args.setup
format_choice = args.format
is_single = args.single
is_playlist = args.playlist

if args.update:
    if updatehelpers is None:
        print("Error: updatehelpers.py not found next to dwnloaderr.py")
        sys.exit(1)
    updatehelpers.update_chk()
    sys.exit(0)

# Validate URL exists
if not target_url:
    parser.print_help()
    print("\nError: URL is required. Pass it as a positional argument.")
    print("Tip: If your URL contains '&', wrap it in quotes: \"https://...&param=value\"")
    sys.exit(1)

# Validate mode flags
if is_single and is_playlist:
    print("Error: Choose either -single OR -playlist, not both.")
    sys.exit(1)

if args.download:
    output_dir = Path(args.download).expanduser()
else:
    output_dir = Path(down_path).expanduser()

try:
    output_dir.mkdir(parents=True, exist_ok=True)
except OSError as e:
    print(f"Error: Cannot create output directory '{output_dir}': {e}")
    sys.exit(1)

# Check output directory exists
if not os.path.exists(output_dir):
    print(f"Error: Output directory '{output_dir}' does not exist.")
    print(f"Create it manually with: mkdir -p '{output_dir}'")
    sys.exit(1)







# Find JavaScript runtime (prioritize node, then deno)
def find_js_runtime():
    """Find available JavaScript runtime for yt-dlp"""
    # Try node first
    node_paths = [
        shutil.which('node'),
        '/usr/bin/node',
        '/usr/local/bin/node',
    ]
    for path in node_paths:
        if path and os.path.isfile(path) and os.access(path, os.X_OK):
            try:
                result = subprocess.run([path, '--version'], capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    return ('node', path)
            except Exception:
                continue

    # Try deno
    deno_path = shutil.which('deno')
    if deno_path:
        return ('deno', deno_path)

    return (None, None)


runtime_type, runtime_path = find_js_runtime()

if runtime_type:
    print(f"Using JavaScript runtime: {runtime_type} at {runtime_path}")
else:
    print("WARNING: No JavaScript runtime found. Installing one may improve YouTube compatibility.")

# Base options
base_opts = {
    'outtmpl': os.path.join(output_dir, '%(title)s.%(ext)s'),
    'format': 'mp4',
    'ignoreerrors': False,
    'retries': retry_val,
    'socket_timeout': timeout_val,
    'ratelimit': rate_val,
    'geobypass': True,
    'writethumbnail': thumbnail_enabled,
    'writesubtitles': subs_enabled,
    'embeddedsubtitles': embed_enabled,
    'addmetadata': meta_data,
}

# Configure JavaScript runtime explicitly
if runtime_type and runtime_path:
    base_opts['extractor_args'] = {
        'youtube': {
            'js_runtimes': [f'{runtime_type}:{runtime_path}']
        }
    }
else:
    # Fallback: try without runtime config
    base_opts['extractor_args'] = {
        'youtube': {
            'player_client': ['web', 'ios']
        }
    }

# OS-specific fixes
if os_name != "Windows":
    base_opts['windowsfilenames'] = False
    base_opts['restrictfilenames'] = False

# Mode handling: single vs playlist
if is_playlist:
    base_opts['noplaylist'] = False
    base_opts['playliststart'] = 1
    base_opts['max_downloads'] = int(max_val)
    if user_user and user_pass:
        base_opts['username'] = user_user
        base_opts['password'] = user_pass
else:
    base_opts['noplaylist'] = True

# Cookie handling - opt-in via -nocs, or explicit cookie file via -cf
if cookie_file_path:
    base_opts['cookiefile'] = cookie_file_path
elif args.no_cookies_from_browser:
    base_opts['cookiesfrombrowser'] = ('brave',)

# Audio format post-processing
if format_choice:
    if format_choice == 'mp4':
        base_opts['format'] = 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'
        base_opts['postprocessors'] = [{
            'key': 'FFmpegVideoConvertor',
            'preferedformat': 'mp4',
        }]
    else:
        base_opts['format'] = 'bestaudio/best'
        base_opts['postprocessors'] = [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': format_choice,
        }]


# Setup handler
def run_setup():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    setup_path = os.path.join(script_dir, 'setup.sh')
    if not os.path.exists(setup_path):
        print("Error: setup.sh not found in project directory")
        return False
    subprocess.run(['sudo', 'bash', setup_path])
    return True


if setup:
    run_setup()
    sys.exit(0)

# Pre-flight check
print(f"yt-dlp version: {yt_dlp.version.__version__}")
print(f"JavaScript runtime: {runtime_type or 'none'}")

# Unified download logic
try:
    with yt_dlp.YoutubeDL(base_opts) as ydl:
        ydl.download([target_url])
    print("\n✓ Download complete!")
    print(f"Saved to: {output_dir}")
except yt_dlp.utils.DownloadError as e:
    print(f"\n✗ Download failed: {e}")
    err = str(e)
    if "JS runtime" in err or "JavaScript runtime" in err or "Signature" in err:
        print("\nCause: No JavaScript runtime found.")
        print(f"Detected runtime: {runtime_type} at {runtime_path or 'N/A'}")
        print("Fix: Install Node.js or Deno:")
        if os_name == "Linux":
            print("  Fedora/RHEL: sudo dnf install nodejs")
            print("  Ubuntu/Debian: sudo apt install nodejs")
        print("  Or install Deno: https://deno.land/manual/getting_started/installation")
    elif "format is not available" in err:
        print("\nCause: The requested format isn't offered for this video.")
        print("Fix: Try listing available formats:")
        print(f"  python3 {sys.argv[0]} -single \"{target_url}\" --list-formats")
    elif "reload" in err.lower():
        print("\nCause: YouTube served a challenge page.")
        print("Fix: Update yt-dlp (pip install --upgrade yt-dlp) and ensure Node.js/Deno is installed.")
    else:
        print("\nCommon causes:")
        print("  1. URL malformed or contains unquoted '&'")
        print("  2. yt-dlp outdated")
        print("  3. Network connectivity issues")
        print("  4. Video unavailable or region-restricted")
    sys.exit(1)
except Exception as e:
    print(f"\n✗ Unexpected error: {type(e).__name__}: {e}")
    sys.exit(1)