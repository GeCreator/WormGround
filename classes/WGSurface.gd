@tool
class_name WGSurface extends Resource

@export var texture: Texture2D:
    set(value):
        texture = value
        if value is Texture2D:
            _size = Vector2(
                value.get_image().get_width(),
                value.get_image().get_height()
            )
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

var _size: Vector2

func get_size() -> Vector2:
    return _size
