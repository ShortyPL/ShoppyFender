class_name EconomyManager
extends Node

signal cash_changed(old_cash: float, new_cash: float, reason: StringName)

var state: EconomyRuntimeState = EconomyRuntimeState.new()


func setup(starting_cash: float) -> void:
	state.cash = starting_cash
	state.lifetime_revenue = 0.0
	state.lifetime_cogs = 0.0
	state.lifetime_gross_profit = 0.0
	cash_changed.emit(starting_cash, starting_cash, &"level_setup")


func get_cash() -> float:
	return state.cash


func can_afford(amount: float) -> bool:
	return state.cash + 0.0001 >= amount


func spend(amount: float, reason: StringName) -> Dictionary:
	if not can_afford(amount):
		return {"ok": false, "reason": &"insufficient_cash"}
	var old_cash := state.cash
	state.cash -= amount
	cash_changed.emit(old_cash, state.cash, reason)
	GameLog.info("ECONOMY", "Cash: %.2f -> %.2f (%s)" % [old_cash, state.cash, String(reason)])
	return {"ok": true, "reason": &"ok"}


func add_revenue(amount: float, reason: StringName, cogs: float = 0.0) -> void:
	var old_cash := state.cash
	state.cash += amount
	state.lifetime_revenue += amount
	state.lifetime_cogs += cogs
	state.lifetime_gross_profit += amount - cogs
	cash_changed.emit(old_cash, state.cash, reason)
	GameLog.info("ECONOMY", "Cash: %.2f -> %.2f (%s)" % [old_cash, state.cash, String(reason)])


func restore_cash(amount: float, reason: StringName = &"wave_repeat") -> void:
	var old_cash := state.cash
	state.cash = amount
	cash_changed.emit(old_cash, state.cash, reason)
	GameLog.info("ECONOMY", "Cash: %.2f -> %.2f (%s)" % [old_cash, state.cash, String(reason)])


func refund(amount: float, reason: StringName) -> void:
	if amount <= 0.0:
		return
	var old_cash := state.cash
	state.cash += amount
	cash_changed.emit(old_cash, state.cash, reason)
	GameLog.info("ECONOMY", "Cash: %.2f -> %.2f (%s)" % [old_cash, state.cash, String(reason)])
