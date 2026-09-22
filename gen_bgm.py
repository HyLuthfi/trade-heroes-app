import math
import struct
import wave
import subprocess
import os
import shutil

AUDIO_DIR = 'C:/Users/luthf/projects/trade-heroes-app/assets/audio'
BGM_DIR = os.path.join(AUDIO_DIR, 'bgm')
SAMPLE_RATE = 44100

def gen_ambient_pad(filename, chords, bpm=30, duration=75, volume=0.35):
    """Generate smooth ambient pad with chord progression"""
    num_samples = int(SAMPLE_RATE * duration)
    samples = [0.0] * num_samples
    beat_dur = 60.0 / bpm
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        chord_idx = int(t / (beat_dur * 4)) % len(chords)
        chord = chords[chord_idx]
        
        val = 0.0
        for note_freq in chord:
            # Smooth sine with very slow vibrato
            vibrato = 1.0 + 0.002 * math.sin(2 * math.pi * 0.3 * t)
            val += math.sin(2 * math.pi * note_freq * vibrato * t) * (1.0 / len(chord))
        
        # Gentle crossfade between chords
        pos_in_chord = (t % (beat_dur * 4)) / (beat_dur * 4)
        env = 1.0
        if pos_in_chord < 0.05:
            env = pos_in_chord / 0.05
        elif pos_in_chord > 0.95:
            env = (1.0 - pos_in_chord) / 0.05
        
        # Master fade in/out
        if t < 3:
            env *= t / 3
        elif t > duration - 4:
            env *= (duration - t) / 4
        
        samples[i] = val * env * volume
    
    wav_path = os.path.join(BGM_DIR, filename.replace('.mp3', '.wav'))
    mp3_path = os.path.join(BGM_DIR, filename)
    with wave.open(wav_path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        for s in samples:
            clamped = max(-0.95, min(0.95, s))
            w.writeframes(struct.pack('<h', int(clamped * 32767)))
    subprocess.run(['ffmpeg', '-y', '-i', wav_path, '-codec:a', 'libmp3lame', '-b:a', '128k', mp3_path],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    os.remove(wav_path)
    print(f'Generated {filename}: {os.path.getsize(mp3_path)//1024}K')

# Deep Space Ambient — very low, warm, floating
gen_ambient_pad('deep_space.mp3', [
    [110, 165, 220],      # A2-E3-A3
    [98, 147, 196],       # G2-D3-G3
    [87, 131, 175],       # F2-C3-F3
    [98, 147, 196],       # G2-D3-G3
], bpm=20, duration=75, volume=0.3)

# Rain Meditation — higher, airy, ethereal
gen_ambient_pad('rain_meditation.mp3', [
    [262, 330, 392, 494],  # C4-E4-G4-B4 (Cmaj7)
    [220, 262, 330, 415],  # A3-C4-E4-Ab4 (Am add9)
    [196, 247, 294, 370],  # G3-B3-D4-Gb4 (Gmaj7)
    [175, 220, 262, 330],  # F3-A3-C4-E4 (Fmaj7)
], bpm=25, duration=75, volume=0.25)

# Copy existing bgm.mp3 as 'default' option
src_bgm = os.path.join(AUDIO_DIR, 'bgm.mp3')
if os.path.exists(src_bgm):
    shutil.copy2(src_bgm, os.path.join(BGM_DIR, 'default.mp3'))
    print(f'Copied default BGM: {os.path.getsize(os.path.join(BGM_DIR, "default.mp3"))//1024}K')

# Summary
print('\n=== ALL BGM TRACKS ===')
for f in sorted(os.listdir(BGM_DIR)):
    fp = os.path.join(BGM_DIR, f)
    print(f'  {f}: {os.path.getsize(fp)//1024}K')
