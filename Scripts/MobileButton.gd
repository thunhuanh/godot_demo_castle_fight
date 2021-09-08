extends TextureButton

# Called when the node enters the scene tree for the first time.
func _ready():
	var osName = OS.get_name().to_lower()
	if osName == 'ios' or osName == 'android':
		pass
	else:
		self.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
