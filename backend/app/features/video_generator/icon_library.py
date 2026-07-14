"""Programmatically drawn vector-style icons selected from storyboard visual prompts.

No external icon assets or image-generation API are used: every icon is drawn
with plain PIL primitives, so the pipeline stays fully offline and
license-free while still giving each scene a concrete illustration instead of
a plain caption card.
"""

import math
from collections.abc import Callable

from PIL import Image, ImageDraw

_KEYWORD_ICON_MAP: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("sun", ("sun", "sunlight", "sunbeam", "sunray", "light")),
    ("water_drop", ("water", "droplet", "rain")),
    ("leaf", ("leaf", "leaves")),
    ("plant", ("plant", "tree", "grow", "root")),
    ("food", ("food", "plate", "eat", "meal", "biryani", "paratha", "kitchen", "cook", "stove", "chulha", "gas")),
    ("factory", ("factory", "industrial", "energy")),
    ("arrow", ("arrow",)),
)
_DEFAULT_ICON_KEY = "star"


def select_icon_key(visual_prompt: str) -> str:
    """Pick the icon key whose keywords best match ``visual_prompt``.

    Args:
        visual_prompt: Storyboard beat's scene description.

    Returns:
        A key accepted by ``render_icon``. Falls back to a generic star icon
        when no keyword matches.
    """
    lowered = visual_prompt.lower()
    for key, keywords in _KEYWORD_ICON_MAP:
        if any(keyword in lowered for keyword in keywords):
            return key
    return _DEFAULT_ICON_KEY


def should_show_arrow_overlay(visual_prompt: str) -> bool:
    """Return whether ``visual_prompt`` calls for a connecting-arrow overlay.

    Args:
        visual_prompt: Storyboard beat's scene description.

    Returns:
        ``True`` if the prompt explicitly describes an arrow.
    """
    return "arrow" in visual_prompt.lower()


def render_icon(key: str, size: int) -> Image.Image:
    """Draw the icon for ``key`` onto a transparent square canvas.

    Args:
        key: One of the keys returned by ``select_icon_key``.
        size: Width and height of the square canvas, in pixels.

    Returns:
        An RGBA image with a transparent background.
    """
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    _ICON_DRAWERS.get(key, _draw_star)(draw, size)
    return canvas


def render_highlight(size: int) -> Image.Image:
    """Draw a soft radial glow used to draw attention behind an icon.

    Args:
        size: Width and height of the square canvas, in pixels.

    Returns:
        An RGBA image with a transparent background and a soft-edged glow.
    """
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    center = size // 2
    steps = 40
    for step in range(steps, 0, -1):
        radius = int(center * step / steps)
        alpha = int(15 + 60 * (1 - step / steps))
        draw.ellipse([center - radius, center - radius, center + radius, center + radius], fill=(255, 235, 150, alpha))
    return canvas


def render_arrow_overlay(width: int, height: int) -> Image.Image:
    """Draw one diagonal connecting arrow across a full-frame transparent canvas.

    Args:
        width: Canvas width in pixels.
        height: Canvas height in pixels.

    Returns:
        An RGBA image with a transparent background.
    """
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    start = (int(width * 0.2), int(height * 0.75))
    end = (int(width * 0.8), int(height * 0.3))
    color = (255, 215, 0, 230)
    draw.line([start, end], fill=color, width=8)
    _draw_arrowhead(draw, start, end, color)
    return canvas


def _draw_arrowhead(
    draw: ImageDraw.ImageDraw, start: tuple[int, int], end: tuple[int, int], color: tuple[int, int, int, int]
) -> None:
    """Draw a triangular arrowhead at ``end``, pointing away from ``start``."""
    angle = math.atan2(end[1] - start[1], end[0] - start[0])
    head_length = 30
    head_angle = math.radians(28)
    left = (end[0] - head_length * math.cos(angle - head_angle), end[1] - head_length * math.sin(angle - head_angle))
    right = (end[0] - head_length * math.cos(angle + head_angle), end[1] - head_length * math.sin(angle + head_angle))
    draw.polygon([end, left, right], fill=color)


