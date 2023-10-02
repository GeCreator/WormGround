class_name WGGeometry

signal error(info)
const CUT_LINE_SIZE = 10000.0
const BAN_ANGLE:= 0.0349 # TAU/180 = 2°
    
const SNAP_GRID_SIZE := Vector2(1.0, 1.0)

const RES_NORMAL: int = 0 # normal shape
const RES_BROKEN: int = 1 # shape with holes inside
const RES_ANOMALY: int = 2 # shape have multiple normal shapes with holes
const RES_MULTIPLE_NORMAL: int = 3 # multiple normal shapes

var _debug: bool = false
var _debug_info: Dictionary
var _minimal_shape_size: float # min sum length of polygon segments

func set_debug(debug:bool) -> void:
    _debug = debug

func _init(minimal_shape_size: float = 30.0)  -> void:
    _minimal_shape_size = minimal_shape_size

func union(add: PackedVector2Array, shapes: Array[PackedVector2Array]):
    if _debug: _add_debug_info(add, shapes, 'union')
    add = add.duplicate()
    var holes: Array[PackedVector2Array]
    var intersected: Array[PackedVector2Array]
    var remove_list: PackedInt32Array
    
    for i in shapes.size():
        if _shape_is_intersects(shapes[i], add):
            intersected.append(shapes[i])
            remove_list.append(i)
    _remove_by_list(shapes, remove_list)

    var clipped : Array[PackedVector2Array] = []
    for shape in intersected:
        var m = Geometry2D.merge_polygons(add, shape)
        match(_res_analysis(m)):
            RES_NORMAL:
                _clip_from_polygons(shape, holes)
                add.clear()
                add.append_array(m[0])
            RES_BROKEN:
                for err in m:
                    if Geometry2D.is_polygon_clockwise(err):
                        holes.append(err)
                    else:
                        _clip_from_polygons(shape, holes)
                        add.clear()
                        add.append_array(err)
            RES_MULTIPLE_NORMAL:
                add.clear()
                add.append_array(m.pop_front())
                clipped.append_array(m)
    clipped.append(add)
    
    if holes.size()>0:
        for hole in holes:
            _clip_from_polygons(hole, clipped)
    else:
        _normalize(clipped)
    shapes.append_array(clipped)

func remove(remove:PackedVector2Array, shapes:Array[PackedVector2Array]):
    if _debug: _add_debug_info(remove, shapes, 'remove')
    remove = remove.duplicate()
    _clip_from_polygons(remove, shapes)

func _normalize(shapes: Array[PackedVector2Array]):
    var result: Array[PackedVector2Array]
    for shape in shapes:
        if _it_small_shape(shape): continue
        result.append_array(_normalize_shape(shape, 3))
    shapes.clear()
    shapes.append_array(result)

func _normalize_shape(shape: PackedVector2Array, iter: int) -> Array[PackedVector2Array]:
    var result: Array[PackedVector2Array]
    # _snap_to_grid(shape)
    _remove_short_segments(shape)
    # _remove_bad_angles(shape)
    # _unchunk_shape(shape)
    return _fix_shape(shape)

    

    
    return result

