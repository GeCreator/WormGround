@tool
class_name WGBorder

static func render(canvas: Array, cell: Array, thickness: float, color: Color) -> void:
    var canvas_rid = canvas[WGCanvas.DATA_CANVAS]
    var shapes: Array[PackedVector2Array] = cell[WGCell.DATA_SURFACE]
    for shape in shapes:
        RenderingServer.canvas_item_add_polyline(canvas_rid, shape, PackedColorArray([color]), thickness)

static func _get_parts(shape_size: int, bad_segments: Array) -> Array:
    var indexes = range(0,shape_size)
    var collection = []
    var b = bad_segments.pop_front()
    var part = []
    for i in indexes:
        if i==b:
            b = bad_segments.pop_front()
            if part.size()>0:
                collection.append(part)
                part = []
        else:
            part.append(i)

    if part.size()>0:
        collection.append(part)
    
    for c in collection:
        var value: int = c[-1]+1
        c.append(value if value<=indexes[-1] else 0)
    
    if collection.size()>1:
        if collection[0][0]==collection[-1][-1]:
            var append = collection.pop_front()
            collection[-1].pop_back()
            collection[-1].append_array(append)
            
    return collection
