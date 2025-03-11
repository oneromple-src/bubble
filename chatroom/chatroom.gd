extends Control

var peer := ENetMultiplayerPeer.new()
var peers := []  # A list to store connected peers

var IP_ADDR = IP.get_local_addresses()[7]

func _ready() -> void:
	# Initial connection setup
	print(IP.get_local_addresses())
	peer.create_client(IP_ADDR, Singleton.selected_port)
	multiplayer.multiplayer_peer = peer
	set_multiplayer_authority(1, true)
	await get_tree().create_timer(0.1).timeout

	# Check if a host exists
	if !%Server.host_exists:
		peer.close()
		host_server(Singleton.selected_port)
		%Chatbox.text = "%s\n%s\n%s\n%s\n" % [
			"=== CHATROOM ===",
			"Port: " + str(Singleton.selected_port),
			"Host: [color=aqua]%s[/color]" % Singleton.username,
			"=================",
		]
		new_message(Singleton.username + " joined the room", "yellow")
		%OnlineText.text = "Online: 1"
		%Server.host_exists = true
		# Connect the host disconnect signal
		tree_exiting.connect(_host_disconnect)
	else:
		Singleton.is_host = false
		join_server(Singleton.selected_port)

# Notification for closing the window
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			_on_disconnect(Singleton.username)
			if Singleton.is_host:
				_host_disconnect()

@rpc("any_peer", "call_local")
func new_message(msg: String, color = "#ffffff"):
	%Chatbox.text = "%s\n[color=%s]%s[/color]" % [%Chatbox.text, color, msg]
	
# Host server setup
func host_server(port: int) -> bool:
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	set_multiplayer_authority(1, true)  # Host has authority
	return true

# Join server setup
func join_server(port: int):
	peer.create_client(IP_ADDR, port)
	multiplayer.multiplayer_peer = peer
	set_multiplayer_authority(1, true)  # Peer has authority

	print("Client connected, waiting before sending RPC...")
	await get_tree().create_timer(0.1).timeout  # Wait briefly before calling RPC

	print("Sending join message via RPC...")
	rpc("new_message", "%s joined the room" % Singleton.username, "yellow")

# Handle chat message submission
func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text.strip_edges() == "":
		return
	
	var msg = "%s: %s" % [Singleton.username, new_text]
	rpc("new_message", msg)  # Send message to all peers
	%LineEdit.text = ""

# Handle disconnects
func _on_disconnect(user: String) -> void:
	rpc("new_message", "%s left the room" % user, "red")

# Host disconnect handler (transfer host to another peer)
func _host_disconnect() -> void:
	print("HOST DC")

	# Check if there are multiple peers connected
	if multiplayer.get_peers().size() > 1:
		# Find the next peer to take ownership
		for peer_id in multiplayer.get_peers():
			# Skip the current host, select a new peer
			if peer_id != multiplayer.get_unique_id():
				# Transfer the host authority to this peer
				multiplayer.set_peer_authority(peer_id, true)
				# Notify all peers that the host has changed
				rpc("new_message", "%s is now the host" % multiplayer.get_peer_name(peer_id), "aqua")
				Singleton.is_host = true
				print("Transferred host to peer: %d" % peer_id)
				# We don't close the connection yet, the new host takes control now
				break
	else:
		# If only one person is left (the host), set host_exists to false
		%Server.host_exists = false
		print("No host exists anymore, ending server.")
		# Closing the server after all peers are disconnected
		peer.close()

func update_count():
	%OnlineText.text = "Online: " + str(multiplayer.get_peers().size()) + " "
