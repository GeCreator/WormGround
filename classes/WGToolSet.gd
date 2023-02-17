@tool
class_name WGToolSet extends Resource

@export var _surfaces: Dictionary

func add_surface(surface_name: String, surface: WGSurface) -> bool:
    if _surfaces.has(surface_name): return false
    _surfaces[surface_name] = surface
    return true
