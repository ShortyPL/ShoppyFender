class_name WaveRuntimeState
extends RefCounted

var wave_id: StringName = &"prototype_002_wave_01"
var state: StringName = &"prepare"
var total_to_spawn: int = 10
var spawned_count: int = 0
var active_customer_count: int = 0
var completed_customer_count: int = 0
var failed_count: int = 0
var elapsed_sec: float = 0.0
var lost_sales_count: int = 0
var lost_sales_value: float = 0.0
var lost_oos: int = 0
var lost_queue: int = 0
var lost_path: int = 0
var satisfaction_total: float = 0.0


func reset_metrics() -> void:
	completed_customer_count = 0
	failed_count = 0
	lost_sales_count = 0
	lost_sales_value = 0.0
	lost_oos = 0
	lost_queue = 0
	lost_path = 0
	satisfaction_total = 0.0
	elapsed_sec = 0.0


func record_customer_exit(served: bool, satisfaction: float, lost_value: float, fail_reason: StringName = &"") -> void:
	satisfaction_total += clampf(satisfaction, 0.0, 100.0)
	if served:
		completed_customer_count += 1
		return
	failed_count += 1
	lost_sales_count += 1
	lost_sales_value += maxf(lost_value, 0.0)
	match fail_reason:
		&"out_of_stock", &"unavailable":
			lost_oos += 1
		&"queue":
			lost_queue += 1
		&"no_path":
			lost_path += 1
		_:
			lost_oos += 1


func get_average_satisfaction() -> float:
	var exited := completed_customer_count + failed_count
	if exited <= 0:
		return 0.0
	return clampf(satisfaction_total / float(exited), 0.0, 100.0)


func get_service_rate() -> float:
	var exited := completed_customer_count + failed_count
	if exited <= 0:
		return 0.0
	return float(completed_customer_count) / float(exited)


static func served_needed(total: int = 10) -> int:
	return maxi(8, ceili(float(maxi(total, 1)) * 0.8))


static func served_star_ok(served: int, total: int = 10) -> bool:
	return served >= served_needed(total)


static func sat_star_ok(satisfaction: float) -> bool:
	return satisfaction + 0.0001 >= 80.0


static func lost_star_ok(lost_count: int) -> bool:
	return lost_count == 0


static func count_stars(served: int, satisfaction: float, lost_count: int, total: int = 10) -> int:
	var n := 0
	if served_star_ok(served, total):
		n += 1
	if sat_star_ok(satisfaction):
		n += 1
	if lost_star_ok(lost_count):
		n += 1
	return n
