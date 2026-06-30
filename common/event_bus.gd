class_name EventBus
extends Object

static var subscribed_events: Dictionary[String, Array] = { }


static func subscribe(to: String, subscriber: Callable, unsubscribe_signal: Signal = Signal()) -> bool:
	if not subscriber.is_valid():
		printerr("Invalid Callable cannot subscribe to EventBus")
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


static func initialize_event(event: String) -> void:
	if not subscribed_events.has(event):
		subscribed_events[event] = []


static func trigger(event: String, etc: Variant = null) -> bool:
	# Event is not subscribed to
	if not event in subscribed_events:
		return false

	for subscriber in subscribed_events[event]:
		if not subscriber.is_valid():
			continue

		# Call with or without etc
		if etc == null:
			subscriber.call()
		else:
			subscriber.call(etc)
	return true


static func unsubscribe(from: String, subscriber: Callable) -> bool:
	if from in subscribed_events and subscribed_events[from] is Array:
		subscribed_events[from].erase(subscriber)
		return true
	return false
