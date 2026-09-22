import urllib.request
import subprocess
import os
import re

AUDIO_DIR = 'C:/Users/luthf/projects/trade-heroes-app/assets/audio'
HEADERS = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}

def download(url, out_path, trim_dur=None, volume=1.0):
    """Download and optionally trim/adjust volume"""
    raw = out_path + '.raw.mp3'
    req = urllib.request.Request(url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp, open(raw, 'wb') as f:
            f.write(resp.read())
    except Exception as e:
        print(f'  FAIL download: {e}')
        return False
    
    # Process with ffmpeg
    af_filters = []
    if volume != 1.0:
        af_filters.append(f'volume={volume}')
    af_filters.append('afade=t=in:d=0.01,afade=t=out:st=-1:d=0.05')
    
    cmd = ['ffmpeg', '-y', '-i', raw]
    if trim_dur:
        cmd += ['-t', str(trim_dur)]
    cmd += ['-af', ','.join(af_filters), '-codec:a', 'libmp3lame', '-b:a', '192k', out_path]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    if os.path.exists(raw):
        os.remove(raw)
    
    if os.path.exists(out_path):
        size = os.path.getsize(out_path)
        print(f'  OK: {os.path.basename(out_path)} ({size//1024}K)')
        return True
    return False

def try_pixabay_download(sound_id):
    """Try to download from Pixabay CDN using known URL patterns"""
    # Pixabay CDN pattern: https://cdn.pixabay.com/download/audio/YYYY/MM/DD/audio_HASH.mp3
    # We need to scrape the page to find the download link
    page_url = f'https://pixabay.com/sound-effects/{sound_id}/'
    req = urllib.request.Request(page_url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
        # Find CDN download URLs
        matches = re.findall(r'https://cdn\.pixabay\.com/download/audio/[^"\'\s]+\.mp3[^"\'\s]*', html)
        if matches:
            return matches[0].split('"')[0].split("'")[0]
    except:
        pass
    return None

# === Try downloading real sounds from Pixabay ===
# Known working IDs from search results
sound_candidates = {
    # Arcade theme
    'arcade_coin': 'film-special-effects-coin-collect-retro-8-bit-sound-effect-145251',
    'typewriter_click': 'film-special-effects-typewriter-click-41042',
}

print("=== Testing Pixabay page scraping ===")
for name, sid in sound_candidates.items():
    url = try_pixabay_download(sid)
    print(f'{name}: {url}')
