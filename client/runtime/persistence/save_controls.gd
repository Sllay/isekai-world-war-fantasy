extends CanvasLayer

var save_action: Callable
var delete_action: Callable
var confirmation := SaveDeleteConfirmation.new()
var delete_button := Button.new()
var feedback := Label.new()

func _ready() -> void:
	var button := Button.new()
	button.text = "Save (K)"
	button.position = Vector2(get_viewport().get_visible_rect().size.x - 280, 20)
	button.size = Vector2(130, 55)
	button.pressed.connect(_save)
	add_child(button)
	delete_button.text = "Delete Save"
	delete_button.position = button.position + Vector2(-155, 0)
	delete_button.size = Vector2(150, 55)
	delete_button.pressed.connect(_delete)
	add_child(delete_button)
	feedback.position = button.position + Vector2(0, 60)
	add_child(feedback)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_K and event.pressed and not event.echo:
		_save()
		get_viewport().set_input_as_handled()

func _save() -> void:
	var error: Error = save_action.call()
	feedback.text = "Saved" if error == OK else "Save failed (%d)" % error

func _delete() -> void:
	if not confirmation.request(Time.get_ticks_msec()):
		delete_button.text = "Confirm Delete"
		return
	var error: Error = delete_action.call()
	feedback.text = "Save deleted; new game" if error == OK else "Delete failed (%d)" % error
	delete_button.text = "Delete Save"

func _process(_delta: float) -> void:
	if not confirmation.pending(Time.get_ticks_msec()):
		delete_button.text = "Delete Save"
