import math
import struct
import wave
import subprocess
import os
import shutil

AUDIO_DIR = 'C:/Users/luthf/projects/trade-heroes-app/assets/audio'
SAMPLE_RATE = 44100

def export_wav_to_mp3(wav_path, mp3_path):
    subprocess.run(['ffmpeg', '-y', '-i', wav_path, '-codec:a', 'libmp3lame', '-b:a', '192k', mp3_path],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    os.remove(wav_path)

def gen_tone(freqs_envs, duration, filename, volume=0.5):
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        val = 0.0
        for fs, fe, amp, decay in freqs_envs:
            freq = fs * math.exp(-t * math.log(max(fs/fe, 0.01)) / duration) if fe > 0 else fs
            env = math.exp(-t * decay)
            val += amp * math.sin(2 * math.pi * freq * t) * env
        samples[i] = val * volume

    wav_path = os.path.join(AUDIO_DIR, filename.replace('.mp3', '.wav'))
    mp3_path = os.path.join(AUDIO_DIR, filename)
    with wave.open(wav_path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        for s in samples:
            clamped = max(-0.95, min(0.95, s))
            w.writeframes(struct.pack('<h', int(clamped * 32767)))
    export_wav_to_mp3(wav_path, mp3_path)
    return os.path.getsize(mp3_path)

def gen_sequence(notes_list, duration, filename, volume=0.3):
    """notes_list: [(start_time, end_time, freq, wave_type)] wave_type: 'sine' or 'square'"""
    n = int(SAMPLE_RATE * duration)
    samples = [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        for start, end, freq, wtype in notes_list:
            if start <= t < end:
                dt = t - start
                env = math.exp(-dt * 12)
                if wtype == 'square':
                    val = (1.0 if math.sin(2*math.pi*freq*t) > 0 else -1.0) * env
                else:
                    val = math.sin(2*math.pi*freq*t) * env
                samples[i] += val * volume

    wav_path = os.path.join(AUDIO_DIR, filename.replace('.mp3', '.wav'))
    mp3_path = os.path.join(AUDIO_DIR, filename)
    with wave.open(wav_path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        for s in samples:
            clamped = max(-0.95, min(0.95, s))
            w.writeframes(struct.pack('<h', int(clamped * 32767)))
    export_wav_to_mp3(wav_path, mp3_path)

# Create theme directories
themes = ['default', 'minimal', 'arcade', 'nature', 'mechanical', 'bubble']
for t in themes:
    os.makedirs(os.path.join(AUDIO_DIR, 'themes', t), exist_ok=True)

# Copy current files as 'default' theme
for f in ['click.mp3', 'correct.mp3', 'wrong.mp3', 'reward.mp3', 'trade.mp3']:
    src = os.path.join(AUDIO_DIR, f)
    if os.path.exists(src):
        shutil.copy2(src, os.path.join(AUDIO_DIR, 'themes', 'default', f))
print('Default theme copied')

# === MINIMAL: ultra-subtle, whisper-quiet ===
d = 'themes/minimal/'
gen_tone([(2200, 1800, 1.0, 200)], 0.015, d+'click.mp3', 0.2)
gen_tone([(523, 523, 0.6, 30), (659, 659, 0.4, 25)], 0.15, d+'correct.mp3', 0.3)
gen_tone([(180, 120, 1.0, 40)], 0.12, d+'wrong.mp3', 0.25)
gen_tone([(523, 523, 0.5, 15), (659, 659, 0.3, 12), (784, 784, 0.2, 10)], 0.25, d+'reward.mp3', 0.3)
gen_tone([(880, 880, 0.7, 35), (1320, 1320, 0.3, 30)], 0.08, d+'trade.mp3', 0.25)
print('Minimal theme generated')

# === ARCADE: retro 8-bit game sounds ===
d = 'themes/arcade/'
gen_tone([(1400, 800, 1.0, 120)], 0.03, d+'click.mp3', 0.4)
gen_sequence([(0, 0.09, 988, 'square'), (0.09, 0.18, 1319, 'square')], 0.18, d+'correct.mp3', 0.3)
gen_tone([(150, 100, 1.0, 20)], 0.2, d+'wrong.mp3', 0.35)
gen_sequence([
    (0, 0.1, 523, 'square'), (0.1, 0.2, 659, 'square'),
    (0.2, 0.3, 784, 'square'), (0.3, 0.4, 1047, 'square')
], 0.4, d+'reward.mp3', 0.25)
gen_tone([(1200, 600, 0.8, 60), (600, 400, 0.4, 40)], 0.1, d+'trade.mp3', 0.35)
print('Arcade theme generated')

# === NATURE: organic water/wind/wood ===
d = 'themes/nature/'
gen_tone([(1800, 400, 1.0, 80), (900, 200, 0.3, 60)], 0.06, d+'click.mp3', 0.3)
gen_tone([(1200, 2400, 0.7, 25), (2400, 3600, 0.3, 30)], 0.12, d+'correct.mp3', 0.3)
gen_tone([(60, 40, 1.0, 12), (90, 60, 0.7, 14), (120, 80, 0.5, 16)], 0.25, d+'wrong.mp3', 0.25)
gen_tone([(2093, 2093, 0.3, 8), (2637, 2637, 0.25, 7), (3136, 3136, 0.2, 6)], 0.5, d+'reward.mp3', 0.3)
gen_tone([(800, 200, 1.0, 100), (400, 100, 0.5, 80)], 0.05, d+'trade.mp3', 0.35)
print('Nature theme generated')

# === MECHANICAL: typewriter / industrial ===
d = 'themes/mechanical/'
gen_tone([(3500, 1500, 0.8, 150), (1750, 750, 0.4, 120)], 0.025, d+'click.mp3', 0.3)
gen_tone([(2000, 2000, 0.8, 10), (4000, 4000, 0.2, 15)], 0.3, d+'correct.mp3', 0.25)
gen_tone([(250, 150, 1.0, 35), (500, 300, 0.5, 40), (125, 75, 0.3, 25)], 0.15, d+'wrong.mp3', 0.3)
gen_tone([(1500, 1500, 0.5, 8), (2000, 2000, 0.4, 7), (2500, 2500, 0.3, 6)], 0.4, d+'reward.mp3', 0.3)
gen_tone([(100, 50, 1.0, 60), (3000, 1000, 0.3, 100)], 0.06, d+'trade.mp3', 0.35)
print('Mechanical theme generated')

# === BUBBLE: playful bubbly pops ===
d = 'themes/bubble/'
gen_tone([(600, 250, 1.0, 70), (1200, 500, 0.3, 60)], 0.04, d+'click.mp3', 0.3)
gen_tone([(500, 800, 0.6, 30), (700, 1100, 0.4, 25)], 0.12, d+'correct.mp3', 0.3)
gen_tone([(400, 100, 1.0, 15)], 0.2, d+'wrong.mp3', 0.25)

# Bubble reward cascade
dur = 0.4
n = int(SAMPLE_RATE * dur)
samples = [0.0] * n
pops = [(0, 400), (0.08, 550), (0.16, 700), (0.24, 900), (0.32, 1100)]
for i in range(n):
    t = i / SAMPLE_RATE
    for start, freq in pops:
        dt = t - start
        if 0 <= dt < 0.07:
            env = math.exp(-dt * 60)
            samples[i] += math.sin(2*math.pi*freq*(1+dt*2)*dt) * env * 0.25
wav_p = os.path.join(AUDIO_DIR, d+'reward.wav')
mp3_p = os.path.join(AUDIO_DIR, d+'reward.mp3')
with wave.open(wav_p, 'w') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SAMPLE_RATE)
    for s in samples:
        w.writeframes(struct.pack('<h', int(max(-0.95, min(0.95, s)) * 32767)))
export_wav_to_mp3(wav_p, mp3_p)

gen_tone([(800, 400, 0.8, 50), (1600, 800, 0.2, 45)], 0.06, d+'trade.mp3', 0.3)
print('Bubble theme generated')

# Summary
print('\n=== ALL THEMES ===')
for t in themes:
    path = os.path.join(AUDIO_DIR, 'themes', t)
    files = os.listdir(path)
    sizes = [f'{f}({os.path.getsize(os.path.join(path, f))//1024}K)' for f in sorted(files)]
    print(f'  {t}: {sizes}')
