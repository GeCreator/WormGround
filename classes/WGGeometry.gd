class_name WGGeometry
var min_angle:= 0.0698132 # TAU/90 or 4 degrees
var min_segment_size = 20.0
var snap_grid_size = Vector2(1,1)
var _iter:int = 0
const RES_NORMAL: int = 0 # normal shape
const RES_BROKEN: int = 1 # shape with holes inside
const RES_ANOMALY: int = 2 # shape have multiple normal shapes with holes
const RES_MULTIPLE_NORMAL: int = 3 # multiple normal shapes

func info(shapes: Array[PackedVector2Array]):
    match _res_analysis(shapes):
        RES_NORMAL: print('RES_NORMAL')
        RES_BROKEN: print('RES_BROKEN')
        RES_ANOMALY: print('RES_ANOMALY')
        RES_MULTIPLE_NORMAL: print('RES_MULTIPLE_NORMAL')
func union(add: PackedVector2Array, shapes: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
    _iter = 0
    #_normalize(add)
    var r := _merge_shapes(add, shapes)
    _normalize_multiple(r)    
    return r

func _merge_shapes(add: PackedVector2Array, shapes: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
    print("iter: %s" % _iter)
    _iter+=1
    var result: Array[PackedVector2Array]
    var broken: Array[PackedVector2Array]
    for shape in shapes:
        if broken.size()>1:
            return broken
            broken = _merge_shapes(shape, broken)
            continue
        var m = Geometry2D.merge_polygons(add, shape)
        info(m)
        match(_res_analysis(m)):
            RES_NORMAL:
                add.clear()
                add.append_array(m[0])
            RES_BROKEN:
                broken =_resolve_hole_errors(m)
                return broken
            RES_MULTIPLE_NORMAL:
                #print('result+ %s vertexes shape' % shape.size())
                result.append(shape)
    if broken.size()==0:
        result.append(add)
    else:
        result.append_array(broken)
    return result

func remove(remove:PackedVector2Array, shapes:Array) -> Array[PackedVector2Array]:
    var result: Array[PackedVector2Array] = []
    result = _clip_from_polygons(remove, shapes)
    _normalize_multiple(result)
    return result

func _normalize_multiple(shapes: Array[PackedVector2Array]):
    for s in shapes:
        _normalize(s)

func _normalize(shape: PackedVector2Array):
    pass
    #_remove_bad_angles(shape)
    #_remove_short_segments(shape)
    #_snap_to_grid(shape)

func _snap_to_grid(shape: PackedVector2Array):
    for i in shape.size():
        _get_segment(i, shape)
        shape[i] = shape[i].snapped(snap_grid_size)

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
        if absf(PI-diff)<min_angle: # remove obtuse angle >176°
            remove_list.append(i)
        elif diff<min_angle: # remove sharp angle <4°
            var s1:= _get_segment(i-1, shape)
            var s2:= _get_segment(i, shape)
            if _get_segment_length(s1)>_get_segment_length(s2):
                shape[wrapi(i+1,0,size)] = _get_segment_intersection(s1, _get_segment(i+1, shape))
            else:
                shape[wrapi(i-1,0,size)] = _get_segment_intersection(_get_segment(i-2, shape), s2)
            remove_list.append(i)
    _remove_vertexes(shape, remove_list)
        
func _remove_short_segments(shape: PackedVector2Array):
    var need_fix_list: PackedInt32Array
    var remove_list: PackedInt32Array
    var size: int = shape.size()
    for i in size:
        var a: Vector2 = shape[i]
        var b: Vector2 = shape[wrapi(i+1, 0, size)]
        if a.distance_squared_to(b)<min_segment_size:
            need_fix_list.append(i)
    
    var p: int = -5
    # remove multiple (with nearest pos) vertexes
    for n in need_fix_list:
        if p==wrapi(n, 0, size): remove_list.append(n)
        p = n
    if remove_list.size()>0:
        _remove_vertexes(shape, remove_list)
        _remove_short_segments(shape)
    elif need_fix_list.size()>0:
        for n in need_fix_list:
            var s1:=_get_segment(n-1, shape)
            var s2:=_get_segment(n+1, shape)
            var point := _get_segment_intersection(s1, s2)
            remove_list.append(wrapi(n+1, 0, size))
            shape[n] = point
        _remove_vertexes(shape, remove_list)

func _remove_vertexes(shape: PackedVector2Array, remove_list: PackedInt32Array):
    remove_list.sort()
    remove_list.reverse()
    for n in remove_list:
        shape.remove_at(n)

## return PackedVector2Array with 2 points of segment n
func _get_segment(n: int, polygon: PackedVector2Array) -> PackedVector2Array:
    var size = polygon.size()
    return PackedVector2Array([
        polygon[wrapi(n,0, size)],
        polygon[wrapi(n+1,0, size)]
    ])

func _get_segment_length(segment: PackedVector2Array) -> float:
    return (segment[1]-segment[0]).length_squared()

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

func _clip_from_polygons(clip: PackedVector2Array, shapes: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
    var result: Array[PackedVector2Array]
    for shape in shapes:
        var res = Geometry2D.clip_polygons(shape, clip)
        match (_res_analysis(res)):
            RES_NORMAL:
                result.append(res[0])
            RES_BROKEN:
                result.append_array(_resolve_hole_errors(res))
            RES_MULTIPLE_NORMAL:
                result.append_array(res)
    return result

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
            result = _clip_from_polygons(hole, result)
            continue
        var x := _remove_hole(result[0], hole)
        result[0].clear()
        result[0].append_array(x[0])
        if x.size()==2:
            result.append(x[1])

    return result

func _remove_hole(normal: PackedVector2Array, hole: PackedVector2Array) -> Array[PackedVector2Array]:
    var p:=_get_left_right_vertexes(hole)
    var hlp: Vector2 = hole[p[0]] # hole leftmost point
    var hrp: Vector2 = hole[p[1]] # hole rightmost point
    var line_a:= _get_collision_line(hlp, normal, -10000.0)
    var line_b:= _get_collision_line(hrp, normal, 10000.0)
    var sl: int = -1; var pl:=Vector2.INF # segment left; point left
    var sr: int = 0; var pr:=Vector2.INF # segment right; point right
    var nsize: int = normal.size()
    for n in nsize:
        var sgm = _get_segment(n, normal)
        var x
        x = Geometry2D.segment_intersects_segment(line_a[0],line_a[1],sgm[0],sgm[1])
        if x!=null and hlp.distance_squared_to(x)<hlp.distance_squared_to(pl):
            sl = n; pl=x
        else:
            x = Geometry2D.segment_intersects_segment(line_b[0],line_b[1],sgm[0],sgm[1])
            if x!=null and hrp.distance_squared_to(x)<hrp.distance_squared_to(pr):
                sr = n; pr=x
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
        var r := Geometry2D.clip_polyline_with_polygon(line, shape)[0]
        r[0].x += -1.0 if max_size < 0 else 1.0
        r[1].x += 1.0 if max_size < 0 else -1.0
        return r

## return leftmost and rightmost vertex of shape
## [0] - left vertex, [1] - right vertex
func _get_left_right_vertexes(shape: PackedVector2Array) -> PackedInt32Array:
    var result := PackedInt32Array([0,0])
    var i: int = 0
    var left: float = INF
    var right: float = -INF
    for p in shape:
        if p.x<left:
            left = p.x
            result[0] = i
        if p.x>right:
            right = p.x
            result[1] = i
        i+=1
    return result

func _shape_is_intersects(a: PackedVector2Array, b: PackedVector2Array):
    return Geometry2D.intersect_polygons(a,b).size()>0

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
