extends Node
class_name User

var username: String

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

signal new_message(author, msg)
