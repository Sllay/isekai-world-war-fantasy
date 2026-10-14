class_name CoreTickScheduler
extends RefCounted

var max_callbacks_per_frame: int = 32
var _next_token: int = 1
var _jobs: Dictionary = {}
var _heap: Array[Dictionary] = []

func schedule(deadline: int, callback: Callable, interval: int = 0) -> int:
	if deadline < 0 or interval < 0 or not callback.is_valid():
		return 0
	var token := _next_token
	_next_token += 1
	var job := {"token": token, "deadline": deadline, "callback": callback, "interval": interval}
	_jobs[token] = job
	_push(job)
	return token

func cancel(token: int) -> void:
	_jobs.erase(token)

func run_due(tick: int) -> int:
	var processed := 0
	var examined := 0
	while not _heap.is_empty() and _heap[0].deadline <= tick and examined < max_callbacks_per_frame:
		var job := _pop()
		examined += 1
		if not _jobs.has(job.token):
			continue
		if not job.callback.is_valid():
			_jobs.erase(job.token)
			continue
		job.callback.call(int(job.deadline))
		processed += 1
		if _jobs.has(job.token):
			if job.interval > 0:
				job.deadline += job.interval
				_push(job)
			else:
				_jobs.erase(job.token)
	return processed

func _before(a: Dictionary, b: Dictionary) -> bool:
	return a.deadline < b.deadline or (a.deadline == b.deadline and a.token < b.token)

func _push(job: Dictionary) -> void:
	_heap.append(job)
	var index := _heap.size() - 1
	while index > 0:
		var parent := (index - 1) / 2
		if not _before(_heap[index], _heap[parent]):
			break
		var swap := _heap[parent]
		_heap[parent] = _heap[index]
		_heap[index] = swap
		index = parent

func _pop() -> Dictionary:
	var result: Dictionary = _heap[0]
	var last: Dictionary = _heap.pop_back()
	if _heap.is_empty():
		return result
	_heap[0] = last
	var index := 0
	while index * 2 + 1 < _heap.size():
		var child := index * 2 + 1
		if child + 1 < _heap.size() and _before(_heap[child + 1], _heap[child]):
			child += 1
		if not _before(_heap[child], _heap[index]):
			break
		var swap := _heap[index]
		_heap[index] = _heap[child]
		_heap[child] = swap
		index = child
	return result

func clear() -> void:
	_jobs.clear()
	_heap.clear()
