extends Entity3D
class_name EntityVehicle3D

@export var seats: Array[Seat3D]
@export var dismount_areas: Array[Area3D]

func get_open_seats() -> Array[Seat3D]:
	var open_seats: Array[Seat3D]
	for seat in seats:
		if seat.is_open():
			open_seats.append(seat)
	return open_seats

func fill_seats(entities: Array[Entity3D]) -> Array[Entity3D]:
	var open_seats: Array[Seat3D] = get_open_seats()
	for entity in entities:
		if open_seats.is_empty():
			return entities
		
		for seat in open_seats:
			if not seat.mount(entity):
				continue
			entities.erase(entity)
			open_seats.erase(seat)
			break
	
	return entities
