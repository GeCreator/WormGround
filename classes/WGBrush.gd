class_name WGBrush
var radius: float = 25.0
var vertexes: int = 12
var is_active: bool = false
var previous_position: Vector2
var shape: PackedVector2Array

signal draw(shape)

func set_position(pos: Vector2):
    if is_active:
        if previous_position.distance_to(pos)>radius:
            emit_signal('draw', shape)
            previous_position = pos
    else:
        previous_position = pos

    shape = _make_polyline(previous_position, pos, radius, vertexes)

func _make_polyline(from: Vector2, to: Vector2, radius: float, vertex_count: int = 10) -> PackedVector2Array:
    var a: PackedVector2Array = _make_circle(from, radius, vertex_count)
    var b: PackedVector2Array = _make_circle(to, radius, vertex_count)
    a.append_array(b)
    return Geometry2D.convex_hull(a)

func _make_circle(position: Vector2, radius: float, segments: int = 12) -> PackedVector2Array:
    var result : PackedVector2Array = []
    var s: float = 2*PI/segments;
    for i in range(0, segments):
        var x : float = position.x + cos(i*s) * radius
        var y : float = position.y + sin(i*s) * radius
        result.append(Vector2(x, y))
    return result
