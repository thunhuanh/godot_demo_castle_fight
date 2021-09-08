tool
extends Panel

signal text_changed(new_text)

export(String) var placeholder_text = "" setget set_placeholder_text


func _on_Input_text_changed(new_text):
	emit_signal("text_changed", new_text)

func set_placeholder_text(new):
	placeholder_text = new
	$Input.placeholder_text = placeholder_text
	
func get_text():
	return $Input.text

func _on_TextureButton_pressed():
	if OS.has_feature('JavaScript') and (OS.get_name().to_lower() == 'ios' or OS.get_name().to_lower() == 'android'):
		var new_text = JavaScript.eval("""
			window.prompt('GameCode')
		""")
		emit_signal("text_changed", new_text)
