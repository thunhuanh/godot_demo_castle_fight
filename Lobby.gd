extends Node2D

var players = {}
var curGame

onready var GameScene = preload("res://Scenes/Game.tscn")
onready var PlayerScene = preload("res://Scenes/player.tscn")

var player
var other_player

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("connected_to_server", self, "_connected_to_server_ok")
	
func host_server():	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(4242, 10)
	get_tree().set_network_peer(peer)
	#checks:
	print("Hosting...This is my ID: ", str(get_tree().get_network_unique_id()))
	$Host.hide()
	$Join.hide()

func join_server():
	var peer_join = NetworkedMultiplayerENet.new()
	peer_join.create_client("127.0.0.1", 4242)
	get_tree().set_network_peer(peer_join)	
	#checks:
	print("Joining...This is my ID: ", str(get_tree().get_network_unique_id())) 
	$Host.hide()
	$Join.hide()
	
func _player_connected(other_playerId): #when someone else connects, I will register the player into my player list dictionary
	$"START GAME!".hide()
	#first the host will setup the game on their end
#		lockLobby()
	
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
#This function not needed, just to double check ID		
func _connected_to_server_ok(): 	
	print("(My eyes only)I connected to the server! This is my ID: ", str(get_tree().get_network_unique_id()))	
	#rpc("register_player", get_tree().get_network_unique_id())
#	if game_started:

remote func register_player(id): 
	print("Everyone sees this.. adding this id to your array! ", id) # everyone sees this
	#the server will see this... better tell this guy who else is already in...
	#if !(id in players):
	players[id] = ""
	
	# Server sends the info of existing players back to the new player
	if get_tree().is_network_server():
		# Send my info to the new player
		rpc_id(id, "register_player", 1) #rpc_id only targets player with specified ID
		
		# Send the info of existing players to the new player from ther server's personal list
		for peer_id in players:
			rpc_id(id, "register_player", peer_id) #rpc_id only targets player with specified ID			
