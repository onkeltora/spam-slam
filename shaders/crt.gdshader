shader_type canvas_item;
// Subtle CRT look for the monitor screen: slight barrel curvature, scanlines,
// a hint of chromatic aberration, vignette and flicker.
// Applied on a ColorRect covering the screen; reads what was drawn below it.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform vec2 rect_size = vec2(880.0, 568.0);        // ColorRect size in canvas pixels
uniform float curvature : hint_range(0.0, 0.2) = 0.025;
// Zooms the sampled picture in slightly so the barrel-warp's corners land back inside
// the source instead of sampling past it (which the "outside" cutoff below would
// otherwise blank to black) -- the same job the old CRT's H-SIZE/V-SIZE knobs did.
uniform float overscan : hint_range(0.0, 0.2) = 0.03;
// Where SCREEN_RECT sits inside this (bulge-grown) rect, as a fraction per axis. The
// drawn content only covers SCREEN_RECT, so the picture is stretched out to fill the
// whole grown rect -- that overshoot is what the bezel then cuts the tube shape from.
uniform vec2 content_inset = vec2(0.0);
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.13;
uniform float scanline_spacing = 3.0;                // canvas pixels per scanline
uniform float aberration_px : hint_range(0.0, 4.0) = 0.7;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.28;
uniform float brightness : hint_range(0.5, 2.5) = 1.1;
// Lifts the picture by the average darkening of the scanlines, so they add texture, not darkness.
uniform bool compensate_scanlines = true;
uniform float flicker : hint_range(0.0, 0.1) = 0.01;

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	vec2 warped = centered + centered * (centered.yx * centered.yx) * curvature;
	vec2 base = warped * (0.5 / (1.0 + overscan)) + 0.5;
	vec2 wuv = mix(content_inset, vec2(1.0) - content_inset, base);

	// Size of this rect in SCREEN_UV units (axis-aligned rect, no rotation).
	vec2 uv_to_screen = vec2(dFdx(SCREEN_UV.x) / dFdx(UV.x), dFdy(SCREEN_UV.y) / dFdy(UV.y));
	vec2 suv = SCREEN_UV + (wuv - UV) * uv_to_screen;
	vec2 px = uv_to_screen / rect_size;  // one canvas pixel in SCREEN_UV

	vec3 col;
	col.r = texture(screen_texture, suv + vec2(px.x * aberration_px, 0.0)).r;
	col.g = texture(screen_texture, suv).g;
	col.b = texture(screen_texture, suv - vec2(px.x * aberration_px, 0.0)).b;

	float line = 0.5 + 0.5 * cos(base.y * rect_size.y / scanline_spacing * 6.28318);
	col *= 1.0 - scanline_strength * line;
	if (compensate_scanlines) {
		col /= 1.0 - scanline_strength * 0.5;
	}

	float vignette = 1.0 - dot(centered, centered) * vignette_strength * 0.5;
	col *= vignette * brightness * (1.0 + flicker * sin(TIME * 110.0));

	float outside = step(0.0, base.x) * step(base.x, 1.0) * step(0.0, base.y) * step(base.y, 1.0);
	COLOR = vec4(col * outside, 1.0);
}
