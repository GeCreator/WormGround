@tool
# The main project object
class_name WormGround extends Node2D
const MAX_BLOCK_RANGE: int = 10000
const CELL_SIZE: int = 200
const DRAW_PER_FRAME: int = 10

@export_category("WormGround")
@export var level_data: WGLevelData:
    set(value):
        level_data = value
        notify_property_list_changed() # required by plugin
        redraw()
## shape/hole size that will be skipped.
## Size is sum of polygon segments length
@export var minimal_shape: float = 20.0

@export_subgroup("texture")
@export var texture: Texture2D:
    set(value): texture = value; redraw()
@export var texture_scale: Vector2 = Vector2.ONE:
    set(value): texture_scale = value; redraw()

@export_subgroup("collision")
@export var debug_physics: bool = false:
    set(value): debug_physics = value; redraw()
@export_flags_2d_physics var layer: int = 1
@export_flags_2d_physics var mask: int = 1
@export var priority: float = 1

@export_subgroup("border")
@export var border_enabled: bool = false:
    set(value): border_enabled = value; redraw()
@export var border_thickness: float = 1.0:
    set(value): border_thickness = value; redraw()
@export var border_color: Color = Color.WHITE:
    set(value): border_color = value; redraw()

var _cells: Dictionary
var _canvases: Dictionary
var _physics: Dictionary
var _canvas_render_list: Dictionary = {}
var _physics_update_list: Dictionary = {}
var _geometry: WGGeometry

func _ready():
    _geometry = WGGeometry.new( minimal_shape )
    if level_data!=null:
        level_data.connect("modified", _on_modified)
        _cells = level_data.get_cells_storage()

        for d in level_data.get_data():
            var cell:=_get_cell(d[WGCell.DATA_COORDS])
            WGCell.set_data(cell, d)
        _on_modified(_cells.values())

func _notification(what):
    if what == NOTIFICATION_EDITOR_PRE_SAVE:
        if level_data!=null:
            level_data.save_changes(_cells)

func add(shape: PackedVector2Array):
    shape = _get_transformed_shape(shape)
    var cells: Array = _get_affected_cells(shape)
    for cell in cells:
        WGCell.add(cell, shape, _geometry)
    level_data.mark_as_modified(cells)

func remove(shape: PackedVector2Array):
    shape = _get_transformed_shape(shape)
    var cells: Array = _get_affected_cells(shape)
    for cell in cells:
        WGCell.remove(cell, shape, _geometry)
    level_data.mark_as_modified(cells)

func redraw():
    _canvas_render_list = _canvases.duplicate()
    set_physics_process(true)

func _on_modified(cells) -> void:
    for cell in cells:
        var id = WGCell.get_id(cell)
        if not _canvas_render_list.has(id):
            _canvas_render_list[id] = _get_canvas(id)
        
        if not _physics_update_list.has(id):
            _physics_update_list[id] = _get_physics(id)
    set_physics_process(true)

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
    return cell

func _get_physics(id: int) -> Array:
    if _physics.has(id): return _physics[id]
    _physics[id] = WGPhysic.create( \
    get_world_2d().space, layer, mask,\
    priority, transform)
    return _physics[id]

func _get_canvas(id: int) -> Array:
    if not _canvases.has(id):
        _canvases[id] = WGCanvas.create(get_canvas_item())
    return _canvases[id]

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
    # update canvas
    var limit: int = DRAW_PER_FRAME
    var remove_list: PackedInt32Array
    for id in _canvas_render_list:
        remove_list.append(id)
        var canvas: Array = _canvas_render_list[id]
        WGCanvas.render(_cells[id], canvas, texture, texture_scale)
        if debug_physics:
            WGCanvas.render_debug(canvas, _physics[id])
        if border_enabled:
            WGBorder.render(canvas, _cells[id], border_thickness, border_color)
        
        limit -=1
        if limit<=0: break
    for id in remove_list: _canvas_render_list.erase(id)
    if limit == DRAW_PER_FRAME:
        set_process(false)

func _physics_process(delta):
    while _physics_update_list.size()>0:
        for id in _physics_update_list:
            var physic: Array = _physics_update_list[id]
            WGPhysic.refresh(physic, _cells[id], _geometry)
            WGPhysic.update(physic, transform)
        _physics_update_list.clear()
    set_physics_process(false)
    set_process(true)

func _get_configuration_warnings() -> PackedStringArray:
    var result: PackedStringArray
    if level_data==null: return ['LevelData required to save stuffs']
    return result
