class_name WGBrush
var shape: PackedVector2Array

var _radius: float = 25.0
var _vertexes: int = 12
var _previous_position: Vector2
var _button: int
var _is_active: bool = false

signal draw(shape)
signal erase(shape)

func click(button: int, pressed: bool):
    if button!=MOUSE_BUTTON_LEFT \
    && button!=MOUSE_BUTTON_RIGHT:
        return
    _is_active = pressed
    _button = button
    if _is_active: _do_event()

func update_position(pos:Vector2):
    if _is_active:
        shape = _make_polyline(_previous_position, pos, _radius, _vertexes)
        if _previous_position.distance_to(pos)>(_radius/2):
            _do_event()
            _previous_position = pos
    else:
        shape = _make_circle(pos, _radius, _vertexes)
        _previous_position = pos

func _do_event():
    match(_button):
        MOUSE_BUTTON_LEFT:
            draw.emit(shape)
        MOUSE_BUTTON_RIGHT:
            erase.emit(shape)

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
