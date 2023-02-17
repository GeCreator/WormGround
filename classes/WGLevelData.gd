@tool
class_name WGLevelData extends Resource

## This container store all surface data.
## Do not edit manually!
@export var _data: Dictionary

func get_data() -> Dictionary:
    return _data

func set_data(data: Dictionary):
    _data = data
    emit_changed()

func get_value(key: String, default):
    if !_data.has(key):
        _data[key] = default
    return _data[key]
