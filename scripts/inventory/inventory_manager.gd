class_name InventoryManager
extends Node

signal stock_changed(product_id: StringName, warehouse: int, ordered: int)

const FEE_STANDARD := 20.0
const FEE_EXPRESS := 45.0

var economy: EconomyManager
var state := InventoryRuntimeState.new()
var ids := RuntimeIdGenerator.new()

func setup(p_economy: EconomyManager) -> void:
	economy = p_economy

func seed_warehouse(product_id: StringName, amount: int) -> void:
	state.warehouse_stock[product_id] = maxi(0, amount)
	_emit(product_id)

func get_warehouse(product_id: StringName) -> int:
	return int(state.warehouse_stock.get(product_id, 0))

func get_ordered(product_id: StringName) -> int:
	return int(state.ordered_stock.get(product_id, 0))

func pending_total() -> int:
	var n := 0
	for row in state.pending_deliveries:
		n += int(row.get("quantity", 0))
	return n


func pending_eta_minutes() -> int:
	var best := -1
	for row in state.pending_deliveries:
		var eta := int(row.get("eta_minutes", -1))
		if eta < 0:
			continue
		if best < 0 or eta < best:
			best = eta
	return best

func quote_order(product: ProductDefinition, quantity: int, delivery_type: StringName) -> Dictionary:
	if product == null or quantity <= 0:
		return {"ok": false, "reason": &"invalid_order", "cost": 0.0}
	var fee := FEE_EXPRESS if delivery_type == &"express" else FEE_STANDARD
	var cost := product.purchase_price * float(quantity) + fee
	if economy == null or not economy.can_afford(cost):
		return {"ok": false, "reason": &"insufficient_cash", "cost": cost}
	return {"ok": true, "reason": &"ok", "cost": cost}

func place_order(product: ProductDefinition, quantity: int, delivery_type: StringName, eta_minutes: int = -1) -> Dictionary:
	var quoted := quote_order(product, quantity, delivery_type)
	if not bool(quoted.get("ok", false)):
		return quoted
	var spend: Dictionary = economy.spend(float(quoted["cost"]), &"order")
	if not bool(spend.get("ok", false)):
		return spend
	if delivery_type == &"express":
		add_to_warehouse(product.id, quantity)
	else:
		var eta := eta_minutes
		if eta < 0:
			eta = StoreClock.OPEN_MINUTES + StoreClock.WAVE_MINUTES
		state.ordered_stock[product.id] = get_ordered(product.id) + quantity
		state.pending_deliveries.append({
			"id": ids.next(&"delivery"),
			"product_id": product.id,
			"quantity": quantity,
			"delivery_type": &"standard",
			"eta_minutes": eta,
		})
		_emit(product.id)
	GameLog.info("INVENTORY", "Order %s x%d %s cost=%.2f" % [String(product.id), quantity, String(delivery_type), float(quoted["cost"])])
	return quoted

func deliver_pending() -> void:
	var pending: Array[Dictionary] = state.pending_deliveries.duplicate()
	state.pending_deliveries.clear()
	for row in pending:
		var product_id: StringName = row.get("product_id", &"")
		var qty := int(row.get("quantity", 0))
		state.ordered_stock[product_id] = maxi(0, get_ordered(product_id) - qty)
		add_to_warehouse(product_id, qty)
		GameLog.info("INVENTORY", "Delivered %s x%d" % [String(product_id), qty])

func take_from_warehouse(product_id: StringName, amount: int) -> int:
	var have := get_warehouse(product_id)
	var take := mini(maxi(amount, 0), have)
	if take <= 0:
		return 0
	state.warehouse_stock[product_id] = have - take
	_emit(product_id)
	return take

func add_to_warehouse(product_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	state.warehouse_stock[product_id] = get_warehouse(product_id) + amount
	_emit(product_id)


func replace_warehouse(stock: Dictionary) -> void:
	var existing: Array = state.warehouse_stock.keys()
	for key in existing:
		if not stock.has(key):
			seed_warehouse(key, 0)
	for key in stock.keys():
		seed_warehouse(key, int(stock[key]))

func _emit(product_id: StringName) -> void:
	stock_changed.emit(product_id, get_warehouse(product_id), get_ordered(product_id))
