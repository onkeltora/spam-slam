@tool
extends ColorRect
## Places the CRT shader exactly over the monitor screen and exposes its look in the inspector
## (select World/CRT in main.tscn – changes show up live in the editor).
## Switch off via `enabled` (e.g. for low-end devices) – the game stays fully readable.

@export var enabled := true:
	set(value):
		enabled = value
		visible = value

@export_group("Look")
## Overall brightness of the screen picture.
@export_range(0.5, 2.5, 0.01) var brightness := 1.1:
	set(value):
		brightness = value
		_apply()
## Brighten the picture by the scanlines' average darkening (keeps the look, not the dimming).
@export var compensate_scanlines := true:
	set(value):
		compensate_scanlines = value
		_apply()
@export_range(0.0, 1.0, 0.01) var scanline_strength := 0.13:
	set(value):
		scanline_strength = value
		_apply()
## Canvas pixels per scanline.
@export_range(2.0, 8.0, 0.5) var scanline_spacing := 3.0:
	set(value):
		scanline_spacing = value
		_apply()
## Darkening towards the screen edges.
@export_range(0.0, 1.0, 0.01) var vignette_strength := 0.28:
	set(value):
		vignette_strength = value
		_apply()
@export_range(0.0, 0.2, 0.005) var curvature := 0.025:
	set(value):
		curvature = value
		_apply()
## Zooms the picture in slightly so the barrel-warp doesn't cut black corners/edges --
## the old CRT "H-SIZE/V-SIZE" knob. Raise this if curvature is raised too.
@export_range(0.0, 0.2, 0.005) var overscan := 0.03:
	set(value):
		overscan = value
		_apply()
## Red/blue color fringing in canvas pixels.
@export_range(0.0, 4.0, 0.1) var aberration_px := 0.7:
	set(value):
		aberration_px = value
		_apply()
@export_range(0.0, 0.1, 0.005) var flicker := 0.01:
	set(value):
		flicker = value
		_apply()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Covers the bulge-grown tube rect, not just SCREEN_RECT -- the picture has to reach
	# past the screen rect for the bezel to cut a bulged tube face out of it.
	position = ScreenLayout.tube_rect().position
	size = ScreenLayout.tube_rect().size
	visible = enabled
	_apply()


func _apply() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	var tube := ScreenLayout.tube_rect()
	shader_material.set_shader_parameter("rect_size", tube.size)
	shader_material.set_shader_parameter("content_inset", ScreenLayout.config().tube_bulge() / tube.size)
	shader_material.set_shader_parameter("brightness", brightness)
	shader_material.set_shader_parameter("compensate_scanlines", compensate_scanlines)
	shader_material.set_shader_parameter("scanline_strength", scanline_strength)
	shader_material.set_shader_parameter("scanline_spacing", scanline_spacing)
	shader_material.set_shader_parameter("vignette_strength", vignette_strength)
	shader_material.set_shader_parameter("curvature", curvature)
	shader_material.set_shader_parameter("overscan", overscan)
	shader_material.set_shader_parameter("aberration_px", aberration_px)
	shader_material.set_shader_parameter("flicker", flicker)
