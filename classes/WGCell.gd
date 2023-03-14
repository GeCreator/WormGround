@tool
class_name WGCell
signal changed

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

func add_surface(surface_id:int, shape: PackedVector2Array):
    if not _surfaces.has(surface_id):
        _surfaces[surface_id] = []
    
    for sid in _surfaces:
        var polygons = _surfaces[sid]
        if surface_id==sid:
            var new_parts = _get_cutted_polygons(shape)
            for p in new_parts:
                polygons = _geometry.union(p, polygons)
            _surfaces[sid] = polygons #_make_optimized(polygons)
        else:
            polygons = _geometry.remove(shape, polygons)
            _surfaces[sid] = polygons #_make_optimized(polygons)
    emit_signal('changed')

func get_surfaces() -> Dictionary:
    return _surfaces

func remove(shape: PackedVector2Array):
    for sid in _surfaces:
        var polygons = _surfaces[sid]
        polygons = _geometry.remove(shape, polygons)
        _surfaces[sid] = polygons #_make_optimized(polygons)
    emit_signal('changed')