func decompose(shapes: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
    var result: Array[PackedVector2Array]
    for shape in shapes:
        result.append_array(Geometry2D.decompose_polygon_in_convex(shape))
    return result

func _unchunk_shape(shape: PackedVector2Array):
    var size:= shape.size()
    var points: Dictionary
    for n in size:
        var point = shape[n]
        if _point_touch_border(point): continue
        var coords := int(point.x) + int(point.y)*1000
        
        if not points.has(coords):
            points[coords] = PackedInt32Array()
        points[coords].append(n)
    for k in points:
        var list: PackedInt32Array = points[k]
        if list.size()>1:
            for n in list:
                var a:= shape[n-1]
                var b:= shape[n]
                var c:= shape[wrapi(n+1,0,size)]
                a -= b
                c -= b
                shape[n] = b+(a.normalized()+c.normalized()).normalized()

            # if _segment_is_horizontal(segment):
func _remove_short_segments(shape:PackedVector2Array):
    var remove_list: PackedInt32Array
    var size := shape.size()
    if size<2: return
    var previous_length = _get_segment_length(_get_segment(-1, shape))
    for i in size:
        var current_length = _get_segment_length(_get_segment(i, shape))
        if (previous_length+current_length)<10.0:
            remove_list.append(i)
            previous_length = previous_length+current_length
        else:
            previous_length = current_length

    _remove_by_list(shape, remove_list)

func _snap_to_grid(shape: PackedVector2Array):
    for i in shape.size():
        shape[i] = shape[i].snapped(SNAP_GRID_SIZE)

func _it_small_shape(shape: PackedVector2Array) -> bool:
    var total_length: float = 0
    for n in shape.size():
        var segment:= _get_segment(n, shape)
        total_length += _get_segment_length(segment)
        if total_length>_minimal_shape_size:
            return false
    return total_length<_minimal_shape_size

func _is_bad_angle(a: Vector2, b: Vector2, c: Vector2) -> bool:
    var r1: = (a-b).angle()
    var r2: = (c-b).angle()
    var diff: float = absf(r1-r2)
    if absf(PI-diff)<BAN_ANGLE: # obtuse angle >178°
        return true
    elif diff<BAN_ANGLE: # sharp angle <2°
        return true
    return false

func _remove_bad_angles(shape: PackedVector2Array):
    var remove_list: PackedInt32Array
    var size : int = shape.size()
    for i in size:
        var a: Vector2 = shape[wrapi(i-1, 0, size)]
        var b: Vector2  = shape[i]
        var c: Vector2  = shape[wrapi(i+1, 0, size)]
        var r1: = (a-b).angle()
        var r2: = (c-b).angle()
        var diff: float = absf(r1-r2)
        if absf(PI-diff)<BAN_ANGLE: # remove obtuse angle >178°
            remove_list.append(i)
        elif diff<BAN_ANGLE: # remove sharp angle <2°
            var s1:= _get_segment(i-1, shape)
            var s2:= _get_segment(i, shape)
            if _get_segment_length(s1)>_get_segment_length(s2):
                shape[wrapi(i+1,0,size)] = _get_segment_intersection(s1, _get_segment(i+1, shape))
            else:
                shape[wrapi(i-1,0,size)] = _get_segment_intersection(_get_segment(i-2, shape), s2)
            remove_list.append(i)
    _remove_by_list(shape, remove_list)

func _remove_by_list(data, remove_list: PackedInt32Array):
    remove_list.sort()
    remove_list.reverse()
    for n in remove_list:
        data.remove_at(n)

## return PackedVector2Array with 2 points of segment n
func _get_segment(n: int, polygon: PackedVector2Array) -> PackedVector2Array:
    var size = polygon.size()
    return PackedVector2Array([
        polygon[wrapi(n,0, size)],
        polygon[wrapi(n+1,0, size)]
    ])

func _segment_is_horizontal(segment: PackedVector2Array) -> bool:
    var a: Vector2 = segment[0]
    var b: Vector2 = segment[1]
    return absf(a.y-b.y)<0.001

func _point_touch_border(point: Vector2) -> bool:
    point = point.posmod(200.0)
    return point.x<1.0 || point.y<1.0 || point.x>199.0 || point.y > 199.0

func _get_segment_length(segment: PackedVector2Array) -> float:
    return segment[0].distance_to(segment[1])

func _get_segment_intersection(s1: PackedVector2Array, s2: PackedVector2Array) -> Vector2:
    var a: Vector2 = s1[0]
    var b: Vector2 = s1[1]
    var c: Vector2 = s2[0]
    var d: Vector2 = s2[1]
    
    b = a+(b-a)*2.0
    c = d+(c-d)*2.0
    var point = Geometry2D.segment_intersects_segment(a,b,c,d)
    if point!=null:
        return point
    return s1[1] # mean error :]

func _clip_from_polygons(clip: PackedVector2Array, shapes: Array[PackedVector2Array]):
    var result: Array[PackedVector2Array]
    var intersected: Array[PackedVector2Array]
    var remove_list: PackedInt32Array

    for i in shapes.size():
        if _shape_is_intersects(shapes[i], clip):
            intersected.append(shapes[i])
            remove_list.append(i)
    _remove_by_list(shapes, remove_list)

    for shape in intersected:
        var res = Geometry2D.clip_polygons(shape, clip)
        match (_res_analysis(res)):
            RES_NORMAL:
                result.append(res[0])
            RES_BROKEN:
                result.append_array(_resolve_hole_errors(res))
            RES_MULTIPLE_NORMAL:
                result.append_array(res)
            RES_ANOMALY:
                var holes: Array[PackedVector2Array]
                var normal: Array[PackedVector2Array]
                for err in res:
                    if Geometry2D.is_polygon_clockwise(err): # is hole
                        holes.append(err)
                    else:
                        normal.append(err)
                for h in holes:
                    _clip_from_polygons(h,normal)
                result.append_array(normal)
    _normalize(result)
    shapes.append_array(result)

func _resolve_hole_errors(shapes: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
    var result :Array[PackedVector2Array]
    var holes: Array[PackedVector2Array]
    for shape in shapes:
        if Geometry2D.is_polygon_clockwise(shape): # is hole
            holes.append(shape)
        else:
            result.append(shape)
    
    for hole in holes:
        var addons: Array[PackedVector2Array] = []
        if result.size()>1:
            hole.reverse()
            _clip_from_polygons(hole, result)
            continue
        var x := _remove_hole(result[0], hole)
        result[0].clear()
        result[0].append_array(x[0])
        if x.size()==2:
            result.append(x[1])
    return result

func _remove_hole(normal: PackedVector2Array, hole: PackedVector2Array) -> Array[PackedVector2Array]:
    if _it_small_shape(hole): return [normal.duplicate()]
    var p:=_get_left_right_vertexes(hole)
    var hlp: Vector2 = hole[p[0]] # hole leftmost point
    var hrp: Vector2 = hole[p[1]] # hole rightmost point
    var line_a:= _get_collision_line(hlp, normal, -CUT_LINE_SIZE)
    var line_b:= _get_collision_line(hrp, normal, CUT_LINE_SIZE)
    
    var sl: int = -1; var pl:=Vector2.INF # segment left; point left
    var sr: int = 0; var pr:=Vector2.INF # segment right; point right
    
    var nsize: int = normal.size()
    for n in nsize:
        var sgm = _get_segment(n, normal)
        if sgm[0].y>sgm[1].y: 
            var x = Geometry2D.segment_intersects_segment(line_a[0],line_a[1],sgm[0],sgm[1])
            if x!=null and hlp.distance_squared_to(x)<hlp.distance_squared_to(pl):
                sl = n; pl=x
        else:
            var x = Geometry2D.segment_intersects_segment(line_b[0],line_b[1],sgm[0],sgm[1])
            if x!=null and hrp.distance_squared_to(x)<hrp.distance_squared_to(pr):
                sr = n; pr=x
    if not pl.is_finite() or not pr.is_finite():
        return [normal]
    # build top segment
    var top_segment: PackedVector2Array
    top_segment.append(pl)
    top_segment.append_array(_extract_sequence(sl+1,sr,normal))
    top_segment.append(pr)
    top_segment.append_array(_extract_sequence(p[1],p[0],hole))
    # build bottom segment
    var bottom_segment: PackedVector2Array
    bottom_segment.append(pr)
    bottom_segment.append_array(_extract_sequence(sr+1,sl,normal))
    bottom_segment.append(pl)
    bottom_segment.append_array(_extract_sequence(p[0],p[1],hole))
    
    return [top_segment, bottom_segment]

func _extract_sequence(from: int, to: int, shape:PackedVector2Array) -> PackedVector2Array:
    var result: PackedVector2Array
    var size: int = shape.size()
    for n in size:
        var idx = wrapi(from+n,0,size)
        result.append(shape[idx])
        if idx == to:
            break
    return result

func _get_collision_line(point: Vector2, shape:PackedVector2Array, max_size: float) -> PackedVector2Array:
        var line = PackedVector2Array([point, Vector2(point.x+max_size,point.y)])
        # try make line shorter
        var clip := Geometry2D.clip_polyline_with_polygon(line, shape)
        if clip.size()>0:
            var r := clip[0]
            r[0].x += -1.0 if max_size < 0 else 1.0
            r[1].x += 1.0 if max_size < 0 else -1.0
        return line

## return leftmost and rightmost vertex of shape
## [0] - left vertex, [1] - right vertex
func _get_left_right_vertexes(shape: PackedVector2Array) -> PackedInt32Array:
    var result := PackedInt32Array([0,0])
    var i: int = 0
    var up: float = INF
    var down: float = -INF
    
    for p in shape:
        if p.y<up:
            up=p.y
            result[0] = i
        if p.y>down:
            down = p.y
            result[1] = i
        i+=1
    return result

func _shape_is_intersects(a: PackedVector2Array, b: PackedVector2Array):
    return Geometry2D.intersect_polygons(a,b).size()>0

func _has_triangulate_error(shape: PackedVector2Array) -> bool:
    return Geometry2D.triangulate_polygon(shape).size()==0

func _has_decompose_error(shape: PackedVector2Array) -> bool:
    return Geometry2D.decompose_polygon_in_convex(shape).size()==0

# analyse result of Geometry2D operations
# return RES_... information
func _res_analysis(res: Array) -> int:
    if res.size()==1: return RES_NORMAL
    
    var normal: int = 0
    var inverted: int = 0
    for s in res:
        if Geometry2D.is_polygon_clockwise(s):
            inverted += 1
        else:
            normal += 1
    
    if normal==1 and inverted>0: return RES_BROKEN
    if normal>1 and inverted==0: return RES_MULTIPLE_NORMAL
    
    return RES_ANOMALY

func _fix_shape(shape: PackedVector2Array, level: int = 0) -> Array[PackedVector2Array]:
    var result : Array[PackedVector2Array]
    if not _has_triangulate_error(shape) or level>10:
        return [shape]

    var N = shape.size()
    var K = N-1
    for i in N-2:
        var segment_a = _get_segment(i, shape)
        for j in range(i+2, K):
            var segment_b = _get_segment(j, shape)
            var intersected = Geometry2D.segment_intersects_segment(segment_a[0], segment_a[1], segment_b[0], segment_b[1])
            if intersected:
                var shape_a = PackedVector2Array([intersected])
                var shape_b = PackedVector2Array([intersected])
                var t = _get_segment(i+1, shape)
                if Geometry2D.segment_intersects_segment(t[0],t[1], segment_b[0], segment_b[1]):
                    shape_a.append_array(_extract_sequence(j+1,i,shape))
                    shape_b.append_array(_extract_sequence(i+2,j,shape))
                else:
                    shape_a.append_array(_extract_sequence(j+2,i,shape))
                    shape_b.append_array(_extract_sequence(i+1,j,shape))
                result.append_array(_fix_shape(shape_a, level+1))
                result.append_array(_fix_shape(shape_b, level+1))
                return result
        K=N
    return result

# + - - - - - - - +
# |  DEV METHODS  |
# + - - - - - - - +
func _add_debug_info(shape: PackedVector2Array, shapes: Array[PackedVector2Array], operation: String):
    _debug_info = {
        shape = shape.duplicate(),
        shapes = shapes.duplicate(true),
        operation = operation
    }

func _dump_shapes(shapes:Array[PackedVector2Array], text: String):
    for s in shapes:
        for p in s:
            if p.abs().length()>CUT_LINE_SIZE:
                print("Infinity point %s" % text)
                print('dump: ', str(s).replace("(","Vector2("))
                s.clear()
                continue
        
        if s.size()<3:
            print("Short shape %s" % text)
        elif Geometry2D.triangulate_polygon(s).size()==0:
            print("Triangulate Error %s" % text)
            print('dump: ', str(s).replace("(","Vector2("))

func _info(shapes:Array[PackedVector2Array]):
    match(_res_analysis(shapes)):
        RES_NORMAL: print('RES_NORMAL')
        RES_BROKEN: print('RES_BROKEN')
        RES_ANOMALY: print('RES_ANOMALY')
        RES_MULTIPLE_NORMAL: print('RES_MULTIPLE_NORMAL')

func _dump_error(type: String):
    print('Found Error: ', type)
    _debug_info['type'] = type
    emit_signal("error", _debug_info)

func _debug_rotate_shape(shape: PackedVector2Array, offset: int):
    var result: PackedVector2Array
    result.append_array( shape.slice(offset) )
    result.append_array( shape.slice(0, offset) )
    shape.clear()
    shape.append_array(result)
