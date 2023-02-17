class_name WGSurface extends Resource

@export var texture: Texture2D:
    set(value):
        texture = value
        _width = value.get_image().get_width()
        _height = value.get_image().get_height()
        pass
@export var color: Color = Color.WHITE
@export var material: Material
@export var scale: Vector2 = Vector2.ONE
var _width: int
var _height: int

func get_width() -> int:
    return _width

func get_height() -> int:
    return _height
