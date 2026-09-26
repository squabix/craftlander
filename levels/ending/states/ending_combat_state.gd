class_name EndingCombatState
extends EndingState


func enter() -> void:
	encounter.wave_spawner.finished.connect(on_waves_finished)
	super()


func exit() -> void:
	encounter.wave_spawner.finished.disconnect(on_waves_finished)


func on_waves_finished() -> void:
	encounter.abort()
