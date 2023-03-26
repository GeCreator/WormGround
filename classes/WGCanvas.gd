@tool
class_name WGCanvas
signal changed

var _canvas: RID
var _tool_set: WGToolSet
var _cells: Dictionary
var _physics: Dictionary

var _brush: WGSurface
var _polygons: Array[PackedVector2Array]
var _rendered: bool = true
var _used_surfaces: Dictionary

func _init(base_canvas: RID):
    _canvas = RenderingServer.canvas_item_create()
    RenderingServer.canvas_item_set_parent(_canvas, base_canvas)
    RenderingServer.canvas_item_set_default_texture_repeat(_canvas, RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_ENABLED)
    #RenderingServer.canvas_item_set_default_texture_filter(_canvas, RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST)

func set_toolset(tool_set: WGToolSet):
    _tool_set = tool_set
    render()

func on_cell_changed(cell: WGCell):
    if not _cells.has(cell):
        _cells[cell] = cell
    emit_changed()

func on_physic_changed(physic: WGPhysic):
    if not _physics.has(physic):
        _physics[physic] = physic
    emit_changed()

func render():
    if _rendered: return
    _rendered = true
    RenderingServer.canvas_item_clear(_canvas)
    for c in _cells:
        var surfaces = (c as WGCell).get_surfaces()
        for surface_id in surfaces:
            if not _used_surfaces.has(surface_id):
                _used_surfaces[surface_id] = _tool_set.get_surface(surface_id)
                (_used_surfaces[surface_id] as WGSurface).changed.connect(emit_changed)
            var surface = _used_surfaces[surface_id]
            _draw_surfaces(surface, surfaces[surface_id])

    for p in _physics:
        var shapes = (p as WGPhysic).get_active_shapes()
        _draw_collision_shapes(shapes)

func _draw_surfaces(surface: WGSurface, polygons: Array):
    var size := surface.get_size()
    var colors := PackedColorArray([surface.color])
    for polygon in polygons:
        #colors = PackedColorArray([_get_next_debug_color()])
        var uvs: PackedVector2Array
        for p in polygon:
            var a: Vector2 = p / size * surface.scale
            uvs.append(a)
        if surface.texture:
            RenderingServer.canvas_item_add_polygon(_canvas, polygon, colors, uvs, surface.texture)
        else:
            RenderingServer.canvas_item_add_polygon(_canvas, polygon, colors, uvs)

func _draw_collision_shapes(shapes:Array[PackedVector2Array]):
    var colors = _get_debug_colors()
    var line_color = PackedColorArray([Color.BLACK])
    var uvs: PackedVector2Array
    var i: int = 0
    for polygon in shapes:
        var color: Color = colors[wrapi(i, 0 ,colors.size())]
        color.a = 0.6
        var c:=PackedColorArray([color])
        RenderingServer.canvas_item_add_polygon(_canvas, polygon, c, uvs)
        RenderingServer.canvas_item_add_polyline(_canvas, polygon, line_color)
        i+=1

func emit_changed():
    _rendered = false
    emit_signal("changed")

func _get_debug_colors() -> PackedColorArray:
    return PackedColorArray( [
        Color.RED,
        Color.ORANGE,
        Color.YELLOW,
        Color.GREEN,
        Color.SKY_BLUE,
        Color.BLUE,
        Color.PALE_VIOLET_RED,
        Color.DARK_GOLDENROD,
        Color.ROYAL_BLUE,
        Color.REBECCA_PURPLE,
        Color.FUCHSIA,
        Color.INDIGO,
        Color.FUCHSIA,
        Color.LIGHT_GOLDENROD,
        Color.ORANGE_RED
    ])
