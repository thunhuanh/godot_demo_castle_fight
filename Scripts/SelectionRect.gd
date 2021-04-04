extends Node2D


var dragStart = Vector2.ZERO
var dragEnd = Vector2.ZERO
var dragging = false


func _draw():
	if dragging:
		draw_rect(Rect2(dragStart, dragEnd - dragStart), Color(1, 1, 1), false)


func update_status(start, end, isDrag):
	dragStart = start
	dragEnd = end
	dragging = isDrag
	update()
