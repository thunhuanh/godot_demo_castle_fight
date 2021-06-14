extends Control

var players = {}
var port = 4242
var maxPlayer = 10
var serverAddress = "127.0.0.1"

onready var unit = load("res://Scenes/unit.tscn")
onready var world = get_node("/root/world")

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("connected_to_server", self, "_connected_to_server_ok")
	
func host_server():	
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, maxPlayer)
	get_tree().set_network_peer(peer)
	#checks:
	print("Hosting...This is my ID: ", str(get_tree().get_network_unique_id()))
	$Host.hide()
	$Join.hide()

func join_server():
	var peer_join = NetworkedMultiplayerENet.new()
	peer_join.create_client(serverAddress, port)
	get_tree().set_network_peer(peer_join)	
	#checks:
	print("Joining...This is my ID: ", str(get_tree().get_network_unique_id())) 
	$Host.hide()
	$Join.hide()
	
func _player_connected(id): 
	print("Hello other players. I just connected and I wont see this message!: ", id)
	register_player(id)
	

remote func register_player(id): 
	# adding player to register list
	players[id] = ""
	
	# Server sends the info of existing players back to the new player
	if get_tree().is_network_server():
		# Send my info to the new player
		rpc_id(id, "register_player", 1) #rpc_id only targets player with specified ID
		
		# Send the info of existing players to the new player from ther server's personal list
		for peer_id in players:
			rpc_id(id, "register_player", peer_id) #rpc_id only targets player with specified ID			

		
func game_setup(): #this will setup every player instance for every player
	$Start.hide()
	#first the host will setup the game on their end
	if get_tree().is_network_server(): 	
		var player_instance = unit.instance()	#dont forget to add yourself  server guy!
		player_instance.set_name(str(1))
		player_instance.set_network_master(1)
		player_instance.position = Vector2(512, 256)
		get_node("/root/world/instanceSort").add_child(player_instance)
		player_instance.playerID = str(1) 
		world.emit_signal("setBuilder", player_instance)

	#Next every player will spawn every other player including the server's own client! Try to move this to server only 
	for peer_id in players:
		if peer_id != 1:
			var player_instance = unit.instance()	
			player_instance.set_name(str(peer_id))			
			player_instance.set_network_master(peer_id)
			player_instance.position = Vector2(512, 256)
			get_node("/root/world/instanceSort").add_child(player_instance)
			player_instance.playerID = str(peer_id)
			world.emit_signal("setBuilder", player_instance)

	
