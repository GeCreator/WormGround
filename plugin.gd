@tool
extends EditorPlugin

var _is_handle: bool = false
var _is_in_edit_mode: bool = false
var _tools_visible: bool = false
var _in_canvas: bool = false

var _brush: WGBrush
var _node: WormGround
var _tool_buttons: HBoxContainer


func _enter_tree():
    _brush = WGBrush.new()
    _brush.draw.connect(_on_brush_draw)
    _brush.erase.connect(_on_brush_erase)
    _brush.changed.connect(update_overlays)
    
    get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
    var gui = get_editor_interface().get_base_control()
    var icon = gui.get_theme_icon("SphereShape3D", "EditorIcons")
    add_custom_type("WormGround", "Node2D", preload("classes/WormGround.gd"), icon)
    
    _tool_buttons = _make_ui_element(preload("./scenes/editor_menu/editor_menu.tscn"))

func _on_selection_changed():
    var selected: Array = get_editor_interface().get_selection().get_selected_nodes()
    _is_handle = selected.size()==1 and selected[0] is WormGround
    if _is_handle:
        _node = selected[0]
        
        if not _node.property_list_changed.is_connected(_on_property_list_changed):
            _node.property_list_changed.connect(_on_property_list_changed)
        _activate_ui()
        _on_property_list_changed()
    else:
        if _node!=null and _node.property_list_changed.is_connected(_on_property_list_changed):
            _node.property_list_changed.disconnect(_on_property_list_changed)
            _is_in_edit_mode = false
            _node = null
            _diactivate_ui()

func _cavas_mouse_entered(entered: bool):
    _in_canvas = entered

func _forward_canvas_draw_over_viewport(overlay: Control):
    # only for fix error(when switch tabs)
    if not overlay.is_connected("mouse_exited", _cavas_mouse_entered):
        overlay.connect("mouse_entered", _cavas_mouse_entered.bind(true))
        overlay.connect("mouse_exited", _cavas_mouse_entered.bind(false))
        
    if not _in_canvas || not _is_in_edit_mode:
        overlay.mouse_default_cursor_shape = Control.CURSOR_ARROW
        return false
    overlay.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    
    var vt: Transform2D = _node.get_viewport_transform()
    var mouse_position: Vector2 = overlay.get_local_mouse_position()
    var pos_transform := Transform2D().translated(vt.get_origin()).inverse()
    var scale_transform := Transform2D().scaled(vt.get_scale())

    overlay.draw_polyline_colors(_brush.shape * scale_transform * pos_transform, PackedColorArray(), 1.0)

func _forward_canvas_gui_input(event) -> bool:
    if not _is_in_edit_mode: return false
    # ---------------------------------
    if (event is InputEventKey):
        if event.keycode == KEY_SHIFT:
            _brush.hold(event.is_pressed())
            return true
        if event.keycode == KEY_ESCAPE:
            _is_in_edit_mode = false
            update_overlays()
            return true
    # ---------------------------------
    if (event is InputEventMouseButton):
        _brush.click(event.button_index, event.is_pressed())
        return true
    # ---------------------------------
    if (event is InputEventMouseMotion):
        _brush.update_position(_get_global_mouse_position(event.position))
        return true
    return false

func _get_global_mouse_position(screen_point: Vector2) -> Vector2:
    var vt: Transform2D = _node.get_viewport_transform()
    return vt.affine_inverse().get_origin() + screen_point*vt.affine_inverse().get_scale()

func _on_brush_draw(shape: PackedVector2Array):
    if not _is_in_edit_mode: return
    _node.add_surface(_current_surface, shape)

func _on_brush_erase(shape: PackedVector2Array):
    if not _is_in_edit_mode: return
    _node.remove_surface(shape)

func _handles(object) -> bool:
    return _is_handle

func _activate_ui():
    if _tools_visible: return
    _tools_visible = true
    add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _tool_buttons)

func _diactivate_ui():
    if not _tools_visible: return
    _tools_visible = false
    remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _tool_buttons)

func _on_ui_action(action: String, value):
    match(action):
        "tool_brush":
            _is_in_edit_mode = true
        _: print(action,": ", value)

func _on_property_list_changed():
    _node.update_configuration_warnings()

func _exit_tree():
    _diactivate_ui()
    _tool_buttons.queue_free()
    remove_custom_type("WormGround")

func _make_ui_element(scene: PackedScene):
    var ui = scene.instantiate()
    ui.connect('action', _on_ui_action)
    return ui
