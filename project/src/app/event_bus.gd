## 事件总线（Layer 2 应用层）。
##
## 订阅-分发模式，将 Layer 1 产出的事件分发给订阅者。
## 表现层、网络层、AI 层均可订阅事件。
##
## 见 ARCHITECTURE §3.3、§4.1。
class_name EventBus extends RefCounted

## 订阅者回调签名：func(event: Event) -> void
## 事件类型 -> 订阅者回调数组
var _subscribers: Dictionary = {}
## 全局订阅者（订阅所有事件）
var _global_subscribers: Array = []


## 订阅指定类型的事件。
## [param event_type] 事件类型（Event.TYPE_*），-1 表示订阅所有
## [param callback] 回调 Callable
func subscribe(event_type: int, callback: Callable) -> void:
	if event_type < 0:
		_global_subscribers.append(callback)
	else:
		if not _subscribers.has(event_type):
			_subscribers[event_type] = []
		_subscribers[event_type].append(callback)


## 取消订阅。
## [param event_type] 事件类型，-1 表示全局
## [param callback] 回调 Callable
func unsubscribe(event_type: int, callback: Callable) -> void:
	if event_type < 0:
		_global_subscribers.erase(callback)
	else:
		if _subscribers.has(event_type):
			_subscribers[event_type].erase(callback)


## 分发单个事件给所有订阅者。
func dispatch(event: Event) -> void:
	# 先分发给特定类型订阅者
	var type_subs: Array = _subscribers.get(event.event_type, [])
	for cb in type_subs:
		cb.call(event)
	# 再分发给全局订阅者
	for cb in _global_subscribers:
		cb.call(event)


## 分发多个事件。
func dispatch_all(events: Array) -> void:
	for e in events:
		dispatch(e)


## 清除所有订阅。
func clear() -> void:
	_subscribers.clear()
	_global_subscribers.clear()


## 获取指定类型的订阅者数量。
func subscriber_count(event_type: int) -> int:
	if event_type < 0:
		return _global_subscribers.size()
	return _subscribers.get(event_type, []).size()


## 总订阅者数量（含全局）。
func total_subscribers() -> int:
	var count: int = _global_subscribers.size()
	for key in _subscribers.keys():
		count += _subscribers[key].size()
	return count
