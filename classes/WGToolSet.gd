@tool
class_name WGToolSet extends Resource

var _surfaces: Dictionary
var _borders: Dictionary
var _decals: Dictionary
var _brushes: Dictionary

func make_surface() -> WGSurface:
    var surface := WGSurface.new()
    var insert_id: int = 1
    for k in _surfaces:
        print(int(k))
        if insert_id<=int(k):
            insert_id = int(k)+1
    _surfaces[insert_id] = surface
    return surface

func _get_property_list():
    return [
        {
        "name": "_borders",
        "type": TYPE_DICTIONARY,
        "usage": PROPERTY_USAGE_STORAGE,
        },
        {
        "name": "_surfaces",
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
