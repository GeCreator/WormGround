@tool
class_name WGCell
signal changed

const DATA_COORDS: int = 0
const DATA_SURFACE: int = 1
const DATA_PHYSIC: int = 2

var _debug_history: Array
var _size: int
var _coords: Vector2
var _surfaces: Dictionary
var _geometry: WGGeometry
var _physics_shapes: Array[PackedVector2Array]

func _init(coords: Vector2, size: int):
    _geometry = WGGeometry.new()
    _coords = coords
    _size = size

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

func _add_hist(shape: PackedVector2Array, type: int):
    var hist = []
    if _surfaces.size()>0:
        for s in _surfaces.values()[0]:
            hist.append(s.duplicate())
    if _debug_history.size()>100: _debug_history.pop_front()
    _debug_history.append([type, _get_cutted_polygons(shape), hist])

## cell is empty and can be skipped on save
func is_empty() -> bool:
    return _surfaces.size()==0 and _physics_shapes.size()==0

func get_data() -> Dictionary:
    var result := {}
    result[DATA_COORDS] = _coords
    result[DATA_SURFACE] = _surfaces
    result[DATA_PHYSIC] = _physics_shapes
    return result

func set_data(data: Dictionary):
    for v in data[DATA_SURFACE]:
        var n: Array[PackedVector2Array]
        for a in data[DATA_SURFACE][v]:
            n.append(a)
        _surfaces[v] = n
    for s in data[DATA_PHYSIC]:
        _physics_shapes.append(s)
    emit_signal("changed")

func add_surface(surface_id:int, shape: PackedVector2Array):
    #_add_hist(shape, 0)
    if not _surfaces.has(surface_id):
        var v:Array[PackedVector2Array] = []
        _surfaces[surface_id] = v
    
    var new_parts = _get_cutted_polygons(shape)
    for p in new_parts:
        _geometry.union(p, _physics_shapes)
    
    for sid in _surfaces:
        if surface_id==sid:
            for p in new_parts:
                _geometry.union(p, _surfaces[sid])
        else:
            _geometry.remove(shape, _surfaces[sid])
            if _surfaces[sid].size() == 0: _surfaces.erase(sid)
    emit_signal('changed')

func get_surfaces() -> Dictionary:
    return _surfaces

func get_physics_shapes() -> Array[PackedVector2Array]:
    return _physics_shapes

func remove(shape: PackedVector2Array):
    #_add_hist(shape, 1)
    _geometry.remove(shape, _physics_shapes)
    
    for sid in _surfaces:
        _geometry.remove(shape, _surfaces[sid])
        if _surfaces[sid].size() == 0: _surfaces.erase(sid)
    emit_signal('changed')
