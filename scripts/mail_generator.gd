class_name MailGenerator
extends RefCounted
## Rolls random mails. While a rule is active, a share of mails is forced to
## match it (so the rule matters) and another share is a deliberate near-miss.

const RULE_MATCH_CHANCE := 0.4
const NEAR_MISS_CHANCE := 0.15
## Weights in SenderKind order: COMPANY, NEWSLETTER, STRANGER, SECURITY
const KIND_WEIGHTS := [30.0, 25.0, 25.0, 20.0]

const K := MailData.SenderKind


func generate(rule: SortRule) -> MailData:
	var mail := MailData.new()
	var roll := randf()
	if rule != null and roll < RULE_MATCH_CHANCE:
		# Prefer senders whose base basket differs from the rule target,
		# otherwise the rule would not change anything.
		mail.set_kind(_random_kind(rule.target))
		_add_noise(mail)
		rule.make_match(mail)
	elif rule != null and roll < RULE_MATCH_CHANCE + NEAR_MISS_CHANCE:
		mail.set_kind(_random_kind())
		_add_noise(mail)
		rule.make_near_miss(mail)
	else:
		mail.set_kind(_random_kind())
		_add_noise(mail)
	return mail


func generate_boss() -> MailData:
	var mail := MailData.new()
	mail.set_kind(K.COMPANY)
	mail.is_boss = true
	return mail


func _random_kind(avoid_base: int = -1) -> MailData.SenderKind:
	var weights: Array = KIND_WEIGHTS.duplicate()
	if avoid_base >= 0:
		for kind in MailData.BASE_CATEGORY:
			if MailData.BASE_CATEGORY[kind] == avoid_base:
				weights[kind] = 0.0
	var total := 0.0
	for w in weights:
		total += w
	var pick := randf() * total
	for i in weights.size():
		pick -= weights[i]
		if pick <= 0.0:
			return i as MailData.SenderKind
	return K.COMPANY


## Background features that appear regardless of the active rule,
## so the player has to actually read instead of reacting to any oddity.
func _add_noise(mail: MailData) -> void:
	var kind := mail.kind
	var loud := kind == K.STRANGER or kind == K.NEWSLETTER

	mail.caps = randf() < (0.18 if kind == K.STRANGER else 0.06)

	var r := randf()
	if loud:
		mail.set_smiley_count(0 if r < 0.55 else 1 if r < 0.77 else 2 if r < 0.91 else randi_range(3, 4))
	else:
		mail.set_smiley_count(0 if r < 0.8 else 1 if r < 0.93 else 2 if r < 0.98 else 3)

	var is_catfacts := kind == K.NEWSLETTER and mail.sender_index == 1
	mail.has_cat = randf() < (0.35 if is_catfacts else 0.04)

	if randf() < (0.2 if kind == K.NEWSLETTER else 0.05):
		mail.exclusive = true
	elif randf() < (0.22 if kind == K.SECURITY else 0.07):
		mail.urgent = true

	mail.set_digits_in_address(randf() < (0.15 if kind == K.STRANGER else 0.05))
	mail.biz_domain = randf() < (0.12 if kind == K.STRANGER else 0.04)
	mail.no_subject = randf() < 0.03

	if randf() < (0.3 if kind == K.COMPANY else 0.12):
		var e := randf()
		mail.attachment_ext = "pdf" if e < 0.4 else "doc" if e < 0.7 else "zip" if e < 0.88 else "exe"
	if kind != K.SECURITY:
		mail.has_link = randf() < (0.06 if kind == K.COMPANY else 0.2)
	if randf() < (0.15 if kind == K.STRANGER or kind == K.SECURITY else 0.06):
		mail.amount = randi_range(1, 160) * 25

	# Keep cards readable: at most two extra lines from noise alone.
	var extras := int(mail.attachment_ext != "") + int(mail.has_link) + int(mail.amount > 0)
	if extras > 2:
		mail.amount = 0
