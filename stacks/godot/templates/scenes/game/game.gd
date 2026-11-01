extends Control

## Placeholder gameplay scene. Build the actual game in here.

## Scene returned to when the player backs out of gameplay.
@export_file("*.tscn") var main_menu_scene: String = "res://scenes/main_menu/main_menu.tscn"

@onready var _back_button: Button = %BackButton


func _ready() -> void:
	# Controller and keyboard players need something focused to press A/Enter on.
	_back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_main_menu()


func _on_back_button_pressed() -> void:
	_return_to_main_menu()


func _return_to_main_menu() -> void:
	var error := get_tree().change_scene_to_file(main_menu_scene)
	if error != OK:
		push_error("Could not load '%s' (error %d)." % [main_menu_scene, error])
