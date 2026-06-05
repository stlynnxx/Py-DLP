import argparse
import sys

import yt_dlp
import os

# Download path
down_path = os.path.join(os.path.expanduser('~'), 'Downloads')
custom_down_path = ""

# argparse config
parser = argparse.ArgumentParser(prog="Py-DLP",description='Python Media Downloader')
parser.add_argument("-single", help='Single download', action='store_true')
parser.add_argument("-download", help='Local download location', action='store_true') # Not being implemented immediately
parser.add_argument("-playlist", help='Playlist download', action='store_true')
parser.add_argument("url", type=str, help="Input URL")




args = parser.parse_args()

# Options

std_opts = {
    'outtmpl' : os.path.join(down_path, '%(title)s.%(ext)s'), # Storage Location
    'format' : 'bestvideo[ext=mp4]+bestaudio[ext=m4a]',
    'noplaylist' : True,


}
custom_opts = {
    'outtmpl' : os.path.join(down_path, '%(title)s.%(ext)s'),
}
playlist_opts = {
    'outtmpl' : os.path.join(down_path, '%(title)s.%(ext)s'),
    'format' : 'bestvideo[ext=mp4]+bestaudio[ext=m4a]',
    'noplaylist' : False,
}

target_url = args.url

if args.single:
    url = target_url
    with yt_dlp.YoutubeDL(std_opts) as ydl:
        ydl.download([url])
        sys.exit(0)
if args.playlist:
    with yt_dlp.YoutubeDL(playlist_opts) as ydl:
        ydl.download([target_url])
        sys.exit(0)


