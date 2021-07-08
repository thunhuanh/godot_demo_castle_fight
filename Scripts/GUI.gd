extends Control

var players = {}
var port = 4242
var maxPlayer = 2
var serverAddress = "127.0.0.1"

onready var unit = load("res://Scenes/player.tscn")
onready var hostButton : Button = $Host
onready var joinButton : Button = $Join
onready var startButton : Button = $Start
onready var serverAddressInput : LineEdit = $ServerAddress

func _ready():
	var error = get_tree().connect("network_peer_connected", self, "_player_connected")
	if error:
		print(error)

	
func host_server():	
	if len(serverAddress.split(".", true)) < 4:
		return
	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, maxPlayer)
	get_tree().set_network_peer(peer)
	#checks:
	print("Hosting...This is my ID: ", str(get_tree().get_network_unique_id()))
	hostButton.hide()
	joinButton.hide()
#	startButton.hide()
	serverAddressInput.hide()

func join_server():
	var peer_join = NetworkedMultiplayerENet.new()
	peer_join.create_client(serverAddress, port)
	get_tree().set_network_peer(peer_join)	
	#checks:
	print("Joining...This is my ID: ", str(get_tree().get_network_unique_id())) 
	hostButton.hide()
	joinButton.hide()
	serverAddressInput.hide()
	
func _player_connected(id): 
	print("Hello other players. I just connected and I wont see this message!: ", id)
	register_player(id)
	
remotesync func toggleStart():
	if startButton.visible:
		startButton.hide()
	else:
		startButton.show()

remote func register_player(id): 
	# adding player to register list
	players[id] = ""
	if len(players) >= maxPlayer:
		rpc("toggleStart")
		toggleStart()
	
	# Server sends the info of existing players back to the new player
	if get_tree().is_network_server():
		# Send my info to the new player
		rpc_id(id, "register_player", 1) #rpc_id only targets player with specified ID
		
		# Send the info of existing players to the new player from ther server's personal list
		for peer_id in players:
			rpc_id(id, "register_player", peer_id) #rpc_id only targets player with specified ID			

		
func game_setup(): #this will setup every player instance for every player
	startButton.hide()
	#first the host will setup the game on their end
	if get_tree().is_network_server(): 	
		var player_instance = unit.instance()	#dont forget to add yourself  server guy!
		player_instance.set_name(str(1))
		player_instance.set_network_master(1)
		player_instance.position = Vector2(512, 256)
		get_node("/root/world/Game/instanceSort").add_child(player_instance)
		player_instance.playerID = str(1)

	#Next every player will spawn every other player including the server's own client! Try to move this to server only 
	for peer_id in players:
		var player_instance = unit.instance()	
		player_instance.set_name(str(peer_id))			
		player_instance.set_network_master(peer_id)
		player_instance.position = Vector2(512, 256)
		if peer_id != 1:
			player_instance.unitOwner = "enemy"
		get_node("/root/world/Game/instanceSort").add_child(player_instance)
		player_instance.playerID = str(peer_id)

func _on_LineEdit_text_changed(new_text: String):
	serverAddress = new_text
