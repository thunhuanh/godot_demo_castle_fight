extends Control

var PORT = 13492
onready var _fetch = GotmLobbyFetch.new()
var curGame
onready var GameScene = preload("res://Scenes/Game.tscn")
onready var PlayerScene = preload("res://Scenes/player.tscn")

var player
var other_player

func _ready():
	Gotm.connect("lobby_changed", self, "_on_Gotm_lobby_changed")
	get_tree().connect("network_peer_connected", self, "_player_connected")

	$Lobbies/List/LobbyEntry.hide()
	_on_Refresh_clicked(null)

remotesync func startGameButtonShow():
	$Label/Button.show()
	$Label.text = "Game Ready"
	$Label/Spinner.hide()

func _on_LobbyEntry_selected(lobby):
	$Lobbies.hide()
	$Game.show()
	
	$Spinner.show()
	var success = yield(lobby.join(), "completed")
	$Spinner.hide()
	if success:
		join()
	else:
		push_error("Failed to connect to lobby '" + lobby.name + "'!")
		$Lobbies.show()
		if curGame:
			remove_child(curGame)

func _on_Host_clicked(instance):
	if $Lobbies/Host/Name.get_text() == "":
		return

	$Lobbies.hide()
	$Label.show()
	
	Gotm.host_lobby(false)
	Gotm.lobby.hidden = false
	Gotm.lobby.name = $Lobbies/Host/Name.get_text()
	host()

func host():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(PORT)
	get_tree().set_network_peer(peer)

func join():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(Gotm.lobby.host.address, PORT)
	get_tree().set_network_peer(peer)
	
	$Label.show()	
	$Label/Spinner.show()
	yield(get_tree(), "connected_to_server")
	$Label/Spinner.hide()

func lockLobby():
	Gotm.lobby.locked = true

func _player_connected(other_playerId):
	lockLobby()
	
	curGame = GameScene.instance()

	var cameraName = "camera"

	player = PlayerScene.instance()
	var playerID = get_tree().get_network_unique_id()
	player.set_network_master(playerID)
	player.set_name(str(playerID))
	player.set_position(Vector2(256, 256))
	curGame.builderID = playerID
	if get_tree().is_network_server():
		player.unitOwner = "ally"
		player.playerName = "BLUE"
		curGame.get_node(cameraName).position = Vector2(256 , 256)
	else:
		player.unitOwner = "enemy"
		player.playerName = "RED"
		player.set_position(Vector2(777, 256))
		curGame.get_node(cameraName).position = Vector2(777, 256)
	curGame.get_node("instanceSort").add_child(player)

	other_player = PlayerScene.instance()
	other_player.set_name(str(other_playerId))
	other_player.set_network_master(other_playerId)
	other_player.set_position(Vector2(512, 256))
	if get_tree().is_network_server():
		other_player.unitOwner = "enemy"
		other_player.playerName = "RED"
	else:
		other_player.unitOwner = "ally"
		other_player.playerName = "BLUE"
	curGame.get_node("instanceSort").add_child(other_player)
	
	get_parent().add_child(curGame)
	get_tree().change_scene_to(curGame)

func _on_Refresh_clicked(_instance):
	$Lobbies/List/Spinner.show()
	for child in $Lobbies/List/Entries.get_children():
		child.queue_free()
	
	var lobbies = yield(_fetch.first(5), "completed")
	for i in range(lobbies.size()):
		var lobby = lobbies[i]
		var node = $Lobbies/List/LobbyEntry.duplicate()
		node.show()
		$Lobbies/List/Entries.add_child(node)
		node.set_lobby(lobby)
		node.rect_position.y += i * 80
	
	$Lobbies/List/Spinner.hide()

func cleaningGameInstance():
	if player && other_player:
		player.queue_free()
		other_player.queue_free()
		curGame.queue_free()
	get_tree().paused = false

func _on_Gotm_lobby_changed():
	if not Gotm.lobby:
		$Lobbies.show()



