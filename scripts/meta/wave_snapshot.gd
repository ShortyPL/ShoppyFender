class_name WaveSnapshot
extends RefCounted

var cash: float = 0.0
var warehouse: Dictionary = {}
var shelves: Array = []


static func capture(economy: EconomyManager, inventory: InventoryManager, store: StoreManager) -> WaveSnapshot:
	var snap := WaveSnapshot.new()
	if economy != null:
		snap.cash = economy.get_cash()
	if inventory != null:
		snap.warehouse = inventory.state.warehouse_stock.duplicate()
	if store != null:
		snap.shelves = store.export_stock_snapshot()
	return snap


func restore(economy: EconomyManager, inventory: InventoryManager, store: StoreManager) -> void:
	if economy != null:
		economy.restore_cash(cash, &"wave_repeat")
	if inventory != null:
		inventory.replace_warehouse(warehouse)
	if store != null:
		store.apply_stock_snapshot(shelves)
