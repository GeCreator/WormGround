@tool
# The main project object
class_name WormGround extends Node2D
const MAX_BLOCK_RANGE: int = 10000
const CELL_SIZE: int = 200
const DRAW_PER_FRAME: int = 10

@export_category("WormGround")
@export var texture: Texture2D:
    set(value):
        texture = value

@export var level_data: WGLevelData:
    set(value):
        level_data = value
        notify_property_list_changed() # required by plugin
## shape/hole size that will be skipped.
## Size is sum of polygon segments length
@export var minimal_shape: float = 20.0
@export_subgroup("collision")
@export_flags_2d_physics var layer: int = 1
@export_flags_2d_physics var mask: int = 1
@export var priority: float = 1

var _cells: Dictionary
var _canvases: Dictionary
var _physics: Dictionary
var _canvas_render_list: Dictionary = {}
var _physics_update_list: Dictionary = {}
var _geometry: WGGeometry


func _ready():
    _geometry = WGGeometry.new( minimal_shape )
    if level_data!=null:
        for d in level_data.get_data():
            var cell:=_get_cell(d[WGCell.DATA_COORDS])
            WGCell.set_data(cell, d)
    _cells_changed(_cells.values())

func _notification(what):
    if what == NOTIFICATION_EDITOR_PRE_SAVE:
        if level_data!=null:
            level_data.save_changes(_cells)

func add_surface(surface_id: int, shape: PackedVector2Array):
    shape = _get_transformed_shape(shape)
    var cells: Array = _get_affected_cells(shape)
    for cell in cells:
        WGCell.add_surface(cell, shape, _geometry)
    _cells_changed(cells)

func remove_surface(shape: PackedVector2Array):
    shape = _get_transformed_shape(shape)
    var cells: Array = _get_affected_cells(shape)
    for cell in cells:
        WGCell.remove(cell, shape, _geometry)
    _cells_changed(cells)

#func redraw():
    #_canvas_render_list = _canvases.duplicate()

func _cells_changed(cells: Array):
    level_data.mark_as_modified()
    for cell in cells:
        var canvas = _get_canvas(cell[WGCell.DATA_COORDS])
        var id = WGCanvas.make_id(cell[WGCell.DATA_COORDS])
        if not _canvas_render_list.has(id):
            _canvas_render_list[id] = canvas
        
        id = WGCell.get_id(cell)
        var physic = _physics[id]
        WGPhysic.refresh(physic, cell, _geometry)
        if not _physics_update_list.has(id):
            _physics_update_list[id] = physic

func _get_affected_cells(shape: PackedVector2Array) -> Array:
    var result: Array
    var aabb := WGUtils.get_shape_area(shape)
    var from = WGUtils.get_cell_coords(aabb.position, CELL_SIZE)
    var to = WGUtils.get_cell_coords(aabb.end, CELL_SIZE)

    for x in range(from.x,to.x+1):
        for y in range(from.y, to.y+1):
            var coords:= Vector2(x, y)
            result.append(_get_cell(coords))
    return result

func _get_cell(coords: Vector2) -> Array:
    var x = int(coords.x)
    var y = int(coords.y)
    
    var id = WGUtils.make_cell_id(coords, MAX_BLOCK_RANGE);
    if _cells.has(id): return _cells[id]
    var cell = WGCell.create(coords)
    _cells[id] = cell
    # === PHYSIC
    _physics[id] = WGPhysic.create( \
    get_world_2d().space, layer, mask,\
    priority, transform)
    # === CANVAS
    var canvas = _get_canvas(coords)
    canvas[WGCanvas.DATA_CELLS].append(cell)
    return cell

func _get_canvas(cell_coords: Vector2) -> Array:
    var canvas_id = WGCanvas.make_id(cell_coords)
    if not _canvases.has(canvas_id):
        _canvases[canvas_id] = WGCanvas.create(get_canvas_item())
    return _canvases[canvas_id]

func _get_transformed_shape(shape:PackedVector2Array) -> PackedVector2Array:
    var t:=Transform2D()
    var s = transform.get_scale()
    s.x = 1.0/s.x
    s.y = 1.0/s.y
    t = t.scaled(s)
    t = t.rotated(transform.get_rotation())
    t = t.translated(transform.origin)
    return shape * t

func _process(_delta: float):
    # wait for physics update
    if _physics_update_list.size()>0: return
    # update canvas
    var bbb:= randi()%2==0
            
    var limit: int = DRAW_PER_FRAME
    var remove_list: PackedInt32Array
    for key in _canvas_render_list:
        remove_list.append(key)
        var canvas: Array = _canvas_render_list[key]
        WGCanvas.render(canvas, texture)
        WGCanvas.render_debug(canvas, _physics)
        limit -=1
        if limit<=0: break
    for key in remove_list: _canvas_render_list.erase(key)

func _physics_process(delta):
    while _physics_update_list.size()>0:
        for key in _physics_update_list:
            var physic: Array = _physics_update_list[key]
            WGPhysic.update(physic, transform)
        _physics_update_list.clear()

func _get_configuration_warnings() -> PackedStringArray:
    var result: PackedStringArray
    if level_data==null: return ['LevelData required to save stuffs']
    return result
