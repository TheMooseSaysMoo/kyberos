"""Look-and-feel extras: splash logo and preview images."""
import shutil
from palette import *
from glyphs import wordmark, crystal
import raster


def generate(out):
    lnf = out / "plasma" / "look-and-feel" / "org.kyberos.desktop" / "contents"
    img = lnf / "splash" / "images"
    img.mkdir(parents=True, exist_ok=True)
    a = CRYSTALS[DEFAULT_CRYSTAL]
    (img / "logo.svg").write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="200" viewBox="0 0 1000 200">'
        f'{crystal(70, 100, 150, a)}{wordmark(560, 100, 9.0, TEXT, a)}</svg>\n')
    prev = lnf / "previews"
    prev.mkdir(parents=True, exist_ok=True)
    shot = out / "wallpapers" / f"KyberOS-{DEFAULT_CRYSTAL.capitalize()}" / "contents"
    big = shot / "images" / "3840x2160.png"
    if big.exists() and raster.available():
        # previews are just scaled wallpaper renders; good enough for the KCM grid
        shutil.copy(shot / "screenshot.png", prev / "preview.png")
        shutil.copy(shot / "screenshot.png", prev / "splash.png")
        shutil.copy(shot / "screenshot.png", prev / "lockscreen.png")
        shutil.copy(big, prev / "fullscreenpreview.jpg")
