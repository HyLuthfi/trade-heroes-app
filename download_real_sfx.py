import urllib.request
import subprocess
import os

AUDIO_DIR = 'C:/Users/luthf/projects/trade-heroes-app/assets/audio'
HEADERS = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}

def dl(url, out_path, trim=None, vol=1.0, fade_out=0.05):
    """Download, trim, adjust volume"""
    raw = out_path + '.raw'
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=15) as resp, open(raw, 'wb') as f:
        f.write(resp.read())
    
    cmd = ['ffmpeg', '-y', '-i', raw]
    if trim:
        cmd += ['-t', str(trim)]
    af = f'volume={vol}'
    if fade_out > 0:
        cmd += ['-af', af]
    cmd += ['-codec:a', 'libmp3lame', '-b:a', '192k', out_path]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    os.remove(raw)
    print(f'  {os.path.basename(out_path)}: {os.path.getsize(out_path)//1024}K')

# Mixkit SFX URLs
MK = 'https://assets.mixkit.co/active_storage/sfx'

# === Theme assignments ===
# Each theme needs: click.mp3, correct.mp3, wrong.mp3, reward.mp3, trade.mp3

themes = {
    'default': {
        'click':   (f'{MK}/2568/2568-preview.mp3', 0.3, 0.5),   # soft UI click
        'correct': (f'{MK}/2000/2000-preview.mp3', 0.8, 0.6),   # correct answer chime
        'wrong':   (f'{MK}/2003/2003-preview.mp3', 0.6, 0.5),   # wrong answer
        'reward':  (f'{MK}/2018/2018-preview.mp3', 1.0, 0.6),   # success notification
        'trade':   (f'{MK}/2869/2869-preview.mp3', 0.5, 0.5),   # notification bell
    },
    'minimal': {
        'click':   (f'{MK}/2568/2568-preview.mp3', 0.1, 0.3),   # very soft click
        'correct': (f'{MK}/2869/2869-preview.mp3', 0.3, 0.4),   # subtle notification
        'wrong':   (f'{MK}/2955/2955-preview.mp3', 0.2, 0.3),   # quiet error
        'reward':  (f'{MK}/2870/2870-preview.mp3', 0.4, 0.4),   # soft alert
        'trade':   (f'{MK}/2867/2867-preview.mp3', 0.3, 0.4),   # gentle chime
    },
    'arcade': {
        'click':   (f'{MK}/2013/2013-preview.mp3', 0.5, 0.5),   # retro game blip
        'correct': (f'{MK}/888/888-preview.mp3', 0.8, 0.6),     # coin collect
        'wrong':   (f'{MK}/2006/2006-preview.mp3', 1.0, 0.5),   # game fail/lose
        'reward':  (f'{MK}/2019/2019-preview.mp3', 1.0, 0.6),   # level up!
        'trade':   (f'{MK}/2020/2020-preview.mp3', 0.6, 0.5),   # game bonus
    },
    'nature': {
        'click':   (f'{MK}/2358/2358-preview.mp3', 0.5, 0.4),   # bubble/water
        'correct': (f'{MK}/2430/2430-preview.mp3', 0.8, 0.8),   # bird chirp
        'wrong':   (f'{MK}/2832/2832-preview.mp3', 0.5, 0.5),   # whoosh wind
        'reward':  (f'{MK}/2867/2867-preview.mp3', 0.7, 0.5),   # wind chime
        'trade':   (f'{MK}/2358/2358-preview.mp3', 0.6, 0.5),   # bubble pop
    },
    'mechanical': {
        'click':   (f'{MK}/2546/2546-preview.mp3', 0.3, 0.4),   # typewriter key
        'correct': (f'{MK}/2573/2573-preview.mp3', 0.6, 0.5),   # metal ding
        'wrong':   (f'{MK}/2955/2955-preview.mp3', 0.5, 0.5),   # error buzz
        'reward':  (f'{MK}/888/888-preview.mp3', 0.6, 0.5),     # cash register
        'trade':   (f'{MK}/2573/2573-preview.mp3', 0.5, 0.4),   # metal click
    },
    'bubble': {
        'click':   (f'{MK}/2358/2358-preview.mp3', 0.4, 0.4),   # bubble pop
        'correct': (f'{MK}/2020/2020-preview.mp3', 0.6, 0.5),   # game bonus bubbly
        'wrong':   (f'{MK}/2832/2832-preview.mp3', 0.4, 0.4),   # whoosh deflate
        'reward':  (f'{MK}/2019/2019-preview.mp3', 0.8, 0.6),   # level up bubbly
        'trade':   (f'{MK}/2358/2358-preview.mp3', 0.5, 0.5),   # bubble pop trade
    },
}

for theme_name, sounds in themes.items():
    theme_dir = os.path.join(AUDIO_DIR, 'themes', theme_name)
    os.makedirs(theme_dir, exist_ok=True)
    print(f'\n=== {theme_name.upper()} ===')
    for sfx_name, (url, trim, vol) in sounds.items():
        out = os.path.join(theme_dir, f'{sfx_name}.mp3')
        try:
            dl(url, out, trim=trim, vol=vol)
        except Exception as e:
            print(f'  FAIL {sfx_name}: {e}')

# Also update root default sounds
print('\n=== ROOT (default click/correct/wrong/reward/trade) ===')
root_sounds = themes['default']
for sfx_name, (url, trim, vol) in root_sounds.items():
    out = os.path.join(AUDIO_DIR, f'{sfx_name}.mp3')
    try:
        dl(url, out, trim=trim, vol=vol)
    except Exception as e:
        print(f'  FAIL {sfx_name}: {e}')

print('\n=== DONE ===')