def _draw_sun(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Draw a sun: a filled circle with eight radiating rays."""
    center = size // 2
    radius = size // 4
    color = (255, 193, 7, 255)
    draw.ellipse([center - radius, center - radius, center + radius, center + radius], fill=color)
    for i in range(8):
        angle = math.pi * i / 4
        inner, outer = radius + 8, radius + 28
        start = (center + inner * math.cos(angle), center + inner * math.sin(angle))
        end = (center + outer * math.cos(angle), center + outer * math.sin(angle))
        draw.line([start, end], fill=color, width=6)


def _draw_water_drop(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Draw a single water droplet: a pointed cap tapering into a circular base.

    The triangular cap's base is drawn exactly at the circle's equator (its
    widest point), so the two shapes meet edge-to-edge with no visible seam.
    """
    center_x = size // 2
    radius = size // 4
    circle_center_y = size * 5 // 8
    tip_y = circle_center_y - radius * 2
    color = (33, 150, 243, 255)
    draw.polygon(
        [(center_x, tip_y), (center_x - radius, circle_center_y), (center_x + radius, circle_center_y)],
        fill=color,
    )
    draw.ellipse([center_x - radius, circle_center_y - radius, center_x + radius, circle_center_y + radius], fill=color)


def _draw_leaf(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Draw a single curved leaf with a center vein."""
    margin = size // 6
    draw.pieslice([margin, margin, size - margin, size - margin], start=200, end=340, fill=(76, 175, 80, 255))
    draw.line([(margin + 10, size - margin - 10), (size - margin - 10, margin + 10)], fill=(56, 142, 60, 255), width=5)


def _draw_plant(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Draw a potted plant with a stem and two leaves."""
    center = size // 2
    pot_top = size * 2 // 3
    draw.polygon(
        [
            (center - size // 6, pot_top),
            (center + size // 6, pot_top),
            (center + size // 8, size - size // 8),
            (center - size // 8, size - size // 8),
        ],
        fill=(121, 85, 72, 255),
    )
    draw.line([(center, pot_top), (center, size // 6)], fill=(56, 142, 60, 255), width=6)
    draw.ellipse([center - size // 5, size // 6, center, size // 6 + size // 4], fill=(76, 175, 80, 255))
    draw.ellipse([center, size // 5, center + size // 5, size // 5 + size // 4], fill=(76, 175, 80, 255))


def _draw_food(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Draw a plate with food on it."""
    margin = size // 8
    draw.ellipse([margin, margin, size - margin, size - margin], outline=(255, 255, 255, 255), width=6)
    inner = size // 4
    draw.ellipse([inner, inner, size - inner, size - inner], fill=(255, 152, 0, 255))


def _draw_factory(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Draw a simple factory building with two chimneys."""
    base_top = size // 2
    color = (96, 125, 139, 255)
    draw.rectangle([size // 6, base_top, size * 5 // 6, size - size // 8], fill=color)
    draw.rectangle([size // 6 + 10, base_top - size // 4, size // 6 + 40, base_top], fill=color)
    draw.rectangle([size // 6 + 60, base_top - size // 3, size // 6 + 90, base_top], fill=color)


def _draw_arrow(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Draw a single horizontal arrow used as its own standalone icon."""
    y = size // 2
    color = (255, 152, 0, 255)
    start, end = (size // 5, y), (size * 4 // 5, y)
    draw.line([start, end], fill=color, width=10)
    _draw_arrowhead(draw, start, end, color)


def _draw_star(draw: ImageDraw.ImageDraw, size: int) -> None:
    """Draw a five-point star, used as the generic fallback icon."""
    center = size // 2
    outer_radius, inner_radius = size * 0.4, size * 0.4 * 0.4
    points: list[tuple[float, float]] = []
    for i in range(10):
        radius = outer_radius if i % 2 == 0 else inner_radius
        angle = math.pi / 5 * i - math.pi / 2
        points.append((center + radius * math.cos(angle), center + radius * math.sin(angle)))
    draw.polygon(points, fill=(255, 202, 40, 255))


_ICON_DRAWERS: dict[str, Callable[[ImageDraw.ImageDraw, int], None]] = {
    "sun": _draw_sun,
    "water_drop": _draw_water_drop,
    "leaf": _draw_leaf,
    "plant": _draw_plant,
    "food": _draw_food,
    "factory": _draw_factory,
    "arrow": _draw_arrow,
    "star": _draw_star,
}
