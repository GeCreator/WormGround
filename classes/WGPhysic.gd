class_name WGPhysic
signal changed
var _compiled_shapes: Array[RID]
var _updated: bool = true
var _body: RID

func _init(space:RID, layer:int, mask:int, priority:float):
    _body = PhysicsServer2D.body_create()
    PhysicsServer2D.body_set_mode(_body, PhysicsServer2D.BODY_MODE_STATIC)
    PhysicsServer2D.body_set_space(_body, space)
    PhysicsServer2D.body_set_state(_body, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, Vector2(0, 0)))
    PhysicsServer2D.body_set_collision_layer(_body, layer)
    PhysicsServer2D.body_set_collision_mask(_body, mask)
    PhysicsServer2D.body_set_collision_priority(_body, priority)

func update(cell:WGCell):
    _compiled_shapes.clear()
    var current: Dictionary
    for s in cell.get_physics_shapes():
        for ds in Geometry2D.decompose_polygon_in_convex(s):
            var convex = PhysicsServer2D.convex_polygon_shape_create()
            PhysicsServer2D.shape_set_data(convex, ds)
            _compiled_shapes.append( convex )
    _updated = false
    changed.emit()

func rebuild():
    if _updated: return
    _updated = true
    PhysicsServer2D.body_clear_shapes(_body)
    for shape in _compiled_shapes:
        PhysicsServer2D.body_add_shape(_body, shape)
