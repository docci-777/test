## EventBus 单元测试。
extends GutTest

var _bus: EventBus
var _received_events: Array


func before_each():
	_bus = EventBus.new()
	_received_events = []


func test_subscribe_and_dispatch():
	_bus.subscribe(Event.TYPE_DICE_ROLLED, func(e: Event): _received_events.append(e))
	var e := Event.create_dice_rolled(0, 3, 4)
	_bus.dispatch(e)
	assert_eq(_received_events.size(), 1)


func test_global_subscriber():
	_bus.subscribe(-1, func(e: Event): _received_events.append(e))
	_bus.dispatch(Event.create_dice_rolled(0, 1, 2))
	_bus.dispatch(Event.create_turn_started(0, 1))
	assert_eq(_received_events.size(), 2)


func test_unsubscribe():
	var cb := func(e: Event): _received_events.append(e)
	_bus.subscribe(Event.TYPE_DICE_ROLLED, cb)
	_bus.unsubscribe(Event.TYPE_DICE_ROLLED, cb)
	_bus.dispatch(Event.create_dice_rolled(0, 1, 2))
	assert_eq(_received_events.size(), 0)


func test_unsubscribe_global():
	var cb := func(e: Event): _received_events.append(e)
	_bus.subscribe(-1, cb)
	_bus.unsubscribe(-1, cb)
	_bus.dispatch(Event.create_dice_rolled(0, 1, 2))
	assert_eq(_received_events.size(), 0)


func test_dispatch_all():
	_bus.subscribe(-1, func(e: Event): _received_events.append(e))
	var events := [Event.create_dice_rolled(0, 1, 2), Event.create_turn_started(0, 1)]
	_bus.dispatch_all(events)
	assert_eq(_received_events.size(), 2)


func test_multiple_subscribers():
	_bus.subscribe(Event.TYPE_DICE_ROLLED, func(e: Event): _received_events.append(e))
	var received2: Array = []
	_bus.subscribe(Event.TYPE_DICE_ROLLED, func(e: Event): received2.append(e))
	_bus.dispatch(Event.create_dice_rolled(0, 1, 2))
	assert_eq(_received_events.size(), 1)
	assert_eq(received2.size(), 1)


func test_type_isolation():
	_bus.subscribe(Event.TYPE_DICE_ROLLED, func(e: Event): _received_events.append(e))
	_bus.dispatch(Event.create_turn_started(0, 1))
	assert_eq(_received_events.size(), 0)


func test_clear():
	_bus.subscribe(Event.TYPE_DICE_ROLLED, func(e: Event): _received_events.append(e))
	_bus.subscribe(-1, func(e: Event): _received_events.append(e))
	_bus.clear()
	_bus.dispatch(Event.create_dice_rolled(0, 1, 2))
	assert_eq(_received_events.size(), 0)


func test_subscriber_count():
	_bus.subscribe(Event.TYPE_DICE_ROLLED, func(e: Event): pass)
	_bus.subscribe(Event.TYPE_DICE_ROLLED, func(e: Event): pass)
	_bus.subscribe(-1, func(e: Event): pass)
	assert_eq(_bus.subscriber_count(Event.TYPE_DICE_ROLLED), 2)
	assert_eq(_bus.subscriber_count(-1), 1)
	assert_eq(_bus.total_subscribers(), 3)
