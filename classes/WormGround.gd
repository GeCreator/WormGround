@tool
# The main project object
class_name WormGround extends Node2D
const MAX_BLOCK_RANGE: int = 10000
const CELL_SIZE: int = 200

@export_category("WormGround")

@export var tool_set: WGToolSet:
    set(value):
        tool_set = value
        for canvas in _canvases:
            (canvas as WGCanvas).set_toolset(tool_set)
        notify_property_list_changed()
@export_subgroup("collision")
@export_flags_2d_physics var layer: int = 1
@export_flags_2d_physics var mask: int = 1
@export var priority: float = 1

# Main data storage(packed to string)
# var -> byte -> compress -> base64
var _data: String
# Main data(extracted)
var _data_size: int
var _data_is_modified: bool = false

var _cells: Dictionary
var _canvases: Dictionary
var _physics: Dictionary
var _canvas_render_list: Array[WGCanvas] = []
var _physics_update_list: Array[WGPhysic] = []

func _notification(what):
    # compress all data into string
    if what == NOTIFICATION_EDITOR_PRE_SAVE and _data_is_modified:
        _data_is_modified = false
        var data: Array[Dictionary]
        for c in _cells:
            var cell = _cells[c]
            if not cell.is_empty():
                data.append(cell.get_data())
        var buffer = var_to_bytes(data)
        _data_size = buffer.size()
        _data = Marshalls.raw_to_base64(buffer.compress(FileAccess.COMPRESSION_GZIP))

func _ready():
    # extract all data from string
    if _data_size>0:
        var buffer := Marshalls.base64_to_raw(_data)
        buffer = buffer.decompress(_data_size, FileAccess.COMPRESSION_GZIP)
        var data = bytes_to_var(buffer)
        for d in data:
            _get_cell(d[WGCell.DATA_COORDS]).set_data(d)

func add_surface(surface_id: int, shape: PackedVector2Array):
    shape = _get_transformed_shape(shape)
    var cells: Array[WGCell] = _get_affected_cells(shape)
    for cell in cells:
        cell.add_surface(surface_id, shape)

func remove_surface(shape: PackedVector2Array):
    shape = _get_transformed_shape(shape)
    var cells: Array[WGCell] = _get_affected_cells(shape)
    for cell in cells:
        cell.remove(shape)

func _get_affected_cells(shape: PackedVector2Array) -> Array[WGCell]:
    var result: Array[WGCell]
    var aabb := WGUtils.get_shape_area(shape)
    var from = WGUtils.get_cell_coords(aabb.position, CELL_SIZE)
    var to = WGUtils.get_cell_coords(aabb.end, CELL_SIZE)

    for x in range(from.x,to.x+1):
        for y in range(from.y, to.y+1):
            var coords:= Vector2(x, y)
            result.append(_get_cell(coords))
    return result

func _get_cell(coords: Vector2) -> WGCell:
    var x = int(coords.x)
    var y = int(coords.y)
    
    var id = WGUtils.make_cell_id(coords, MAX_BLOCK_RANGE);
    if _cells.has(id): return _cells[id]
    var cell = WGCell.new(coords, CELL_SIZE)
    cell.changed.connect(_get_canvas(coords).update.bind(cell))
    cell.changed.connect(_get_physic(coords).update.bind(cell))
    _cells[id] = cell
    return  _cells[id]

func _get_canvas(cell_coords: Vector2) -> WGCanvas:
    # 1 WGCanvas for 4 WGCell
    var canvas_coords := (cell_coords - cell_coords.posmod(2.0))/2.0
    var canvas_id = WGUtils.make_cell_id(canvas_coords, MAX_BLOCK_RANGE)
    if not _canvases.has(canvas_id):
        var canvas := WGCanvas.new(get_canvas_item())
        canvas.set_toolset(tool_set)
        canvas.changed.connect(_on_canvas_changed.bind(canvas))
        _canvases[canvas_id] = canvas
    return _canvases[canvas_id]

func _get_physic(cell_coords: Vector2) -> WGPhysic:
    var physic_bloc_id = WGUtils.make_cell_id(cell_coords, MAX_BLOCK_RANGE)
    if not _physics.has(physic_bloc_id):
        var physic := WGPhysic.new(get_world_2d().space, layer, mask, priority)
        physic.changed.connect(_on_physics_changed.bind(physic))
        _physics[physic_bloc_id] = physic
    return _physics[physic_bloc_id]

func _get_transformed_shape(shape:PackedVector2Array) -> PackedVector2Array:
    var t:=Transform2D()
    var s = transform.get_scale()
    s.x = 1.0/s.x
    s.y = 1.0/s.y
    t = t.scaled(s)
    t = t.rotated(transform.get_rotation())
    t = t.translated(transform.origin)
    return shape * t

func _on_canvas_changed(canvas: WGCanvas):
    _data_is_modified = true
    _canvas_render_list.append(canvas)

func _on_physics_changed(physic: WGPhysic):
    _data_is_modified = true
    _physics_update_list.append(physic)

func _process(_delta: float):
    while _canvas_render_list.size()>0:
        var canvas : WGCanvas = _canvas_render_list.pop_back()
        canvas.render()

func _physics_process(delta):
    while _physics_update_list.size()>0:
        var physic : WGPhysic = _physics_update_list.pop_back()
        physic.rebuild()

func _get_property_list():
    return [
        {
            name = "_data",
            type = TYPE_STRING,
            usage = PROPERTY_USAGE_STORAGE,
        },
        {
            name = "_data_size",
            type = TYPE_INT,
            usage = PROPERTY_USAGE_STORAGE
        }
    ]
