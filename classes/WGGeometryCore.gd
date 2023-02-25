# allows you to combine multiple polygons and cut holes in polygons
class_name WGGeometryCore

const RES_NORMAL: int = 0 # normal shape
const RES_BROKEN: int = 1 # shape with holes inside
const RES_ANOMALY: int = 2 # shape have multiple normal shapes with holes
const RES_MULTIPLE_NORMAL: int = 3 # multiple normal shapes

class DistanceInfo:
    var distance: float
    var point_a: ShpVertex
    var point_b: ShpVertex

class ShapesConnector:
    var _shapes: Array[Shp]

    func _init(shapes: Array[PackedVector2Array]):
        for s in shapes:
            _shapes.append( Shp.new(s) )
    
    func get_result() -> PackedVector2Array:
        var connected_shapes: Array[Shp] = []
        connected_shapes.append( _shapes.pop_front() )
        while _shapes.size()>0:
            _add_nearest_and_connect(_shapes, connected_shapes)
        
        var limit: int = 0
        for s in connected_shapes:
            s.sort_vertexes_links()
            limit += s.size()
        
        return connected_shapes[0].build_shape(limit)
    
    func _add_nearest_and_connect(shapes: Array[Shp], add_to: Array[Shp]):
        var min: float = INF
        var di: DistanceInfo
        var min_di: DistanceInfo
        var pop_index: int = 0
        
        for cs in add_to:
            var i: int = -1
            for s in shapes:
                i+=1
                di = cs.get_distance_info(s)
                if di.distance<min:
                    min = di.distance
                    min_di = di
                    pop_index = i
        
        min_di.point_a.add_next_point(min_di.point_b)
        min_di.point_b.add_next_point(min_di.point_a)
        add_to.append(shapes.pop_at(pop_index))


class Shp:
    var _vertexs: Array[ShpVertex]
    
    func _init(s: PackedVector2Array):
        # init vertexes
        var j: int = 0
        for point in s:
            _vertexs.append(ShpVertex.new(point, j))
            j+=1
        
        # set vertexes base links
        for i in range(-1, _vertexs.size()-1):
            var v: ShpVertex = _vertexs[i]
            v.add_next_point(_vertexs[i+1])
    
    func size() -> int:
        return _vertexs.size()
        
    func get_vertexes() -> Array[ShpVertex]:
        return _vertexs
        
    func sort_vertexes_links():
        for v in _vertexs:
            v.sort_links()

    # returns the closest distance to the specified shape
    func get_distance_info(shape: Shp) -> DistanceInfo:
        var min_d: float = INF
        var result: DistanceInfo = DistanceInfo.new()
        for p1 in _vertexs:
            for p2 in shape.get_vertexes():
                var d = p1.position.distance_to(p2.position)
                if d<min_d:
                    min_d = d
                    result.distance = min_d
                    result.point_a = p1
                    result.point_b = p2
        return result
    
    func build_shape(limit: int) -> PackedVector2Array:
        var previous: ShpVertex = _vertexs[-1]
        var current: ShpVertex = _vertexs[0]
        var start: ShpVertex = current
        var result: PackedVector2Array
        while not current.is_completed():
            result.append(current.position)
            var next := current.get_next_vertex(previous)
            previous = current
            current = next
            
        return result

class ShpVertex:
    
    class VertexDirection:
        var angle: float
        var vertex: ShpVertex
    var _id: int
    var _next_links: Array[VertexDirection]
    var _base: Vector2
    var _get_iterations: int
    var position: Vector2
    
    func _init(pos: Vector2, id: int):
        _id = id
        position = pos

    func add_next_point(v: ShpVertex):
        var vd = VertexDirection.new()
        vd.vertex = v
        if _next_links.size() ==0:
            vd.angle = TAU
            _base = v.position - position
        else:
            vd.angle = _get_angle(v.position)
        _next_links.append(vd)
        
    
    func _get_angle(to: Vector2) -> float:
        var g = (to-position).angle_to(_base)
        if g<0: g+= TAU
        return g
    
    func is_completed() -> bool:
        return _get_iterations==0
        
    func get_next_vertex(previous: ShpVertex) -> ShpVertex:
        _get_iterations-=1
        if _next_links.size()==1:
            return _next_links[0].vertex
        var angle = _get_angle(previous.position)
        for l in _next_links:
            if angle < l.angle:
                return l.vertex
        return _next_links.back().vertex
    
    func sort_links():
        _get_iterations = _next_links.size()
        _next_links.sort_custom(func(a:VertexDirection, b:VertexDirection): return a.angle<b.angle)



static func remove(remove:PackedVector2Array, shapes:Array) -> Array:
    var result: Array[PackedVector2Array] = []
    for s in shapes:
        if _shape_is_intersects(remove, s):
            var res = Geometry2D.clip_polygons(s, remove)
            
            match _res_analysis(res):
                RES_NORMAL: result.append( res[0] )
                RES_BROKEN: result.append(_resolve_errors(res))
                RES_ANOMALY:
                    result.append_array(_resolve_anomaly(res))
                RES_MULTIPLE_NORMAL: result.append_array(res)
        else:
            result.append(s)

    
    return result

# add new shape to shapes group
static func union(add: PackedVector2Array, shapes: Array) -> Array:
    var result: Array[PackedVector2Array] = []
    var neutral: Array[PackedVector2Array] = []
    
    for s in shapes:
        if not _shape_is_intersects(add,s):
            neutral.append(s)
            continue
        var res = Geometry2D.merge_polygons(add, s)
        match _res_analysis(res):
            RES_NORMAL: add = res[0]
            RES_BROKEN: add = _resolve_errors(res)
            RES_ANOMALY: neutral.append(s)
    
    result.append(add)
    result.append_array(neutral)
    return result

# analyse result of Geometry2D operations
# return RES_... information
static func _res_analysis(res: Array) -> int:
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

static func _resolve_errors(shapes: Array[PackedVector2Array]) -> PackedVector2Array:
    var x = ShapesConnector.new(shapes)
    return x.get_result()

static func _has_errors(shapes: Array) -> bool:
    for s in shapes:
        if Geometry2D.is_polygon_clockwise(s):
            return true
    return false

static func _resolve_anomaly(shapes: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
    var result : Array[PackedVector2Array]
    var holes: Array
    var normal: Array
    for s in shapes:
        if Geometry2D.is_polygon_clockwise(s):
            holes.append(s)
        else:
            normal.append(s)
    for n in normal:
        var re: Array[PackedVector2Array] = [n]
        var hh: Array[PackedVector2Array]
        var ne: Array[PackedVector2Array]
        var c: bool = true
        while c:
            var hs = holes.pop_back()
            if hs!=null: 
                if _shape_is_intersects(hs, n):
                    re.append(hs)
                else:
                    ne.append(hs)
            else: c = false
        holes = ne
        result.append(_resolve_errors(re))
            
    return result

static func _shape_is_intersects(a: PackedVector2Array, b: PackedVector2Array):
    return Geometry2D.intersect_polygons(a,b).size()>0
