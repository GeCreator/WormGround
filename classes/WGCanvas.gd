@tool
class_name WGCanvas
signal changed

var _canvas: RID
var _tool_set: WGToolSet
var _cells: Dictionary

var _brush: WGSurface
var _polygons: Array[PackedVector2Array]
var _rendered: bool = true

func _init(base_canvas: RID):
    _canvas = RenderingServer.canvas_item_create()
    RenderingServer.canvas_item_set_parent(_canvas, base_canvas)
    RenderingServer.canvas_item_set_default_texture_repeat(_canvas, RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_ENABLED)

func set_toolset(tool_set: WGToolSet):
    _tool_set = tool_set
    render()

func update(cell: WGCell):
    if not _cells.has(cell):
        _cells[cell] = cell
    emit_signal('changed')
    _rendered = false

func render():
    if _rendered: return
    _rendered = true
    RenderingServer.canvas_item_clear(_canvas)
    for c in _cells:
        var surfaces = (c as WGCell).get_surfaces()
        for surface_id in surfaces:
            var surface = _tool_set.get_surface(surface_id)
            _draw_surfaces(surface, surfaces[surface_id])


func _draw_surfaces(surface: WGSurface, polygons: Array):
    var w = surface.get_width()
    var h = surface.get_height()
    for polygon in polygons:
        var colors: PackedColorArray
        var uvs: PackedVector2Array
        var i: int = 0
        for p in polygon:
            var a: Vector2 = p
            a.x = a.x/float(w)
            a.y = a.y/float(h)
            uvs.append(a)
            colors.append(surface.color)
            i+=1
        if surface.texture:
            RenderingServer.canvas_item_add_polygon(_canvas, polygon, colors, uvs, surface.texture)
        else:
            RenderingServer.canvas_item_add_polygon(_canvas, polygon, colors, uvs)
        
        

