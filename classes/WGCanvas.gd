@tool
class_name WGCanvas

const DATA_CANVAS: int = 0
const DATA_CELLS: int = 1

static func create(base: RID) -> Array:
    var canvas = RenderingServer.canvas_item_create()
    RenderingServer.canvas_item_set_parent(canvas, base)
    RenderingServer.canvas_item_set_default_texture_repeat(canvas, RenderingServer.CANVAS_ITEM_TEXTURE_REPEAT_ENABLED)
    var result: Array
    result.resize(2)
    result[DATA_CANVAS] = canvas
    result[DATA_CELLS] = []
    return result

static func render(canvas_data: Array, toolset: WGToolSet):
    var canvas :RID = canvas_data[DATA_CANVAS]
    var cells :Array = canvas_data[DATA_CELLS]
    RenderingServer.canvas_item_clear(canvas)
    for c in cells:
        var surfaces = c[WGCell.DATA_SURFACE]
        for surface_id in surfaces:
            var surface = toolset.get_surface(surface_id)
            _draw_surfaces(canvas, surface, surfaces[surface_id])

static func render_debug(canvas_data: Array, physics: Dictionary):
    var cells :Array = canvas_data[DATA_CELLS]
    var canvas: RID = canvas_data[DATA_CANVAS]
    for cell in cells:
        var id = WGCell.get_id(cell)
        var shapes = WGPhysic.get_active_shapes(physics[id])
        _draw_collision_shapes(canvas, shapes)

static func _draw_surfaces(canvas: RID, surface: WGSurface, polygons: Array):
    var size := surface.get_size()
    var colors := PackedColorArray([surface.color])
    for polygon in polygons:
        var uvs: PackedVector2Array
        for p in polygon:
            var a: Vector2 = p / size * surface.scale
            uvs.append(a)
        if surface.texture:
            RenderingServer.canvas_item_add_polygon(canvas, polygon, colors, uvs, surface.texture)
        else:
            RenderingServer.canvas_item_add_polygon(canvas, polygon, colors, uvs)

static func _draw_collision_shapes(canvas: RID, shapes:Array[PackedVector2Array]):
    var colors = _get_debug_colors()
    var line_color = PackedColorArray([Color.BLACK])
    var uvs: PackedVector2Array
    var i: int = 0
    for polygon in shapes:
        var color: Color = colors[wrapi(i, 0 ,colors.size())]
        color.a = 0.6
        var c:=PackedColorArray([color])
        RenderingServer.canvas_item_add_polygon(canvas, polygon, c, uvs)
        RenderingServer.canvas_item_add_polyline(canvas, polygon, line_color)
        i+=1

static func make_id(cell_coords: Vector2) -> int:
    var canvas_coords := (cell_coords - cell_coords.posmod(2.0))/2.0
    return WGUtils.make_cell_id(canvas_coords, WormGround.MAX_BLOCK_RANGE)

static func _get_debug_colors() -> PackedColorArray:
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
