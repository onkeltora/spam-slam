class_name MailData
extends RefCounted
## One mail in the inbox. All sorting-relevant features are plain flags;
## the visible text is built from them at draw time, so it stays localizable.

enum Category { IMPORTANT, SPAM, NEWSLETTER, PHISHING }
enum SenderKind { COMPANY, NEWSLETTER, STRANGER, SECURITY }

const CATEGORY_KEYS := {
	Category.IMPORTANT: "CAT_IMPORTANT",
	Category.SPAM: "CAT_SPAM",
	Category.NEWSLETTER: "CAT_NEWSLETTER",
	Category.PHISHING: "CAT_PHISHING",
}
## Legend text for the base rule of each basket ("🏢 Colleagues" etc.)
const BASE_RULE_KEYS := {
	Category.IMPORTANT: "BASE_IMPORTANT",
	Category.SPAM: "BASE_SPAM",
	Category.NEWSLETTER: "BASE_NEWSLETTER",
	Category.PHISHING: "BASE_PHISHING",
}
const CATEGORY_COLORS := {
	Category.IMPORTANT: Color("f2c14e"),
	Category.SPAM: Color("e0605a"),
	Category.NEWSLETTER: Color("5aa9e6"),
	Category.PHISHING: Color("a66cff"),
}
## Base rule: the sender kind decides the basket unless the active rule overrides it.
const BASE_CATEGORY := {
	SenderKind.COMPANY: Category.IMPORTANT,
	SenderKind.NEWSLETTER: Category.NEWSLETTER,
	SenderKind.STRANGER: Category.SPAM,
	SenderKind.SECURITY: Category.PHISHING,
}
const KIND_ICONS := {
	SenderKind.COMPANY: "🏢",
	SenderKind.NEWSLETTER: "📰",
	SenderKind.STRANGER: "❓",
	SenderKind.SECURITY: "🔒",
}

const COMPANY_DOMAIN := "dullcorp.com"
const LOOKALIKE_DOMAIN := "dullc0rp.com"
const HR_SENDER_INDEX := 3

## [name_key, handle, domain] – an empty domain means the company domain.
const SENDERS := {
	SenderKind.COMPANY: [
		["SENDER_KAREN", "karen.accounting", ""],
		["SENDER_BERND", "bernd.it", ""],
		["SENDER_TEAMLEAD", "teamlead", ""],
		["SENDER_HR", "hr", ""],
		["SENDER_KEVIN", "kevin.intern", ""],
	],
	SenderKind.NEWSLETTER: [
		["SENDER_MEGAMART", "news", "megamart.com"],
		["SENDER_CATFACTS", "daily", "catfacts.net"],
		["SENDER_FITNESS", "weekly", "fitnessfreak.com"],
		["SENDER_TECHDAILY", "newsletter", "techdaily.io"],
	],
	SenderKind.STRANGER: [
		["SENDER_WINNER", "claim", "win-big.biz"],
		["SENDER_DIET", "offers", "miracle-diet.net"],
		["SENDER_CRYPTO", "chris", "moon-coins.io"],
		["SENDER_LORD", "reginald", "royal-inheritance.com"],
	],
	SenderKind.SECURITY: [
		["SENDER_PAYPOL", "security", "paypol-support.com"],
		["SENDER_BONK", "service", "bonk-online.net"],
		["SENDER_ACCOUNT", "no-reply", "account-verify.com"],
		["SENDER_PARCEL", "tracking", "parcel-status.info"],
	],
}
const SUBJECT_PREFIXES := {
	SenderKind.COMPANY: "SUBJ_COMPANY_",
	SenderKind.NEWSLETTER: "SUBJ_NEWS_",
	SenderKind.STRANGER: "SUBJ_STRANGER_",
	SenderKind.SECURITY: "SUBJ_SECURITY_",
}
const SUBJECT_COUNTS := {
	SenderKind.COMPANY: 7,
	SenderKind.NEWSLETTER: 5,
	SenderKind.STRANGER: 5,
	SenderKind.SECURITY: 5,
}
const EMOJI_POOL := ["🎉", "💰", "🔥", "😍", "✨", "🚀", "💯", "🎁"]
const ATTACHMENT_EXTENSIONS := ["pdf", "docx", "zip", "exe"]
const ATTACHMENT_KEYS := {"pdf": "FILE_PDF", "docx": "FILE_DOCX", "zip": "FILE_ZIP", "exe": "FILE_EXE"}

