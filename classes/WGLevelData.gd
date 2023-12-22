@tool
class_name WGLevelData extends Resource

## This container store all surface data.
var _data: String
# Main data(extracted)
var _data_size: int
var _is_modified: bool = false

func mark_as_modified():
    _is_modified = true

func save_changes(cells: Dictionary):
    if not _is_modified: return
    _is_modified = false
    var data: Array
    for k in cells:
        var cell: Array = cells[k]
        if not WGCell.is_empty(cell):
            data.append(cell)
    var buffer = var_to_bytes(data)
    _data_size = buffer.size()
    _data = Marshalls.raw_to_base64(buffer.compress(FileAccess.COMPRESSION_GZIP))
    if Engine.is_editor_hint() \
        and not resource_path.contains("::") \
        and not resource_path.is_empty():
            ResourceSaver.save(self, resource_path)

func get_data() -> Array:
    # extract all data from string
    if _data_size>0:
        var buffer := Marshalls.base64_to_raw(_data)
        buffer = buffer.decompress(_data_size, FileAccess.COMPRESSION_GZIP)
        return bytes_to_var(buffer)
    return []

func _get_property_list():
    return [
        {
            name = "_data",
            type = TYPE_STRING,
            usage = PROPERTY_USAGE_STORAGE,
        },
        {
            name = "_data_size",
            type = TYPE_INT,
            usage = PROPERTY_USAGE_STORAGE
        },
        {
            name = "_is_modified",
            type = TYPE_BOOL,
            usage = PROPERTY_USAGE_INTERNAL
        }
    ]
