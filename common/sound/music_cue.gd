class_name MusicCue
extends Resource

@export var stream: AudioStream
@export_custom(PROPERTY_HINT_NONE, "suffix:dB") var volume_db := 0.0
@export var loop := true

@export_group("Fade", "fade")
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fade_in := 1.5
@export_custom(PROPERTY_HINT_NONE, "suffix:s") var fade_out := 1.5
