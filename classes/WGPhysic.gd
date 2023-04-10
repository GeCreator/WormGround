class_name WGPhysic
const DATA_BODY: int = 0
const DATA_NEW_SHAPES: int = 1

static func create(space:RID, layer:int, mask:int, priority:float, transform: Transform2D) -> Array:
    var body = PhysicsServer2D.body_create()
    PhysicsServer2D.body_set_mode(body, PhysicsServer2D.BODY_MODE_STATIC)
    PhysicsServer2D.body_set_space(body, space)
    PhysicsServer2D.body_set_state(body, PhysicsServer2D.BODY_STATE_TRANSFORM, Transform2D(0, Vector2(0, 0)))
    PhysicsServer2D.body_set_collision_layer(body, layer)
    PhysicsServer2D.body_set_collision_mask(body, mask)
    PhysicsServer2D.body_set_collision_priority(body, priority)
    var result: Array
    result.resize(2)
    result[DATA_BODY] = body
    result[DATA_NEW_SHAPES] = []
    return result

static func refresh(physic_data:Array, cell_data: Array, geometry: WGGeometry):
     physic_data[DATA_NEW_SHAPES] = geometry.decompose(cell_data[WGCell.DATA_PHYSIC])

static func update(physic_data: Array, transform: Transform2D):
    var body = physic_data[DATA_BODY]
    PhysicsServer2D.body_clear_shapes(body)
    for s in physic_data[DATA_NEW_SHAPES]:
        var shape = PhysicsServer2D.convex_polygon_shape_create()
        PhysicsServer2D.shape_set_data(shape, s)
        PhysicsServer2D.body_add_shape(body, shape, transform)

static func get_active_shapes(physic_data: Array) -> Array[PackedVector2Array]:
    var result: Array[PackedVector2Array]
    var body = physic_data[DATA_BODY]
    for i in PhysicsServer2D.body_get_shape_count(body):
        var shape = PhysicsServer2D.body_get_shape(body, i)
        var data:PackedVector2Array = PhysicsServer2D.shape_get_data(shape)
        result.append(data)
    return result
