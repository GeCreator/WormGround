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
        var v:Array[PackedVector2Array] = []
        _surfaces[surface_id] = v
    
    for sid in _surfaces:
        if surface_id==sid:
            var new_parts = _get_cutted_polygons(shape)
            for p in new_parts:
        else:
            _geometry.remove(shape, _surfaces[sid])
    emit_signal('changed')

func get_surfaces() -> Dictionary:
    return _surfaces

func remove(shape: PackedVector2Array):
    for sid in _surfaces:
        _geometry.remove(shape, _surfaces[sid])
    emit_signal('changed')
