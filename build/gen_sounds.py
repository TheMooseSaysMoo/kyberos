"""'KyberOS' freedesktop sound theme, synthesised from scratch (pure Python, WAV).

All sounds are original synthesis: console blips, door swooshes, alarms.
"""
import math
import random
import struct
import wave

SR = 32000


def env(n, attack, release, total):
    """Linear attack / exponential-ish release envelope value for sample n."""
    t = n / SR
    if t < attack:
        return t / attack
    rem = total - t
    if rem < release:
        return max(rem / release, 0) ** 1.6
    return 1.0


def tone(freq, dur, vol=0.5, attack=0.004, release=0.05, shape="sine", f_end=None, vib=0):
    out, phase = [], 0.0
    n_total = int(dur * SR)
    for n in range(n_total):
        f = freq if f_end is None else freq * (f_end / freq) ** (n / n_total)
        if vib:
            f *= 1 + 0.02 * math.sin(2 * math.pi * vib * n / SR)
        phase += 2 * math.pi * f / SR
        if shape == "sine":
            s = math.sin(phase)
        elif shape == "square":
            s = 0.6 * (1 if math.sin(phase) >= 0 else -1) + 0.4 * math.sin(phase)
        elif shape == "saw":
            s = 2 * ((phase / (2 * math.pi)) % 1) - 1
        else:  # fm 'console chirp'
            s = math.sin(phase + 2.2 * math.sin(phase * 2.01))
        out.append(s * vol * env(n, attack, release, dur))
    return out


def noise(dur, vol, cutoff_start, cutoff_end, attack=0.05, release=0.2, seed=1):
    """Low-passed noise with a swept cutoff: swooshes and rumbles."""
    rnd = random.Random(seed)
    out, y = [], 0.0
    n_total = int(dur * SR)
    for n in range(n_total):
        fc = cutoff_start * (cutoff_end / cutoff_start) ** (n / n_total)
        a = 1 - math.exp(-2 * math.pi * fc / SR)
        y += a * (rnd.uniform(-1, 1) - y)
        out.append(y * vol * 3 * env(n, attack, release, dur))
    return out


def silence(dur):
    return [0.0] * int(dur * SR)


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] for t in tracks if i < len(t)) for i in range(n)]


def seq(*parts):
    out = []
    for p in parts:
        out += p
    return out


def at(offset, track):
    return silence(offset) + track


def save(path, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = min(1.0, 0.89 / peak)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32767)) for s in samples))


def sounds():
    blip = lambda f, d=0.06, v=0.4: tone(f, d, v, release=0.03, shape="fm")
    s = {}
    # incoming transmission: three rising console chirps
    s["message-new-instant"] = seq(blip(1600), silence(0.03), blip(2100), silence(0.03), blip(2700, 0.09))
    s["dialog-information"] = seq(blip(1900, 0.05), silence(0.04), blip(2500, 0.08))
    s["bell"] = tone(1250, 0.12, 0.45, release=0.08, shape="fm")
    s["window-attention"] = seq(blip(2200, 0.05), silence(0.06), blip(2200, 0.05))
    s["dialog-question"] = seq(blip(1800, 0.05), silence(0.03), blip(1500, 0.05), silence(0.03), blip(2300, 0.08))
    # caution: amber two-tone pulses
    s["dialog-warning"] = seq(tone(880, 0.14, 0.35, shape="square"), silence(0.05), tone(660, 0.18, 0.35, shape="square"))
    # alarm: falling buzz
    s["dialog-error"] = mix(tone(240, 0.45, 0.4, shape="saw", f_end=150, vib=9), tone(120, 0.45, 0.2, f_end=80))
    s["outcome-failure"] = s["dialog-error"]
    # success: rising triad with shimmer
    s["complete"] = mix(at(0, tone(880, 0.16, 0.3, shape="fm")), at(0.09, tone(1175, 0.16, 0.3, shape="fm")),
                        at(0.18, tone(1760, 0.3, 0.3, shape="fm", release=0.2)))
    s["outcome-success"] = s["complete"]
    # blast-door style swooshes for devices
    s["device-added"] = mix(noise(0.45, 0.5, 300, 4000, attack=0.08, release=0.15, seed=2), at(0.32, blip(2400, 0.07)))
    s["device-removed"] = mix(noise(0.45, 0.5, 4000, 250, attack=0.03, release=0.25, seed=3), at(0.0, blip(1400, 0.07)))
    s["power-plug"] = seq(tone(500, 0.1, 0.3, f_end=1500), blip(2200, 0.06))
    s["power-unplug"] = tone(1500, 0.18, 0.3, f_end=400)
    s["battery-low"] = seq(tone(660, 0.12, 0.35, shape="square"), silence(0.08), tone(660, 0.12, 0.35, shape="square"))
    # trash: short descending energy bolt
    s["trash-empty"] = mix(tone(2400, 0.22, 0.35, shape="fm", f_end=300, release=0.12), noise(0.18, 0.15, 3000, 600, seed=4))
    s["audio-volume-change"] = tone(1800, 0.035, 0.35, release=0.02, shape="fm")
    s["screen-capture"] = mix(noise(0.06, 0.6, 6000, 2000, attack=0.002, release=0.04, seed=5), at(0.05, noise(0.05, 0.5, 5000, 1500, attack=0.002, release=0.03, seed=6)))
    s["camera-shutter"] = s["screen-capture"]
    # login: hyperspace jump (rising rumble + pitch sweep + thump)
    s["desktop-login"] = mix(noise(1.6, 0.45, 120, 5000, attack=0.9, release=0.35, seed=7),
                             tone(90, 1.5, 0.25, shape="saw", f_end=900, attack=0.6, release=0.3),
                             at(1.45, tone(60, 0.45, 0.6, f_end=35, release=0.35)))
    s["service-login"] = s["desktop-login"]
    # logout: power-down
    s["desktop-logout"] = mix(tone(700, 1.1, 0.35, shape="saw", f_end=50, release=0.5), noise(1.0, 0.25, 3000, 100, attack=0.01, release=0.6, seed=8))
    s["service-logout"] = s["desktop-logout"]
    s["network-connectivity-established"] = seq(blip(1400, 0.05), blip(2100, 0.05), blip(2800, 0.07))
    s["network-connectivity-lost"] = seq(blip(2800, 0.05), blip(2100, 0.05), blip(1400, 0.08))
    s["message-new-email"] = s["message-new-instant"]
    s["suspend-error"] = s["dialog-error"]
    s["theme-demo"] = s["desktop-login"]
    # door swoosh, used by nothing standard but handy for scripts
    s["kyberos-door"] = mix(noise(0.5, 0.55, 5000, 400, attack=0.01, release=0.3, seed=9), tone(160, 0.35, 0.25, f_end=60))
    return s


def generate(out):
    d = out / "sounds" / "KyberOS"
    stereo = d / "stereo"
    stereo.mkdir(parents=True, exist_ok=True)
    for name, samples in sounds().items():
        save(stereo / f"{name}.wav", samples)
    (d / "index.theme").write_text("[Sound Theme]\nName=KyberOS\nComment=Synthesised Imperial console sounds\nInherits=ocean,freedesktop\nDirectories=stereo\n\n[stereo]\nOutputProfile=stereo\n")
