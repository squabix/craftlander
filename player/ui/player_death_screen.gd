extends Menu

@export var respawn_button: Button
@export var quit_button: Button
@export var health: Health

@export_group("Animation", "animation")
@export var animation_player: AnimationPlayer
@export var animation_title_label: Control
@export var animation_intro := &"intro"


func _ready() -> void:
	super()
	hide()
	health.died.connect(open_death_screen)
	health.revived.connect(close_death_screen)
	animation_title_label.resized.connect(update_title_pivot)
	animation_player.animation_finished.connect(_on_animation_finished)

	if quit_button.pressed.is_connected(Main.root.quit_to_title):
		return
	quit_button.pressed.connect(Main.root.quit_to_title)


func open_death_screen() -> void:
	show()
	set_buttons_disabled(true)
	update_title_pivot()

	animation_player.play(animation_intro)
	animation_player.advance(0.0)


func close_death_screen() -> void:
	animation_player.stop()
	hide()


func reveal_buttons() -> void:
	set_buttons_disabled(false)
	respawn_button.grab_focus()


func set_buttons_disabled(to: bool) -> void:
	respawn_button.disabled = to
	quit_button.disabled = to


func update_title_pivot() -> void:
	animation_title_label.pivot_offset = animation_title_label.size / 2.0


func _on_animation_finished(animation: StringName) -> void:
	if animation == animation_intro:
		reveal_buttons()
