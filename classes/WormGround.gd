@tool
# The main project object
class_name WormGround extends Node2D
const MAX_BLOCK_RANGE: int = 10000
const CELL_SIZE: int = 100

@export_category("WormGround")

@export var tool_set: WGToolSet:
    set(value):
        tool_set = value
        notify_property_list_changed()

var _data: Dictionary


var _cells: Dictionary

func add_surface(surface: WGSurface, shape: PackedVector2Array):
    var cells: Array[WGCell] = _get_affected_cells(shape)
    for cell in cells:
        pass
        # cell.add(shape, brush)

func remove(shape: PackedVector2Array):
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
            var pos:= Vector2(x, y)
            result.append(_get_cell(pos))
    return result

func _get_cell(coords: Vector2) -> WGCell:
    var id = _make_cell_id(coords);
    if _cells.has(id): return _cells[id]
    #_cells[id] = WTCell.new(coords, CELL_SIZE, _canvas_group)
    return  _cells[id]

# Преобразует координаты ячейки (Например Vector2(10, 20))
# в id ячейки
func _make_cell_id(coords: Vector2) -> int:
    var id: int = 0
    id += int(MAX_BLOCK_RANGE + coords.x)
    id += pow(MAX_BLOCK_RANGE, 2) * 2 + coords.y * MAX_BLOCK_RANGE * 2
    return id

func _get_cutted_polygons(coords: Vector2, shape: PackedVector2Array) -> Array[PackedVector2Array]:
    var x = coords.x * CELL_SIZE
    var y = coords.y * CELL_SIZE
    
    var cut_polygon = PackedVector2Array([
        Vector2(x, y),
        Vector2(x+CELL_SIZE, y),
        Vector2(x+CELL_SIZE, y+CELL_SIZE),
        Vector2(x, y+CELL_SIZE),
    ])
    return Geometry2D.intersect_polygons(shape, cut_polygon)

func _get_property_list():
    return [
        {
        "name": "_data",
        "type": TYPE_DICTIONARY,
        "usage": PROPERTY_USAGE_STORAGE,
        }
    ]
