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

func _make_optimized(polygons: Array) -> Array:
    var result : = Array()
    for p in polygons:
        var optimized = _optimise(p)
        if optimized.size()>2:
            result.append(optimized)
    return result
           
func _optimise(shape: PackedVector2Array) -> PackedVector2Array:
    var result := PackedVector2Array()
    result.append(shape[-2])
    var previous: Vector2 = shape[-2]    
    for i in range(-1,shape.size()-2):        
        var current: Vector2  = shape[i]
        if _vertex_on_border(current):
            result.append(current)
            previous = current
        else:
            var next = shape[i+1]
            var a = previous-current
            var b = next-current
            var angle = absf(rad_to_deg(a.angle_to(b)))
            # обрезаем острые углы
            if (angle>30.0):
                result.append(current)
            previous = current
    return result

func _vertex_on_border(v: Vector2) -> bool:
    var mod = v.abs().posmod(_size)
    var b = 1.0
    return (mod.x<b or mod.x>(_size-b)) or (mod.y<b or mod.y>(_size-b))
