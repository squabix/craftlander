extends RichTextLabel

const SUN_ICON_PATH := "res://assets/ui/sun.png"
const MOON_ICON_PATH := "res://assets/ui/moon.png"
const ICON_SIZE := 50

const SUN_TINT := Color(1.0, 0.95, 0.6)
const MOON_TINT := Color(0.75, 0.85, 1.0)


func _process(_delta: float) -> void:
	var is_night := DayNightCycle.is_night()
	var icon_path := MOON_ICON_PATH if is_night else SUN_ICON_PATH
	var tint := MOON_TINT if is_night else SUN_TINT
	text = "[img=%dx%d color=#%s]%s[/img] Day %d" % [
		ICON_SIZE, ICON_SIZE, tint.to_html(false), icon_path, DayNightCycle.current_day_number + 1,
	]
