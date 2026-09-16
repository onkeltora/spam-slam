extends Control
## "Der Filter" in a webcam corner. Placeholder face drawn in code that reacts
## live: grin on combos, eye-roll on mistakes, sweat when the inbox piles up.

enum Mood { NEUTRAL, HAPPY, ANNOYED, BOOST, DEFEAT }

const SKIN := Color("e3bd98")
const SHIRT := Color("d9d3b6")
const TIE := Color("8b2d2d")
const HAIR := Color("5a4a3a")

var _mood := Mood.NEUTRAL
var _mood_timer := 0.0
var _time := 0.0
var _blink := 0.0
var _next_blink := 2.5
var _stress := 0.0           # 0..1 from pile height
var _posture := 0.0          # straightens up on streaks
var _glasses_slip := 0.0


func _ready() -> void:
	GameManager.mail_sorted.connect(_on_mail_sorted)
	GameManager.pile_changed.connect(func(count: int, max_count: int) -> void:
		_stress = clampf((float(count) / max_count - 0.45) / 0.45, 0.0, 1.0))
	GameManager.boost_started.connect(func(d: float) -> void: set_mood(Mood.BOOST, d))
	GameManager.game_over.connect(func(_r: String) -> void: set_mood(Mood.DEFEAT, 999.0))
	GameManager.game_started.connect(func() -> void: set_mood(Mood.NEUTRAL, 0.0))


func set_mood(mood: Mood, duration: float) -> void:
	_mood = mood
	_mood_timer = duration


func _on_mail_sorted(result: Dictionary) -> void:
	if _mood == Mood.BOOST:
		return
	if result.correct:
		if GameManager.combo >= 5 and GameManager.combo % 5 == 0:
			set_mood(Mood.HAPPY, 1.2)
		elif _mood == Mood.NEUTRAL:
			set_mood(Mood.HAPPY, 0.35)
	else:
		set_mood(Mood.ANNOYED, 1.1)
		_glasses_slip = 1.0


