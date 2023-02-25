@tool
extends TabContainer
signal action(name, value)

var _tool_set: WGToolSet
var SurfaceButton: PackedScene = preload("surface_button.tscn")
var _previous_surface_button_selected = null

func show_error(text: String):
    OS.alert(text)

func set_tool_set(toolset: WGToolSet):
    _tool_set = toolset
    if not _tool_set.changed.is_connected(_refresh):
        _tool_set.changed.connect(_refresh)
        _refresh()

func _refresh():
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
    action.emit('create_surface', null)

func _on_surface_button_selected(button: Node):
    if _previous_surface_button_selected!=null:
        _previous_surface_button_selected.unselect()
    _previous_surface_button_selected = button
    action.emit('tool_selected', {id=button.get_id(), tool=button.get_surface()})
    
