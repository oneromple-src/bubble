extends Control

@onready var join_button: Button = $CreateBG/VBoxContainer/Join

func _ready() -> void:
	print(OS.get_processor_name())
	
func _on_join_button_pressed() -> void:
	Singleton.username = %Username.text
	Singleton.selected_port = %SpinBox.value
	if Singleton.selected_port == 0:
		Singleton.selected_port = find_available_port(49152, 65535)  # Ephemeral port range

	get_tree().change_scene_to_file("res://chatroom/chatroom.tscn")
	print("Connecting to server...")



func _on_username_text_changed(new_text: String) -> void:
	var text = new_text.lstrip(' ').rstrip(' ')
	join_button.disabled = !(text.length() >= 3 && text.length() < 16)
	join_button.disabled = text.replace(" ", "").is_empty()

func find_available_port(start_port: int, end_port: int) -> int:
	var test_peer := ENetMultiplayerPeer.new()
	
	for port in range(start_port, end_port + 1):
		if test_peer.create_server(port) == OK:
			test_peer.close()
			return port  
	
	return -1
