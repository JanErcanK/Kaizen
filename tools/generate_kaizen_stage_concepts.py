"""Generate review-only Kaizen level icon concepts as SVGs and PNGs."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "app_icons" / "progress" / "concepts"
INK = "#234936"
STEP = "#7FB83D"
STEP_DARK = "#6FAE00"
STEP_LIGHT = "#8FC65A"
BG = "#F7F9F5"
DETAIL = "#91C44F"
FONT_PATH = Path(r"C:\Windows\Fonts\segoeui.ttf")
SCALE = 4


@dataclass(frozen=True)
class Segment:
    command: str
    values: tuple[float, ...]


@dataclass(frozen=True)
class PathShape:
    start: tuple[float, float]
    segments: tuple[Segment, ...]
    width: float = 19
    fill: str | None = None
    stroke: str = INK


def q(cx: float, cy: float, x: float, y: float) -> Segment:
    return Segment("Q", (cx, cy, x, y))


def c(c1x: float, c1y: float, c2x: float, c2y: float, x: float, y: float) -> Segment:
    return Segment("C", (c1x, c1y, c2x, c2y, x, y))


def l(x: float, y: float) -> Segment:
    return Segment("L", (x, y))


def shape(start: tuple[float, float], *segments: Segment, width: float = 19,
          fill: str | None = None, stroke: str = INK) -> PathShape:
    return PathShape(start, tuple(segments), width, fill, stroke)


def regular_figure(kind: str) -> tuple[list[PathShape], list[tuple[float, float, float]]]:
    """Return local-coordinate paths and filled circles for upright figures."""
    head = [(0, -213, 30)]
    if kind == "step1":
        paths = [
            shape((-4, -171), q(8, -128, -2, -81)),
            shape((2, -152), q(-32, -130, -51, -94)),
            shape((4, -152), q(32, -151, 51, -180)),
            shape((-2, -81), q(-26, -43, -38, -8)),
            shape((-2, -81), q(25, -42, 36, -8)),
        ]
    elif kind == "step5":
        paths = [
            shape((-3, -170), q(13, -131, 12, -81)),
            shape((2, -150), q(-26, -133, -43, -105)),
            shape((5, -150), q(35, -169, 55, -193)),
            shape((12, -81), q(-16, -51, -38, -8)),
            shape((12, -81), q(36, -65, 43, -45), q(50, -26, 72, -82)),
        ]
    elif kind == "step30":
        paths = [
            shape((-3, -171), q(8, -128, -2, -81)),
            shape((2, -152), q(-32, -130, -51, -94)),
            shape((4, -152), q(24, -169, 24, -198)),
            shape((-2, -81), q(-25, -43, -37, -8)),
            shape((-2, -81), q(25, -42, 37, -8)),
        ]
    elif kind == "step100":
        paths = [
            shape((0, -171), q(1, -127, 0, -82)),
            shape((-19, -157), q(-39, -146, -39, -127), q(-39, -116, -24, -108)),
            shape((19, -157), q(39, -146, 39, -127), q(39, -116, 24, -108)),
            shape((0, -82), q(-25, -45, -34, -8)),
            shape((0, -82), q(25, -45, 34, -8)),
        ]
    else:
        raise ValueError(kind)
    return paths, head


def crawling_figure() -> tuple[list[PathShape], list[tuple[float, float, float]]]:
    paths = [
        shape((-32, -58), c(-7, -75, 19, -76, 45, -62), width=18),
        shape((24, -63), c(48, -73, 68, -83, 99, -82), width=15),
        shape((22, -56), c(47, -64, 70, -78, 91, -82), width=15),
        shape((-25, -57), q(-48, -51, -64, -40), q(-75, -31, -91, -31), width=17),
        shape((-24, -52), q(-42, -37, -47, -21), q(-57, -12, -74, -12), width=17),
    ]
    return paths, [(-55, -71, 23)]


def reaching_figure() -> tuple[list[PathShape], list[tuple[float, float, float]]]:
    paths = [
        shape((-2, -168), q(9, -130, 17, -89)),
        shape((-3, -151), q(24, -170, 55, -145), q(69, -127, 79, -83)),
        shape((4, -151), q(31, -145, 48, -114), q(61, -94, 69, -82)),
        shape((17, -89), q(-8, -66, -30, -42), q(-39, -24, -39, -8)),
        shape((17, -89), q(44, -65, 42, -43), q(28, -20, 21, -8)),
    ]
    return paths, [(2, -205, 29)]


def muscular_figure() -> tuple[list[PathShape], list[tuple[float, float, float]]]:
    neck = shape((-10, -190), l(10, -190), l(10, -162), l(-10, -162), l(-10, -190), fill=INK, stroke="none")
    body = shape(
        (-33, -169),
        c(-50, -160, -48, -143, -41, -124),
        l(-31, -94),
        c(-27, -82, -14, -78, 0, -78),
        c(14, -78, 27, -82, 31, -94),
        l(41, -124),
        c(48, -143, 50, -160, 33, -169),
        c(21, -177, 13, -166, 0, -163),
        c(-13, -166, -21, -177, -33, -169),
        fill=INK,
        stroke="none",
    )
    paths = [
        neck,
        body,
        shape((-28, -162), c(-50, -156, -58, -177, -54, -197), q(-53, -214, -65, -226), width=20),
        shape((28, -162), c(50, -156, 58, -177, 54, -197), q(53, -214, 65, -226), width=20),
        shape((-17, -80), q(-30, -48, -32, -8), width=24),
        shape((17, -80), q(30, -48, 32, -8), width=24),
        shape((-18, -137), q(0, -127, 18, -137), width=4, stroke=DETAIL),
        shape((0, -161), l(0, -135), width=4, stroke=DETAIL),
        shape((-15, -119), q(0, -111, 15, -119), width=4, stroke=DETAIL),
        shape((-13, -103), q(0, -97, 13, -103), width=4, stroke=DETAIL),
    ]
    return paths, [(0, -214, 29), (-65, -230, 11), (65, -230, 11)]


STAGES = [
    {"level": 1, "pose": "step1", "anchor": (356, 674), "scale": 1.0,
     "description": "Steht auf Stufe 1 und blickt nach oben."},
    {"level": 5, "pose": "step5", "anchor": (462, 592), "scale": 0.94,
     "description": "Hat die erste Stufe erklommen und steigt weiter."},
    {"level": 30, "pose": "step30", "anchor": (568, 510), "scale": 0.94,
     "description": "Steht auf Stufe 3 und zeigt nach oben."},
    {"level": 50, "pose": "crawl", "anchor": (605, 510), "scale": 1.0,
     "description": "Zieht sich von Stufe 3 auf Stufe 4."},
    {"level": 100, "pose": "step100", "anchor": (662, 428), "scale": 0.90,
     "description": "Steht motiviert und startklar auf Stufe 4."},
    {"level": 200, "pose": "reach", "anchor": (668, 428), "scale": 0.98,
     "description": "Greift nach der letzten Stufe."},
    {"level": 300, "pose": "muscular", "anchor": (758, 346), "scale": 0.98,
     "description": "Steht kraftvoll auf der letzten Stufe."},
]


def svg_path_data(path: PathShape) -> str:
    x, y = path.start
    parts = [f"M {x:g} {y:g}"]
    for segment in path.segments:
        parts.append(segment.command + " " + " ".join(f"{v:g}" for v in segment.values))
    return " ".join(parts)


def pose_paths(pose: str) -> tuple[list[PathShape], list[tuple[float, float, float]]]:
    if pose == "crawl":
        return crawling_figure()
    if pose == "reach":
        return reaching_figure()
    if pose == "muscular":
        return muscular_figure()
    return regular_figure(pose)


def write_svg(stage: dict) -> None:
    paths, circles = pose_paths(stage["pose"])
    x, y = stage["anchor"]
    scale = stage["scale"]
    elements = []
    for path in paths:
        attributes = [f'd="{svg_path_data(path)}"']
        if path.fill:
            attributes.extend([f'fill="{path.fill}"', 'stroke="none"'])
        else:
            attributes.extend([
                'fill="none"', f'stroke="{path.stroke}"',
                f'stroke-width="{path.width}"',
                'stroke-linecap="round"', 'stroke-linejoin="round"',
            ])
        elements.append("    <path " + " ".join(attributes) + "/>" )
    for cx, cy, radius in circles:
        elements.append(
            f'    <circle cx="{cx:g}" cy="{cy:g}" r="{radius:g}" fill="{INK}"/>'
        )
    if stage["pose"] == "muscular":
        elements.append(
            '    <path d="M 22 -222 Q 32 -218 24 -211 L 19 -212 Z" fill="' + INK + '"/>'
        )
    else:
        elements.append(
            '    <path d="M 22 -221 Q 35 -216 24 -208 Q 20 -208 20 -212 Z" fill="' + INK + '"/>'
        )

    content = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="background" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#FCFDFB"/>
      <stop offset="1" stop-color="#F0F5EC"/>
    </linearGradient>
    <linearGradient id="steps" x1="0" y1="1" x2="1" y2="0">
      <stop offset="0" stop-color="{STEP_DARK}"/>
      <stop offset="1" stop-color="{STEP_LIGHT}"/>
    </linearGradient>
  </defs>
  <rect width="1024" height="1024" rx="224" fill="url(#background)"/>
  <path d="M 238 674 H 428 V 592 H 522 V 510 H 616 V 428 H 710 V 346 H 804"
    fill="none" stroke="url(#steps)" stroke-width="27" stroke-linecap="square" stroke-linejoin="round"/>
  <g transform="translate({x} {y}) scale({scale:g})">
{chr(10).join(elements)}
  </g>
  <text x="512" y="820" text-anchor="middle" fill="{INK}"
    font-family="Inter, Avenir Next, 'Segoe UI', Arial, sans-serif"
    font-size="84" font-weight="400" letter-spacing="1"
    textLength="300" lengthAdjust="spacingAndGlyphs">Kaizen</text>
</svg>
'''
    filename = OUT / f"kaizen_level_{stage['level']:03}_concept.svg"
    filename.write_text(content, encoding="utf-8")


def cubic_points(p0, p1, p2, p3, n=28):
    points = []
    for index in range(1, n + 1):
        t = index / n
        mt = 1 - t
        x = mt**3 * p0[0] + 3 * mt**2 * t * p1[0] + 3 * mt * t**2 * p2[0] + t**3 * p3[0]
        y = mt**3 * p0[1] + 3 * mt**2 * t * p1[1] + 3 * mt * t**2 * p2[1] + t**3 * p3[1]
        points.append((x, y))
    return points


def sampled_points(path: PathShape) -> list[tuple[float, float]]:
    points = [path.start]
    current = path.start
    for segment in path.segments:
        v = segment.values
        if segment.command == "L":
            points.append((v[0], v[1]))
        elif segment.command == "Q":
            cx, cy, x, y = v
            c1 = (current[0] + (2 / 3) * (cx - current[0]), current[1] + (2 / 3) * (cy - current[1]))
            c2 = (x + (2 / 3) * (cx - x), y + (2 / 3) * (cy - y))
            points.extend(cubic_points(current, c1, c2, (x, y)))
        else:
            c1 = (v[0], v[1])
            c2 = (v[2], v[3])
            end = (v[4], v[5])
            points.extend(cubic_points(current, c1, c2, end))
        current = (v[-2], v[-1])
    return points


def transformed(points: Iterable[tuple[float, float]], anchor, scale):
    return [((anchor[0] + x * scale) * SCALE, (anchor[1] + y * scale) * SCALE) for x, y in points]


def draw_path(draw: ImageDraw.ImageDraw, path: PathShape, anchor, scale):
    coords = transformed(sampled_points(path), anchor, scale)
    if path.fill:
        draw.polygon(coords, fill=path.fill)
        return
    width = max(1, round(path.width * scale * SCALE))
    radius = width / 2
    for start, end in zip(coords, coords[1:]):
        draw.line((start, end), fill=path.stroke, width=width)
    for px, py in coords:
        draw.ellipse((px - radius, py - radius, px + radius, py + radius), fill=path.stroke)


def draw_gradient_stairs(draw: ImageDraw.ImageDraw):
    points = [(238, 674), (428, 674), (428, 592), (522, 592), (522, 510),
              (616, 510), (616, 428), (710, 428), (710, 346), (804, 346)]
    for index, (start, end) in enumerate(zip(points, points[1:])):
        t = index / max(1, len(points) - 2)
        color = tuple(round(int(STEP_DARK[i:i+2], 16) * (1-t) + int(STEP_LIGHT[i:i+2], 16) * t)
                      for i in (1, 3, 5))
        ccolor = "#%02x%02x%02x" % color
        scaled = [(x * SCALE, y * SCALE) for x, y in (start, end)]
        width = 27 * SCALE
        draw.line(scaled, fill=ccolor, width=width)
        radius = width / 2
        for px, py in scaled:
            draw.ellipse((px-radius, py-radius, px+radius, py+radius), fill=ccolor)


def render_png(stage: dict) -> Image.Image:
    canvas = Image.new("RGBA", (1024 * SCALE, 1024 * SCALE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((0, 0, 1024 * SCALE - 1, 1024 * SCALE - 1),
                           radius=224 * SCALE, fill=BG)
    draw_gradient_stairs(draw)
    paths, circles = pose_paths(stage["pose"])
    anchor, pose_scale = stage["anchor"], stage["scale"]
    for path in paths:
        draw_path(draw, path, anchor, pose_scale)
    for cx, cy, radius in circles:
        px = (anchor[0] + cx * pose_scale) * SCALE
        py = (anchor[1] + cy * pose_scale) * SCALE
        r = radius * pose_scale * SCALE
        draw.ellipse((px-r, py-r, px+r, py+r), fill=INK)
    if stage["pose"] == "muscular":
        nose = shape((22, -222), q(32, -218, 24, -211), l(19, -212), fill=INK)
    elif stage["pose"] == "crawl":
        nose = shape((-33, -80), q(-23, -75, -32, -69), l(-38, -71), fill=INK)
    else:
        nose = shape((22, -221), q(35, -216, 24, -208), q(20, -208, 20, -212), l(22, -221), fill=INK)
    draw_path(draw, nose, anchor, pose_scale)

    font = ImageFont.truetype(str(FONT_PATH), 84 * SCALE)
    text = "Kaizen"
    bbox = draw.textbbox((0, 0), text, font=font)
    layer = Image.new("RGBA", (bbox[2] - bbox[0] + 12 * SCALE, bbox[3] - bbox[1] + 12 * SCALE), (0, 0, 0, 0))
    text_draw = ImageDraw.Draw(layer)
    text_draw.text((6 * SCALE - bbox[0], 6 * SCALE - bbox[1]), text, font=font, fill=INK)
    layer = layer.crop(layer.getbbox())
    target_width = 300 * SCALE
    target_height = round(layer.height * target_width / layer.width)
    layer = layer.resize((target_width, target_height), Image.Resampling.LANCZOS)
    canvas.alpha_composite(layer, ((1024 * SCALE - target_width) // 2, 750 * SCALE))
    return canvas.resize((1024, 1024), Image.Resampling.LANCZOS)


def make_contact_sheet(previews: list[tuple[dict, Image.Image]]):
    columns, cell_w, cell_h, gap = 4, 360, 420, 22
    rows = (len(previews) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * cell_w + (columns + 1) * gap,
                              rows * cell_h + (rows + 1) * gap), "#F1F4EF")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype(str(FONT_PATH), 27)
    for index, (stage, logo) in enumerate(previews):
        col, row = index % columns, index // columns
        x, y = gap + col * (cell_w + gap), gap + row * (cell_h + gap)
        draw.rounded_rectangle((x, y, x + cell_w, y + cell_h), radius=22, fill="#FFFFFF")
        draw.text((x + 22, y + 15), f"LEVEL {stage['level']}", font=font, fill=INK)
        thumbnail = logo.resize((300, 300), Image.Resampling.LANCZOS)
        sheet.paste(thumbnail, (x + (cell_w - 300) // 2, y + 62), thumbnail)
        desc_font = ImageFont.truetype(str(FONT_PATH), 16)
        words = stage["description"].split()
        lines, line = [], ""
        for word in words:
            candidate = f"{line} {word}".strip()
            if draw.textlength(candidate, font=desc_font) > cell_w - 34:
                lines.append(line)
                line = word
            else:
                line = candidate
        if line:
            lines.append(line)
        for line_idx, text in enumerate(lines[:2]):
            draw.text((x + 17, y + 369 + line_idx * 21), text, font=desc_font, fill="#647267")
    sheet.save(OUT / "kaizen_stage_concepts_overview.png")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    previews = []
    for stage in STAGES:
        write_svg(stage)
        image = render_png(stage)
        image.save(OUT / f"kaizen_level_{stage['level']:03}_concept.png", optimize=True)
        previews.append((stage, image))
    # Keep the original stage-one concept path used in the earlier preview in sync.
    (ROOT / "assets" / "app_icons" / "progress" / "kaizen_stage_1_concept.svg").write_bytes(
        (OUT / "kaizen_level_001_concept.svg").read_bytes()
    )
    (ROOT / "assets" / "app_icons" / "progress" / "kaizen_stage_1_concept.png").write_bytes(
        (OUT / "kaizen_level_001_concept.png").read_bytes()
    )
    make_contact_sheet(previews)
    print(f"Created {len(STAGES)} icon concepts in {OUT}")


if __name__ == "__main__":
    main()
