import argparse
import sys
import platform
import yt_dlp
import os


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
parser.add_argument("-single", help='Single download', action='store_true')
parser.add_argument("-download", help='Local download location', action='store_true') # Not being implemented immediately
parser.add_argument("-playlist", help='Playlist download', action='store_true')
parser.add_argument("url", type=str, help="Input URL")
parser.add_argument("-format", choices=["flac", "wav", "mp3", "mp4", "opus"], help='Download Format')
parser.add_argument("-retry", help="Retry count", type=int)
parser.add_argument("-timeout", help="Timeout count", type=int)
parser.add_argument("-ratelim", help="Ratelimit value, default 100000000", type=int)
parser.add_argument("-username", help="Define Username", type=str)
parser.add_argument("-pswd", help="Define Password", type=str)
parser.add_argument("cookiefile", help="This is for passing the path to the desired cookie file", type=str)
parser.add_argument("-max", help="Sets max download limit for playlist downloading; default is 25", type=str)
parser.add_argument("-thumbnail", help="Choosing to write the thumbnail to file or not.", choices=["Y", "N"])
parser.add_argument("-subs", help="Choosing to write subtitles to file or to not.", choices=["Y", "N"])
parser.add_argument("-embed", help="Choosing to embed the subtitles within the file or not.", choices=["Y", "N"])
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
    'cookiesfrombrowser': ('firefox',),
    'geobypass': True,
    'writethumbnail': True,
    'writesubtitles': True,
    'embededsubtitles': True,
    'addmetadata': True,

}

for browser in browsers:
    try:
        std_opts[browser] = (browser,)
        break
    except Exception:
        continue

custom_opts = {
    'outtmpl' : os.path.join(down_path, '%(title)s.%(ext)s'),
    'postprocessors': [{
        'key': 'FFmpegExtractAudio',
        'preferredcodec': cus_form,
    }],
    'retries': retry_val,
    'socket_timeout': timeout_val,
    'ratelimit': rate_val,
    'username': user_user,
    'password': user_pass,
    'cookiefile': cookie_file_path
}

playlist_opts = {
    'outtmpl' : os.path.join(down_path, '%(title)s.%(ext)s'),
    'format' : 'bestvideo[ext=mp4]+bestaudio[ext=m4a]',
    'noplaylist' : False,
    'playliststart': 1,
    'max_downloads': 25,
}

# OS Check
if os_name != "Windows":
    std_opts['windowsfilenames'] = False

# Format setting
if args.format:
    match args.format:
        case 'flac':
           cus_form = "flac"
        case 'wav':
          cus_form = "wav"
        case 'mp3':
           cus_form = "mp3"
        case 'mp4':
            cus_form = "mp4"
        case 'opus':
            cus_form = "opus"
        case _:
            sys.stderr.write("Invalid format")
            sys.exit(1)

# Single Download Logic
if args.single:
    url = target_url
    if args.format:
        if args.thumbnail:
            custom_opts['thumbnail'] = args.thumbnail
        if args.subs:
            custom_opts['subtitles'] = args.subs
        if args.embed:
            custom_opts['embed'] = args.embed
        with yt_dlp.YoutubeDL(custom_opts) as ydl:
            ydl.download([url])
            sys.exit(0)
    else:
        with yt_dlp.YoutubeDL(std_opts) as ydl:
            ydl.download([url])
            sys.exit(0)

# Playlist Download Logic
if args.playlist:
    if args.max:
        playlist_opts['max'] = args.max
    with yt_dlp.YoutubeDL(playlist_opts) as ydl:
        ydl.download([target_url])
        sys.exit(0)


