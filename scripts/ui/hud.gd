extends CanvasLayer
## HUD root. Most widgets listen to GameManager themselves; this script only
## handles cross-widget moments (announcements, damage flash).

@onready var announcer: Control = %Announcer
@onready var flash_rect: ColorRect = %FlashRect
@onready var rule_banner: Control = %RuleBanner


func _ready() -> void:
	GameManager.rule_changed.connect(_on_rule_changed)
	GameManager.baskets_swapped.connect(func(_a: int, _b: int) -> void:
		announcer.announce(tr("HUD_REORG_TITLE"), tr("HUD_REORG_TEXT"), Color("ff8a3d"))
		rule_banner.pulse())
	GameManager.boost_started.connect(func(_d: float) -> void:
		announcer.announce(tr("HUD_BOOST"), tr("HUD_BOOST_TEXT"), Color("c47a2c"))
		flash(Color(1.0, 0.7, 0.3), 0.35))
	GameManager.mail_sorted.connect(func(result: Dictionary) -> void:
		if not result.correct:
			flash(Color(1, 0.1, 0.05), 0.4))


func _on_rule_changed(rule: SortRule) -> void:
	if rule == null:
		return
	announcer.announce(tr("HUD_NEW_RULE"), rule.get_text(), MailData.CATEGORY_COLORS[rule.target])
	GameManager.screen_shake.emit(6.0)


func flash(color: Color, strength: float) -> void:
	flash_rect.color = Color(color, strength)
	create_tween().tween_property(flash_rect, "color:a", 0.0, 0.35)
