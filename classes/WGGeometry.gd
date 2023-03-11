class_name WGGeometry

const CUT_LINE_SIZE = 10000.0
const BAN_ANGLE:= 0.0174533 # TAU/360 or 1 degrees
const MIN_PART_SIZE = 15.0 # min sum length of polygon segments 
var snap_grid_size = Vector2(10,10)

const RES_NORMAL: int = 0 # normal shape
const RES_BROKEN: int = 1 # shape with holes inside
const RES_ANOMALY: int = 2 # shape have multiple normal shapes with holes
const RES_MULTIPLE_NORMAL: int = 3 # multiple normal shapes

func union(add: PackedVector2Array, shapes: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
    add = add.duplicate()
    var result: Array[PackedVector2Array]
    var holes: Array[PackedVector2Array]
    var remove_list: PackedInt32Array
    
    for i in shapes.size():
        if not _shape_is_intersects(shapes[i], add):
            result.append(shapes[i])
            remove_list.append(i)
    _remove_by_list(shapes, remove_list)
    
    for shape in shapes:
        var m = Geometry2D.merge_polygons(add, shape)
        match(_res_analysis(m)):
            RES_NORMAL:
                add.clear()
                add.append_array(m[0])
            RES_BROKEN:
                for err in m:
                    if Geometry2D.is_polygon_clockwise(err):
                        holes.append(err)
                    else:
                        add.clear()
                        add.append_array(err)
    var clipped : Array[PackedVector2Array] = [add]
    
    _remove_small_shapes(holes)
    for hole in holes:
        clipped = _clip_from_polygons(hole, clipped)
    _repair_multiple(clipped)
    result.append_array(clipped)
    return result

func remove(remove:PackedVector2Array, shapes:Array) -> Array[PackedVector2Array]:
    remove = remove.duplicate()
    var result: Array[PackedVector2Array] = []
    result = _clip_from_polygons(remove, shapes)
    _repair_multiple(result)
    return result

func _repair_multiple(shapes: Array[PackedVector2Array]):
    var remove_shapes: PackedInt32Array
    for i in shapes.size():
        if not _repair(shapes[i]):
            _dump_triangulation(shapes[i])
            remove_shapes.append(i)
    remove_shapes.reverse()
    for i in remove_shapes:
        shapes.remove_at(i)

func _repair(shape: PackedVector2Array) -> bool:
    #_snap_to_grid(shape)
    _remove_bad_angles(shape)
    for x in 3: # repair tries
        if Geometry2D.triangulate_polygon(shape).size()>0: return true
        var size: int = shape.size()
        var remove_list: PackedInt32Array
        for i in size:
            var sgm:= _get_segment(i, shape)
            if _get_segment_length(sgm)<1:
                var sgm_prev:= _get_segment(i-1, shape)
                if _segment_is_global_ortho(sgm_prev):
                    remove_list.append(wrapi(i+1,0, size))
                else:
                    remove_list.append(i)
        _remove_by_list(shape, remove_list)
    return false

func _dump_triangulation(shape: PackedVector2Array):
    if Geometry2D.triangulate_polygon(shape).size()>0: return
    print(str(shape).replace("(","Vector2("))

func _snap_to_grid(shape: PackedVector2Array):
    for i in shape.size():
        shape[i] = shape[i].snapped(snap_grid_size)

func _remove_small_shapes(shapes: Array[PackedVector2Array]):
    var remove_list: PackedInt32Array
    for j in shapes.size():
        var total_length: float = 0
        var shape = shapes[j]
        for n in shape.size():
            var segment:= _get_segment(n, shape)
            total_length += _get_segment_length(segment)
            if total_length>MIN_PART_SIZE:
                break
        if total_length<MIN_PART_SIZE:
            remove_list.append(j)
    _remove_by_list(shapes, remove_list)

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
        if absf(PI-diff)<BAN_ANGLE: # remove obtuse angle >179°
            remove_list.append(i)
        elif diff<BAN_ANGLE: # remove sharp angle <1°
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

func _chunk_shape(shape: PackedVector2Array) -> Array[PackedVector2Array]:
    var gp: Dictionary # graph points
    var coords: PackedVector2Array
    var links: Array[PackedInt32Array]
    var size  = shape.size()
    for n in size:
        shape[n] = shape[n].snapped(snap_grid_size)

    # build graph
    var index: int = 0
    for n in size:
        var point:= shape[n]
        if not gp.has(point):
            gp[point] = index
            links.append(PackedInt32Array())
            coords.append(point)
            index +=1

    # build links
    for n in size:
        var point:= shape[n]
        var next_point:= shape[wrapi(n+1,0,size)]
        var current : int = gp[point]
        var next : int = gp[next_point]
        if current!=next:
            links[current].append(next)

    # prepare shape point indexes
    size = links.size()
    var all: Array[PackedInt32Array]
    for i in size:
        var result: PackedInt32Array
        var links_stack: PackedInt32Array = links[i]
        if links_stack.size()==0: continue
        for tmp in size:
            var next:=links_stack[links_stack.size()-1]
            links_stack.remove_at(links_stack.size()-1)
            result.append(next)
            links_stack = links[next]
            if next==i: break
        all.append(result)
    
    # construct shapes from point indexes
    var result: Array[PackedVector2Array]
    for points in all:
        if points.size()<3: continue
        var new_shape: PackedVector2Array
        for idx in points:
            new_shape.append(coords[idx])
        result.append(new_shape)
    
    return result

## return PackedVector2Array with 2 points of segment n
func _get_segment(n: int, polygon: PackedVector2Array) -> PackedVector2Array:
    var size = polygon.size()
    return PackedVector2Array([
        polygon[wrapi(n,0, size)],
        polygon[wrapi(n+1,0, size)]
    ])

func _segment_is_global_ortho(segment: PackedVector2Array) -> bool:
    var a: Vector2 = segment[0]
    var b: Vector2 = segment[1]
    if absf(a.y-b.y)<0.001 || absf(a.x-b.x)<0.001:
        return true
    return false

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
    _remove_small_shapes(result)
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
    var line_a:= _get_collision_line(hlp, normal, -CUT_LINE_SIZE)
    var line_b:= _get_collision_line(hrp, normal, CUT_LINE_SIZE)
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
