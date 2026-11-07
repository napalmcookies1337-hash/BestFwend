class_name Fmt
extends RefCounted
## Text formatting shared by every screen.


## 1234567 -> "$$$ 1,234,567"
static func money(amount: int) -> String:
	return "$$$ " + grouped(amount)


static func grouped(value: int) -> String:
	var digits := str(absi(value))
	var result := ""
	while digits.length() > 3:
		result = "," + digits.right(3) + result
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + result
