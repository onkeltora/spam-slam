class_name SortRule
extends Resource
## A special rule that overrides the base rule (sender kind) while active.
## Self-contained: each condition knows how to test a mail AND how to produce
## matching mails and near-misses, so the generator can make the rule relevant.
##
## New rule = new Condition entry + one case in matches/make_match/make_near_miss
## + a COND_ key in localization/strings.csv + an entry in RulePool.

enum Condition {
	CAPS,
	DIGITS_IN_ADDRESS,
	MANY_SMILEYS,
	EXE_ATTACHMENT,
	BIZ_DOMAIN,
	EXCLUSIVE,
	URGENT,
	BIG_AMOUNT,
	CAT,
	COMPANY_LINK,
	NEWSLETTER_ATTACHMENT,
	NO_SUBJECT,
	FROM_HR,
	CORP_SECURITY,
}

const CONDITION_KEYS := {
	Condition.CAPS: "COND_CAPS",
	Condition.DIGITS_IN_ADDRESS: "COND_DIGITS",
	Condition.MANY_SMILEYS: "COND_SMILEYS",
	Condition.EXE_ATTACHMENT: "COND_EXE",
	Condition.BIZ_DOMAIN: "COND_BIZ",
	Condition.EXCLUSIVE: "COND_EXCLUSIVE",
	Condition.URGENT: "COND_URGENT",
	Condition.BIG_AMOUNT: "COND_AMOUNT",
	Condition.CAT: "COND_CAT",
	Condition.COMPANY_LINK: "COND_COMPANY_LINK",
	Condition.NEWSLETTER_ATTACHMENT: "COND_NEWS_ATTACH",
	Condition.NO_SUBJECT: "COND_NO_SUBJECT",
	Condition.FROM_HR: "COND_HR",
	Condition.CORP_SECURITY: "COND_CORP_SECURITY",
}

const MANY_SMILEYS_THRESHOLD := 3
const BIG_AMOUNT_THRESHOLD := 1000

@export var condition: Condition = Condition.CAPS
@export var target: MailData.Category = MailData.Category.SPAM


static func create(p_condition: Condition, p_target: MailData.Category) -> SortRule:
	var rule := SortRule.new()
	rule.condition = p_condition
	rule.target = p_target
	return rule


func get_condition_text() -> String:
	return tr(CONDITION_KEYS[condition])


func get_text() -> String:
	return get_condition_text() + "  →  " + tr(MailData.CATEGORY_KEYS[target])


func matches(mail: MailData) -> bool:
	if mail.is_boss:
		return false
	match condition:
		Condition.CAPS:
			return mail.caps and not mail.no_subject
		Condition.DIGITS_IN_ADDRESS:
			return mail.digits_in_address
		Condition.MANY_SMILEYS:
			return mail.smiley_count >= MANY_SMILEYS_THRESHOLD and not mail.no_subject
		Condition.EXE_ATTACHMENT:
			return mail.attachment_ext == "exe"
		Condition.BIZ_DOMAIN:
			return mail.get_domain().ends_with(".biz")
		Condition.EXCLUSIVE:
			return mail.exclusive and not mail.no_subject
		Condition.URGENT:
			return mail.urgent and not mail.exclusive and not mail.no_subject
		Condition.BIG_AMOUNT:
			return mail.amount > BIG_AMOUNT_THRESHOLD
		Condition.CAT:
			return mail.has_cat and not mail.no_subject
		Condition.COMPANY_LINK:
			return mail.kind == MailData.SenderKind.COMPANY and mail.has_link
		Condition.NEWSLETTER_ATTACHMENT:
			return mail.kind == MailData.SenderKind.NEWSLETTER and mail.attachment_ext != ""
		Condition.NO_SUBJECT:
			return mail.no_subject
		Condition.FROM_HR:
			return mail.is_from_hr()
		Condition.CORP_SECURITY:
			return mail.kind == MailData.SenderKind.SECURITY and mail.company_domain
	return false


## Modifies the mail so the rule applies.
func make_match(mail: MailData) -> void:
	match condition:
		Condition.CAPS:
			mail.no_subject = false
			mail.caps = true
		Condition.DIGITS_IN_ADDRESS:
			mail.set_digits_in_address(true)
		Condition.MANY_SMILEYS:
			mail.no_subject = false
			mail.set_smiley_count(randi_range(MANY_SMILEYS_THRESHOLD, 5))
		Condition.EXE_ATTACHMENT:
			mail.attachment_ext = "exe"
		Condition.BIZ_DOMAIN:
			mail.biz_domain = true
		Condition.EXCLUSIVE:
			mail.no_subject = false
			mail.exclusive = true
		Condition.URGENT:
			mail.no_subject = false
			mail.exclusive = false
			mail.urgent = true
		Condition.BIG_AMOUNT:
			mail.amount = randi_range(21, 199) * 50
		Condition.CAT:
			mail.no_subject = false
			mail.has_cat = true
		Condition.COMPANY_LINK:
			mail.set_kind(MailData.SenderKind.COMPANY)
			mail.has_link = true
		Condition.NEWSLETTER_ATTACHMENT:
			mail.set_kind(MailData.SenderKind.NEWSLETTER)
			mail.attachment_ext = MailData.ATTACHMENT_EXTENSIONS.pick_random()
		Condition.NO_SUBJECT:
			mail.no_subject = true
		Condition.FROM_HR:
			mail.set_kind(MailData.SenderKind.COMPANY)
			mail.sender_index = MailData.HR_SENDER_INDEX
		Condition.CORP_SECURITY:
			mail.set_kind(MailData.SenderKind.SECURITY)
			mail.company_domain = true
			mail.lookalike_company_domain = false
			mail.biz_domain = false


## Modifies the mail so it LOOKS close to the rule but does not match.
## This is where autopilot players get caught.
func make_near_miss(mail: MailData) -> void:
	match condition:
		Condition.CAPS:
			mail.caps = false
			mail.urgent = true
		Condition.DIGITS_IN_ADDRESS:
			mail.set_digits_in_address(false)
			mail.amount = randi_range(2, 60) * 25
		Condition.MANY_SMILEYS:
			mail.set_smiley_count(2)
		Condition.EXE_ATTACHMENT:
			mail.attachment_ext = "zip"
		Condition.BIZ_DOMAIN:
			mail.biz_domain = false
		Condition.EXCLUSIVE:
			mail.exclusive = false
			mail.urgent = true
		Condition.URGENT:
			mail.urgent = false
			mail.exclusive = true
		Condition.BIG_AMOUNT:
			mail.amount = randi_range(10, 20) * 50
		Condition.CAT:
			mail.has_cat = false
			mail.set_smiley_count(2)
		Condition.COMPANY_LINK:
			mail.set_kind([MailData.SenderKind.NEWSLETTER, MailData.SenderKind.STRANGER].pick_random())
			mail.has_link = true
		Condition.NEWSLETTER_ATTACHMENT:
			mail.set_kind(MailData.SenderKind.COMPANY)
			mail.attachment_ext = "pdf"
		Condition.NO_SUBJECT:
			mail.no_subject = false
		Condition.FROM_HR:
			mail.set_kind(MailData.SenderKind.COMPANY)
			while mail.sender_index == MailData.HR_SENDER_INDEX:
				mail.sender_index = randi() % MailData.SENDERS[MailData.SenderKind.COMPANY].size()
		Condition.CORP_SECURITY:
			mail.set_kind(MailData.SenderKind.SECURITY)
			mail.company_domain = false
			mail.lookalike_company_domain = true
