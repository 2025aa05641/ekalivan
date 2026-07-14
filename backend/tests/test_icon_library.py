"""Unit tests for the programmatically drawn storyboard icon library."""

import pytest
from PIL import Image

from app.features.video_generator import icon_library


@pytest.mark.parametrize(
    ("visual_prompt", "expected_key"),
    [
        ("A bright sun shining down on the field.", "sun"),
        ("A single water droplet falling from a leaf.", "water_drop"),
        ("Close-up of a green leaf with visible veins.", "leaf"),
        ("A small plant growing in a pot.", "plant"),
        ("A plate of biryani cooking on the stove.", "food"),
        ("Smoke rising from a factory chimney.", "factory"),
        ("An arrow pointing between two ideas.", "arrow"),
        ("A completely unrelated abstract description.", "star"),
    ],
)
def test_select_icon_key_matches_expected_keywords(visual_prompt: str, expected_key: str) -> None:
    """Each icon key is chosen from prompt text via its associated keywords."""
    assert icon_library.select_icon_key(visual_prompt) == expected_key


def test_select_icon_key_is_case_insensitive() -> None:
    """Keyword matching does not depend on the casing of the prompt text."""
    assert icon_library.select_icon_key("A SUNBEAM shining brightly.") == "sun"


@pytest.mark.parametrize(
    ("visual_prompt", "expected"),
    [
        ("Draw an arrow from the sun to the leaf.", True),
        ("A plant absorbing sunlight.", False),
    ],
)
def test_should_show_arrow_overlay(visual_prompt: str, expected: bool) -> None:
    """The arrow overlay is only requested when the prompt explicitly mentions one."""
    assert icon_library.should_show_arrow_overlay(visual_prompt) is expected


@pytest.mark.parametrize("key", ["sun", "water_drop", "leaf", "plant", "food", "factory", "arrow", "star"])
def test_render_icon_produces_a_transparent_square_image(key: str) -> None:
    """Every known icon key renders a correctly sized RGBA canvas."""
    image = icon_library.render_icon(key, 200)

    assert image.mode == "RGBA"
    assert image.size == (200, 200)


def test_render_icon_falls_back_to_star_for_an_unknown_key() -> None:
    """An unrecognized key still renders (the generic star), rather than raising."""
    image = icon_library.render_icon("not-a-real-key", 150)

    assert image.size == (150, 150)


def test_render_highlight_produces_a_transparent_square_glow() -> None:
    """The highlight glow renders at the requested size with a transparent background."""
    image = icon_library.render_highlight(120)

    assert image.mode == "RGBA"
    assert image.size == (120, 120)
    # The canvas corner is outside the glow and should remain fully transparent.
    assert image.getpixel((0, 0))[3] == 0


def test_render_arrow_overlay_produces_a_transparent_full_frame_image() -> None:
    """The arrow overlay renders at the requested frame size."""
    image = icon_library.render_arrow_overlay(320, 240)

    assert isinstance(image, Image.Image)
    assert image.mode == "RGBA"
    assert image.size == (320, 240)
