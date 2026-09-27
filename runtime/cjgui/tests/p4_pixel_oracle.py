"""Small scalar reference for P4 isolated-group pixel expectations.

This module deliberately has no dependency on CJGUI scene parsing, Metal, or a
shader implementation. Colors use straight (unassociated) sRGB components in
0..1. Compositing is evaluated in those component values, matching the P4
contract; this is not a linear-light reference.
"""

from __future__ import annotations

import math
from typing import Iterable, Literal


Color = tuple[float, float, float, float]
BlendMode = Literal["normal", "multiply"]
TRANSPARENT: Color = (0.0, 0.0, 0.0, 0.0)


def _check_color(color: Color) -> None:
    if len(color) != 4 or any(not math.isfinite(c) or c < 0.0 or c > 1.0 for c in color):
        raise ValueError("RGBA components must be finite values in 0..1")


def scale_alpha(color: Color, factor: float) -> Color:
    """Scale premultiplied contribution while retaining straight RGB."""
    _check_color(color)
    if not math.isfinite(factor) or factor < 0.0 or factor > 1.0:
        raise ValueError("alpha factor must be finite and in 0..1")
    return (color[0], color[1], color[2], color[3] * factor)


def over(source: Color, backdrop: Color, mode: BlendMode = "normal") -> Color:
    """Composite a straight-alpha source over a straight-alpha backdrop.

    Implements the W3C source-over blend equation. `multiply` changes only the
    overlap blend function; alpha and non-overlap contributions remain the
    source-over values.
    """
    _check_color(source)
    _check_color(backdrop)
    if mode not in ("normal", "multiply"):
        raise ValueError(f"unsupported blend mode: {mode}")

    sa, ba = source[3], backdrop[3]
    out_a = sa + ba * (1.0 - sa)
    if out_a == 0.0:
        return TRANSPARENT

    channels: list[float] = []
    for sc, bc in zip(source[:3], backdrop[:3]):
        blend = sc if mode == "normal" else sc * bc
        premul = sa * (1.0 - ba) * sc + sa * ba * blend + (1.0 - sa) * ba * bc
        channels.append(premul / out_a)
    return (channels[0], channels[1], channels[2], out_a)


def isolated_group(
    children: Iterable[Color],
    backdrop: Color,
    *,
    opacity: float = 1.0,
    mask_alpha: float = 1.0,
    mode: BlendMode = "normal",
) -> Color:
    """Paint children in order to transparent, then apply group effects once."""
    for name, factor in (("opacity", opacity), ("mask alpha", mask_alpha)):
        if not math.isfinite(factor) or factor < 0.0 or factor > 1.0:
            raise ValueError(f"{name} must be finite and in 0..1")
    group = TRANSPARENT
    for child in children:
        group = over(child, group)
    group = scale_alpha(group, opacity * mask_alpha)
    return over(group, backdrop, mode)
