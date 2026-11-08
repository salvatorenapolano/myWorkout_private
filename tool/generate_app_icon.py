"""Genera l'icona dell'app: l'emoji 💪 (Noto Emoji, Apache 2.0) su gradiente giallo.

Uso:  python tool/generate_app_icon.py
Poi:  dart run flutter_launcher_icons   (crea tutte le misure iOS e Android)

File creati in assets/icon/:
- app_icon.png             1024×1024, icona completa (iOS e Android "classico")
- app_icon_background.png  solo il gradiente (sfondo dell'icona adattiva Android)
- app_icon_foreground.png  solo l'emoji, su trasparente (primo piano Android)
"""
from pathlib import Path

from PIL import Image, ImageFilter

SIZE = 1024
ICON_DIR = Path(__file__).resolve().parent.parent / "assets" / "icon"
EMOJI = ICON_DIR / "noto_emoji_u1f4aa.png"

# Gradiente diagonale: giallo chiaro in alto a sinistra, giallo caldo in basso a destra.
TOP_LEFT = (255, 247, 204)      # #FFF7CC
BOTTOM_RIGHT = (255, 214, 92)   # #FFD65C
SHADOW = (150, 90, 0)           # ombra ambra scura


def gradient() -> Image.Image:
    # Si calcola su una versione piccola e si ingrandisce: è più veloce
    # e il risultato, essendo una sfumatura, resta liscio.
    small = 256
    img = Image.new("RGB", (small, small))
    px = img.load()
    for y in range(small):
        for x in range(small):
            t = (x + y) / (2 * (small - 1))
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(TOP_LEFT, BOTTOM_RIGHT))
    return img.resize((SIZE, SIZE), Image.BICUBIC)


def emoji_layer(emoji_size: int) -> Image.Image:
    """L'emoji centrata su trasparente, con un'ombra morbida sotto."""
    emoji = Image.open(EMOJI).convert("RGBA").resize((emoji_size, emoji_size), Image.LANCZOS)
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    pos = ((SIZE - emoji_size) // 2, (SIZE - emoji_size) // 2)

    # Ombra: la sagoma dell'emoji, colorata, spostata in basso e sfocata.
    alpha = emoji.getchannel("A").point(lambda a: a * 0.35)
    shadow = Image.new("RGBA", emoji.size, SHADOW + (0,))
    shadow.putalpha(alpha)
    offset = emoji_size // 30
    layer.alpha_composite(shadow, (pos[0], pos[1] + offset))
    layer = layer.filter(ImageFilter.GaussianBlur(emoji_size / 40))

    layer.alpha_composite(emoji, pos)
    return layer


def main() -> None:
    background = gradient()
    background.save(ICON_DIR / "app_icon_background.png")

    # Icona completa: l'emoji occupa circa il 62% del lato.
    full = background.convert("RGBA")
    full.alpha_composite(emoji_layer(int(SIZE * 0.62)))
    full.convert("RGB").save(ICON_DIR / "app_icon.png")  # iOS non vuole trasparenze

    # Android adattiva: il sistema ritaglia l'icona (cerchio, goccia...).
    # flutter_launcher_icons aggiunge già un margine del 16% per lato,
    # quindi qui l'emoji è grande: alla fine sarà circa il 46% del lato,
    # dentro la "zona sicura" che nessun ritaglio taglia.
    emoji_layer(int(SIZE * 0.68)).save(ICON_DIR / "app_icon_foreground.png")
    print("Icone generate in", ICON_DIR)


if __name__ == "__main__":
    main()
