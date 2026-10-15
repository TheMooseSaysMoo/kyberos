"""SVG -> PNG via rsvg-convert (librsvg2-tools)."""
import shutil
import subprocess

_warned = False


def available():
    return shutil.which("rsvg-convert") is not None


def png(svg_path, png_path, width=None, height=None):
    global _warned
    if not available():
        if not _warned:
            print("    ! rsvg-convert missing: PNGs skipped (install librsvg: librsvg2-tools / librsvg2-bin / librsvg)")
            _warned = True
        return False
    cmd = ["rsvg-convert", "-o", str(png_path)]
    if width:
        cmd += ["-w", str(width)]
    if height:
        cmd += ["-h", str(height)]
    subprocess.run(cmd + [str(svg_path)], check=True)
    return True
