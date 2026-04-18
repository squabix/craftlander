class_name EventBus
extends Object

static var subscribed_events: Dictionary = {}

static func subscribe(to: String, subscriber: Callable, unsubscribe_signal: Signal = Signal()) -> bool:
	if subscriber.is_valid():
		if to in subscribed_events and subscribed_events[to] is Array:
			subscribed_events[to].append(subscriber)
		else:
			subscribed_events[to] = [subscriber]
		
		# Unsubscribe when received signal
		unsubscribe_signal.connect(EventBus.unsubscribe.bind(to, subscriber))
		return true
	else:
		printerr("Invalid Callable cannot subscribe to EventBus")
	return false

static func trigger(event: String, etc: Variant = null) -> bool:
	if event in subscribed_events:
		for subscriber in subscribed_events[event]:
			if subscriber.is_valid():
				if etc == null:
					subscriber.call()
				else:
					subscriber.call(etc)
		return true
	return false

static func unsubscribe(from: String, subscriber: Callable) -> bool:
	if from in subscribed_events and subscribed_events[from] is Array:
		subscribed_events[from].erase(subscriber)
		return true
	return false
