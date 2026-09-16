extends Control
## Big centered slam-in announcements: NEW RULE!, REORG!, CAFFEINE BOOST!

const SLAM_TIME := 0.16
const HOLD_TIME := 1.0
const FADE_TIME := 0.3

var _title := ""
var _subtitle := ""
var _color := Color.WHITE
var _t := -1.0


func announce(title: String, subtitle: String, color: Color) -> void:
	_title = title
	_subtitle = subtitle
	_color = color
	_t = 0.0


func _process(delta: float) -> void:
	if _t < 0.0:
		return
	_t += delta
	if _t > SLAM_TIME + HOLD_TIME + FADE_TIME:
		_t = -1.0
	queue_redraw()


func _draw() -> void:
	if _t < 0.0:
		return
	var slam := clampf(_t / SLAM_TIME, 0.0, 1.0)
	var scale_factor := lerpf(2.4, 1.0, ease(slam, 0.35))
	var alpha := 1.0 - clampf((_t - SLAM_TIME - HOLD_TIME) / FADE_TIME, 0.0, 1.0)
	var center := size * Vector2(0.5, 0.47)

	# Dark band behind the text for readability
	var band_h := 150.0
	draw_rect(Rect2(0, center.y - band_h * 0.5, size.x, band_h), Color(0, 0, 0, 0.55 * alpha))
	draw_rect(Rect2(0, center.y - band_h * 0.5, size.x, 4), Color(_color, alpha))
	draw_rect(Rect2(0, center.y + band_h * 0.5 - 4, size.x, 4), Color(_color, alpha))

	draw_set_transform(center, randf_range(-0.02, 0.02) * (1.0 - slam), Vector2.ONE * scale_factor)
	DrawUtil.text_centered(self, _title, Vector2(0, -24), 58, Color(_color.lightened(0.2), alpha), 12, Color(0, 0, 0, alpha))
	draw_set_transform(center)
	if _subtitle != "":
		var sub_size := DrawUtil.fit_size(_subtitle, 30, size.x - 80)
		DrawUtil.text_centered(self, _subtitle, Vector2(0, 38), sub_size, Color(1, 1, 1, alpha), 6, Color(0, 0, 0, alpha))
	draw_set_transform(Vector2.ZERO)
