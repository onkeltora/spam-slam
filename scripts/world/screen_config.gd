@tool
class_name ScreenConfig
extends Resource
## Every number that shapes the CRT and places the furniture that has to line up with
## it, in one Inspector-editable place (resources/screen_config.tres -- click it in the
## FileSystem dock).
##
## It's one resource on purpose: the tube face is drawn TWICE, once as the CRT
## ColorRect + shader (crt_effect.gd) and once as the hole the casing cuts
## (monitor_bezel.gd). They only line up while they read the same numbers, so they read
## these. Changing a value here moves both at once.

@export_group("Tube face")
## How far the corners of the picture are cut back.
@export_range(0.0, 150.0, 1.0) var corner_radius := 42.0
## How far the picture bows out past SCREEN_RECT at the left/right edge midpoints.
@export_range(0.0, 60.0, 1.0) var bulge_horizontal := 14.0
## Same for the top/bottom edge midpoints.
@export_range(0.0, 60.0, 1.0) var bulge_vertical := 14.0

@export_group("Casing")
## Off = the old flat-edged, square-cornered casing.
@export var curved_casing := true
@export_range(0.0, 100.0, 1.0) var casing_corner_radius := 30.0
@export_range(0.0, 40.0, 1.0) var casing_bulge := 10.0

@export_group("Taskbar")
## Shifts the whole bar off its default spot at the bottom of SCREEN_RECT. Negative y
## lifts it clear of the tube's bottom corners.
@export var taskbar_offset := Vector2(0, -30)
## Start button, relative to the bar's left end.
@export var start_button_offset := Vector2(30, 0)
## Tray (OCQ flower, WhipAmp bars, clock), relative to the bar's right end.
@export var tray_offset := Vector2(-30, 0)
## The clock alone, on top of tray_offset.
@export var clock_offset := Vector2(0, 0)


## Per-axis bulge as one vector: x bows the left/right edges, y the top/bottom ones.
func tube_bulge() -> Vector2:
	return Vector2(bulge_horizontal, bulge_vertical)


func casing_bulge_vec() -> Vector2:
	return Vector2(casing_bulge, casing_bulge) if curved_casing else Vector2.ZERO
