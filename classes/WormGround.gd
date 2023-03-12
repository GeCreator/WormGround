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

var _data: Dictionary

var _cells: Dictionary
var _canvases: Dictionary
var _canvas_render_list: Array[WGCanvas] = []

func add_surface(surface_id: int, shape: PackedVector2Array):
    var cells: Array[WGCell] = _get_affected_cells(shape)
    for cell in cells:
        cell.add_surface(surface_id, shape)

func remove_surface(shape: PackedVector2Array):
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

func _on_canvas_changed(canvas: WGCanvas):
    _canvas_render_list.append(canvas)

func _process(_delta: float):
    while _canvas_render_list.size()>0:
        var canvas : WGCanvas = _canvas_render_list.pop_back()
        canvas.render()

func _get_property_list():
    return [
        {
        "name": "_data",
        "type": TYPE_DICTIONARY,
        "usage": PROPERTY_USAGE_STORAGE,
        }
    ]
