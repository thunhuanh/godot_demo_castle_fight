extends PopupPanel

func _on_HostButton_pressed():
	get_tree().get_root().get_node("Main")._on_HostButton_pressed()

func _on_JoinButton_pressed():
	get_tree().get_root().get_node("Main")._on_JoinButton_pressed()
