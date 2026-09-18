class_name MailPresenter
extends Node2D
## The mail currently in front of the player, medium-agnostic: drag-follow physics,
## fly-into-a-folder animation and hit-testing. How it actually looks is up to a
## subclass's _measure()/_draw() -- MailCard for a DullOS 98 window, PaperLetterCard
## for a 60er paper letter. Origin = card center.

const DRAG_SMOOTHING := 28.0

var data: MailData
var card_size := Vector2(470.0, 200.0)
## Animated by the slide-in tween; drag offset is added on top.
var base_position := Vector2.ZERO
var flying := false
## A subclass can set this (e.g. in _measure()) for a fixed per-card tilt, like a
## paper letter's slight skew. Drag rotation is added on top of it every frame.
var base_rotation := 0.0

var _drag_target := Vector2.ZERO
var _drag := Vector2.ZERO
var _time := 0.0


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func setup(mail: MailData, home: Vector2) -> void:
	data = mail
	base_position = home
	position = home
	_measure()
	queue_redraw()


func set_drag(offset: Vector2) -> void:
	_drag_target = offset


func _process(delta: float) -> void:
	_time += delta
	if flying:
		return
	_drag = _drag.lerp(_drag_target, 1.0 - exp(-DRAG_SMOOTHING * delta))
	position = base_position + _drag
	rotation = base_rotation + _drag.x * 0.0009
	if data != null and data.is_boss:
		queue_redraw()


## Tween into a folder, then free.
func fly_to(target: Vector2, duration: float = 0.17) -> void:
	flying = true
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position", target, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2.ONE * 0.12, duration).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, duration).set_delay(duration * 0.6)
	tween.chain().tween_callback(queue_free)


func covers(world_pos: Vector2) -> bool:
	return Rect2(global_position - card_size * 0.5, card_size).has_point(world_pos)


## Overridden by subclasses to size card_size (and cache whatever layout it needs)
## from `data`. Called once from setup().
func _measure() -> void:
	pass
