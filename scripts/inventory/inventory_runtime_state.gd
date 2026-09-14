class_name InventoryRuntimeState
extends RefCounted

var warehouse_stock: Dictionary = {} # StringName -> int
var ordered_stock: Dictionary = {}
var pending_deliveries: Array[Dictionary] = []
