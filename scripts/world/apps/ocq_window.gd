class_name OcqWindow
extends RetroWindow
## OCQ contact list, docked at the right like a certain flower messenger:
## status flowers, a couple of familiar contacts and this run's messages from the boss.

enum Status { ONLINE, AWAY, OFFLINE }

const SIZE := Vector2(252, 400)  # ends above the OCQ toast area
const UIN := "#1337042"
const ROW_HEIGHT := 22.0
const HISTORY_ENTRIES := 3
const CONTACTS := [
	["SENDER_BOSS", Status.ONLINE],
	["SENDER_KAREN", Status.ONLINE],
	["SENDER_KEVIN", Status.AWAY],
	["SENDER_BERND", Status.OFFLINE],
	["CONTACT_MOM", Status.OFFLINE],
	["SENDER_LORD", Status.OFFLINE],
]
const STATUS_COLORS := {
	Status.ONLINE: Color("3fbf4a"),
	Status.AWAY: Color("f2c14e"),
	Status.OFFLINE: Color("e0453a"),
}

## Shared with AppWindows: [{"goal": int}] or [{"success": bool}], oldest first.
var history: Array[Dictionary] = []


func _init() -> void:
	var desktop := ScreenLayout.DESKTOP_RECT
	window_rect = Rect2(Vector2(desktop.end.x - SIZE.x - 14, desktop.position.y + 18), SIZE)


func get_title() -> String:
	return "OCQ " + UIN


func get_title_colors() -> Array[Color]:
	return [Color("1f6a2a"), Color("5cb85c")]


func draw_title_icon(center: Vector2) -> void:
	AppIcons.draw_flower(self, center, 8.0)


func draw_content(rect: Rect2) -> void:
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x

	# Contact list
	var list := Rect2(x, y, w, 196)
	ScreenLayout.draw_sunken(self, list, Color.WHITE)
	var row_y := list.position.y + 14
	var online := CONTACTS.filter(func(c: Array) -> bool: return c[1] != Status.OFFLINE)
	var offline := CONTACTS.filter(func(c: Array) -> bool: return c[1] == Status.OFFLINE)
	row_y = _draw_group(tr("OCQ_ONLINE"), online, x + 8, row_y)
	row_y = _draw_group(tr("OCQ_OFFLINE"), offline, x + 8, row_y + 4)

	# Boss message history
	var history_rect := Rect2(x, list.end.y + 8, w, rect.end.y - list.end.y - 54)
	ScreenLayout.draw_sunken(self, history_rect, Color("fffbe6"))
	DrawUtil.text_left(self, tr("OCQ_HISTORY"), Vector2(x + 8, history_rect.position.y + 13), 13, Color("1f6a2a"), -1, 1, Color("1f6a2a"))
	var f := DrawUtil.font()
	var entry_y := history_rect.position.y + 30
	if history.is_empty():
		DrawUtil.text_left(self, tr("OCQ_NO_MESSAGES"), Vector2(x + 8, entry_y + 8), 13, Color("8a867a"))
	else:
		var recent := history.slice(maxi(history.size() - HISTORY_ENTRIES, 0))
		recent.reverse()
		for entry in recent:
			var text := tr("SENDER_BOSS") + ": " + _entry_text(entry)
			var h := f.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w - 30, 13).y
			if entry_y + h > history_rect.end.y - 4:
				break
			AppIcons.draw_flower(self, Vector2(x + 13, entry_y + 7), 5.0)
			draw_multiline_string(f, Vector2(x + 22, entry_y + f.get_ascent(13)), text, HORIZONTAL_ALIGNMENT_LEFT,
					w - 30, 13, -1, ScreenLayout.TEXT_DARK)
			entry_y += h + 6

	# Bottom buttons
	var buttons_y := rect.end.y - 38
	var menu := Rect2(x, buttons_y, w * 0.42, 30)
	var status := Rect2(x + w * 0.46, buttons_y, w * 0.54, 30)
	ScreenLayout.draw_raised(self, menu)
	ScreenLayout.draw_raised(self, status)
	DrawUtil.text_centered(self, tr("OCQ_MENU"), menu.get_center(), 14, ScreenLayout.TEXT_DARK, 1, ScreenLayout.TEXT_DARK)
	AppIcons.draw_status_flower(self, Vector2(status.position.x + 16, status.get_center().y), 7.0, STATUS_COLORS[Status.ONLINE])
	DrawUtil.text_left(self, tr("OCQ_ONLINE"), Vector2(status.position.x + 28, status.get_center().y), 14, ScreenLayout.TEXT_DARK)


func _draw_group(title: String, contacts: Array, x: float, y: float) -> float:
	DrawUtil.text_left(self, "▾ %s (%d)" % [title, contacts.size()], Vector2(x, y), 13, Color("1f6a2a"), -1, 1, Color("1f6a2a"))
	y += ROW_HEIGHT
	for contact in contacts:
		var status: Status = contact[1]
		AppIcons.draw_status_flower(self, Vector2(x + 16, y), 7.0, STATUS_COLORS[status])
		var color := Color("8a867a") if status == Status.OFFLINE else ScreenLayout.TEXT_DARK
		var name_text := tr(contact[0])
		DrawUtil.text_left(self, name_text, Vector2(x + 30, y), DrawUtil.fit_size(name_text, 14, SIZE.x - 60), color)
		y += ROW_HEIGHT
	return y


func _entry_text(entry: Dictionary) -> String:
	if entry.has("goal"):
		return tr("BOSS_CHALLENGE").format({"goal": entry.goal})
	return tr("BOSS_SUCCESS") if entry.success else tr("BOSS_FAIL")
