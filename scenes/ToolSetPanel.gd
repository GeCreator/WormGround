@tool
extends Control
signal action(name, value)

func _on_create_surfaces_pressed():
    var sname: String = $GridContainer/name.text
    sname = sname.strip_edges()
    if sname.length()>0:
        action.emit('create_surface', sname)
    else:
        show_error('Enter any unique name you want')

func show_error(text: String):
    OS.alert(text)
