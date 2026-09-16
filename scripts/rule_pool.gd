class_name RulePool
extends RefCounted
## The pool of special rules a run draws from.

const C := SortRule.Condition
const Cat := MailData.Category


static func create() -> Array[SortRule]:
	var rules: Array[SortRule] = [
		SortRule.create(C.CAPS, Cat.SPAM),
		SortRule.create(C.DIGITS_IN_ADDRESS, Cat.PHISHING),
		SortRule.create(C.MANY_SMILEYS, Cat.SPAM),
		SortRule.create(C.EXE_ATTACHMENT, Cat.PHISHING),
		SortRule.create(C.BIZ_DOMAIN, Cat.SPAM),
		SortRule.create(C.EXCLUSIVE, Cat.NEWSLETTER),
		SortRule.create(C.URGENT, Cat.IMPORTANT),
		SortRule.create(C.BIG_AMOUNT, Cat.PHISHING),
		SortRule.create(C.CAT, Cat.IMPORTANT),
		SortRule.create(C.COMPANY_LINK, Cat.PHISHING),
		SortRule.create(C.NEWSLETTER_ATTACHMENT, Cat.SPAM),
		SortRule.create(C.NO_SUBJECT, Cat.SPAM),
		SortRule.create(C.FROM_HR, Cat.NEWSLETTER),
		SortRule.create(C.CORP_SECURITY, Cat.IMPORTANT),
	]
	return rules
