class_name WGUtils

static func get_shape_area(shape: PackedVector2Array) -> Rect2:
    var result: Rect2 = Rect2(shape[0], Vector2.ZERO)
    for p in shape:
        result = result.expand(p)
    return result

static func get_cell_coords(pos: Vector2, cell_size: int) -> Vector2:
    var pm = pos.posmod(float(cell_size))
    return (pos - pm)/cell_size

# convert coords (e.g. Vector2(10, 20)) to unique int
static func make_cell_id(coords: Vector2, max_range: int) -> int:
    var id: int = 0
    id += int(max_range + coords.x)
    id += pow(max_range, 2) * 2 + coords.y * max_range * 2
    return id

static func castToArrayPackedVector2Array(data: Array) -> Array[PackedVector2Array]:
    var result: Array[PackedVector2Array]
    for a in data:
        result.append(a)
    return result
