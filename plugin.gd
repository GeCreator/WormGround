@tool
extends EditorPlugin


var _is_in_edit_mode: bool = false
var _brush: WGBrush
var _node: WormGround
var _panel: Control
var _panel_is_visible: bool = false
var _current_tool
var _current_tool_id: int
var _overlay: Control

func _enter_tree():
    _brush = WGBrush.new()
    _brush.draw.connect(_on_brush_draw)
    _brush.erase.connect(_on_brush_erase)
    
    get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
    var gui = get_editor_interface().get_base_control()
    var icon = gui.get_theme_icon("SphereShape3D", "EditorIcons")
    add_custom_type("WormGround", "Node2D", preload("classes/WormGround.gd"), icon)
    
    _panel = preload("./scenes/ToolSetPanel.tscn").instantiate()
    _panel.connect('action', _on_panel_action)

func _on_selection_changed():
    var selected: Array = get_editor_interface().get_selection().get_selected_nodes()
    if selected.size()==1 and selected[0] is WormGround:
        _node = selected[0]
        if not _node.property_list_changed.is_connected(_check_tool_set):
            _node.property_list_changed.connect(_check_tool_set)
        _check_tool_set()
    else:
        _is_in_edit_mode = false
        _node = null
        _diactivate_panel()

func _forward_canvas_draw_over_viewport(overlay: Control):
    if not _is_in_edit_mode: return false

    var vt: Transform2D = _node.get_viewport_transform()
    var mouse_position: Vector2 = overlay.get_local_mouse_position()
    var pos_transform := Transform2D().translated(vt.get_origin()).inverse()
    var scale_transform := Transform2D().scaled(vt.get_scale())

    overlay.draw_polyline_colors(_brush.shape * scale_transform * pos_transform, PackedColorArray(), 1.0)

func _forward_canvas_gui_input(event) -> bool:
    if not _is_in_edit_mode: return false
    # ---------------------------------
    if (event is InputEventKey):
        if event.keycode == KEY_ESCAPE:
            _is_in_edit_mode = false
            update_overlays()
            return true
    # ---------------------------------
    if (event is InputEventMouseButton):
        if event.button_index == MOUSE_BUTTON_LEFT \
        || event.button_index == MOUSE_BUTTON_RIGHT:
            _brush.is_active = event.is_pressed()
            _brush.button = event.button_index
        return true
    # ---------------------------------
    if (event is InputEventMouseMotion):
        var vt: Transform2D = _node.get_viewport_transform()
        var global_mouse_position = _get_global_mouse_position(event.position)
        _brush.set_position(global_mouse_position)
        update_overlays()
        return true
    return false

func _get_global_mouse_position(screen_point: Vector2) -> Vector2:
    var vt: Transform2D = _node.get_viewport_transform()
    return vt.affine_inverse().get_origin() + screen_point*vt.affine_inverse().get_scale()

func _on_brush_draw(shape: PackedVector2Array):
    if not _is_in_edit_mode: return
    if _current_tool is WGSurface:
        _node.add_surface(_current_tool_id, shape)

func _on_brush_erase(shape: PackedVector2Array):
    if not _is_in_edit_mode: return
    if _current_tool is WGSurface:
        _node.remove_surface(shape)

func _handles(object) -> bool:
    return _is_in_edit_mode

func _activate_panel():
    if _panel_is_visible: return
    _panel_is_visible = true
    add_control_to_bottom_panel(_panel,'WormGround')
    make_bottom_panel_item_visible(_panel)

func _diactivate_panel():
    _panel_is_visible = false
    remove_control_from_bottom_panel(_panel)

func _on_panel_action(action: String, value):
    match(action):
        'create_surface':
            var surface := WGSurface.new()
            _node.tool_set.add_surface(surface)
            get_editor_interface().edit_resource(surface)
        'tool_selected':
            _is_in_edit_mode = true
            _current_tool = value["tool"]
            _current_tool_id = value["id"]
            get_editor_interface().edit_resource(_current_tool)
        _: print('unknow panel action')

func _check_tool_set():
    if _node.tool_set is WGToolSet:
        _panel.set_tool_set(_node.tool_set)
        _activate_panel()
    else:
        _diactivate_panel()

func _exit_tree():
    remove_custom_type("WormGround")
    _diactivate_panel()
    _panel.queue_free()


