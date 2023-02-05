# Главный объект разрушаемой поверхности
# Он хранит в себе блоки (_cells) которым
# передает команды по добавлению/удалению
# форм из них

class_name WormsTerrain extends Node2D
const MAX_BLOCK_RANGE: int = 10000
const CELL_SIZE: int = 100

@export_category("WormsTerrain")
@export_flags_2d_render var occluder_light_mask = 0
@export_flags_2d_physics var collsion_mask: int = 0

var _cells: Dictionary
var _canvas_group: DTCanvasGroup

func _ready():
    _canvas_group = DTCanvasGroup.new(CELL_SIZE, get_canvas_item())

func add(shape: PackedVector2Array, brush: DTBrush):
    var cells: Array[DTCell] = _get_affected_cells(shape)
    for cell in cells:
        cell.add(shape, brush)

func remove(shape: PackedVector2Array):
    var cells: Array[DTCell] = _get_affected_cells(shape)
    for cell in cells:
        cell.remove(shape)

func _get_affected_cells(shape: PackedVector2Array) -> Array[DTCell]:
    var result: Array[DTCell]
    var aabb := _get_shape_area(shape)
    var from = _cell_coords(aabb.position)
    var to = _cell_coords(aabb.end)

    for x in range(from.x,to.x+1):
        for y in range(from.y, to.y+1):
            var pos:= Vector2(x, y)
            result.append(_get_cell(pos))
    return result

func _get_shape_area(shape: PackedVector2Array) -> Rect2:
    var result: Rect2
    var min_x: float = INF
    var min_y: float = INF
    var max_x: float = -INF
    var max_y: float = -INF
    # определяем границы формы в пространстве
    for p in shape:
        if p.x<min_x: min_x = p.x
        if p.y<min_y: min_y = p.y
        if p.x>max_x: max_x = p.x
        if p.y>max_y: max_y = p.y
    
    result.position = Vector2(min_x,min_y)
    result.end = Vector2(max_x, max_y)
    return result
    
func _get_cell(coords: Vector2) -> DTCell:
    var id = _make_cell_id(coords);
    if _cells.has(id): return _cells[id]
    _cells[id] = DTCell.new(coords, CELL_SIZE, _canvas_group)
    return  _cells[id]


# возвращает позицию ячейки полученную из указаных координат
func _cell_coords(pos: Vector2) -> Vector2:
    var pm = pos.posmod(float(CELL_SIZE))
    return (pos - pm)/CELL_SIZE

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

func _process(delta):
    _canvas_group.render()
