class_name CustomerRuntimeState
extends RefCounted

var runtime_id: StringName
var customer_type_id: StringName = &"regular_customer"
var state: StringName = &"spawning"
var shopping_list: Array[ShoppingListItem] = []
var basket: Array[BasketItem] = []
var frustration: float = 0.0
var satisfaction: float = 100.0
var money_spent: float = 0.0
var fail_reason: StringName = &""
var leave_threshold: float = 100.0
