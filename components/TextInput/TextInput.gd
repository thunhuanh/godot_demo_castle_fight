tool
extends Panel

signal text_changed(new_text)
const ALNUM = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234679";


export(String) var placeholder_text = "" setget set_placeholder_text

func _ready():
	randomize()

func _on_Input_text_changed(new_text):
	emit_signal("text_changed", new_text)
	print(new_text)

func set_placeholder_text(new):
	placeholder_text = new
	$Input.placeholder_text = placeholder_text
	
func get_text():
	return $Input.text

func randomSecret() -> String:
	var out = "";
	for i in range(5):
		out += ALNUM[randi() % ALNUM.length() - 1];
	return out;

func _on_RandomName_clicked(_instance):
	var randomLobbyName = randomSecret()
	$Input.text = randomLobbyName
	emit_signal("text_changed", randomLobbyName)
	
