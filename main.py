import argparse
import sys
import platform
import yt_dlp
import os
import subprocess


# OS Discovery
os_name = platform.system()
if os_name == "Linux":
    print("Linux detected!")
    print("Excellent choice in OS, my friend.")
# Download path
down_path = os.path.join(os.path.expanduser('~'), 'Downloads')
custom_down_path = ""

cus_form = ""

# argparse config
parser = argparse.ArgumentParser(prog="Py-DLP",description='Python Media Downloader')
parser.add_argument("-setup", help="Setup script for fresh installs", action="store_true")
parser.add_argument("-single", help='Single download', action='store_true')
parser.add_argument("-download", help='Local download location', action='store_true') # Not being implemented immediately
parser.add_argument("-playlist", help='Playlist download', action='store_true')
parser.add_argument("url", type=str, help="Input URL")
parser.add_argument("-format", choices=["flac", "wav", "mp3", "mp4", "opus"], help='Download Format')
parser.add_argument("-retry", help="Retry count", type=int, default=4)
parser.add_argument("-timeout", help="Timeout count", type=int, default=20)
parser.add_argument("-ratelim", help="Ratelimit value, default 100000000", type=int, default=10000000)
parser.add_argument("-username", help="Define Username", type=str)
parser.add_argument("-pswd", help="Define Password", type=str)
#parser.add_argument("cookiefile", help="This is for passing the path to the desired cookie file", type=str)
parser.add_argument("-max", help="Sets max download limit for playlist downloading; default is 25", type=str, default=25)
parser.add_argument("-thumbnail", help="Choosing to write the thumbnail to file or not, default is true.", action='store_true', default=True)
parser.add_argument("-subs", help="Choosing to write subtitles to file or to not, default is True.", action='store_true', default=True)
parser.add_argument("-embed", help="Choosing to embed the subtitles within the file or not, default is True", action='store_true', default=True)
parser.add_argument("-metadata", help="Toggles addition of metadata, default is True", action='store_true', default=True)
args = parser.parse_args()

# Arg vals being saved
retry_val = args.retry
target_url = args.url
timeout_val = args.timeout
rate_val = args.ratelim
user_user = args.username
user_pass = args.pswd
max_val = args.max
#cookie_file_path = args.cookiefile
meta_data = args.metadata
setup = args.setup

# Options
# Browser List
browsers = ['chrome','firefox','brave','opera']

std_opts = {
    'outtmpl' : os.path.join(down_path, '%(title)s.%(ext)s'), # Storage Location
    'format' : 'best',
    'noplaylist' : True,
    'ignoreerrors': True,
    'windowsfilenames': True,
    'restrictfilenames': True,
    'retries': 4,
    'socket_timeout': 20,
    'ratelimit': 100000000,
    'cookiesfrombrowser': ('brave',),
    'geobypass': True,
    'writethumbnail': True,
    'writesubtitles': True,
    'embeddedsubtitles': True,
    'addmetadata': True,
    'extractor_args': {'youtube': {'js_runtimes': ['node']}}
}

for browser in browsers:
    try:
        std_opts[browser] = (browser,)
        break
    except Exception:
        continue



playlist_opts = {
    'outtmpl' : os.path.join(down_path, '%(title)s.%(ext)s'),
    'format' : 'bestvideo[ext=mp4]+bestaudio[ext=m4a]',
    'noplaylist' : False,
    'playliststart': 1,
    'max_downloads': 25,
    'retries': retry_val,
    'socket_timeout': timeout_val,
    'ratelimit': rate_val,
    'username': user_user,
    'password': user_pass,
    #'cookiefile': cookie_file_path
}
def run_setup():
    setup_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'setup.sh')
    if not os.path.exists(setup_path):
        print("setup.sh not found")
        return
    subprocess.run(['sudo', 'bash', setup_path])
# OS Check
if os_name != "Windows":
    std_opts['windowsfilenames'] = False
if setup:
    run_setup()

# Format setting
if args.format:
    cus_form = args.format
    custom_opts = {
        'outtmpl': os.path.join(down_path, '%(title)s.%(ext)s'),
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': cus_form,
        }],
        'retries': retry_val,
        'socket_timeout': timeout_val,
        'ratelimit': rate_val,
        'username': user_user,
        'password': user_pass,
        # 'cookiefile': cookie_file_path,
        'addmetadata': meta_data
    }
    if cus_form == 'mp4':
        custom_opts['format'] = 'bestvideo[ext=mp4]+bestaudio[ext=m4a]'
        custom_opts['postprocessors'] = [{
            'key': 'FFmpegVideoConvertor',
            'preferedformat': 'mp4',
        }]
    else:
        custom_opts['format'] = 'bestaudio/best'
        custom_opts['postprocessors'] = [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': cus_form,
        }]


# Single Download Logic
if args.single:
    url = target_url
    if args.format:
        custom_opts['thumbnail'] = args.thumbnail
        custom_opts['subtitles'] = args.subs
        custom_opts['embed'] = args.embed
        with yt_dlp.YoutubeDL(custom_opts) as ydl:
            ydl.download([url])
            print("args.single if")
            sys.exit(0)
    else:
        with yt_dlp.YoutubeDL(std_opts) as ydl:
            ydl.download([url])
            print("Args.single else")
            sys.exit(0)

# Playlist Download Logic
if args.playlist:
    if args.format:
        playlist_opts['thumbnail'] = args.thumbnail
        playlist_opts['subtitles'] = args.subs
        playlist_opts['embed'] = args.embed
        playlist_opts['max'] = args.max
        playlist_opts['metadata'] = meta_data
        with yt_dlp.YoutubeDL(playlist_opts) as ydl:
            ydl.download([target_url])
            sys.exit(0)
    else:
        with yt_dlp.YoutubeDL(playlist_opts) as ydl:
            ydl.download([target_url])
            sys.exit(0)