func _process(delta: float) -> void:
	_time += delta
	if _mood_timer > 0.0:
		_mood_timer -= delta
		if _mood_timer <= 0.0 and _mood != Mood.DEFEAT:
			_mood = Mood.NEUTRAL
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 1.0
		_next_blink = randf_range(1.8, 4.5)
	_blink = move_toward(_blink, 0.0, delta * 8.0)
	var target_posture := clampf(GameManager.combo / 15.0, 0.0, 1.0) if GameManager.running else 0.0
	_posture = lerpf(_posture, target_posture, 1.0 - exp(-3.0 * delta))
	_glasses_slip = move_toward(_glasses_slip, 0.0, delta * 0.8)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	DrawUtil.rounded_rect(self, rect, 8, Color("1e2228"))
	draw_rect(rect.grow(-6), Color("47505a"))

	# Scene clipped roughly by drawing inside the frame
	var c := Vector2(size.x * 0.5, size.y * 0.52 - _posture * 5.0 + sin(_time * 1.6) * 1.2)
	if _mood == Mood.DEFEAT:
		c.y += 10

	# Shirt + tie
	var shoulders := PackedVector2Array([
		Vector2(12, size.y - 6), Vector2(size.x - 12, size.y - 6),
		Vector2(size.x - 26, c.y + 40 - _posture * 4), Vector2(26, c.y + 40 - _posture * 4)])
	draw_colored_polygon(shoulders, SHIRT)
	draw_circle(Vector2(size.x * 0.62, size.y - 22), 5, Color(0.55, 0.4, 0.15, 0.7))  # mustard stain
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-5, 42), c + Vector2(6, 42), c + Vector2(12, 78), c + Vector2(2, 86), c + Vector2(-4, 76)]), TIE)

	# Head
	draw_circle(c + Vector2(-38, 2), 8, SKIN.darkened(0.08))
	draw_circle(c + Vector2(38, 2), 8, SKIN.darkened(0.08))
	draw_circle(c, 38, SKIN)
	# Stubble
	for i in 14:
		var a := PI * (0.15 + 0.7 * i / 13.0)
		draw_circle(c + Vector2(cos(a), sin(a)) * (27.0 + (i % 3) * 2.5), 1.2, Color(0.25, 0.2, 0.15, 0.5))
	# Thin hair
	for i in 5:
		var x := -16.0 + i * 8.0
		draw_arc(c + Vector2(x, -34), 10, PI * 1.1, PI * 1.9, 8, HAIR, 2.0)

	# Eyes
	var eye_y := -6.0
	var bag := Color(0.45, 0.3, 0.35, 0.45)
	for side in [-1, 1]:
		var e := c + Vector2(14 * side, eye_y)
		draw_arc(e + Vector2(0, 8), 7, PI * 0.15, PI * 0.85, 8, bag, 2.0)
		var openness := 1.0 - _blink
		if _mood == Mood.DEFEAT:
			draw_line(e + Vector2(-5, -4), e + Vector2(5, 4), Color.BLACK, 2.5)
			draw_line(e + Vector2(5, -4), e + Vector2(-5, 4), Color.BLACK, 2.5)
			continue
		if openness < 0.3:
			draw_line(e + Vector2(-6, 0), e + Vector2(6, 0), Color.BLACK, 2.0)
			continue
		var eye_r := 8.0 if _mood == Mood.BOOST else 6.5
		draw_circle(e, eye_r, Color.WHITE)
		var pupil := Vector2.ZERO
		match _mood:
			Mood.ANNOYED:
				pupil = Vector2(2 * side, -4)   # eye roll
			Mood.BOOST:
				pupil = Vector2(sin(_time * 30.0) * 1.5, 0)
		draw_circle(e + pupil, 3.2 if _mood != Mood.BOOST else 2.2, Color.BLACK)
		# Brows: inner end lowered when annoyed, raised when happy
		var tilt := 0.0
		match _mood:
			Mood.ANNOYED:
				tilt = 4.0
			Mood.HAPPY:
				tilt = -2.0
		var inner := e + Vector2(-7 * side, -11 + tilt)
		var outer := e + Vector2(7 * side, -11 - tilt * 0.5)
		draw_line(inner, outer, HAIR.darkened(0.3), 3.0)

	# Glasses (slide down after mistakes)
	var slip := Vector2(0, ease(_glasses_slip, 0.5) * 6.0)
	for side in [-1, 1]:
		draw_rect(Rect2(c + Vector2(14 * side - 10, eye_y - 8) + slip, Vector2(20, 16)), Color(0.1, 0.1, 0.1), false, 2.0)
	draw_line(c + Vector2(-4, eye_y - 2) + slip, c + Vector2(4, eye_y - 2) + slip, Color(0.1, 0.1, 0.1), 2.0)

	# Mouth
	var m := c + Vector2(0, 18)
	match _mood:
		Mood.HAPPY:
			draw_arc(m + Vector2(0, -6), 11, PI * 0.15, PI * 0.85, 12, Color(0.3, 0.1, 0.1), 3.0)
		Mood.ANNOYED:
			draw_polyline(PackedVector2Array([m + Vector2(-10, 3), m + Vector2(-4, -1), m + Vector2(2, 3), m + Vector2(9, -1)]), Color(0.3, 0.1, 0.1), 3.0)
		Mood.BOOST:
			draw_circle(m + Vector2(0, 2), 6, Color(0.3, 0.1, 0.1))
		Mood.DEFEAT:
			draw_arc(m + Vector2(0, 10), 10, PI * 1.15, PI * 1.85, 12, Color(0.3, 0.1, 0.1), 3.0)
		_:
			draw_line(m + Vector2(-9, 1), m + Vector2(9, 0), Color(0.3, 0.1, 0.1), 3.0)

	# Sweat drops when the inbox piles up
	if _stress > 0.0 or _mood == Mood.DEFEAT:
		var s := 1.0 if _mood == Mood.DEFEAT else _stress
		for i in 2:
			var drip := fmod(_time * (0.8 + i * 0.3) + i * 0.5, 1.0)
			var p := c + Vector2(30 - i * 58, -20 + drip * 26)
			var drop := PackedVector2Array([p + Vector2(0, -7), p + Vector2(4, 1), p + Vector2(0, 5), p + Vector2(-4, 1)])
			draw_colored_polygon(drop, Color(0.55, 0.8, 1.0, s * (1.0 - drip * 0.6)))

	# Webcam chrome
	var rec_on := fmod(_time, 1.2) < 0.7
	draw_circle(Vector2(18, 16), 5, Color(1, 0.15, 0.1, 1.0 if rec_on else 0.3))
	DrawUtil.text_left(self, "REC", Vector2(28, 16), 12, Color(1, 1, 1, 0.8))
	DrawUtil.rounded_frame(self, rect, 8, Color("101215"), 4)
