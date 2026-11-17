from pathlib import Path
from PIL import Image, ImageChops, ImageFilter
import numpy as np

source = Path(r'C:\Users\janjk\.codex\visualizations\2026\10\20\01a15889-8a9c-7c43-bc5a-1e48da6da409\male_mannequin_preview.png')
out = Path(__file__).with_name('male_mannequin_3d_embossed.png')
image = Image.open(source).convert('RGBA')
width, height = image.size
rgb = np.asarray(image.convert('RGB'), dtype=np.float32)
luma = rgb[..., 0] * .2126 + rgb[..., 1] * .7152 + rgb[..., 2] * .0722

# Isolate the two rendered figures while leaving the card, captions, and frame intact.
y, x = np.mgrid[0:height, 0:width]
combined = Image.new('L', (width, height), 0)
figure_masks = []
for center_x, left, right in [(555, 280, 825), (1110, 835, 1400)]:
    roi = (x >= left) & (x <= right) & (y >= 245) & (y <= 1170)
    mask = (luma > 82) & roi
    mask_img = Image.fromarray((mask * 255).astype('uint8'))
    figure_masks.append((center_x, mask_img))
    combined = ImageChops.lighter(combined, mask_img)

# A soft, offset contact shadow adds real depth against the dark stage.
expanded = combined.filter(ImageFilter.MaxFilter(17))
shadow = ImageChops.offset(expanded, 10, 13)
shadow = ImageChops.subtract(shadow, combined).filter(ImageFilter.GaussianBlur(8))
shadow_overlay = Image.new('RGBA', (width, height), (1, 4, 3, 0))
shadow_overlay.putalpha(shadow.point(lambda a: int(a * .52)))
image = Image.alpha_composite(image, shadow_overlay)

# Directional studio shading across each silhouette: bright upper-left planes,
# quieter midtones, and cooler shadows toward the outer and lower edges.
shade = np.ones((height, width), dtype=np.float32)
for center_x, mask_img in figure_masks:
    left, right = ((280, 825) if center_x < 800 else (835, 1400))
    local_x = (x - center_x) / ((right - left) * .5)
    vertical = (y - 245) / 925.0
    field = 0.94 - .14 * np.maximum(local_x, 0) - .11 * np.maximum(-local_x, 0)
    field += .07 * (1 - np.clip(vertical, 0, 1)) - .09 * np.clip(vertical, 0, 1)
    field -= .10 * np.clip(np.abs(local_x) - .55, 0, 1) ** 1.3
    # Soft specular bounce on upper torso and shoulders.
    chest_glint = np.exp(-(((x - (center_x - 40)) / 115) ** 2 + ((y - 500) / 175) ** 2) * 1.4)
    field += .05 * chest_glint
    mask_array = np.asarray(mask_img) > 0
    shade[mask_array] = field[mask_array]

shaded = np.clip(rgb * shade[..., None], 0, 255).astype('uint8')
shaded_layer = Image.fromarray(shaded, 'RGB').convert('RGBA')
shaded_layer.putalpha(combined)
image = Image.alpha_composite(image, shaded_layer)

# Small sculpted bevels around each muscle plane: soft light on the upper-left
# edge and a restrained recessed shadow on the lower-right.
for _, mask_img in figure_masks:
    mask_img = mask_img.filter(ImageFilter.GaussianBlur(.35))
    top_left = ImageChops.subtract(mask_img, ImageChops.offset(mask_img, 7, 8))
    bottom_right = ImageChops.subtract(mask_img, ImageChops.offset(mask_img, -7, -8))
    top_left = top_left.filter(ImageFilter.GaussianBlur(1.15))
    bottom_right = bottom_right.filter(ImageFilter.GaussianBlur(1.45))
    hi = Image.new('RGBA', (width, height), (243, 255, 230, 0))
    hi.putalpha(top_left.point(lambda a: int(a * .15)))
    lo = Image.new('RGBA', (width, height), (5, 11, 9, 0))
    lo.putalpha(bottom_right.point(lambda a: int(a * .21)))
    image = Image.alpha_composite(image, lo)
    image = Image.alpha_composite(image, hi)

image.convert('RGB').save(out, quality=95)
print(f'Saved: {out} ({image.width}x{image.height})')

