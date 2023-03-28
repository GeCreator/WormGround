@tool
extends HBoxContainer
signal action(name, value)

func _ready():
    $edit.icon = get_theme_icon("SphereShape3D", "EditorIcons")

func _on_edit_pressed():
    emit_signal("action", "tool_brush", null)
