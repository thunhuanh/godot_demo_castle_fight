extends TextureButton

# Called when the node enters the scene tree for the first time.
func _ready():
	var screenSize = OS.get_screen_size()
	var isLandscapeMode = screenSize.x > screenSize.y
	var isPlayingOnMobile = (screenSize.x <= 670 && screenSize.y <= 380) if isLandscapeMode else (screenSize.y <= 670 && screenSize.x <= 380)
	
	if isPlayingOnMobile:
		pass
	else:
		self.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
