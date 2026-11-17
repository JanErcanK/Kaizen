"""Generate Play Store feature graphic (1024x500) for Kaizen."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ICON_PATH = ROOT / "assets" / "app_icon.png"
OUT_PATH = ROOT / "assets" / "vorstellungsgrafik.png"

W, H = 1024, 500
WHITE = (255, 255, 255)
BLUE = (41, 98, 255)
BLUE_LIGHT = (210, 228, 255)
GREEN = (120, 190, 70)
GREEN_LIGHT = (220, 242, 205)
GRAY = (170, 178, 190)
GRAY_LIGHT = (245, 247, 250)
TEXT = (55, 65, 82)
TEXT_MUTED = (130, 140, 158)
ACCENT = (255, 140, 55)


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    xy: tuple[int, int, int, int],
    radius: int,
    fill: tuple[int, ...],
    outline: tuple[int, ...] | None = None,
    width: int = 1,
) -> None:
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def draw_progress_bar(
    draw: ImageDraw.ImageDraw,
    x: int,
    y: int,
    w: int,
    h: int,
    value: float,
    color: tuple[int, int, int],
) -> None:
    rounded_rect(draw, (x, y, x + w, y + h), h // 2, GRAY_LIGHT)
    fill_w = max(h, int(w * max(0.0, min(1.0, value))))
    rounded_rect(draw, (x, y, x + fill_w, y + h), h // 2, color)


def draw_weekly_chart(layer: Image.Image, origin: tuple[int, int]) -> None:
    draw = ImageDraw.Draw(layer)
    ox, oy = origin
    card_w, card_h = 300, 190
    rounded_rect(draw, (ox, oy, ox + card_w, oy + card_h), 18, (252, 253, 255), outline=(230, 235, 242), width=2)

    title_font = load_font(18, bold=True)
    label_font = load_font(13)
    draw.text((ox + 18, oy + 16), "Weekly workouts", fill=TEXT, font=title_font)

    days = ["M", "T", "W", "T", "F", "S", "S"]
    values = [0.55, 0.85, 0.35, 1.0, 0.7, 0.45, 0.9]
    bar_area_x = ox + 24
    bar_area_y = oy + 52
    bar_w = 28
    gap = 12
    max_h = 95

    for i, (day, val) in enumerate(zip(days, values)):
        x = bar_area_x + i * (bar_w + gap)
        bar_h = int(max_h * val)
        y_top = bar_area_y + max_h - bar_h
        color = BLUE if i != 3 else GREEN
        rounded_rect(draw, (x, y_top, x + bar_w, bar_area_y + max_h), 8, color)
        draw.text((x + 8, bar_area_y + max_h + 10), day, fill=TEXT_MUTED, font=label_font)

    draw.text((ox + 18, oy + card_h - 28), "5 sessions this week", fill=BLUE, font=label_font)


def draw_weight_chart(layer: Image.Image, origin: tuple[int, int]) -> None:
    draw = ImageDraw.Draw(layer)
    ox, oy = origin
    card_w, card_h = 260, 150
    rounded_rect(draw, (ox, oy, ox + card_w, oy + card_h), 16, (252, 253, 255), outline=(230, 235, 242), width=2)

    title_font = load_font(16, bold=True)
    draw.text((ox + 16, oy + 14), "Weight trend", fill=TEXT, font=title_font)

    points = [(0, 42), (38, 36), (76, 40), (114, 28), (152, 30), (190, 18), (228, 12)]
    base_x, base_y = ox + 16, oy + 58
    scaled = [(base_x + px, base_y + py) for px, py in points]
    draw.line(scaled, fill=GREEN, width=4, joint="curve")
    for x, y in scaled[::2]:
        draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=GREEN)

    draw.text((ox + 16, oy + card_h - 28), "78.4 kg  ·  -1.2 kg", fill=TEXT_MUTED, font=load_font(13))


def draw_stats_panel(layer: Image.Image, origin: tuple[int, int]) -> None:
    draw = ImageDraw.Draw(layer)
    ox, oy = origin
    card_w, card_h = 290, 220
    rounded_rect(draw, (ox, oy, ox + card_w, oy + card_h), 18, (252, 253, 255), outline=(230, 235, 242), width=2)

    title_font = load_font(18, bold=True)
    value_font = load_font(24, bold=True)
    label_font = load_font(13)

    draw.text((ox + 18, oy + 16), "Today's analytics", fill=TEXT, font=title_font)

    stats = [
        ("Steps", "8,420", BLUE),
        ("Calories", "2,140", ACCENT),
        ("Workouts", "1", GREEN),
        ("Afterburn", "+86 kcal", BLUE),
    ]

    y = oy + 58
    for label, value, color in stats:
        draw.text((ox + 18, y), label, fill=TEXT_MUTED, font=label_font)
        draw.text((ox + card_w - 18, y), value, fill=color, font=value_font, anchor="ra")
        draw.line((ox + 18, y + 30, ox + card_w - 18, y + 30), fill=(236, 240, 246), width=1)
        y += 38


def draw_macros_table(layer: Image.Image, origin: tuple[int, int]) -> None:
    draw = ImageDraw.Draw(layer)
    ox, oy = origin
    card_w, card_h = 280, 170
    rounded_rect(draw, (ox, oy, ox + card_w, oy + card_h), 16, (252, 253, 255), outline=(230, 235, 242), width=2)

    title_font = load_font(16, bold=True)
    label_font = load_font(13)
    draw.text((ox + 16, oy + 14), "Macros", fill=TEXT, font=title_font)

    rows = [
        ("Protein", 0.72, GREEN),
        ("Carbs", 0.58, BLUE),
        ("Fat", 0.64, ACCENT),
    ]

    y = oy + 48
    for label, progress, color in rows:
        draw.text((ox + 16, y), label, fill=TEXT_MUTED, font=label_font)
        draw_progress_bar(draw, ox + 92, y + 2, 160, 12, progress, color)
        y += 34


def draw_recovery_badge(layer: Image.Image, origin: tuple[int, int]) -> None:
    draw = ImageDraw.Draw(layer)
    ox, oy = origin
    rounded_rect(draw, (ox, oy, ox + 210, oy + 74), 14, GREEN_LIGHT, outline=(190, 225, 170), width=2)
    draw.text((ox + 16, oy + 14), "Recovery ready", fill=(40, 110, 40), font=load_font(15, bold=True))
    draw.text((ox + 16, oy + 38), "6 / 7 muscle groups", fill=TEXT_MUTED, font=load_font(13))


def main() -> None:
    canvas = Image.new("RGBA", (W, H), WHITE + (255,))
    decor = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    draw_weekly_chart(decor, (36, 58))
    draw_weight_chart(decor, (36, 290))
    draw_macros_table(decor, (720, 300))
    draw_stats_panel(decor, (700, 48))
    draw_recovery_badge(decor, (760, 250))

    decor = decor.filter(ImageFilter.GaussianBlur(0.3))

    decor_alpha = decor.split()[3]
    decor_alpha = decor_alpha.point(lambda p: int(p * 0.82))
    decor.putalpha(decor_alpha)

    canvas = Image.alpha_composite(canvas, decor)

    icon = Image.open(ICON_PATH).convert("RGBA")
    icon_size = 300
    icon = icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS)

    shadow = Image.new("RGBA", (icon_size + 40, icon_size + 40), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse(
        (10, icon_size - 18, icon_size + 30, icon_size + 24),
        fill=(0, 0, 0, 35),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(8))

    icon_x = (W - icon_size) // 2
    icon_y = (H - icon_size) // 2 - 8
    canvas.alpha_composite(shadow, (icon_x - 20, icon_y - 10))
    canvas.alpha_composite(icon, (icon_x, icon_y))

    draw = ImageDraw.Draw(canvas)
    title_font = load_font(34, bold=True)
    subtitle_font = load_font(18)
    draw.text((W // 2, H - 42), "Train smarter. Track everything.", fill=TEXT, font=title_font, anchor="ms")
    draw.text((W // 2, H - 12), "Workouts · Nutrition · Analytics", fill=TEXT_MUTED, font=subtitle_font, anchor="ms")

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(OUT_PATH, format="PNG", optimize=True)
    print(f"Saved {OUT_PATH} ({W}x{H})")


if __name__ == "__main__":
    main()