var kind: SenderKind = SenderKind.COMPANY
var sender_index := 0
var subject_index := 0
var is_boss := false

# --- Rule-relevant features ---
var caps := false
var emoji_count := 0
var emojis := ""
var has_cat := false
var exclusive := false
var urgent := false
var no_subject := false
var digits_in_address := false
var address_digits := ""
var xyz_domain := false
var company_domain := false         # security alert really sent from @dullcorp.com
var lookalike_company_domain := false  # ...or from @dullc0rp.com (nasty)
var attachment_ext := ""            # "" = no attachment
var has_link := false
var amount := 0                     # 0 = no amount line

# --- Visual state for the inbox pile (owned by InboxPile) ---
var pile_jitter := Vector2.ZERO
var pile_rotation := 0.0
var pile_drop := 1.0


func _init() -> void:
	pile_jitter = Vector2(randf_range(-8.0, 8.0), randf_range(-2.0, 2.0))
	pile_rotation = randf_range(-0.035, 0.035)


## Sets the sender kind and rolls a fitting sender + subject.
func set_kind(new_kind: SenderKind) -> void:
	kind = new_kind
	sender_index = randi() % SENDERS[kind].size()
	subject_index = randi() % SUBJECT_COUNTS[kind]
	if kind == SenderKind.SECURITY:
		has_link = true


func set_emoji_count(count: int) -> void:
	emoji_count = count
	emojis = ""
	for i in count:
		emojis += EMOJI_POOL[randi() % EMOJI_POOL.size()]


func set_digits_in_address(enabled: bool) -> void:
	digits_in_address = enabled
	address_digits = str(randi_range(7, 2099)) if enabled else ""


func base_category() -> Category:
	return BASE_CATEGORY[kind]


func is_from_hr() -> bool:
	return kind == SenderKind.COMPANY and sender_index == HR_SENDER_INDEX and not is_boss


func has_company_domain() -> bool:
	return kind == SenderKind.COMPANY or company_domain


func get_icon() -> String:
	return "★" if is_boss else KIND_ICONS[kind]


func get_sender_name() -> String:
	if is_boss:
		return tr("SENDER_BOSS")
	if kind == SenderKind.SECURITY and (company_domain or lookalike_company_domain):
		return tr("SENDER_CORP_SECURITY")
	return tr(SENDERS[kind][sender_index][0])


func get_domain() -> String:
	var domain: String
	if lookalike_company_domain:
		domain = LOOKALIKE_DOMAIN
	elif has_company_domain():
		domain = COMPANY_DOMAIN
	else:
		domain = SENDERS[kind][sender_index][2]
	if xyz_domain:
		domain = domain.get_basename() + ".xyz"
	return domain


func get_address() -> String:
	var handle: String
	if is_boss:
		handle = "boss"
	elif company_domain or lookalike_company_domain:
		handle = "it-security"
	else:
		handle = SENDERS[kind][sender_index][1]
	return handle + address_digits + "@" + get_domain()


func get_subject() -> String:
	if no_subject:
		return tr("SUBJ_NONE")
	var subject := tr("SUBJ_BOSS") if is_boss else tr(SUBJECT_PREFIXES[kind] + str(subject_index))
	if exclusive:
		subject = tr("WORD_EXCLUSIVE") + ": " + subject
	elif urgent:
		subject = tr("WORD_URGENT") + ": " + subject
	if caps:
		subject = subject.to_upper()
	if has_cat:
		subject += " 🐱"
	if emoji_count > 0:
		subject += " " + emojis
	return subject


## Attachment / link / amount lines shown below the subject.
func get_extra_lines() -> Array[String]:
	var lines: Array[String] = []
	if attachment_ext != "":
		lines.append("📎 " + tr(ATTACHMENT_KEYS[attachment_ext]) + "." + attachment_ext)
	if has_link:
		lines.append("🔗 " + tr("LINK_TEXT"))
	if amount > 0:
		lines.append(tr("AMOUNT_FMT").format({"v": _format_number(amount)}))
	return lines


func _format_number(value: int) -> String:
	var digits := str(value)
	var result := ""
	var sep := tr("NUM_SEP")
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			result += sep
		result += digits[i]
	return result
