"""
updatehelpers.py - self-update machinery for Py-DLP.

Ported from Slippery Penguin's updater. Endpoint contract unchanged:

    GET {UPDATE_URL}{current_version}

    {
      "latest": "1.0.1",
      "url":    "https://.../py-dlp-1.0.1.tar.gz",
      "hash":   "<sha256 of that tarball>"
    }
"""


import urllib.request
import urllib.error
import json
import os
import tempfile
import hashlib
import shutil
import tarfile



# Keep in step with py-dlp.py's __version__.
__version__ = "1.0.0"
UPDATE_URL = "https://eclecticelectronics.fly.dev/api/check-update/dlp/"


def download_update(url, expected_hash):
    fd, tmp_path = tempfile.mkstemp(suffix=".tar.gz")
    os.close(fd)
    hasher = hashlib.sha256()
    try:
        with (
            urllib.request.urlopen(url, timeout=10) as resp,
            open(tmp_path, "wb") as out,
        ):
            while chunk := resp.read(65536):
                out.write(chunk)
                hasher.update(chunk)
            if hasher.hexdigest() != expected_hash:
                os.unlink(tmp_path)
                raise RuntimeError("Checksum mismatch- download aborted")
        return tmp_path
    except Exception as e:
        print(f"[red]{e}[/red]")
        return None


def extract_update(tmp_path):
    extract_dir = tempfile.mkdtemp()
    with tarfile.open(tmp_path, "r:gz") as tar:
        tar.extractall(extract_dir, filter="data")
        # Changed from Slippery Penguin: this project's file list.
        required = ["py-dlp.py", "updatehelpers.py"]
        extracted_names = os.listdir(extract_dir)
        for name in required:
            if name not in extracted_names:
                raise RuntimeError("Incomplete package, download aborted")
    return extract_dir


def install_update(extract_dir):
    install_root = os.path.dirname(os.path.abspath(__file__))
    for fname in os.listdir(extract_dir):
        src = os.path.join(extract_dir, fname)
        dst = os.path.join(install_root, fname)

        # Changed from Slippery Penguin: stage the copy inside install_root
        # before renaming. os.replace() is only atomic within a single
        # filesystem, and tempfile.mkdtemp() lands on /tmp - tmpfs on Fedora -
        # so a direct os.replace(src, dst) raises
        # OSError: [Errno 18] Invalid cross-device link.
        staged = dst + ".new"
        shutil.copy2(src, staged)
        os.replace(staged, dst)

    shutil.rmtree(extract_dir)


def update_chk():
    try:
        with urllib.request.urlopen(UPDATE_URL + __version__, timeout=10) as resp:
            update_info = json.loads(resp.read().decode())
    except (urllib.error.URLError, json.JSONDecodeError) as e:
        print(f"[red]Could not reach update server: {e}[/red]")
        return None

    latest = update_info.get("latest", "")

    if latest == __version__:
        print("[green]Already on latest version[/green]")
        return None

    if latest < __version__:
        print("[yellow]You're on the development version[/yellow]")
        return None

    if latest > __version__:
        print(
            f"[magenta]Update available: {latest} (you are running {__version__})[/magenta]"
        )
        print(
            "[green]Would you like to update, or stay on the current version? (y to update):[/green]"
        )
        print("[magenta](y/n)[/magenta]")
        usr_in = input().lower()

        if usr_in != "y":
            print("[yellow]Update cancelled[/yellow]")
            return None

        # Execute update
        try:
            # Changed from Slippery Penguin: the GTFOBins refresh step is
            # removed. It belongs to that project, not this one. Nothing
            # replaces it - add a step here if Py-DLP ever needs one.
            expected_hash = update_info.get("sha256")
            if not expected_hash:
                print(
                    "[red]Server did not return a hash, aborting update[/red]"
                )
                return None

            # Changed from Slippery Penguin: this call passed `latest` (a
            # version string) where a hash was expected, so the checksum
            # could never match. Now uses the hash the endpoint returns.
            downloaded_path = download_update(update_info["url"], expected_hash)
            if downloaded_path is None:
                print("[red]Download failed, aborting update[/red]")
                return None

            extract_dir = extract_update(downloaded_path)
            install_update(extract_dir)
            print("[green]Update Successful![/green]")

        except Exception as e:
            print(f"[red]Update failed: {e}[/red]")
            return None

        return update_info