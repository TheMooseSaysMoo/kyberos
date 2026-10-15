# Vendored base: Mint-Y-Dark (Linux Mint)

These files are the compiled CSS and Cinnamon assets of **Mint-Y-Dark-Aqua** from
[linuxmint/mint-themes](https://github.com/linuxmint/mint-themes) **2.3.8**,
Copyright 2012-2014 Clement Lefebvre and the Linux Mint team, licensed **GPL-3.0-or-later**
(same as KyberOS, see `/LICENSE`).

KyberOS does not ship them as-is: `build/gen_gtk.py` and `build/gen_cinnamon.py` recolour
every value onto the KyberOS palette (`build/recolor.py`), swap the checkbox/radio/switch
images for generated KyberOS SVGs and append the KyberOS layer (chamfered plates, typography,
saber progress bars). Keep this copy unmodified so it can be refreshed from upstream.
