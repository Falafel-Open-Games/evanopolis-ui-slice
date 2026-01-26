class_name NumberFormat
extends RefCounted

static func format_fiat(value: float) -> String:
	var text: String = "%.2f" % value
	var parts: PackedStringArray = text.split(".")
	var integer_part: String = parts[0]
	var fractional: String = parts[1] if parts.size() > 1 else "00"
	var sign: String = ""
	if integer_part.begins_with("-"):
		sign = "-"
		integer_part = integer_part.substr(1, integer_part.length() - 1)
	return "%s%s.%s" % [sign, _format_with_commas(integer_part), fractional]

static func format_btc(value: float) -> String:
	return "%.4f" % value

static func _format_with_commas(digits: String) -> String:
	if digits.length() <= 3:
		return digits
	var groups: Array[String] = []
	var start: int = digits.length() % 3
	if start == 0:
		start = 3
	groups.append(digits.substr(0, start))
	for index in range(start, digits.length(), 3):
		groups.append(digits.substr(index, 3))
	return ",".join(groups)
