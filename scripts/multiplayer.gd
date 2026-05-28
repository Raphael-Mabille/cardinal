extends Node


const SIGNALING_URL := "ws://192.168.0.3:8080"

# STUN is needed for browser NAT traversal and also generally for WebRTC
const ICE_SERVERS = [
	{
		"urls": ["stun:stun.l.google.com:19302"]
	}
]

# -------------------------
# ui signals
# -------------------------

signal send_ui_message(msg)
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)

var player_info = {"name": "Name"}
var players : Dictionary = {}

# -------------------------
# Signaling
# -------------------------
var ws := WebSocketPeer.new()
var ws_connected := false

# -------------------------
# WebRTC / Multiplayer
# -------------------------
var my_peer_id := 0
var current_room := ""
var is_host := false

var webrtc_multiplayer: WebRTCMultiplayerPeer
var rtc_connections: Dictionary = {} # peer_id -> WebRTCPeerConnection

func _ready() -> void:
	set_process(true)

	# Godot multiplayer events
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(_delta: float) -> void:
	_poll_websocket()
	_poll_rtc()


# ============================================================
# UI BUTTONS
# ============================================================

func connect_to_server() -> String:
	var err := ws.connect_to_url(SIGNALING_URL)
	if err != OK:
		return "Connect failed: " + str(err)
	return ""

func create_room() -> void:
	is_host = true
	my_peer_id = 1

	# Create WebRTC multiplayer as host
	webrtc_multiplayer = WebRTCMultiplayerPeer.new()
	webrtc_multiplayer.create_server()
	multiplayer.multiplayer_peer = webrtc_multiplayer

	_send_json({
		"type": "create_room"
	})


func join_room(room_code : String) -> void:
	if room_code.is_empty():
		send_ui_message.emit("Enter a room code")
		return

	is_host = false

	_send_json({
		"type": "join_room",
		"room": room_code
	})


# ============================================================
# SIGNALING SOCKET
# ============================================================

func _poll_websocket() -> void:
	match ws.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			ws.poll()

		WebSocketPeer.STATE_OPEN:
			ws.poll()

			if not ws_connected:
				ws_connected = true
				send_ui_message.emit("connected")

			while ws.get_available_packet_count() > 0:
				var raw := ws.get_packet().get_string_from_utf8()
				print("RECV: ", raw)

				var data = JSON.parse_string(raw)
				if typeof(data) == TYPE_DICTIONARY:
					_handle_message(data)

		WebSocketPeer.STATE_CLOSING:
			ws.poll()

		WebSocketPeer.STATE_CLOSED:
			if ws_connected:
				ws_connected = false
				send_ui_message.emit("disconnected")


func _handle_message(data: Dictionary) -> void:
	match data.get("type", ""):
		"room_created":
			current_room = str(data.get("room", ""))
			my_peer_id = int(data.get("peer_id", 1))

			send_ui_message.emit("Room created as host")
			send_ui_message.emit("Room: " + current_room + " | My peer ID: " + str(my_peer_id))

		"joined_room":
			current_room = str(data.get("room", ""))
			my_peer_id = int(data.get("peer_id", -1))

			# IMPORTANT:
			# Client can only create WebRTCMultiplayerPeer after it knows its assigned peer ID
			webrtc_multiplayer = WebRTCMultiplayerPeer.new()
			webrtc_multiplayer.create_client(my_peer_id)
			multiplayer.multiplayer_peer = webrtc_multiplayer

			send_ui_message.emit("Joined room successfully")
			send_ui_message.emit("Room: " + current_room + " | My peer ID: " + str(my_peer_id))

		"join_failed":
			var reason := str(data.get("reason", "Unknown error"))
			send_ui_message.emit("Join failed: " + reason)

		"new_peer":
			var peer_id := int(data.get("peer_id", -1))
			send_ui_message.emit("New peer joined: " + str(peer_id))

			# Host initiates WebRTC connection
			if is_host:
				_create_connection_for_peer(peer_id, true)

		"offer":
			var from_id := int(data.get("from", -1))
			var offer_sdp := str(data.get("offer", ""))

			send_ui_message.emit("Received offer from " + str(from_id))

			# Joiner receives offer and creates answer
			if not rtc_connections.has(from_id):
				_create_connection_for_peer(from_id, false)

			var pc: WebRTCPeerConnection = rtc_connections[from_id]
			var err := pc.set_remote_description("offer", offer_sdp)
			print("set_remote_description(offer) => ", err)

		"answer":
			var from_id := int(data.get("from", -1))
			var answer_sdp := str(data.get("answer", ""))

			send_ui_message.emit("Received answer from " + str(from_id))

			if rtc_connections.has(from_id):
				var pc: WebRTCPeerConnection = rtc_connections[from_id]
				var err := pc.set_remote_description("answer", answer_sdp)
				print("set_remote_description(answer) => ", err)

		"ice_candidate":
			var from_id := int(data.get("from", -1))
			var media := str(data.get("media", "0"))
			var index := int(data.get("index", 0))
			var candidate := str(data.get("candidate", ""))

			if rtc_connections.has(from_id):
				var pc: WebRTCPeerConnection = rtc_connections[from_id]
				var err := pc.add_ice_candidate(media, index, candidate)
				print("add_ice_candidate => ", err)

		"peer_left":
			var peer_id := int(data.get("peer_id", -1))
			send_ui_message.emit("Peer left: " + str(peer_id))

			if rtc_connections.has(peer_id):
				rtc_connections.erase(peer_id)

		_:
			send_ui_message.emit("Unhandled message: " + str(data.get("type", "?")))


