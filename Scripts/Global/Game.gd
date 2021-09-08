extends Node

signal game_connected(other_player_id)
signal game_disconnected()
signal game_info(game)
signal connection_failed()

var connected : bool = false
var game_code : String = ""

func _ready():
# warning-ignore:return_value_discarded
	MultiplayerClient.connect("connected", self, "_on_network_connected")
# warning-ignore:return_value_discarded
	MultiplayerClient.connect("connection_failed", self, "_on_connection_failed")
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected", self, "_on_player_connected")
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected",self,"_on_player_disconnected")
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed",self,"_on_connection_failed")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")


func host(server : String):
	self.connected = false
# warning-ignore:return_value_discarded
	MultiplayerClient.host_game(server)

func join(server : String, code : String):
	self.game_code = code
	self.connected = false
# warning-ignore:return_value_discarded
	MultiplayerClient.join_game(server, code)

func end():
	connected = false

	get_tree().network_peer = null
	MultiplayerClient.stop()

	emit_signal("game_disconnected")


func _on_network_connected(game : String):
	self.game_code = game

	print("Game code is %s" % self.game_code)
	emit_signal("game_info", game)

	get_tree().network_peer = MultiplayerClient.rtc_mp

func _on_connection_failed():
	print("Connection failed!")

	connected = false
	emit_signal("connection_failed")

	get_tree().network_peer = null
	MultiplayerClient.stop()


func _on_player_connected(id : int):
	print("Player connected")

	connected = true
	emit_signal("game_connected", id)

# warning-ignore:unused_argument
func _on_player_disconnected(id):
	print("Player disconnected")

	connected = false
	emit_signal("game_disconnected")

	get_tree().network_peer = null
	MultiplayerClient.stop()

func _on_server_disconnected():
	_on_player_disconnected(1)
