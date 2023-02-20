@tool
class_name WGSurface extends Resource

@export var texture: Texture2D:
    set(value):
        texture = value
        _width = value.get_image().get_width()
        _height = value.get_image().get_height()
        emit_changed()
@export var color: Color = Color.WHITE:
    set(value):
        color = value
        emit_changed()
@export var material: Material:
    set(value):
        material = value
        emit_changed()
@export var scale: Vector2 = Vector2.ONE:
    set(value):
        scale = value
        emit_changed()

var _width: int
var _height: int

func get_width() -> int:
    return _width

func get_height() -> int:
    return _height
