@tool
class_name WGCell
signal changed

const DATA_COORDS: int = 0
const DATA_SURFACE: int = 1
var _size: int
var _coords: Vector2
var _surfaces: Dictionary
var _geometry: WGGeometry

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

## cell is empty and can be skipped on save
func is_empty() -> bool:
    return _surfaces.size()==0

func get_data() -> Dictionary:
    var result := {}
    result[DATA_COORDS] = _coords
    result[DATA_SURFACE] = _surfaces
    return result

func set_data(data: Dictionary):
    for v in data[DATA_SURFACE]:
        var n: Array[PackedVector2Array]
        for a in data[DATA_SURFACE][v]:
            n.append(a)
        _surfaces[v] = n
    emit_signal("changed")

func add_surface(surface_id:int, shape: PackedVector2Array):
    if not _surfaces.has(surface_id):
        var v:Array[PackedVector2Array] = []
        _surfaces[surface_id] = v
    
    for sid in _surfaces:
        if surface_id==sid:
            var new_parts = _get_cutted_polygons(shape)
            for p in new_parts:
                _geometry.union(p, _surfaces[sid])
        else:
            _geometry.remove(shape, _surfaces[sid])
            if _surfaces[sid].size() == 0: _surfaces.erase(sid)
    emit_signal('changed')

func get_surfaces() -> Dictionary:
    return _surfaces

func remove(shape: PackedVector2Array):
    for sid in _surfaces:
        _geometry.remove(shape, _surfaces[sid])
        if _surfaces[sid].size() == 0: _surfaces.erase(sid)
    emit_signal('changed')
