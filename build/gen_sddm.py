"""SDDM login theme: src/sddm/kyberos plus the wallpaper's Backdrop, scenes and images,
so the login screen draws the same animated display (pure QtQuick, no Plasma imports)."""
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def generate(out):
    dst = out / "sddm" / "kyberos"
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(ROOT / "src" / "sddm" / "kyberos", dst)
    wp = out / "plasma" / "wallpapers" / "org.kyberos.tactical" / "contents"
    (dst / "ui").mkdir()
    shutil.copy2(wp / "ui" / "Backdrop.qml", dst / "ui" / "Backdrop.qml")
    shutil.copytree(wp / "ui" / "scenes", dst / "ui" / "scenes")
    shutil.copytree(wp / "images", dst / "images")
