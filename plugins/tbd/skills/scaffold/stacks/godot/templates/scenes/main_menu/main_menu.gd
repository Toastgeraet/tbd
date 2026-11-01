extends Control

## Main menu, and the project's entry point (see `application/run/main_scene`).
##
## Button presses are wired to the `_on_*_pressed` callbacks below via signal
## connections stored in `main_menu.tscn`.

## Scene swapped in when the player starts a new game.
@export_file("*.tscn") var new_game_scene: String = "res://scenes/game/game.tscn"

@onready var _menu_column: VBoxContainer = $MenuColumn
@onready var _continue_button: Button = %ContinueButton
@onready var _new_game_button: Button = %NewGameButton

## Remembered so controller navigation can resume after a click on empty space
## clears the viewport's focus owner.
var _last_focused: Button = null


func _ready() -> void:
	for button in _all_buttons():
		button.focus_entered.connect(_on_button_focus_entered.bind(button))
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))

	# No save system yet, so there is never anything to continue. Once saves
	# exist this becomes `_set_continue_enabled(SaveManager.has_save())`.
	_set_continue_enabled(false)

	# Give the first actionable entry focus so keyboard and controller players
	# can navigate the menu without touching the mouse.
	_new_game_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	# Clicking empty space clears the focus owner, which otherwise leaves the
	# menu unnavigable by controller. Restore focus on the next nav input.
	if get_viewport().gui_get_focus_owner() != null:
		return
	if not (event.is_action_pressed(&"ui_up")
			or event.is_action_pressed(&"ui_down")
			or event.is_action_pressed(&"ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if _last_focused != null and _last_focused.focus_mode != Control.FOCUS_NONE:
		_last_focused.grab_focus()
	else:
		_new_game_button.grab_focus()


## Toggles "Continue" and keeps focus navigation consistent with it.
func _set_continue_enabled(enabled: bool) -> void:
	_continue_button.disabled = not enabled
	# `disabled` on its own does NOT stop focus navigation from landing here,
	# which strands controller users on an entry that does nothing.
	_continue_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	_update_focus_wrap()


## Wraps navigation around both ends of the column. Recomputed whenever the set
## of focusable buttons changes, so it stays correct once "Continue" is enabled.
func _update_focus_wrap() -> void:
	for button in _all_buttons():
		button.focus_neighbor_top = ^""
		button.focus_neighbor_bottom = ^""
		button.focus_previous = ^""
		button.focus_next = ^""

	var buttons := _focusable_buttons()
	if buttons.size() < 2:
		return
	var first := buttons[0]
	var last := buttons[-1]
	first.focus_neighbor_top = first.get_path_to(last)
	first.focus_previous = first.get_path_to(last)
	last.focus_neighbor_bottom = last.get_path_to(first)
	last.focus_next = last.get_path_to(first)


func _all_buttons() -> Array[Button]:
	var result: Array[Button] = []
	for child in _menu_column.get_children():
		if child is Button:
			result.append(child)
	return result


func _focusable_buttons() -> Array[Button]:
	var result: Array[Button] = []
	for button in _all_buttons():
		if button.focus_mode != Control.FOCUS_NONE:
			result.append(button)
	return result


func _on_button_focus_entered(button: Button) -> void:
	_last_focused = button


func _on_button_mouse_entered(button: Button) -> void:
	# Hovering also takes focus, so the hover and focus highlights can never sit
	# on two different buttons at once. Guarded: grab_focus() errors on FOCUS_NONE.
	if button.focus_mode != Control.FOCUS_NONE:
		button.grab_focus()


func _on_continue_button_pressed() -> void:
	# TODO: resume from the most recent save.
	pass


func _on_new_game_button_pressed() -> void:
	var error := get_tree().change_scene_to_file(new_game_scene)
	if error != OK:
		push_error("Could not load '%s' (error %d)." % [new_game_scene, error])


func _on_load_game_button_pressed() -> void:
	# TODO: open the save slot browser.
	push_warning("Load Game is not implemented yet.")


func _on_settings_button_pressed() -> void:
	# TODO: open the settings menu.
	push_warning("Settings is not implemented yet.")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
