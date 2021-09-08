extends Node2D

var OtherPlayer = preload("res://Scenes/player.tscn")
var Player = preload("res://Scenes/player.tscn")
var GameScene = preload("res://Scenes/Game.tscn")
var curGame = null


var player
var other_player

func _ready():
	if OS.get_name() == "Windows":
		$Menu/VBoxContainer/GameCode.remove_child($Menu/VBoxContainer/GameCode/TextureButton)
# warning-ignore:return_value_discarded
	OnlineGame.connect("game_connected", self, "_on_game_connected")
# warning-ignore:return_value_discarded
	OnlineGame.connect("game_disconnected", self, "_on_game_disconnected")
# warning-ignore:return_value_discarded
	OnlineGame.connect("game_info", self, "_on_game_info")

func _on_game_connected(other_playerId):
	if curGame:
		cleaningGameInstance()

	curGame = GameScene.instance()

	player = Player.instance()
	var playerID = get_tree().get_network_unique_id()
	player.set_network_master(playerID)
	player.set_name(str(playerID))
	player.set_position(Vector2(256, 256))
	if MultiplayerClient.hosting :
		player.playerName = "BLUE"
		curGame.builderID = 1
		curGame.get_node("camera2D").position = Vector2(256 - get_viewport().size.x / 2, 256 - get_viewport().size.y / 2)
	else:
		player.unitOwner = "enemy"
		player.playerName = "RED"
		player.set_position(Vector2(777, 256))
		curGame.get_node("camera2D").position = Vector2(777 - get_viewport().size.x / 2, 256 - get_viewport().size.y / 2)
		curGame.builderID = 2
	curGame.get_node("instanceSort").add_child(player)

	other_player = OtherPlayer.instance()
	other_player.set_name(str(other_playerId))
	other_player.set_network_master(other_playerId)
	other_player.set_position(Vector2(512, 256))
	if MultiplayerClient.hosting :
		other_player.unitOwner = "enemy"
		other_player.playerName = "RED"
	else:
		other_player.unitOwner = "ally"
		other_player.playerName = "BLUE"
	curGame.get_node("instanceSort").add_child(other_player)
	add_child(curGame)
	
	$Menu.hide()
	$GameCode.hide()
	$WaitingLabel.hide()

func _on_game_disconnected():
	cleaningGameInstance()

	$GameCode.hide()
	$Menu.show()

func cleaningGameInstance():
	if player && other_player:
		player.queue_free()
		other_player.queue_free()
	remove_child(curGame)
	get_tree().paused = false

func _on_game_info(game):
	$GameCode.text = "Game Code: %s" % game
	if MultiplayerClient.hosting:
		$WaitingLabel.text = 'Waiting for player...'
	$GameCode.show()

func _on_HostButton_pressed():
	if curGame:
		cleaningGameInstance()
	OnlineGame.host(GlobalVar.signal_server_url)
	$WaitingLabel.text = 'Waiting for server...'
	$WaitingLabel.show()
	$Menu.hide()

func _on_JoinButton_pressed():
	if curGame:
		cleaningGameInstance()
	if $Menu/VBoxContainer/GameCode.text == "":
		return
	OnlineGame.join(GlobalVar.signal_server_url, $Menu/VBoxContainer/GameCode.text)
	$WaitingLabel.text = 'Joining room ' + $Menu/VBoxContainer/GameCode.text
	$WaitingLabel.show()
	$Menu.hide()

func _on_TextureButton_pressed():
	if OS.has_feature('JavaScript'):
		$Menu/VBoxContainer/GameCode.text = JavaScript.eval("""
			window.prompt('GameCode')
		""")
