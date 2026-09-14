class_name StoreClock
extends RefCounted

const OPEN_MINUTES := 9 * 60
const WAVE_MINUTES := 120

var minutes: int = OPEN_MINUTES


static func format_clock(total_minutes: int) -> String:
	var wrapped := posmod(total_minutes, 24 * 60)
	var hour := int(wrapped / 60.0)
	var minute := wrapped % 60
	var suffix := "AM" if hour < 12 else "PM"
	var hour12 := hour % 12
	if hour12 == 0:
		hour12 = 12
	return "%d:%02d %s" % [hour12, minute, suffix]


func eta_after_wave() -> int:
	return minutes + WAVE_MINUTES


func displayed_minutes(state: StringName, wave_progress: float) -> int:
	if state == GameManager.STATE_SIMULATION:
		return minutes + int(round(float(WAVE_MINUTES) * clampf(wave_progress, 0.0, 1.0)))
	if state == GameManager.STATE_RESULTS:
		return minutes + WAVE_MINUTES
	return minutes


func advance_wave() -> void:
	minutes += WAVE_MINUTES
