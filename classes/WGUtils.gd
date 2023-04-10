class_name WGUtils

static func get_shape_area(shape: PackedVector2Array) -> Rect2:
    var result: Rect2
    var min_x: float = INF
    var min_y: float = INF
    var max_x: float = -INF
    var max_y: float = -INF
    # detect shape borders
    for p in shape:
        if p.x<min_x: min_x = p.x
        if p.y<min_y: min_y = p.y
        if p.x>max_x: max_x = p.x
        if p.y>max_y: max_y = p.y
    
    result.position = Vector2(min_x,min_y)
    result.end = Vector2(max_x, max_y)
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
