@tool
extends Button
signal selected

var _surface: WGSurface

func _ready():
    focus_mode = Control.FOCUS_NONE
    _refresh()

func get_surface() -> WGSurface:
    return _surface

func unselect():
    disabled = false

func init(surface: WGSurface):
    _surface = surface
    _surface.connect('changed', _refresh)

func _refresh():
    if _surface.texture!=null:
        $"%texture".texture = _surface.texture
        $"%texture".visible = true
        $"%texture".modulate = _surface.color
        $"%color".visible = false
    else:
        $"%color".color = _surface.color
        $"%texture".visible = false
        $"%color".visible = true

func _on_pressed():
    selected.emit()
    disabled = true

func _can_drop_data(position, data):
    return data['type']=='files' and data['files'].size()==1

func _drop_data(position, data):
    if data['type']=='files' and data['files'].size()==1:
        var image = load(data['files'][0])
        if image is Texture2D:
            _surface.texture = image

