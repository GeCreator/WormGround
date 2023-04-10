@tool
class_name WGCell

const DATA_COORDS: int = 0
const DATA_SURFACE: int = 1
const DATA_PHYSIC: int = 2

static func create(coords: Vector2) -> Array:
    var result: Array
    result.resize(3)
    result[DATA_COORDS] = coords
    result[DATA_SURFACE] = {}
    result[DATA_PHYSIC] = WGUtils.castToArrayPackedVector2Array([])
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
    return cell[DATA_SURFACE].size()==0 && cell[DATA_PHYSIC].size()==0

static func get_data(cell: Array) -> Dictionary:
    var result := {}
    result[DATA_COORDS] = cell[DATA_COORDS]
    result[DATA_SURFACE] = cell[DATA_SURFACE]
    result[DATA_PHYSIC] = cell[DATA_PHYSIC]
    return result

static func set_data(cell: Array, data: Dictionary, geometry: WGGeometry):
    var surfaces := {}
    for v in data[DATA_SURFACE]:
        var n: Array[PackedVector2Array]
        for a in data[DATA_SURFACE][v]:
            n.append(a)
        surfaces[v] = n
    cell[DATA_SURFACE] = surfaces
    cell[DATA_PHYSIC] = WGUtils.castToArrayPackedVector2Array(data[DATA_PHYSIC])

static func add_surface(cell: Array, surface_id:int, shape: PackedVector2Array, geometry: WGGeometry):
    var surfaces: Dictionary = cell[DATA_SURFACE]
    if not surfaces.has(surface_id):
        var v:Array[PackedVector2Array] = []
        surfaces[surface_id] = v
    
    var new_parts = _get_cutted_polygons(shape, cell[DATA_COORDS])
    for p in new_parts:
        geometry.union(p, cell[DATA_PHYSIC])
    
    for sid in surfaces:
        if surface_id==sid:
            for p in new_parts:
                geometry.union(p, surfaces[sid])
        else:
            for p in new_parts:
                geometry.remove(p, surfaces[sid])

static func remove(cell: Array, shape: PackedVector2Array, geometry: WGGeometry):
    geometry.remove(shape, cell[DATA_PHYSIC])
    var surfaces = cell[DATA_SURFACE]
    for sid in surfaces:
        geometry.remove(shape, surfaces[sid])

static func get_id(cell: Array) -> int:
    return WGUtils.make_cell_id(cell[DATA_COORDS], WormGround.MAX_BLOCK_RANGE)
