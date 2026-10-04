class_name IslandCarousel
extends Carousel


func get_options() -> Array[IslandOption]:
	var options: Array[IslandOption]
	options.assign(get_pages())
	return options


func get_current_option() -> IslandOption:
	return get_current_page() as IslandOption


func reload(boat_level: int) -> void:
	for option in get_options():
		option.reload(boat_level)
	select_island(Main.current_level_index, false)


func select_island(level_index: int, animate := true) -> void:
	var options := get_options()
	for i in options.size():
		if options[i].island_resource.index == level_index:
			select_page(i, animate)
			return
