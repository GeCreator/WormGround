@tool
class_name WGToolSet extends Resource

var _surfaces: Dictionary
var _borders: Dictionary
var _decals: Dictionary
var _brushes: Dictionary


func add_surface(surface: WGSurface) -> int:
    var id := _get_insert_id(_surfaces)
    _surfaces[id] = surface
    return id
    
    if Engine.is_editor_hint() && resource_path!='':
        ResourceSaver.save(self, resource_path)
    emit_changed()
    return id

func get_surfaces() -> Dictionary:
    return _surfaces

func get_surface(id: int) -> WGSurface:
    return _surfaces[id]

func _get_insert_id(d: Dictionary) -> int:
    var insert_id: int = 1
    for k in _surfaces:
        if insert_id<=int(k):
            insert_id = int(k)+1
    return insert_id

func _get_property_list():
    return [
        {
        "name": "_surfaces",
        "type": TYPE_DICTIONARY,
        "usage": PROPERTY_USAGE_STORAGE,
        },
        {
        "name": "_borders",
        "type": TYPE_DICTIONARY,
        "usage": PROPERTY_USAGE_STORAGE,
        },
        {
        "name": "_decals",
        "type": TYPE_DICTIONARY,
        "usage": PROPERTY_USAGE_STORAGE,
        },
        {
        "name": "_brushes",
        "type": TYPE_DICTIONARY,
        "usage": PROPERTY_USAGE_STORAGE,
        }
    ]

