class_name SaveDeleteConfirmation
extends RefCounted

const WINDOW_MS := 3000
var deadline := -1

func request(now_ms: int) -> bool:
	if deadline >= 0 and now_ms < deadline:
		deadline = -1
		return true
	deadline = now_ms + WINDOW_MS
	return false

func pending(now_ms: int) -> bool:
	return deadline >= 0 and now_ms < deadline
