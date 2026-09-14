class_name RuntimeIdGenerator
extends RefCounted

var _counters: Dictionary = {}


func next(prefix: StringName) -> StringName:
	var n: int = int(_counters.get(prefix, 0)) + 1
	_counters[prefix] = n
	return StringName("%s_%06d" % [String(prefix), n])
