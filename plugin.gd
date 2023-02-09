@tool
extends EditorPlugin

class Pen:
    var radius: float = 25.0
    var vertexes: int = 12
    var is_active: bool = false
    var previous_position: Vector2
    var shape: PackedVector2Array

    signal draw(shape)

    func set_position(pos: Vector2):
        if is_active:
            if previous_position.distance_to(pos)>radius:
                emit_signal('draw', shape)
                previous_position = pos
        else:
            previous_position = pos

        shape = _make_polyline(previous_position, pos, radius, vertexes)

    func _make_polyline(from: Vector2, to: Vector2, radius: float, vertex_count: int = 10) -> PackedVector2Array:
        var a: PackedVector2Array = _make_circle(from, radius, vertex_count)
        var b: PackedVector2Array = _make_circle(to, radius, vertex_count)
        a.append_array(b)
        return Geometry2D.convex_hull(a)

    func _make_circle(position: Vector2, radius: float, segments: int = 12) -> PackedVector2Array:
        var result : PackedVector2Array = []
        var s: float = 2*PI/segments;
        for i in range(0, segments):
            var x : float = position.x + cos(i*s) * radius
            var y : float = position.y + sin(i*s) * radius
            result.append(Vector2(x, y))
        return result

var _is_in_edit_mode: bool = false
var _pen: Pen
var node: WormsTerrain
var _panel: Control

func _enter_tree():
    _pen = Pen.new()
    get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
    var gui = get_editor_interface().get_base_control()
    var icon = gui.get_theme_icon("KeyEasedSelected", "EditorIcons")
    add_custom_type("WormsTerrain", "Node2D", preload("WormsTerrain.gd"), icon)
    _panel = Control.new()
    add_control_to_bottom_panel(_panel,'WormsTerrain')

func _on_selection_changed():
    var selected: Array = get_editor_interface().get_selection().get_selected_nodes()
    if selected.size()==1 and selected[0] is WormsTerrain:
        node = selected[0]
        _is_in_edit_mode = true
    else:
        node = null
        _is_in_edit_mode = false

func _forward_canvas_draw_over_viewport(overlay: Control):
    if not _is_in_edit_mode: return false

    var vt: Transform2D = node.get_viewport_transform()
    var mouse_position: Vector2 = overlay.get_local_mouse_position()
    var pos_transform := Transform2D().translated(vt.get_origin()).inverse()
    var scale_transform := Transform2D().scaled(vt.get_scale())

    overlay.draw_polyline_colors(_pen.shape * scale_transform * pos_transform, PackedColorArray(), 1.0)

func _forward_canvas_gui_input(event) -> bool:
    if not _is_in_edit_mode: return false
    # ---------------------------------
    if (event is InputEventMouseButton):
        _pen.is_active = event.is_pressed()
        return true
    # ---------------------------------
    if (event is InputEventMouseMotion):
        var vt: Transform2D = node.get_viewport_transform()
        var global_mouse_position = _get_global_mouse_position(event.position)
        _pen.set_position(_get_global_mouse_position(event.position))
        update_overlays()
        return true
    return false
    
func _get_global_mouse_position(screen_point: Vector2) -> Vector2:
    var vt: Transform2D = node.get_viewport_transform()
    return vt.affine_inverse().get_origin() + screen_point*vt.affine_inverse().get_scale()

func _handles(object) -> bool:    
    return _is_in_edit_mode

func _exit_tree():    
    remove_custom_type("WormsTerrain")
    remove_control_from_bottom_panel(_panel)


