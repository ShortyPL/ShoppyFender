class_name CheckoutQueue
extends RefCounted

const SLOT_COUNT := 4
const PAY_SEC := 1.8
const WAIT_TICK_SEC := 3.0

var pay_sec: float = PAY_SEC
var _ids: Array[StringName] = []
var _pay_left: float = 0.0
var _paying: bool = false
var _wait_acc: float = 0.0

func enqueue(customer_id: StringName) -> int:
	_ids.append(customer_id)
	return display_index(_ids.size() - 1)

func dequeue(customer_id: StringName) -> void:
	var i := _ids.find(customer_id)
	if i < 0:
		return
	_ids.remove_at(i)
	if i == 0:
		_paying = false
		_pay_left = 0.0

func index_of(customer_id: StringName) -> int:
	return _ids.find(customer_id)

func display_index(raw: int) -> int:
	return mini(raw, SLOT_COUNT - 1)

func size() -> int:
	return _ids.size()


func is_paying() -> bool:
	return _paying

func front() -> StringName:
	return _ids[0] if not _ids.is_empty() else &""

func start_pay_if_idle() -> void:
	if _ids.is_empty() or _paying:
		return
	_paying = true
	_pay_left = pay_sec

func advance_pay(delta: float) -> bool:
	if not _paying:
		return false
	_pay_left -= delta
	if _pay_left > 0.0:
		return false
	_paying = false
	_pay_left = 0.0
	return true

func wait_tick_due(delta: float) -> bool:
	if _ids.size() <= 1:
		_wait_acc = 0.0
		return false
	_wait_acc += delta
	if _wait_acc < WAIT_TICK_SEC:
		return false
	_wait_acc = 0.0
	return true
