class_name WGPhysic
signal changed
var _new_shapes: Array[PackedVector2Array]
var _shapes: Array[PackedVector2Array]
var _updated: bool = true
var _body: RID
var _is_enabled: bool = false
var _insert_index: int = -1
var _transform: Transform2D


func _init(space:RID, layer:int, mask:int, priority:float, transform: Transform2D):
    _is_enabled = layer>0 or mask>0
    if not _is_enabled: return
    _transform = transform
    _body = PhysicsServer2D.body_create()
    PhysicsServer2D.body_set_mode(_body, PhysicsServer2D.BODY_MODE_STATIC)
    PhysicsServer2D.body_set_space(_body, space)
    PhysicsServer2D.body_set_state(_body, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, Vector2(0, 0)))
    PhysicsServer2D.body_set_collision_layer(_body, layer)
    PhysicsServer2D.body_set_collision_mask(_body, mask)
    PhysicsServer2D.body_set_collision_priority(_body, priority)

func add(shape: PackedVector2Array, geometry: WGGeometry):
    _updated = false
    geometry.union(shape, _shapes)
    _new_shapes = geometry.decompose(_shapes)
    changed.emit()

func remove(shape: PackedVector2Array, geometry: WGGeometry):
    _updated = false
    geometry.remove(shape, _shapes)
    _new_shapes = geometry.decompose(_shapes)
    changed.emit()

func update():
    if _updated: return
    PhysicsServer2D.body_clear_shapes(_body)
    for s in _new_shapes:
        var shape = PhysicsServer2D.convex_polygon_shape_create()
        PhysicsServer2D.shape_set_data(shape, s)
        PhysicsServer2D.body_add_shape(_body, shape, _transform)
    _updated = true

func is_empty() -> bool:
    return _shapes.size()==0

func get_shapes() -> Array[PackedVector2Array]:
    return _shapes

func set_shapes(shapes: Array, geometry: WGGeometry):
    _updated = false
    var typed_shapes: Array[PackedVector2Array]
    typed_shapes.append_array(shapes)
    _new_shapes = geometry.decompose(typed_shapes)
    _shapes = typed_shapes
    changed.emit()

func get_active_shapes() -> Array[PackedVector2Array]:
    var result: Array[PackedVector2Array]
    for i in PhysicsServer2D.body_get_shape_count(_body):
        var shape = PhysicsServer2D.body_get_shape(_body, i)
        var data:PackedVector2Array = PhysicsServer2D.shape_get_data(shape)
        result.append(data)
    return result

func _remove_by_list(data, remove_list: PackedInt32Array):
    remove_list.sort()
    remove_list.reverse()
    for n in remove_list:
        data.remove_at(n)
