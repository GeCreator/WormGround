@tool
class_name WGCell
signal changed

const DATA_COORDS: int = 0
const DATA_SURFACE: int = 1
const DATA_PHYSIC: int = 2

var _size: int
var _coords: Vector2
var _surfaces: Dictionary
var _physic: WGPhysic

func _init(coords: Vector2, size: int, physic: WGPhysic):
    _coords = coords
    _size = size
    _physic = physic

func _get_cutted_polygons(shape: PackedVector2Array) -> Array[PackedVector2Array]:
    var x = _coords.x * _size
    var y = _coords.y * _size
    
    var cut_polygon = PackedVector2Array([
        Vector2(x, y),
        Vector2(x+_size, y),
        Vector2(x+_size, y+_size),
        Vector2(x, y+_size),
    ])
    return Geometry2D.intersect_polygons(shape, cut_polygon)

## cell is empty and can be skipped on save
func is_empty() -> bool:
    return _surfaces.size()==0 and _physic.is_empty()

func get_data() -> Dictionary:
    var result := {}
    result[DATA_COORDS] = _coords
    result[DATA_SURFACE] = _surfaces
    result[DATA_PHYSIC] = _physic.get_shapes()
    return result

func set_data(data: Dictionary):
    for v in data[DATA_SURFACE]:
        var n: Array[PackedVector2Array]
        for a in data[DATA_SURFACE][v]:
            n.append(a)
        _surfaces[v] = n
    _physic.set_shapes(data[DATA_PHYSIC])
    
    emit_signal("changed")

func add_surface(surface_id:int, shape: PackedVector2Array, geometry: WGGeometry):
    if not _surfaces.has(surface_id):
        var v:Array[PackedVector2Array] = []
        _surfaces[surface_id] = v
    
    var new_parts = _get_cutted_polygons(shape)
    for p in new_parts: _physic.add(p, geometry)
    
    for sid in _surfaces:
        if surface_id==sid:
            for p in new_parts:
                geometry.union(p, _surfaces[sid])
        else:
            for p in new_parts:
                geometry.remove(p, _surfaces[sid])
    emit_signal('changed')

func get_surfaces() -> Dictionary:
    return _surfaces

func remove(shape: PackedVector2Array, geometry: WGGeometry):
    _physic.remove(shape, geometry)
    
    for sid in _surfaces:
        geometry.remove(shape, _surfaces[sid])
    emit_signal('changed')
