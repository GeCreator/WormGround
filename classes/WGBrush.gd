class_name WGBrush
var shape: PackedVector2Array

var _radius: float = 15.0
var _vertexes: int = 12
var _previous_position: Vector2
var _current_position: Vector2
var _button: int
var _is_active: bool = false
var _is_hold: bool = false

signal draw(shape)
signal erase(shape)
signal changed # position/shape/size of brush changed

func set_size(size:float):
    _radius = size
    changed.emit()


func click(button: int, pressed: bool):
    if button!=MOUSE_BUTTON_LEFT \
    && button!=MOUSE_BUTTON_RIGHT:
        return
    _is_active = pressed
    _button = button
    if _is_active: _do_event()

func update_position(pos:Vector2):
    _current_position = pos
    _build_shape()
    if _is_active:
        if _previous_position.distance_to(_current_position)>(_radius/2):
            _do_event()
    else:
        if not _is_hold:
            _previous_position = pos

func hold(pressed: bool):
    _is_hold = pressed

func _do_event():
    _previous_position = _current_position
    match(_button):
        MOUSE_BUTTON_LEFT:
            draw.emit(shape)
        MOUSE_BUTTON_RIGHT:
            erase.emit(shape)
    _build_shape()

func _build_shape() -> void:
    shape = _make_polyline(_previous_position, _current_position, _radius, _vertexes)
    changed.emit()

func _make_polyline(from: Vector2, to: Vector2, radius: float, vertex_count: int = 10) -> PackedVector2Array:
    var a: PackedVector2Array = _make_circle(from, radius, vertex_count)
    var b: PackedVector2Array = _make_circle(to, radius, vertex_count)
    a.append_array(b)
    return Geometry2D.convex_hull(a)

func _make_circle(position: Vector2, radius: float, segments: int = 12) -> PackedVector2Array:
    var result : PackedVector2Array = []
    var s: float = 2*PI/segments;
    for i in range(0, segments+1):
        var x : float = position.x + cos(i*s) * radius
        var y : float = position.y + sin(i*s) * radius
        result.append(Vector2(x, y))
    return result
