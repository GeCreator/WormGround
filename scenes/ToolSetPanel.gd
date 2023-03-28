@tool
extends Control
signal action(name, value)

var _tool_set: WGToolSet
var SurfaceButton: PackedScene = preload("surface_button.tscn")
var _previous_surface_button_selected = null


func show_error(text: String):
    OS.alert(text)

func set_toolset(toolset):
    # disconnect from previous
    if _tool_set!=null and _tool_set.changed.is_connected(_refresh):
        _tool_set.changed.disconnect(_refresh)
    # connect to new
    if toolset!=null and not toolset.changed.is_connected(_refresh):
        toolset.changed.connect(_refresh)
    if _tool_set!=toolset:
        _tool_set = toolset
        _refresh()

func _refresh():
    if _tool_set == null:
        $info.show(); $panel.hide(); return
    $info.hide(); $panel.show()
    _clear_children($"%SurfaceContainer")
    var surfaces = _tool_set.get_surfaces()
    for id in surfaces:
        var surface_button = _create(SurfaceButton, {id=id, surface=surfaces[id]})
        surface_button.selected.connect(_on_surface_button_selected.bind(surface_button))
        $"%SurfaceContainer".add_child(surface_button)

func _create(scene: PackedScene, data):
    var instance = scene.instantiate()
    instance.init(data)
    return instance

func _clear_children(node: Node):
    for c in node.get_children():
        node.remove_child(c)
        c.queue_free()

func _on_create_surface_pressed():
    action.emit('surface_create', null)

func _on_surface_button_selected(button: Node):
    if _previous_surface_button_selected!=null:
        _previous_surface_button_selected.unselect()
    _previous_surface_button_selected = button
    action.emit('surface_select', button.get_id())

func _on_visibility_changed():
    emit_signal("action","panel_visibility_changed", visible)