func _send_json(data: Dictionary) -> void:
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json := JSON.stringify(data)
		print("SEND: ", json)
		ws.send_text(json)


# ============================================================
# WEBRTC
# ============================================================

func _create_connection_for_peer(remote_peer_id: int, create_offer: bool) -> void:
	print("Creating WebRTC connection for peer ", remote_peer_id, " | offer? ", create_offer)

	var pc := WebRTCPeerConnection.new()
	var err := pc.initialize({
		"iceServers": ICE_SERVERS
	})
	if err != OK:
		send_ui_message.emit("WebRTC init failed: " + str(err))
		print("WebRTC initialize failed => ", err)
		return

	rtc_connections[remote_peer_id] = pc

	# IMPORTANT: Register this peer connection with Godot multiplayer
	var add_err := webrtc_multiplayer.add_peer(pc, remote_peer_id)
	print("add_peer => ", add_err)

	# When local SDP is ready
	pc.session_description_created.connect(func(type: String, sdp: String):
		print("session_description_created => ", type)

		var local_err := pc.set_local_description(type, sdp)
		print("set_local_description => ", local_err)

		if type == "offer":
			_send_json({
				"type": "offer",
				"room": current_room,
				"to": remote_peer_id,
				"from": my_peer_id,
				"offer": sdp
			})
		elif type == "answer":
			_send_json({
				"type": "answer",
				"room": current_room,
				"to": remote_peer_id,
				"from": my_peer_id,
				"answer": sdp
			})
	)

	# When local ICE candidate is found
	pc.ice_candidate_created.connect(func(media: String, index: int, candidate: String):
		print("ice_candidate_created => ", media, " | ", index)

		_send_json({
			"type": "ice_candidate",
			"room": current_room,
			"to": remote_peer_id,
			"from": my_peer_id,
			"media": media,
			"index": index,
			"candidate": candidate
		})
	)

	# VERY IMPORTANT:
	# When remote description is set to "offer", Godot automatically emits
	# session_description_created("answer", ...)
	# after you call set_remote_description("offer", ...)
	#
	# Host explicitly creates offer:
	if create_offer:
		var offer_err := pc.create_offer()
		print("create_offer => ", offer_err)


func _poll_rtc() -> void:
	for peer_id in rtc_connections.keys():
		var pc: WebRTCPeerConnection = rtc_connections[peer_id]
		pc.poll()


# ============================================================
# MULTIPLAYER EVENTS
# ============================================================

func _on_peer_connected(id: int) -> void:
	send_ui_message.emit("Multiplayer connected to peer " + str(id))
	_register_player.rpc_id(id, player_info)
	

func _on_peer_disconnected(id: int) -> void:
	send_ui_message.emit("Multiplayer disconnected from peer " + str(id))


func _on_server_disconnected() -> void:
	send_ui_message.emit("Server disconnected")
	


# ============================================================
# RPC TEST
# ============================================================


func _on_send_ping_pressed() -> void:
	var target_id := _get_other_peer_id()
	if target_id == -1:
		send_ui_message.emit("No connected peer to ping")
		return

	var message := "Ping from peer " + str(multiplayer.get_unique_id())
	print("Sending ping to peer ", target_id, " | ", message)

	# Send RPC only to the other peer
	receive_ping.rpc_id(target_id, message)

	# Local feedback
	send_ui_message.emit("Last message: sent -> " + message)
	send_ui_message.emit("Ping sent to peer " + str(target_id))


@rpc("any_peer", "reliable")
func receive_ping(message: String) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	print("receive_ping() from peer ", sender_id, " | message = ", message)

	send_ui_message.emit("Last message: from " + str(sender_id) + " -> " + message)
	send_ui_message.emit("Received ping from peer " + str(sender_id))


func _get_other_peer_id() -> int:
	if multiplayer.multiplayer_peer == null:
		return -1

	var peers := multiplayer.get_peers()
	if peers.is_empty():
		return -1

	# For Step 4 we only support 1 remote peer
	return peers[0]


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)
