class_name GameLog
extends RefCounted


static func info(channel: String, message: String) -> void:
	print("[%s] %s" % [channel, message])
