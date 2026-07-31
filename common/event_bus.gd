class_name EventBus
extends Object

static var subscribed_events: Dictionary[StringName, Array] = { }


static func subscribe(to: StringName, subscriber: Callable, unsubscribe_signal: Signal = Signal()) -> bool:
	if Engine.is_editor_hint():
		return false
	
	if not subscriber.is_valid():
		push_error("Invalid Callable %s cannot subscribe to EventBus" % subscriber)
		return false

	# Initialize the array for this event if it doesn't exist
	initialize_event(to)

	# Prevent duplicate subscriptions
	if subscriber in subscribed_events[to]:
		return false

	subscribed_events[to].append(subscriber)

	# Unsubscribe when received signal
	if unsubscribe_signal.get_object() != null:
		unsubscribe_signal.connect(EventBus.unsubscribe.bind(to, subscriber), CONNECT_ONE_SHOT)
	return true


static func initialize_event(event: StringName) -> void:
	if not subscribed_events.has(event):
		subscribed_events[event] = []


static func trigger(event: StringName, etc: Variant = null) -> bool:
	if Engine.is_editor_hint():
		return false
	
	# Event is not subscribed to
	if not event in subscribed_events:
		return false
	
	var subscribers: Array[Callable]
	subscribers.assign(subscribed_events[event])
	for subscriber in subscribers:
		if not subscriber.is_valid():
			continue
		
		var object := subscriber.get_object()
		if object != null and not is_instance_valid(object):
			continue

		# Call with or without etc
		if etc == null:
			subscriber.call()
		else:
			subscriber.call(etc)
	return true


static func unsubscribe(from: StringName, subscriber: Callable) -> bool:
	if from in subscribed_events and subscribed_events[from] is Array:
		subscribed_events[from].erase(subscriber)
		return true
	return false
