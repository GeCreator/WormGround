@tool
class_name WGBorder

static func render(canvas: Array, cell: Array, thickness: float, color: Color) -> void:
    var canvas_rid = canvas[WGCanvas.DATA_CANVAS]
    var shapes: Array[PackedVector2Array] = cell[WGCell.DATA_SURFACE]
    var used_segments:= _create_used_segments(shapes)
    for shape in shapes:
        var parts = _get_parts(shape.size(), _get_bad_segments(shape, used_segments))
        for line in _make_polylines(shape, parts):
            RenderingServer.canvas_item_add_polyline(canvas_rid, line, PackedColorArray([color]), thickness)

static func _create_used_segments(shapes: Array[PackedVector2Array]) -> Dictionary:
    var result: Dictionary
    for shape in shapes:
        var size := shape.size()
        for n in size:
            var s:= _get_segment(n, shape, size)
            if int(s[0].y)==int(s[1].y):
                var key:= _used_segments_key(s[0])
                if not result.has(key): result[key] = 0
                result[key] += 1
    return result

static func _used_segments_key(a:Vector2) -> int:
    return int(a.y)
    
static func _make_polylines(shape: PackedVector2Array, parts: Array) -> Array[PackedVector2Array]:
    
    var result :Array[PackedVector2Array]
    for part in parts:
        var s: PackedVector2Array = []
        for n in part: s.append(shape[n])
        result.append(s)
    return result

static func _get_bad_segments(shape: PackedVector2Array, used_segments: Dictionary) -> PackedInt32Array:
    var result: PackedInt32Array = []
    var size: int = shape.size()
    for n in size:
        var segment:= _get_segment(n, shape, size)
        if _segment_on_border(segment, used_segments):
            result.append(n)
    return result

static func _segment_on_border(segment: PackedVector2Array, used_segments: Dictionary) -> bool:
    var a: Vector2 = segment[0].posmod(WormGround.CELL_SIZE)
    var b: Vector2 = segment[1].posmod(WormGround.CELL_SIZE)

    if int(a.x)==int(b.x):
        return int(a.x)==0
    if int(a.y)==int(b.y):
        var key:=_used_segments_key(segment[0])
        if used_segments.has(key) and used_segments[key]>1:
            return true
        return int(a.y)==0
    return false

## return PackedVector2Array with 2 points of segment n
static func _get_segment(n: int, polygon: PackedVector2Array, size: int) -> PackedVector2Array:
    return PackedVector2Array([
        polygon[wrapi(n,0, size)],
        polygon[wrapi(n+1,0, size)]
    ])
    
static func _segment_is_on_border(segment: PackedVector2Array) -> bool:
    return true

static func _get_parts(shape_size: int, bad_segments: Array) -> Array:
    var indexes = range(0,shape_size)
    var collection = []
    var b = bad_segments.pop_front()
    var part = []
    for i in indexes:
        if i==b:
            b = bad_segments.pop_front()
            if part.size()>0:
                collection.append(part)
                part = []
        else:
            part.append(i)

    if part.size()>0:
        collection.append(part)
    
    for c in collection:
        var value: int = c[-1]+1
        c.append(value if value<=indexes[-1] else 0)
    
    if collection.size()>1:
        if collection[0][0]==collection[-1][-1]:
            var append = collection.pop_front()
            collection[-1].pop_back()
            collection[-1].append_array(append)
            
    return collection
