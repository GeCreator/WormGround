@tool
class_name WGCell

const DATA_COORDS: int = 0
const DATA_SURFACE: int = 1

static func create(coords: Vector2) -> Array:
    var result: Array = []
    var surfaces: Array[PackedVector2Array]
    result.resize(2)
    result[DATA_COORDS] = coords
    result[DATA_SURFACE] = surfaces
    return result

static func _get_cutted_polygons(shape: PackedVector2Array, coords: Vector2) -> Array[PackedVector2Array]:
    var x = coords.x * WormGround.CELL_SIZE
    var y = coords.y * WormGround.CELL_SIZE
    
    var cut_polygon = PackedVector2Array([
        Vector2(x, y),
        Vector2(x+WormGround.CELL_SIZE, y),
        Vector2(x+WormGround.CELL_SIZE, y+WormGround.CELL_SIZE),
        Vector2(x, y+WormGround.CELL_SIZE),
    ])
    return Geometry2D.intersect_polygons(shape, cut_polygon)

## cell is empty and can be skipped on save
static func is_empty(cell: Array) -> bool:
    return cell[DATA_SURFACE].size()==0

static func set_data(cell: Array, data: Array):
    var n:Array[PackedVector2Array]
    for s in data[DATA_SURFACE]:
        n.append(s)
    cell[DATA_SURFACE] = n
    

static func add_surface(cell: Array, shape: PackedVector2Array, geometry: WGGeometry):
    var new_parts = _get_cutted_polygons(shape, cell[DATA_COORDS])
    for p in new_parts:
        geometry.union(p, cell[DATA_SURFACE])

static func remove(cell: Array, shape: PackedVector2Array, geometry: WGGeometry):
    geometry.remove(shape, cell[DATA_SURFACE])

static func get_id(cell: Array) -> int:
    return WGUtils.make_cell_id(cell[DATA_COORDS], WormGround.MAX_BLOCK_RANGE)
