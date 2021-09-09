extends Node2D

var on = true
var gridSize = 32

func _draw():
	if on:
		var cameraName = "camera"
		var size = get_viewport_rect().size  * get_parent().get_node(cameraName).zoom / 2
		var cam = get_parent().get_node(cameraName).position
		for i in range(int((cam.x - size.x) / gridSize) - 1, int((size.x + cam.x) / gridSize) + 1):
			draw_line(Vector2(i * gridSize, cam.y + size.y + 100), Vector2(i * gridSize, cam.y - size.y - 100), "ff0000")
		for i in range(int((cam.y - size.y) / gridSize) - 1, int((size.y + cam.y) / gridSize) + 1):
			draw_line(Vector2(cam.x + size.x + 100, i * gridSize), Vector2(cam.x - size.x - 100, i * gridSize), "ff0000")

func _process(_delta):
	update()
